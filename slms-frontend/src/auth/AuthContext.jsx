import { createContext, useContext, useEffect, useMemo, useState, useCallback } from 'react';
import { login as loginRequest } from '../api/endpoints';
import { registerUnauthorizedHandler } from '../api/client';

const STORAGE_KEY = 'slms_auth';
const AuthContext = createContext(null);

function readStoredSession() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }) {
  const [session, setSession] = useState(readStoredSession);

  const clearSession = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
    setSession(null);
  }, []);

  // A 401 from any request (expired or tampered token) clears the session so
  // ProtectedRoute redirects to login on the next render, wherever the user is.
  useEffect(() => {
    registerUnauthorizedHandler(clearSession);
  }, [clearSession]);

  const login = useCallback(async (username, password) => {
    const data = await loginRequest(username, password);
    const next = { token: data.token, user: data.user };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    setSession(next);
    return next.user;
  }, []);

  const value = useMemo(
    () => ({
      user: session?.user ?? null,
      token: session?.token ?? null,
      isAuthenticated: Boolean(session?.token),
      login,
      logout: clearSession,
    }),
    [session, login, clearSession]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
}
