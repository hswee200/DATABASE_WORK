import { Link } from 'react-router-dom';
import { courseColor } from '../lib/courseColor';

// Canvas-style colored course tile. `meta` is a short line under the course
// name - e.g. next class time, or "Teaching" - left to the caller since
// student and lecturer overviews want different second lines. Renders as a
// <Link> when `to` is given, a plain div otherwise.
export default function CourseCard({ courseId, courseCode, courseName, meta, to }) {
  const content = (
    <>
      <div className="course-card-band" style={{ background: courseColor(courseId) }} />
      <div className="course-card-body">
        <div className="course-card-code">{courseCode || courseId}</div>
        <div className="course-card-name">{courseName}</div>
        {meta && <div className="course-card-meta">{meta}</div>}
      </div>
    </>
  );

  if (to) {
    return (
      <Link to={to} className="course-card">
        {content}
      </Link>
    );
  }

  return <div className="course-card">{content}</div>;
}
