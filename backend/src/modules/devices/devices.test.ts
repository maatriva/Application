import { prisma } from '../../config/database';
import { DevicesService } from './devices.service';
import * as assert from 'assert';

const devicesService = new DevicesService();

async function runTests() {
  console.log('--- STARTING DEVICE REGISTRATION & PAIRING INTEGRATION TESTS ---');

  // Generate unique IDs for testing
  const randomSuffix = Math.floor(Math.random() * 1000000).toString();
  const testParentEmail = `parent-${randomSuffix}@test.com`;
  const otherParentEmail = `other-${randomSuffix}@test.com`;
  const testDeviceId = `DEV-${randomSuffix}`;
  const testRegKey = `REG-${randomSuffix}`;

  let parentId: string | null = null;
  let otherParentId: string | null = null;
  let babyId: string | null = null;
  let otherBabyId: string | null = null;

  try {
    // 1. Setup mock parents and babies
    console.log('Step 1: Setting up mock users and babies...');
    const parent = await prisma.user.create({
      data: {
        fullName: 'Test Parent',
        email: testParentEmail,
        passwordHash: 'dummyhash',
        role: 'PARENT',
      },
    });
    parentId = parent.id;

    const otherParent = await prisma.user.create({
      data: {
        fullName: 'Other Parent',
        email: otherParentEmail,
        passwordHash: 'dummyhash',
        role: 'PARENT',
      },
    });
    otherParentId = otherParent.id;

    const baby = await prisma.baby.create({
      data: {
        parentId: parentId,
        name: 'Test Baby',
        birthDate: new Date(),
        gender: 'female',
      },
    });
    babyId = baby.id;

    const otherBaby = await prisma.baby.create({
      data: {
        parentId: otherParentId,
        name: 'Other Baby',
        birthDate: new Date(),
        gender: 'male',
      },
    });
    otherBabyId = otherBaby.id;

    console.log('Mock database context seeded successfully.');

    // 2. Test successful device registration without a baby
    console.log('\nStep 2: Testing device registration without baby...');
    const registeredDevice = await devicesService.registerDevice({
      deviceId: testDeviceId,
      deviceName: 'Test Smart Cradle',
      type: 'Smart Cradle',
      registrationKey: testRegKey,
    });

    assert.strictEqual(registeredDevice.deviceId, testDeviceId, 'Device ID mismatch');
    assert.strictEqual(registeredDevice.registrationKey, testRegKey, 'Registration Key mismatch');
    assert.strictEqual(registeredDevice.paired, false, 'Device should not be paired initially');
    assert.strictEqual(registeredDevice.status, 'UNPAIRED', 'Device should be UNPAIRED initially');
    console.log('✔ Device registered successfully without baby info.');

    // 2b. Test registration with auto-generated key
    console.log('\nStep 2b: Testing device registration with auto-generated key...');
    const autoGenDeviceId = `DEV-AUTO-${randomSuffix}`;
    const autoGenDevice = await devicesService.registerDevice({
      deviceId: autoGenDeviceId,
      deviceName: 'Auto Key Cradle',
      type: 'Smart Cradle',
    });
    assert.strictEqual(autoGenDevice.deviceId, autoGenDeviceId, 'Device ID mismatch');
    assert.ok(autoGenDevice.registrationKey, 'Registration key should be auto-generated');
    assert.ok(autoGenDevice.registrationKey.startsWith('REG-'), 'Registration key should start with REG-');
    assert.strictEqual(autoGenDevice.status, 'UNPAIRED', 'Device should be UNPAIRED initially');
    console.log('✔ Auto-generated registration key test passed.');

    // 3. Test that telemetry lookup returns null for this device before pairing
    console.log('\nStep 3: Verifying no telemetry association before pairing...');
    const assignmentBefore = await prisma.deviceAssignment.findFirst({
      where: { deviceId: testDeviceId },
    });
    assert.strictEqual(assignmentBefore, null, 'Device assignment should not exist before pairing');
    console.log('✔ Telemetry association is null as expected.');

    // 4. Test validation: Invalid registration key
    console.log('\nStep 4: Testing invalid registration key validation...');
    await assert.rejects(
      async () => {
        await devicesService.pairDevice({
          registrationKey: 'INVALID-KEY-123',
          babyId: babyId!,
          userId: parentId!,
        });
      },
      (err: any) => {
        assert.strictEqual(err.statusCode, 404, 'Invalid key error should return 404');
        assert.strictEqual(err.message, 'Invalid registration key.', 'Error message mismatch');
        return true;
      },
      'Should have rejected invalid registration key'
    );
    console.log('✔ Invalid registration key returned 404 correctly.');

    // 5. Test validation: Unauthorized baby access
    console.log('\nStep 5: Testing unauthorized baby access validation...');
    await assert.rejects(
      async () => {
        // Parent trying to pair device to otherParent's baby
        await devicesService.pairDevice({
          registrationKey: testRegKey,
          babyId: otherBabyId!,
          userId: parentId!,
        });
      },
      (err: any) => {
        assert.strictEqual(err.statusCode, 403, 'Unauthorized access should return 403');
        assert.strictEqual(err.message, 'Unauthorized baby access.', 'Error message mismatch');
        return true;
      },
      'Should have rejected unauthorized baby access'
    );
    console.log('✔ Unauthorized baby access returned 403 correctly.');

    // 6. Test validation: Non-existent baby
    console.log('\nStep 6: Testing non-existent baby validation...');
    await assert.rejects(
      async () => {
        await devicesService.pairDevice({
          registrationKey: testRegKey,
          babyId: '00000000-0000-0000-0000-000000000000',
          userId: parentId!,
        });
      },
      (err: any) => {
        assert.strictEqual(err.statusCode, 404, 'Non-existent baby should return 404');
        assert.strictEqual(err.message, 'Baby not found.', 'Error message mismatch');
        return true;
      },
      'Should have rejected non-existent baby'
    );
    console.log('✔ Non-existent baby returned 404 correctly.');

    // 7. Test successful pairing
    console.log('\nStep 7: Testing successful device pairing...');
    const pairingResult = await devicesService.pairDevice({
      registrationKey: testRegKey,
      babyId: babyId!,
      userId: parentId!,
    });

    assert.strictEqual(pairingResult.deviceId, testDeviceId, 'Paired device ID mismatch');
    assert.strictEqual(pairingResult.babyId, babyId, 'Paired baby ID mismatch');
    assert.strictEqual(pairingResult.status, 'PAIRED', 'Paired status should be PAIRED');
    console.log('✔ Device successfully paired to the baby.');

    // 8. Verify telemetry association after pairing (simulate telemetry subscriber check)
    console.log('\nStep 8: Verifying telemetry association after pairing...');
    const assignmentAfter = await prisma.deviceAssignment.findFirst({
      where: { deviceId: testDeviceId },
    });
    assert.ok(assignmentAfter, 'Device assignment should exist after pairing');
    assert.strictEqual(assignmentAfter.babyId, babyId, 'Assignment babyId mismatch');
    console.log('✔ Telemetry association is active and maps correctly.');

    // 9. Test duplicate pairing prevention
    console.log('\nStep 9: Testing duplicate pairing prevention...');
    await assert.rejects(
      async () => {
        await devicesService.pairDevice({
          registrationKey: testRegKey,
          babyId: babyId!,
          userId: parentId!,
        });
      },
      (err: any) => {
        assert.strictEqual(err.statusCode, 400, 'Duplicate pairing should return 400');
        assert.strictEqual(err.message, 'Device is already paired.', 'Error message mismatch');
        return true;
      },
      'Should have blocked duplicate pairing'
    );
    console.log('✔ Duplicate pairing blocked with 400 correctly.');

    console.log('\n--- ALL DEVICE REGISTRATION & PAIRING TESTS PASSED SUCCESSFULLY! ---');
  } catch (error) {
    console.error('\n❌ INTEGRATION TEST FAILED WITH ERROR:', error);
    process.exit(1);
  } finally {
    // 10. Cleanup
    console.log('\nStep 10: Cleaning up test data from DB...');
    try {
      // Delete assignments first
      await prisma.deviceAssignment.deleteMany({
        where: { deviceId: { in: [testDeviceId, `DEV-AUTO-${randomSuffix}`] } },
      });
      // Delete device
      await prisma.device.deleteMany({
        where: { deviceId: { in: [testDeviceId, `DEV-AUTO-${randomSuffix}`] } },
      });
      if (babyId) {
        await prisma.baby.deleteMany({
          where: { id: babyId },
        });
      }
      if (otherBabyId) {
        await prisma.baby.deleteMany({
          where: { id: otherBabyId },
        });
      }
      if (parentId) {
        await prisma.user.deleteMany({
          where: { id: parentId },
        });
      }
      if (otherParentId) {
        await prisma.user.deleteMany({
          where: { id: otherParentId },
        });
      }
      console.log('Cleanup completed successfully.');
    } catch (cleanupError) {
      console.error('Error during cleanup:', cleanupError);
    }
    await prisma.$disconnect();
  }
}

runTests();
