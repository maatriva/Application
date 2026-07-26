import { prisma } from '../../config/database';
import { TelemetryService } from './telemetry.service';
import { TelemetryController } from './telemetry.controller';
import * as assert from 'assert';

const telemetryService = new TelemetryService();

// Mock Express Response helper
function createMockResponse() {
  const res: any = {};
  res.status = (code: number) => {
    res.statusCode = code;
    return res;
  };
  res.json = (data: any) => {
    res.body = data;
    return res;
  };
  return res;
}

async function runTests() {
  console.log('--- STARTING TELEMETRY INGESTION INTEGRATION TESTS ---');

  // Generate unique IDs for testing
  const randomSuffix = Math.floor(Math.random() * 1000000).toString();
  const testParentEmail = `parent-tel-${randomSuffix}@test.com`;
  const testDeviceId = `DEV-TEL-${randomSuffix}`;
  const testRegKey = `REG-TEL-${randomSuffix}`;

  let parentId: string | null = null;
  let babyId: string | null = null;

  try {
    // 1. Setup mock database records
    console.log('Step 1: Setting up mock user, baby, and device...');
    const parent = await prisma.user.create({
      data: {
        fullName: 'Telemetry Test Parent',
        email: testParentEmail,
        passwordHash: 'dummyhash',
        role: 'PARENT',
      },
    });
    parentId = parent.id;

    const baby = await prisma.baby.create({
      data: {
        parentId: parentId,
        name: 'Telemetry Test Baby',
        birthDate: new Date(),
        gender: 'male',
      },
    });
    babyId = baby.id;

    // Create device (UNPAIRED initially)
    await prisma.device.create({
      data: {
        deviceId: testDeviceId,
        deviceName: 'Test Cradle',
        type: 'Smart Cradle',
        registrationKey: testRegKey,
        status: 'UNPAIRED',
        paired: false,
      },
    });
    console.log('Mock setup complete.');

    // 2. Test ingestion on an UNPAIRED device
    console.log('\nStep 2: Testing telemetry ingestion on unpaired device...');
    const reqUnpaired: any = {
      body: {
        deviceId: testDeviceId,
        heartRate: 120,
        breathingRate: 30,
        bodyTemperature: 36.5,
        roomTemperature: 24.0,
        humidity: 50,
        timestamp: new Date().toISOString(),
      },
    };
    const resUnpaired = createMockResponse();

    await TelemetryController.ingest(reqUnpaired, resUnpaired, () => {});
    assert.strictEqual(resUnpaired.statusCode, 400, 'Unpaired device should return 400');
    assert.strictEqual(resUnpaired.body.success, false);
    assert.ok(resUnpaired.body.message.includes('Unpaired device'));
    console.log('✔ Unpaired device returned 400 correctly.');

    // 3. Pair the device
    console.log('\nStep 3: Pairing device to the baby...');
    await prisma.deviceAssignment.create({
      data: {
        deviceId: testDeviceId,
        babyId: babyId,
      },
    });
    await prisma.device.update({
      where: { deviceId: testDeviceId },
      data: { paired: true, status: 'PAIRED' },
    });
    console.log('Device successfully paired.');

    // 4. Test successful telemetry ingestion
    console.log('\nStep 4: Testing successful telemetry ingestion...');
    const timestampStr = new Date().toISOString();
    const reqSuccess: any = {
      body: {
        deviceId: testDeviceId,
        heartRate: 130,
        breathingRate: 32,
        bodyTemperature: 36.9,
        roomTemperature: 25.0,
        humidity: 55,
        movement: 'NORMAL',
        cryDetected: false,
        sleepStage: 'LIGHT',
        batteryLevel: 95,
        timestamp: timestampStr,
      },
    };
    const resSuccess = createMockResponse();

    await TelemetryController.ingest(reqSuccess, resSuccess, () => {});
    assert.strictEqual(resSuccess.statusCode, 201, 'Successful ingestion should return 201');
    assert.strictEqual(resSuccess.body.success, true);
    console.log('✔ Telemetry ingested successfully with 201.');

    // Verify stored telemetry in database
    console.log('\nStep 5: Verifying telemetry record in database...');
    const records = await prisma.telemetry.findMany({
      where: { deviceId: testDeviceId },
      orderBy: { timestamp: 'desc' },
    });
    assert.strictEqual(records.length, 1, 'Exactly 1 telemetry record should be stored');
    const record = records[0];
    assert.strictEqual(record.heartRate, 130);
    assert.strictEqual(record.respirationRate, 32, 'breathingRate should map to respirationRate');
    assert.strictEqual(record.bodyTemperature, 36.9);
    assert.strictEqual(record.movementDetected, true, 'movement NORMAL should map to movementDetected true');
    assert.strictEqual(record.sleepStage, 'LIGHT');
    assert.strictEqual(record.batteryLevel, 95);
    console.log('✔ Database records verified successfully.');

    // Verify device status was updated to ONLINE
    console.log('\nStep 6: Verifying device registry updates...');
    const updatedDevice = await prisma.device.findUnique({
      where: { deviceId: testDeviceId },
    });
    assert.ok(updatedDevice);
    assert.strictEqual(updatedDevice.status, 'ONLINE', 'Device status should be ONLINE');
    assert.strictEqual(updatedDevice.battery, 95, 'Device battery level should be updated');
    console.log('✔ Device status updated to ONLINE correctly.');

    // 5. Test unknown device
    console.log('\nStep 7: Testing unknown device ingestion...');
    const reqUnknown: any = {
      body: {
        deviceId: 'NON-EXISTENT-DEVICE',
        heartRate: 110,
        timestamp: new Date().toISOString(),
      },
    };
    const resUnknown = createMockResponse();
    await TelemetryController.ingest(reqUnknown, resUnknown, () => {});
    assert.strictEqual(resUnknown.statusCode, 404, 'Unknown device should return 404');
    assert.strictEqual(resUnknown.body.success, false);
    console.log('✔ Unknown device returned 404 correctly.');

    // 6. Test invalid payload (missing timestamp)
    console.log('\nStep 8: Testing invalid payload (missing timestamp)...');
    const reqInvalid: any = {
      body: {
        deviceId: testDeviceId,
        heartRate: 110,
      },
    };
    const resInvalid = createMockResponse();
    await TelemetryController.ingest(reqInvalid, resInvalid, () => {});
    assert.strictEqual(resInvalid.statusCode, 400, 'Invalid payload should return 400');
    assert.strictEqual(resInvalid.body.success, false);
    console.log('✔ Invalid payload returned 400 correctly.');

    console.log('\n--- ALL TELEMETRY INGESTION TESTS PASSED SUCCESSFULLY! ---');
  } catch (error) {
    console.error('\n❌ TELEMETRY INGESTION TEST FAILED WITH ERROR:', error);
    process.exit(1);
  } finally {
    console.log('\nStep 9: Cleaning up test data from DB...');
    try {
      if (testDeviceId) {
        await prisma.telemetry.deleteMany({
          where: { deviceId: testDeviceId },
        });
        await prisma.deviceAssignment.deleteMany({
          where: { deviceId: testDeviceId },
        });
        await prisma.device.deleteMany({
          where: { deviceId: testDeviceId },
        });
      }
      if (babyId) {
        await prisma.baby.deleteMany({
          where: { id: babyId },
        });
      }
      if (parentId) {
        await prisma.user.deleteMany({
          where: { id: parentId },
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
