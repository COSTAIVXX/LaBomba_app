const crypto = require('crypto');

const sensitiveKeyPattern = /token|secret|password|authorization|cookie|email|phone|pii|jwt/i;

function sanitizeLogPayload(value) {
  if (value === null || value === undefined) {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => sanitizeLogPayload(item));
  }

  if (typeof value === 'object') {
    const cleaned = {};
    for (const [key, nestedValue] of Object.entries(value)) {
      if (sensitiveKeyPattern.test(key)) {
        cleaned[key] = '[REDACTED]';
        continue;
      }
      cleaned[key] = sanitizeLogPayload(nestedValue);
    }
    return cleaned;
  }

  return value;
}

function buildCorrelationId(provided) {
  return provided && String(provided).trim() ? String(provided).trim() : crypto.randomUUID();
}

function structuredLog(eventName, payload = {}, options = {}) {
  const correlationId = buildCorrelationId(options.correlationId);
  const safePayload = sanitizeLogPayload(payload);
  const entry = {
    ts: new Date().toISOString(),
    event: eventName,
    correlationId,
    ...safePayload,
  };

  console.log(JSON.stringify(entry));
  return correlationId;
}

module.exports = {
  sanitizeLogPayload,
  buildCorrelationId,
  structuredLog,
};
