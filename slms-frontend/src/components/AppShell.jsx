import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

// Shared shell for all three dashboards: a persistent sidebar (brand + nav)
// and a topbar (identity + logout), with the active route rendered via
// Outlet. navItems is the only thing that differs per role.
export default function AppShell({ navItems }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate('/login', { replace: true });
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">SLMS</div>
        <nav className="sidebar-nav">
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              end={item.end}
              className={({ isActive }) =>
                `sidebar-link${isActive ? ' active' : ''}${item.divider ? ' sidebar-link-divider' : ''}`
              }
            >
              <span className="sidebar-icon" aria-hidden="true">
                {item.icon}
              </span>
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </aside>
      <div className="shell-main">
        <header className="app-header">
          <div className="user-info">
            <span>{user.username}</span>
            <span className="role-badge">{user.roleName}</span>
            <button className="btn-secondary" onClick={handleLogout}>
              Log out
            </button>
          </div>
        </header>
        <main className="page-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
