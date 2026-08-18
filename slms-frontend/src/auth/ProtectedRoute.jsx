import { Navigate } from 'react-router-dom';
import { useAuth } from './AuthContext';

// Wraps a dashboard route: redirects to /login if there is no session, and to
// the caller's own dashboard if their role does not match this route (a
// student cannot land on /lecturer by typing the URL).
export default function ProtectedRoute({ allowedRole, children }) {
  const { isAuthenticated, user } = useAuth();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (user.roleName !== allowedRole) {
    return <Navigate to={`/${user.roleName.toLowerCase()}`} replace />;
  }

  return children;
}
