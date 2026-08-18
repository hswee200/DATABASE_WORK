import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

export default function DashboardLayout({ title, children }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate('/login', { replace: true });
  }

  return (
    <div>
      <header className="app-header">
        <span className="brand">SLMS</span>
        <div className="user-info">
          <span>{user.username}</span>
          <span className="role-badge">{user.roleName}</span>
          <button className="btn-secondary" onClick={handleLogout}>
            Log out
          </button>
        </div>
      </header>
      <main className="page-content">
        <h1 className="page-title">{title}</h1>
        {children}
      </main>
    </div>
  );
}
