function errorHandler(err, req, res, next) {
  if (res.headersSent) return next(err);

  console.error(err);

  // Procedures and triggers raise SQLSTATE 45000 with a user-facing message
  // (duplicate enrollment, score over MaxScore) — surface those as 400s.
  if (err.sqlState === '45000') {
    return res.status(400).json({ error: err.sqlMessage });
  }

  return res.status(500).json({ error: 'Internal server error.' });
}

module.exports = errorHandler;
