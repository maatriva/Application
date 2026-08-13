/**
 * Sanitization utility for safe logging.
 * Replaces sensitive credential fields, tokens, and secrets with '[REDACTED]'.
 * Never mutates original objects.
 */

const SENSITIVE_KEYS = new Set([
  'password',
  'passwordplain',
  'passwordhash',
  'confirmpassword',
  'token',
  'accesstoken',
  'refreshtoken',
  'jwt',
  'authorization',
  'cookie',
  'cookies',
  'secret',
  'jwt_secret',
  'apikey',
  'api_key',
  'database_url',
  'admin_password',
]);

const CLEAN_SENSITIVE_KEYS = Array.from(SENSITIVE_KEYS).map(k => k.replace(/[-_]/g, ''));

/**
 * Checks if a key string represents a sensitive credential/token key.
 */
export function isSensitiveKey(key: string): boolean {
  if (!key) return false;
  const clean = key.toLowerCase().replace(/[-_]/g, '');
  return CLEAN_SENSITIVE_KEYS.some(k => clean.includes(k));
}

/**
 * Sanitizes a string value if it looks like a JWT or Bearer token.
 */
export function sanitizeString(val: string): string {
  if (!val) return val;
  if (val.toLowerCase().startsWith('bearer ') || /^eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_=]*$/.test(val.trim())) {
    return '[REDACTED]';
  }
  return val;
}

/**
 * Recursively clones an object/array, replacing sensitive values with '[REDACTED]'.
 * Does not mutate original object.
 */
export function sanitizeObject(obj: any): any {
  if (obj === null || obj === undefined) return obj;

  if (typeof obj === 'string') {
    return sanitizeString(obj);
  }

  if (typeof obj !== 'object') {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map(item => sanitizeObject(item));
  }

  const sanitized: Record<string, any> = {};
  for (const key of Object.keys(obj)) {
    if (isSensitiveKey(key)) {
      sanitized[key] = '[REDACTED]';
    } else {
      sanitized[key] = sanitizeObject(obj[key]);
    }
  }
  return sanitized;
}
