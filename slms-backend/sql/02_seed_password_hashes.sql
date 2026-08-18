-- Replaces the placeholder seed value with a real bcrypt hash so login can be
-- tested across all three roles. Plaintext password: Password123!
-- Scoped by the placeholder value so it only touches unmodified seed rows.

UPDATE APP_USER
SET PasswordHash = '$2b$10$9PQ4blJPsXD8SGutu.t6AeAoMH9hR.ZJL9KiBgYHk6x0CuN.Oh85a'
WHERE PasswordHash = '$2y$10$hashedpassword';
