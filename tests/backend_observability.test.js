const test = require('node:test');
const assert = require('node:assert/strict');

const {
  sanitizeLogPayload,
  buildCorrelationId,
} = require('../backend/observability');

test('sanitizeLogPayload redacts sensitive keys', () => {
  const payload = {
    status: 'ok',
    authorization: 'token-value',
    nested: {
      email: 'user@example.com',
      password: 'secret',
      safe: 'value',
    },
  };

  const sanitized = sanitizeLogPayload(payload);
  assert.equal(sanitized.authorization, '[REDACTED]');
  assert.equal(sanitized.nested.email, '[REDACTED]');
  assert.equal(sanitized.nested.password, '[REDACTED]');
  assert.equal(sanitized.nested.safe, 'value');
});

test('buildCorrelationId generates a value when missing', () => {
  const id = buildCorrelationId();
  assert.match(id, /^[0-9a-f-]{36}$/i);
});
