import { useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { updateTimetable } from '../../../api/endpoints';
import DataTable from '../../../components/DataTable';
import StatusBanner from '../../../components/StatusBanner';

const WEEKDAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const COLUMNS = [
  { key: 'timetableId', label: 'ID' },
  { key: 'dayOfWeek', label: 'Day' },
  { key: 'startTime', label: 'Start' },
  { key: 'endTime', label: 'End' },
  { key: 'room', label: 'Room' },
];

export default function CourseTimetable() {
  const { course, reload } = useOutletContext();
  const sessions = course.timetable;

  const [timetableId, setTimetableId] = useState('');
  const [dayOfWeek, setDayOfWeek] = useState(WEEKDAYS[0]);
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [room, setRoom] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  function selectSession(s) {
    setTimetableId(s.timetableId);
    setDayOfWeek(s.dayOfWeek);
    setStartTime(s.startTime.slice(0, 5));
    setEndTime(s.endTime.slice(0, 5));
    setRoom(s.room);
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      const data = await updateTimetable(timetableId, { dayOfWeek, startTime, endTime, room });
      setSuccess(`${data.timetableId} updated: ${data.dayOfWeek} ${data.startTime.slice(0, 5)}–${data.endTime.slice(0, 5)}, ${data.room}.`);
      reload();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div>
      <DataTable columns={COLUMNS} rows={sessions} emptyMessage="No sessions scheduled." />

      {sessions.length > 0 && (
        <>
          <h2 className="section-heading">Edit a Session</h2>
          <div className="quick-links" style={{ marginBottom: '1rem' }}>
            {sessions.map((s) => (
              <button key={s.timetableId} className="btn-secondary" onClick={() => selectSession(s)}>
                {s.timetableId}
              </button>
            ))}
          </div>
          <form onSubmit={handleSubmit}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 1rem' }}>
              <div className="field">
                <label htmlFor="ctDay">Day</label>
                <select id="ctDay" value={dayOfWeek} onChange={(e) => setDayOfWeek(e.target.value)}>
                  {WEEKDAYS.map((d) => (
                    <option key={d} value={d}>
                      {d}
                    </option>
                  ))}
                </select>
              </div>
              <div className="field">
                <label htmlFor="ctRoom">Room</label>
                <input id="ctRoom" value={room} onChange={(e) => setRoom(e.target.value)} required />
              </div>
              <div className="field">
                <label htmlFor="ctStart">Start Time</label>
                <input
                  id="ctStart"
                  type="time"
                  value={startTime}
                  onChange={(e) => setStartTime(e.target.value)}
                  required
                />
              </div>
              <div className="field">
                <label htmlFor="ctEnd">End Time</label>
                <input
                  id="ctEnd"
                  type="time"
                  value={endTime}
                  onChange={(e) => setEndTime(e.target.value)}
                  required
                />
              </div>
            </div>
            <button
              type="submit"
              className="btn-primary"
              disabled={submitting || !timetableId || !startTime || !endTime || !room.trim()}
            >
              {submitting ? 'Saving…' : 'Save Changes'}
            </button>
          </form>
          <StatusBanner error={error} success={success} />
        </>
      )}
    </div>
  );
}
