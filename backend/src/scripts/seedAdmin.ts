import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import { prisma } from '../config/database';
import { UserRole } from '@prisma/client';

dotenv.config();

const INSECURE_PASSWORDS = [
  'admin@123456',
  'admin123',
  'password',
  'password123',
  '12345678',
  'admin',
  'maatriva',
];

export async function seedAdmin(): Promise<void> {
  const emailRaw = process.env.ADMIN_EMAIL;
  const passwordRaw = process.env.ADMIN_PASSWORD;
  const fullName = process.env.ADMIN_FULL_NAME?.trim() || 'System Administrator';

  if (!emailRaw || emailRaw.trim() === '') {
    throw new Error('[ERROR] Missing required environment variable: ADMIN_EMAIL');
  }

  if (!passwordRaw || passwordRaw.trim() === '') {
    throw new Error('[ERROR] Missing required environment variable: ADMIN_PASSWORD');
  }

  const cleanEmail = emailRaw.trim().toLowerCase();
  const cleanPassword = passwordRaw.trim();

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(cleanEmail)) {
    throw new Error('[ERROR] ADMIN_EMAIL must be a valid email address.');
  }

  // Validate password length
  if (cleanPassword.length < 8) {
    throw new Error('[ERROR] ADMIN_PASSWORD must be at least 8 characters long.');
  }

  // Reject known default / insecure passwords
  if (INSECURE_PASSWORDS.includes(cleanPassword.toLowerCase())) {
    throw new Error('[ERROR] Insecure or default ADMIN_PASSWORD detected. Please specify a strong password.');
  }

  // Check if user already exists
  const existing = await prisma.user.findUnique({
    where: { email: cleanEmail },
  });

  if (existing) {
    console.log('Admin account already exists. No changes made.');
    return;
  }

  // Hash password using standard bcrypt (10 rounds)
  const passwordHash = await bcrypt.hash(cleanPassword, 10);

  // Create Admin User
  const adminUser = await prisma.user.create({
    data: {
      fullName,
      email: cleanEmail,
      passwordHash,
      role: UserRole.ADMIN,
    },
  });

  console.log(`✓ Admin user successfully seeded with role ${adminUser.role}.`);
}

// Execute CLI run if script is called directly
if (require.main === module) {
  seedAdmin()
    .catch((err) => {
      console.error(err.message || err);
      process.exitCode = 1;
    })
    .finally(async () => {
      await prisma.$disconnect();
    });
}
