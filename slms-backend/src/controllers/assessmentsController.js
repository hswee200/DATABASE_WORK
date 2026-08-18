const { withRole } = require('../db');
const { canModifyCourseContent, canReadCourse } = require('../auth/access');

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;
// Not schema-enforced (AssessmentType is a plain VARCHAR(50)) - these are the
// values the seed data uses and what the frontend offers, but not a hard
// whitelist, so a lecturer isn't blocked from a type like "Exam" or "Project".

// AssessmentCategory IS schema-enforced (an ENUM) - it drives weighting in
// vw_course_grades (Midsem 20%, Final 40%, Regular splits the rest), so
// unlike AssessmentType this one is a real whitelist.
const ASSESSMENT_CATEGORIES = new Set(['Regular', 'Midsem', 'Final']);

async function loadAssessmentContext(conn, assessmentId) {
  const [rows] = await conn.execute(
    `SELECT a.AssessmentID, a.CourseID, c.LecturerID
       FROM ASSESSMENT a
       JOIN COURSE c ON a.CourseID = c.CourseID
      WHERE a.AssessmentID = ?`,
    [assessmentId]
  );
  return rows[0] || null;
}

// Lecturer-only, own course only - editing an assessment's due date or max
// score is an academic-judgment call, not an administrative one. No Admin
// exception (see canModifyCourseContent).
async function updateAssessment(req, res, next) {
  try {
    const { assessmentId } = req.params;
    const { dueDate, maxScore } = req.body || {};

    if (typeof dueDate !== 'string' || !ISO_DATE.test(dueDate)) {
      return res.status(400).json({ error: 'dueDate is required in YYYY-MM-DD format.' });
    }
    if (typeof maxScore !== 'number' || !Number.isFinite(maxScore) || maxScore <= 0) {
      return res.status(400).json({ error: 'maxScore is required and must be a positive number.' });
    }

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      const context = await loadAssessmentContext(conn, assessmentId);
      if (!context) return { notFound: true };

      // Ownership is checked before the call, not after: sp_update_assessment
      // runs as DEFINER=root and would otherwise edit any lecturer's assessment.
      if (!canModifyCourseContent(req.user, context.LecturerID)) return { forbidden: true };

      await conn.query('CALL sp_update_assessment(?, ?, ?)', [assessmentId, dueDate, maxScore]);

      const [rows] = await conn.execute(
        'SELECT AssessmentID, CourseID, AssessmentName, AssessmentType, DueDate, MaxScore FROM ASSESSMENT WHERE AssessmentID = ?',
        [assessmentId]
      );
      return { assessment: rows[0] };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No assessment found with ID ${assessmentId}.` });
    }
    if (outcome.forbidden) {
      return res.status(403).json({ error: 'Not permitted to edit this assessment.' });
    }

    const a = outcome.assessment;
    return res.json({
      assessmentId: a.AssessmentID,
      courseId: a.CourseID,
      assessmentName: a.AssessmentName,
      assessmentType: a.AssessmentType,
      dueDate: a.DueDate,
      maxScore: Number(a.MaxScore),
    });
  } catch (err) {
    return next(err);
  }
}

// Lecturer-only, own course only - creating an assessment is the prerequisite
// an "Edit Assessment" action assumes already happened. No Admin exception,
// same reasoning as updateAssessment.
async function createAssessment(req, res, next) {
  try {
    const { courseId } = req.params;
    const { assessmentType, assessmentName, maxScore, dueDate } = req.body || {};
    // Unchecked in the UI (neither Midsem nor Final) means Regular - the
    // frontend only ever sends this field when one of the two is checked.
    const assessmentCategory = req.body?.assessmentCategory || 'Regular';

    if (typeof assessmentType !== 'string' || assessmentType.trim() === '') {
      return res.status(400).json({ error: 'assessmentType is required.' });
    }
    if (typeof assessmentName !== 'string' || assessmentName.trim() === '') {
      return res.status(400).json({ error: 'assessmentName is required.' });
    }
    if (typeof maxScore !== 'number' || !Number.isFinite(maxScore) || maxScore <= 0) {
      return res.status(400).json({ error: 'maxScore is required and must be a positive number.' });
    }
    if (typeof dueDate !== 'string' || !ISO_DATE.test(dueDate)) {
      return res.status(400).json({ error: 'dueDate is required in YYYY-MM-DD format.' });
    }
    if (!ASSESSMENT_CATEGORIES.has(assessmentCategory)) {
      return res.status(400).json({ error: 'assessmentCategory must be one of Regular, Midsem, Final.' });
    }

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      const [courses] = await conn.execute(
        'SELECT CourseID, CourseName, LecturerID FROM COURSE WHERE CourseID = ?',
        [courseId]
      );
      if (courses.length === 0) return { notFound: true };

      const course = courses[0];
      if (!canModifyCourseContent(req.user, course.LecturerID)) return { forbidden: true };

      // AssessmentID is never supplied by the caller - the procedure
      // generates it internally (same pattern as sp_enroll_student) and
      // returns it via a trailing SELECT.
      const [result] = await conn.query('CALL sp_create_assessment(?, ?, ?, ?, ?, ?)', [
        courseId,
        assessmentType,
        assessmentName,
        maxScore,
        dueDate,
        assessmentCategory,
      ]);

      return { course, assessmentId: result[0][0].AssessmentID };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No course found with ID ${courseId}.` });
    }
    if (outcome.forbidden) {
      return res.status(403).json({ error: 'Not permitted to create an assessment for this course.' });
    }

    return res.status(201).json({
      assessmentId: outcome.assessmentId,
      courseId,
      courseName: outcome.course.CourseName,
      assessmentType,
      assessmentName,
      maxScore,
      dueDate,
      assessmentCategory,
    });
  } catch (err) {
    // sp_create_assessment raises 45000 when the course already has a
    // Midsem/Final (at most one of each).
    if (err.sqlState === '45000') {
      return res.status(409).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

// Read-only for whoever can already read the course: Admin any, Lecturer own,
// Student if enrolled - reuses the exact rule getRoster already applies.
async function getCourseAssessments(req, res, next) {
  try {
    const { courseId } = req.params;

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      const [courses] = await conn.execute(
        'SELECT CourseID, LecturerID FROM COURSE WHERE CourseID = ?',
        [courseId]
      );
      if (courses.length === 0) return { notFound: true };

      const course = courses[0];

      let isEnrolled = false;
      if (req.user.roleName === 'Student') {
        const [enrolments] = await conn.execute(
          'SELECT EnrollmentID FROM ENROLLMENT WHERE StudentID = ? AND CourseID = ?',
          [req.user.username, courseId]
        );
        isEnrolled = enrolments.length > 0;
      }

      if (!canReadCourse(req.user, course.LecturerID, isEnrolled)) return { forbidden: true };

      const [rows] = await conn.execute(
        `SELECT AssessmentID, AssessmentType, AssessmentCategory, AssessmentName, MaxScore, DueDate
           FROM ASSESSMENT
          WHERE CourseID = ?
          ORDER BY DueDate, AssessmentID`,
        [courseId]
      );
      return { rows };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No course found with ID ${courseId}.` });
    }
    if (outcome.forbidden) {
      return res.status(403).json({ error: 'Not permitted to view assessments for this course.' });
    }

    return res.json({
      courseId,
      assessments: outcome.rows.map((row) => ({
        assessmentId: row.AssessmentID,
        assessmentType: row.AssessmentType,
        assessmentCategory: row.AssessmentCategory,
        assessmentName: row.AssessmentName,
        maxScore: Number(row.MaxScore),
        dueDate: row.DueDate,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

// Read-only, course-context "Grades" tab: every assessment in the course,
// graded or not (vw_course_grades LEFT JOINs SUBMISSION), with its computed
// weight. Student sees only their own rows; Lecturer sees the whole class
// (own course only). The running "average so far" is computed here rather
// than in the view - it needs to exclude ungraded rows and renormalize the
// remaining weights to 100%, which is awkward to express as a view column.
async function getCourseGrades(req, res, next) {
  try {
    const { courseId } = req.params;

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      const [courses] = await conn.execute(
        'SELECT CourseID, LecturerID FROM COURSE WHERE CourseID = ?',
        [courseId]
      );
      if (courses.length === 0) return { notFound: true };

      const course = courses[0];
      const isLecturer = req.user.roleName === 'Lecturer';

      if (isLecturer) {
        if (!canModifyCourseContent(req.user, course.LecturerID)) return { forbidden: true };
      } else if (req.user.roleName === 'Student') {
        const [enrolments] = await conn.execute(
          'SELECT EnrollmentID FROM ENROLLMENT WHERE StudentID = ? AND CourseID = ?',
          [req.user.username, courseId]
        );
        if (enrolments.length === 0) return { forbidden: true };
      } else {
        return { forbidden: true };
      }

      const params = [courseId];
      let studentFilter = '';
      if (!isLecturer) {
        studentFilter = 'AND StudentID = ?';
        params.push(req.user.username);
      }

      const [rows] = await conn.execute(
        `SELECT StudentID, F_Name, L_Name, AssessmentID, AssessmentName, AssessmentCategory,
                MaxScore, Score, SubmissionID, Weight
           FROM vw_course_grades
          WHERE CourseID = ? ${studentFilter}
          ORDER BY StudentID, AssessmentCategory = 'Midsem' DESC, AssessmentCategory = 'Final' DESC, AssessmentName`,
        params
      );
      return { rows };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No course found with ID ${courseId}.` });
    }
    if (outcome.forbidden) {
      return res.status(403).json({ error: 'Not permitted to view grades for this course.' });
    }

    // Group by student, computing each student's renormalized-over-graded
    // average alongside their per-assessment rows.
    const byStudent = new Map();
    for (const row of outcome.rows) {
      if (!byStudent.has(row.StudentID)) {
        byStudent.set(row.StudentID, {
          studentId: row.StudentID,
          firstName: row.F_Name,
          lastName: row.L_Name,
          assessments: [],
        });
      }
      byStudent.get(row.StudentID).assessments.push({
        assessmentId: row.AssessmentID,
        assessmentName: row.AssessmentName,
        assessmentCategory: row.AssessmentCategory,
        maxScore: Number(row.MaxScore),
        score: row.Score === null ? null : Number(row.Score),
        weight: Number(row.Weight),
      });
    }

    const students = Array.from(byStudent.values()).map((s) => {
      let weightedSum = 0;
      let gradedWeight = 0;
      for (const a of s.assessments) {
        if (a.score !== null) {
          weightedSum += (a.score / a.maxScore) * a.weight;
          gradedWeight += a.weight;
        }
      }
      return {
        ...s,
        averageSoFar: gradedWeight > 0 ? Number(((weightedSum / gradedWeight) * 100).toFixed(2)) : null,
      };
    });

    return res.json({ courseId, students });
  } catch (err) {
    return next(err);
  }
}

module.exports = { updateAssessment, createAssessment, getCourseAssessments, getCourseGrades };
