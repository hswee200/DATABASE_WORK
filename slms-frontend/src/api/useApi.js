import { useCallback, useEffect, useState } from 'react';

// Runs `fn` on mount (and whenever `deps` change) and exposes
// { data, error, loading, reload }. Every read-only dashboard section follows
// this same fetch/error/loading shape, so it is centralised here once.
export function useApi(fn, deps) {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const result = await fn();
      setData(result);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useEffect(() => {
    load();
  }, [load]);

  return { data, error, loading, reload: load };
}
