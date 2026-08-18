import { useState } from 'react';

// A text input that filters a provided {id, label}[] list as you type and
// shows matches to click - the shared fix for every place in this app that
// used to make someone type a raw database ID for a person they know by
// name. Selecting a match calls onSelect(id) and shows that label as the
// resolved choice; the ID itself is never displayed or typed.
export default function NameSearch({ id, options, onSelect, placeholder = 'Type a name…', selectedLabel }) {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);

  const matches =
    query.trim() === ''
      ? []
      : options.filter((o) => o.label.toLowerCase().includes(query.trim().toLowerCase())).slice(0, 8);

  function pick(option) {
    onSelect(option.id);
    setQuery(option.label);
    setOpen(false);
  }

  function handleChange(e) {
    setQuery(e.target.value);
    setOpen(true);
    // Typing again after a selection clears it - a stale ID must never
    // survive an edited, no-longer-matching name.
    onSelect('');
  }

  return (
    <div style={{ position: 'relative' }}>
      <input
        id={id}
        value={query}
        onChange={handleChange}
        onFocus={() => setOpen(true)}
        onBlur={() => setTimeout(() => setOpen(false), 150)}
        placeholder={placeholder}
        autoComplete="off"
      />
      {selectedLabel && !open && (
        <p className="empty-note" style={{ margin: '0.25rem 0 0' }}>
          Selected: {selectedLabel}
        </p>
      )}
      {open && matches.length > 0 && (
        <ul
          style={{
            position: 'absolute',
            zIndex: 10,
            top: '100%',
            left: 0,
            right: 0,
            margin: '0.25rem 0 0',
            padding: '0.25rem 0',
            listStyle: 'none',
            background: 'var(--surface)',
            border: '1px solid var(--border)',
            borderRadius: 'var(--radius)',
            boxShadow: 'var(--shadow)',
            maxHeight: '14rem',
            overflowY: 'auto',
          }}
        >
          {matches.map((o) => (
            <li key={o.id}>
              <button
                type="button"
                onClick={() => pick(o)}
                style={{
                  display: 'block',
                  width: '100%',
                  textAlign: 'left',
                  padding: '0.4rem 0.7rem',
                  border: 'none',
                  background: 'transparent',
                  cursor: 'pointer',
                  font: 'inherit',
                }}
              >
                {o.label}
              </button>
            </li>
          ))}
        </ul>
      )}
      {open && query.trim() !== '' && matches.length === 0 && (
        <p className="empty-note" style={{ margin: '0.25rem 0 0' }}>
          No match.
        </p>
      )}
    </div>
  );
}
