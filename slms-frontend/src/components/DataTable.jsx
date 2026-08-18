// Plain HTML table from an array of column defs: { key, label, render? }.
// No component library, per the brief - styled entirely through theme.css.
export default function DataTable({ columns, rows, emptyMessage = 'No records.' }) {
  if (!rows || rows.length === 0) {
    return <p className="empty-note">{emptyMessage}</p>;
  }

  return (
    <div className="data-table-wrap">
      <table className="data-table">
        <thead>
          <tr>
            {columns.map((col) => (
              <th key={col.key}>{col.label}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr key={row.id ?? i}>
              {columns.map((col) => (
                <td key={col.key}>{col.render ? col.render(row) : row[col.key]}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
