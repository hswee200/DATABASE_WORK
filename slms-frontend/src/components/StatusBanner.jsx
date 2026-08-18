// Renders the actual API error message (or a plain success note), never a
// generic "something went wrong" - the brief specifically wants real messages
// shown, including 403 bodies from the ownership checks.
export default function StatusBanner({ error, success }) {
  if (!error && !success) return null;
  return (
    <p className={`banner ${error ? 'banner-error' : 'banner-success'}`}>
      {error || success}
    </p>
  );
}
