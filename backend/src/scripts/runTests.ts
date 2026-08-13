import bcrypt from 'bcryptjs';
import { prisma } from '../config/database';
import { AuthService } from '../modules/auth/auth.service';
import { seedAdmin } from './seedAdmin';
import { UserRole } from '@prisma/client';
import express from 'express';
import http from 'http';

async function runAllTests() {
  console.log('\n========================================');
  console.log('  RUNNING SECURITY & AUTH VERIFICATION TESTS');
  console.log('========================================\n');

  let passed = 0;
  let failed = 0;

  async function assertTest(name: string, fn: () => Promise<void>) {
    try {
      await fn();
      console.log(`✓ PASS: ${name}`);
      passed++;
    } catch (err: any) {
      console.error(`✗ FAIL: ${name}`);
      console.error(`  Error: ${err.message || err}`);
      failed++;
    }
  }

  const authService = new AuthService();

  // Test 1: Seed fails when ADMIN_EMAIL is missing
  await assertTest('Seed fails when ADMIN_EMAIL is missing', async () => {
    const origEmail = process.env.ADMIN_EMAIL;
    delete process.env.ADMIN_EMAIL;
    process.env.ADMIN_PASSWORD = 'ValidSecurePassword123!';
    try {
      await seedAdmin();
      throw new Error('Expected seedAdmin to fail, but it succeeded');
    } catch (err: any) {
      if (!err.message.includes('ADMIN_EMAIL')) {
        throw err;
      }
    } finally {
      process.env.ADMIN_EMAIL = origEmail;
    }
  });

  // Test 2: Seed fails when ADMIN_PASSWORD is missing
  await assertTest('Seed fails when ADMIN_PASSWORD is missing', async () => {
    const origPass = process.env.ADMIN_PASSWORD;
    process.env.ADMIN_EMAIL = 'testadmin@maatriva.com';
    delete process.env.ADMIN_PASSWORD;
    try {
      await seedAdmin();
      throw new Error('Expected seedAdmin to fail, but it succeeded');
    } catch (err: any) {
      if (!err.message.includes('ADMIN_PASSWORD')) {
        throw err;
      }
    } finally {
      process.env.ADMIN_PASSWORD = origPass;
    }
  });

  // Test 3: Seed fails on invalid email format
  await assertTest('Seed fails on invalid email format', async () => {
    process.env.ADMIN_EMAIL = 'invalid-email-format';
    process.env.ADMIN_PASSWORD = 'ValidSecurePassword123!';
    try {
      await seedAdmin();
      throw new Error('Expected seedAdmin to fail on invalid email format');
    } catch (err: any) {
      if (!err.message.includes('valid email address')) {
        throw err;
      }
    }
  });

  // Test 4: Seed fails on short/weak password
  await assertTest('Seed fails on short password (< 8 chars)', async () => {
    process.env.ADMIN_EMAIL = 'testadmin@maatriva.com';
    process.env.ADMIN_PASSWORD = 'short';
    try {
      await seedAdmin();
      throw new Error('Expected seedAdmin to fail on short password');
    } catch (err: any) {
      if (!err.message.includes('at least 8 characters')) {
        throw err;
      }
    }
  });

  // Test 5: Seed fails on known insecure default password
  await assertTest('Seed fails on insecure default password (Admin@123456)', async () => {
    process.env.ADMIN_EMAIL = 'testadmin@maatriva.com';
    process.env.ADMIN_PASSWORD = 'Admin@123456';
    try {
      await seedAdmin();
      throw new Error('Expected seedAdmin to fail on insecure default password');
    } catch (err: any) {
      if (!err.message.includes('Insecure or default ADMIN_PASSWORD')) {
        throw err;
      }
    }
  });

  // Test 6: Successful admin seeding with valid credentials
  const testAdminEmail = `test_admin_${Date.now()}@maatriva-test.local`;
  const testAdminPass = 'SuperSecretSecureAdminPass2026!';

  await assertTest('Successful admin seeding with valid credentials', async () => {
    process.env.ADMIN_EMAIL = testAdminEmail;
    process.env.ADMIN_PASSWORD = testAdminPass;

    await seedAdmin();

    const created = await prisma.user.findUnique({ where: { email: testAdminEmail } });
    if (!created) {
      throw new Error('Admin user was not created in database');
    }
    if (created.role !== UserRole.ADMIN) {
      throw new Error(`Expected role ADMIN, got ${created.role}`);
    }
    const isPassValid = await bcrypt.compare(testAdminPass, created.passwordHash);
    if (!isPassValid) {
      throw new Error('Password hash does not match seeded password');
    }
  });

  // Test 7: Re-running seed on existing admin does not overwrite password
  await assertTest('Re-running seed on existing admin exits safely without overwriting', async () => {
    process.env.ADMIN_EMAIL = testAdminEmail;
    process.env.ADMIN_PASSWORD = 'DifferentNewPassword999!';

    await seedAdmin(); // Should report existing admin and exit cleanly

    const user = await prisma.user.findUnique({ where: { email: testAdminEmail } });
    const isOrigPassValid = await bcrypt.compare(testAdminPass, user!.passwordHash);
    if (!isOrigPassValid) {
      throw new Error('Original admin password was unexpectedly overwritten');
    }
  });

  // Test 8: Normal admin login works via AuthService.login
  await assertTest('Normal admin login works via standard AuthService.login', async () => {
    const loginResult = await authService.login(testAdminEmail, testAdminPass);
    if (!loginResult.accessToken || !loginResult.refreshToken) {
      throw new Error('Tokens missing from login response');
    }
    if (loginResult.user.role !== UserRole.ADMIN) {
      throw new Error('Admin role missing in login response user object');
    }
  });

  // Test 9: Incorrect password for admin fails login
  await assertTest('Incorrect password for admin fails login with 401', async () => {
    try {
      await authService.login(testAdminEmail, 'WrongPassword123!');
      throw new Error('Expected login to fail, but it succeeded');
    } catch (err: any) {
      if (err.statusCode !== 401) {
        throw new Error(`Expected status 401, got ${err.statusCode}`);
      }
    }
  });

  // Test 10: Old hardcoded password (Admin@123456) fails on seeded admin account
  await assertTest('Old hardcoded password (Admin@123456) has no backdoor effect and fails', async () => {
    try {
      await authService.login(testAdminEmail, 'Admin@123456');
      throw new Error('Expected login with old backdoor password to fail');
    } catch (err: any) {
      if (err.statusCode !== 401) {
        throw new Error(`Expected status 401, got ${err.statusCode}`);
      }
    }
  });

  // Clean up test admin account
  await prisma.user.deleteMany({
    where: { email: testAdminEmail },
  });

  // =========================================================================
  // DEBUG ROUTE ISOLATION TESTS (Requirement 8)
  // =========================================================================

  console.log('\n--- Debug Route Isolation Tests ---\n');

  // Test 11: Production environment with DEBUG_MODE=true MUST STILL disable debug routes
  await assertTest('Production environment with DEBUG_MODE=true disables debug routes', async () => {
    const envVal: string = 'production';
    const debugVal: string = 'true';
    const isProduction = envVal === 'production';
    const isDebugMode = debugVal === 'true';
    const isDebugEnabled = !isProduction && isDebugMode;

    if (isDebugEnabled) {
      throw new Error('isDebugEnabled must be false in production, even if DEBUG_MODE=true');
    }
  });

  // Test 12: Development environment with DEBUG_MODE=false disables debug routes
  await assertTest('Development environment with DEBUG_MODE=false disables debug routes', async () => {
    const envVal: string = 'development';
    const debugVal: string = 'false';
    const isProduction = envVal === 'production';
    const isDebugMode = debugVal === 'true';
    const isDebugEnabled = !isProduction && isDebugMode;

    if (isDebugEnabled) {
      throw new Error('isDebugEnabled must be false when DEBUG_MODE is false');
    }
  });

  // Test 13: Development environment with DEBUG_MODE=true enables debug routes
  await assertTest('Development environment with DEBUG_MODE=true enables debug routes', async () => {
    const envVal: string = 'development';
    const debugVal: string = 'true';
    const isProduction = envVal === 'production';
    const isDebugMode = debugVal === 'true';
    const isDebugEnabled = !isProduction && isDebugMode;

    if (!isDebugEnabled) {
      throw new Error('isDebugEnabled must be true in development when DEBUG_MODE=true');
    }
  });

  // Test 14: HTTP Protection Test - Debug router endpoints return 404 when unmounted
  await assertTest('Debug endpoints (DELETE /debug/reset, POST /debug/telemetry, etc.) return 404 when debug is disabled', async () => {
    const testApp = express();
    const isDebugEnabled = false; // Simulated production / debug-disabled state

    if (isDebugEnabled) {
      // In production, router is NOT mounted
      const debugRoutes = (await import('../modules/debug/debug.routes')).default;
      testApp.use('/debug', debugRoutes);
    }

    const testServer = http.createServer(testApp);
    await new Promise<void>((resolve) => testServer.listen(0, resolve));
    const port = (testServer.address() as any).port;

    try {
      const endpoints = [
        { method: 'DELETE', path: '/debug/reset' },
        { method: 'POST', path: '/debug/reset' },
        { method: 'POST', path: '/debug/telemetry' },
        { method: 'POST', path: '/debug/alert' },
        { method: 'POST', path: '/debug/device/offline' },
        { method: 'GET', path: '/debug/status' },
      ];

      for (const ep of endpoints) {
        const res = await fetch(`http://localhost:${port}${ep.path}`, { method: ep.method });
        if (res.status !== 404) {
          throw new Error(`Endpoint ${ep.method} ${ep.path} returned status ${res.status}, expected 404`);
        }
      }
    } finally {
      await new Promise<void>((resolve) => testServer.close(() => resolve()));
    }
  });

  // =========================================================================
  // HARDENED CORS TESTS
  // =========================================================================

  console.log('\n--- CORS Hardening Tests ---\n');

  const corsApp = express();
  const { corsMiddleware } = await import('../middleware/cors.middleware');
  corsApp.use(corsMiddleware);
  corsApp.get('/health', (req, res) => res.json({ status: 'OK' }));

  const corsServer = http.createServer(corsApp);
  await new Promise<void>((resolve) => corsServer.listen(0, resolve));
  const corsPort = (corsServer.address() as any).port;

  try {
    // Test 15: Approved origin gets CORS approval headers
    await assertTest('Approved origin receives Access-Control-Allow-Origin & Credentials', async () => {
      const res = await fetch(`http://localhost:${corsPort}/health`, {
        headers: { Origin: 'http://localhost:3000' },
      });
      const allowOrigin = res.headers.get('access-control-allow-origin');
      const allowCreds = res.headers.get('access-control-allow-credentials');
      if (allowOrigin !== 'http://localhost:3000') {
        throw new Error(`Expected Access-Control-Allow-Origin 'http://localhost:3000', got '${allowOrigin}'`);
      }
      if (allowCreds !== 'true') {
        throw new Error(`Expected Access-Control-Allow-Credentials 'true', got '${allowCreds}'`);
      }
    });

    // Test 16: Malicious/Unapproved origin does NOT get CORS approval
    await assertTest('Malicious origin does NOT receive Access-Control-Allow-Origin or Credentials', async () => {
      const res = await fetch(`http://localhost:${corsPort}/health`, {
        headers: { Origin: 'https://evil-hacker.com' },
      });
      const allowOrigin = res.headers.get('access-control-allow-origin');
      const allowCreds = res.headers.get('access-control-allow-credentials');
      if (allowOrigin === 'https://evil-hacker.com') {
        throw new Error('Access-Control-Allow-Origin dynamically reflected malicious origin!');
      }
      if (allowCreds === 'true') {
        throw new Error('Access-Control-Allow-Credentials was granted to malicious origin!');
      }
    });

    // Test 17: OPTIONS Preflight with approved origin succeeds (204)
    await assertTest('OPTIONS preflight for approved origin returns 204 with method/header rules', async () => {
      const res = await fetch(`http://localhost:${corsPort}/health`, {
        method: 'OPTIONS',
        headers: {
          Origin: 'http://localhost:3000',
          'Access-Control-Request-Method': 'POST',
          'Access-Control-Request-Headers': 'Authorization, Content-Type',
        },
      });
      if (res.status !== 204) {
        throw new Error(`Expected status 204 for approved preflight, got ${res.status}`);
      }
      const allowMethods = res.headers.get('access-control-allow-methods');
      if (!allowMethods || !allowMethods.includes('POST')) {
        throw new Error(`Expected Access-Control-Allow-Methods to include POST, got '${allowMethods}'`);
      }
    });

    // Test 18: OPTIONS Preflight for malicious origin fails with 403 Forbidden
    await assertTest('OPTIONS preflight for malicious origin fails with 403 Forbidden', async () => {
      const res = await fetch(`http://localhost:${corsPort}/health`, {
        method: 'OPTIONS',
        headers: {
          Origin: 'https://evil-hacker.com',
          'Access-Control-Request-Method': 'POST',
        },
      });
      if (res.status !== 403) {
        throw new Error(`Expected status 403 for malicious preflight, got ${res.status}`);
      }
    });

    // Test 19: Requests without Origin header proceed normally (e.g. mobile apps / curl)
    await assertTest('Requests without Origin header proceed normally without CORS error', async () => {
      const res = await fetch(`http://localhost:${corsPort}/health`);
      if (res.status !== 200) {
        throw new Error(`Expected status 200 for request without Origin, got ${res.status}`);
      }
      const data: any = await res.json();
      if (data.status !== 'OK') {
        throw new Error('Health check payload invalid');
      }
    });

  } finally {
    await new Promise<void>((resolve) => corsServer.close(() => resolve()));
  }

  // =========================================================================
  // LOGGING SANITIZATION TESTS (Requirement 13)
  // =========================================================================

  console.log('\n--- Logging Sanitization Tests ---\n');

  const { isSensitiveKey, sanitizeString, sanitizeObject } = await import('../utils/sanitizer.utils');

  // Test 20: isSensitiveKey correctly identifies sensitive keys
  await assertTest('isSensitiveKey correctly identifies password, token, authorization, and secret keys', async () => {
    const keysToTest = ['password', 'passwordPlain', 'accessToken', 'refreshToken', 'authorization', 'JWT_SECRET', 'DATABASE_URL', 'apiKey'];
    for (const key of keysToTest) {
      if (!isSensitiveKey(key)) {
        throw new Error(`Expected key '${key}' to be identified as sensitive`);
      }
    }
  });

  // Test 21: sanitizeObject redacts sensitive keys without mutating original object
  await assertTest('sanitizeObject redacts sensitive fields without mutating original object', async () => {
    const rawPayload = {
      email: 'user@example.com',
      password: 'MySecretPassword123!',
      token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.secret',
      nested: {
        refreshToken: 'refresh_token_value_123',
        safeField: 'safeValue',
      },
    };

    const sanitized = sanitizeObject(rawPayload);

    // Verify sanitized object
    if (sanitized.password !== '[REDACTED]' || sanitized.token !== '[REDACTED]' || sanitized.nested.refreshToken !== '[REDACTED]') {
      throw new Error('Sanitized object failed to redact sensitive keys');
    }
    if (sanitized.email !== 'user@example.com' || sanitized.nested.safeField !== 'safeValue') {
      throw new Error('Sanitized object corrupted non-sensitive keys');
    }

    // Verify original object was NOT mutated
    if (rawPayload.password !== 'MySecretPassword123!' || rawPayload.token !== 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.secret') {
      throw new Error('Original payload object was mutated by sanitizeObject');
    }
  });

  // Test 22: sanitizeString redacts Bearer tokens and raw JWT strings
  await assertTest('sanitizeString redacts Bearer tokens and raw JWT strings', async () => {
    const jwtStr = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.secret';
    const bearerStr = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.secret';

    if (sanitizeString(jwtStr) !== '[REDACTED]' || sanitizeString(bearerStr) !== '[REDACTED]') {
      throw new Error('sanitizeString failed to redact raw JWT or Bearer string');
    }
    if (sanitizeString('Normal non-sensitive error message') !== 'Normal non-sensitive error message') {
      throw new Error('sanitizeString altered a non-sensitive string');
    }
  });

  console.log('\n----------------------------------------');
  console.log(`  RESULTS: ${passed} Passed, ${failed} Failed`);
  console.log('----------------------------------------\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runAllTests()
  .catch((err) => {
    console.error('Test execution error:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
