require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const studentRoutes = require('./routes/students');
const lecturerRoutes = require('./routes/lecturers');
const submissionRoutes = require('./routes/submissions');
const courseRoutes = require('./routes/courses');
const adminRoutes = require('./routes/admins');
const userRoutes = require('./routes/users');
const attendanceRoutes = require('./routes/attendance');
const assessmentRoutes = require('./routes/assessments');
const timetableRoutes = require('./routes/timetable');
const reportRoutes = require('./routes/reports');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// The frontend runs on Vite's dev server (a different origin than the API), so
// cross-origin requests need to be allowed explicitly. Restricted to the
// configured origin rather than left open, since the API carries auth tokens.
const corsOrigin = process.env.CORS_ORIGIN || 'http://localhost:5173';
app.use(cors({ origin: corsOrigin }));

app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/lecturers', lecturerRoutes);
app.use('/api/submissions', submissionRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/admins', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/assessments', assessmentRoutes);
app.use('/api/timetable', timetableRoutes);
app.use('/api/reports', reportRoutes);
app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.use(errorHandler);

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  console.log(`SLMS backend listening on http://localhost:${port}`);
});
