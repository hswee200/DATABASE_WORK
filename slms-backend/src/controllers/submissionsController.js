const { withRole } = require('../db');
const { canModifyCourseContent } = require('../auth/access');

// Lecturer-only, own record only: the grading screen used to make the
// lecturer type a raw SubmissionID; this lists exactly what still needs
// grading across ALL of their courses (by student/course/assessment name,
// not ID) so the frontend can drive sp_record_grade from a row click
// instead. Backed directly by vw_ungraded_submissions (see
// sql/08_add_reporting_views.sql) - no course scoping here because the
// view itself has none, only a LecturerID column, so Grade Submission is a
// general cross-course page rather than a per-course tab now.
async function getUngradedSubmissions(req, res, next) {
  try {
    const lecturerId = req.user.username;

    const rows = await withRole(req.user.dbRole, async (conn) => {
      const [result] = await conn.execute(
        'SELECT * FROM vw_ungraded_submissions WHERE LecturerID = ? ORDER BY SubmissionDate, SubmissionID',
        [lecturerId]
      );
      return result;
    });

    return res.json({
      submissions: rows.map((row) => ({
        submissionId: row.SubmissionID,
        submissionDate: row.SubmissionDate,
        courseName: row.CourseName,
        assessmentName: row.AssessmentName,
        studentFirstName: row.F_Name,
        studentLastName: row.L_Name,
        ungradedCountForAssessment: row.UngradedCountForThisAssessment,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

// Resolves a submission to the lecturer who owns it, walking
// SUBMISSION -> ASSESSMENT -> COURSE -> STUDENT. Returns null if the
// submission is unknown or has been superseded by a resubmission - a
// deactivated attempt is not gradeable, so it should read as "not found"
// here just like sp_record_grade itself now targets only the active row.
async function loadSubmissionContext(conn, submissionId) {
  const [rows] = await conn.execute(
    `SELECT s.SubmissionID, s.Score, s.StudentID, a.MaxScore, a.AssessmentName,
            c.CourseID, c.CourseName, c.LecturerID,
            st.F_Name AS StudentFirstName, st.L_Name AS StudentLastName
       FROM SUBMISSION s
       JOIN ASSESSMENT a ON s.AssessmentID = a.AssessmentID
       JOIN COURSE    c ON a.CourseID     = c.CourseID
       JOIN STUDENT   st ON s.StudentID   = st.StudentID
      WHERE s.SubmissionID = ?
        AND s.IsActive = TRUE`,
    [submissionId]
  );
  return rows[0] || null;
}

async function recordGrade(req, res, next) {
  try {
    const { submissionId } = req.params;
    const { score } = req.body || {};

    if (typeof score !== 'number' || !Number.isFinite(score)) {
      return res.status(400).json({ error: 'score is required and must be a number.' });
    }
    // sp_record_grade rejects scores above MaxScore but has no lower bound, so a
    // negative score would be stored. Guarded here since the database will not.
    if (score < 0) {
      return res.status(400).json({ error: 'score cannot be negative.' });
    }

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      const context = await loadSubmissionContext(conn, submissionId);
      if (!context) return { notFound: true };

      // Ownership is checked before the call, not after: sp_record_grade runs as
      // DEFINER=root and would otherwise grade any lecturer's submission.
      // Admin is deliberately excluded here - see canModifyCourseContent.
      if (!canModifyCourseContent(req.user, context.LecturerID)) return { forbidden: true };

      // Raises SQLSTATE 45000 if the score exceeds the assessment's MaxScore.
      await conn.query('CALL sp_record_grade(?, ?)', [submissionId, score]);

      const updated = await loadSubmissionContext(conn, submissionId);
      return { submission: updated, previousScore: context.Score };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No submission found with ID ${submissionId}.` });
    }
    if (outcome.forbidden) {
      return res
        .status(403)
        .json({ error: 'Not permitted to grade this submission.' });
    }

    const s = outcome.submission;
    return res.json({
      submissionId: s.SubmissionID,
      courseId: s.CourseID,
      courseName: s.CourseName,
      assessmentName: s.AssessmentName,
      studentId: s.StudentID,
      studentFirstName: s.StudentFirstName,
      studentLastName: s.StudentLastName,
      // DECIMAL arrives as a string from the driver; clients want numbers.
      previousScore: outcome.previousScore === null ? null : Number(outcome.previousScore),
      score: s.Score === null ? null : Number(s.Score),
      maxScore: Number(s.MaxScore),
    });
  } catch (err) {
    // sp_record_grade raises only one 45000 here: score above MaxScore. That is
    // bad input rather than a state conflict, so 400.
    if (err.sqlState === '45000') {
      return res.status(400).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

// Loads the assessment + course context a submission is attached to, and
// confirms the assessment exists - shared by submit and resubmit so a bad
// assessmentId reads as 404 rather than a foreign-key error surfacing as a
// generic 500.
async function loadAssessmentSummary(conn, assessmentId) {
  const [rows] = await conn.execute(
    `SELECT a.AssessmentID, a.AssessmentName, a.CourseID, c.CourseName
       FROM ASSESSMENT a
       JOIN COURSE c ON a.CourseID = c.CourseID
      WHERE a.AssessmentID = ?`,
    [assessmentId]
  );
  return rows[0] || null;
}

// Student-only, first submission for a given assessment. studentId comes
// from the token, never the request body - a student cannot submit on
// another student's behalf. The actual file/content of a submission is
// handled outside this app; here we only record that one exists.
// SubmissionID is never supplied by the client - sp_submit_assessment
// generates it server-side (same MAX+LPAD pattern sp_enroll_student uses for
// EnrollmentID), so it's read back afterward rather than passed in.
async function submitAssessment(req, res, next) {
  try {
    const { assessmentId } = req.body || {};

    if (typeof assessmentId !== 'string' || assessmentId.trim() === '') {
      return res.status(400).json({ error: 'assessmentId is required.' });
    }

    const studentId = req.user.username;

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      const assessment = await loadAssessmentSummary(conn, assessmentId);
      if (!assessment) return { notFound: true };

      // Raises SQLSTATE 45000 if an active submission already exists for
      // this (student, assessment) pair.
      await conn.query('CALL sp_submit_assessment(?, ?)', [studentId, assessmentId]);

      // The procedure returns nothing, so read back the row it just created.
      const [rows] = await conn.execute(
        `SELECT SubmissionID, SubmissionDate
           FROM SUBMISSION
          WHERE StudentID = ? AND AssessmentID = ? AND IsActive = TRUE`,
        [studentId, assessmentId]
      );

      return { assessment, submission: rows[0] };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No assessment found with ID ${assessmentId}.` });
    }

    const a = outcome.assessment;
    return res.status(201).json({
      submissionId: outcome.submission.SubmissionID,
      assessmentId: a.AssessmentID,
      assessmentName: a.AssessmentName,
      courseId: a.CourseID,
      courseName: a.CourseName,
      studentId,
      submissionDate: outcome.submission.SubmissionDate,
      score: null,
    });
  } catch (err) {
    // sp_submit_assessment raises 45000 when an active submission already exists.
    if (err.sqlState === '45000') {
      return res.status(409).json({ error: err.sqlMessage });
    }
    // The generated SubmissionID is computed from MAX(...)+1, so two requests
    // racing on the same instant can compute the same ID - the same
    // concurrency weakness sp_enroll_student already has for EnrollmentID.
    // Surface it as a retryable conflict rather than an unhandled 500.
    if (err.code === 'ER_DUP_ENTRY') {
      // Log the real error - this branch used to swallow it silently, which
      // once cost a forensic DB investigation to diagnose a real bug
      // (LPAD truncating the generated ID, see sql/07_widen_submission_id_width.sql).
      console.error(err);
      return res.status(409).json({ error: 'That submission could not be recorded - please try again.' });
    }
    return next(err);
  }
}

// Student-only, and always for the caller's own record: studentId comes from
// the token, never from the request body. Which submission gets deactivated
// is resolved by StudentID+AssessmentID (see sp_resubmit_assessment), and the
// new row's SubmissionID is generated server-side too - the student never
// supplies an ID for either half of a resubmit.
async function resubmitAssessment(req, res, next) {
  try {
    const { assessmentId } = req.body || {};

    if (typeof assessmentId !== 'string' || assessmentId.trim() === '') {
      return res.status(400).json({ error: 'assessmentId is required.' });
    }

    const studentId = req.user.username;

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      const assessment = await loadAssessmentSummary(conn, assessmentId);
      if (!assessment) return { notFound: true };

      // Deactivates the caller's current active submission and inserts a
      // fresh one with Score = NULL. Raises SQLSTATE 45000 if there is no
      // active submission to resubmit - see sp_resubmit_assessment.
      await conn.query('CALL sp_resubmit_assessment(?, ?)', [studentId, assessmentId]);

      // The procedure returns nothing, so read back the row it just created.
      const [rows] = await conn.execute(
        `SELECT SubmissionID, SubmissionDate, Score
           FROM SUBMISSION
          WHERE StudentID = ? AND AssessmentID = ? AND IsActive = TRUE`,
        [studentId, assessmentId]
      );
      return { submission: rows[0], assessment };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No assessment found with ID ${assessmentId}.` });
    }

    const s = outcome.submission;
    return res.status(201).json({
      submissionId: s.SubmissionID,
      assessmentId: outcome.assessment.AssessmentID,
      assessmentName: outcome.assessment.AssessmentName,
      courseId: outcome.assessment.CourseID,
      courseName: outcome.assessment.CourseName,
      studentId,
      submissionDate: s.SubmissionDate,
      score: s.Score === null ? null : Number(s.Score),
    });
  } catch (err) {
    // sp_resubmit_assessment raises 45000 when there is no active submission
    // to resubmit - the prerequisite Submit hasn't happened yet.
    if (err.sqlState === '45000') {
      return res.status(404).json({ error: err.sqlMessage });
    }
    // Same MAX(...)+1 race as submitAssessment - see the comment there.
    if (err.code === 'ER_DUP_ENTRY') {
      console.error(err);
      return res.status(409).json({ error: 'That resubmission could not be recorded - please try again.' });
    }
    return next(err);
  }
}

async function deleteSubmission(req, res, next) {
  try {
    const { submissionId } = req.params;

    // Looked up before the delete so the response can name what was removed
    // instead of just echoing back the ID the admin typed.
    const context = await withRole(req.user.dbRole, async (conn) => {
      const found = await loadSubmissionContext(conn, submissionId);
      await conn.query('CALL sp_delete_submission(?)', [submissionId]);
      return found;
    });

    return res.json({
      submissionId,
      deleted: true,
      studentId: context?.StudentID ?? null,
      studentFirstName: context?.StudentFirstName ?? null,
      studentLastName: context?.StudentLastName ?? null,
      courseId: context?.CourseID ?? null,
      courseName: context?.CourseName ?? null,
      assessmentName: context?.AssessmentName ?? null,
    });
  } catch (err) {
    // sp_delete_submission raises only one 45000: unknown or already-inactive.
    if (err.sqlState === '45000') {
      return res.status(404).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

module.exports = {
  recordGrade,
  submitAssessment,
  resubmitAssessment,
  deleteSubmission,
  getUngradedSubmissions,
};
