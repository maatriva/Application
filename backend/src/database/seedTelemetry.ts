import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const babyId = '1c99edfe-a47c-43a9-9c4f-a9d61577cb61';
  const deviceId = 'MTR-CRD-000001';

  console.log(`Cleaning old telemetry, alerts, and sleep sessions for baby ${babyId}...`);
  await prisma.telemetry.deleteMany({ where: { babyId } });
  await prisma.alert.deleteMany({ where: { babyId } });
  
  // Clean sleep stages first due to foreign keys
  await prisma.sleepStage.deleteMany({
    where: { session: { babyId } }
  });
  await prisma.sleepSession.deleteMany({ where: { babyId } });

  console.log('Seeding telemetry history, sleep sessions, and alerts for the past 30 days...');

  const now = new Date();
  const telemetryData: any[] = [];

  // Generate 30 days of data
  for (let d = 30; d >= 0; d--) {
    const currentDate = new Date(now);
    currentDate.setDate(now.getDate() - d);

    // Sleep Session: 8:00 PM to 6:00 AM (next morning)
    const sleepStart = new Date(currentDate);
    sleepStart.setHours(20, 0, 0, 0);

    const sleepEnd = new Date(currentDate);
    sleepEnd.setDate(currentDate.getDate() + 1);
    sleepEnd.setHours(6, 0, 0, 0);

    // Create sleep session record
    const sleepSession = await prisma.sleepSession.create({
      data: {
        babyId,
        startTime: sleepStart,
        endTime: sleepEnd,
        sleepScore: Math.floor(Math.random() * 15) + 80, // 80 - 95
        notes: 'Slept peacefully',
      }
    });

    // Create sleep stages for this session
    // 10 hours = 600 minutes. We split it into blocks: awake, light, deep, rem
    const stages = [
      { stage: 'light', dur: 120 },
      { stage: 'deep', dur: 180 },
      { stage: 'rem', dur: 90 },
      { stage: 'deep', dur: 120 },
      { stage: 'awake', dur: 30 },
      { stage: 'light', dur: 60 }
    ];

    let currentStageStart = new Date(sleepStart);
    for (const st of stages) {
      const currentStageEnd = new Date(currentStageStart);
      currentStageEnd.setMinutes(currentStageStart.getMinutes() + st.dur);
      await prisma.sleepStage.create({
        data: {
          sessionId: sleepSession.id,
          startTime: currentStageStart,
          endTime: currentStageEnd,
          stage: st.stage
        }
      });
      currentStageStart = currentStageEnd;
    }

    // Telemetry: 1 reading every 2 hours
    for (let h = 0; h < 24; h += 2) {
      const readingTime = new Date(currentDate);
      readingTime.setHours(h, Math.floor(Math.random() * 60), 0, 0);

      // Determine sleep stage based on time of day (sleeping between 8 PM and 6 AM)
      const isSleeping = h >= 20 || h < 6;
      const sleepStage = isSleeping ? (h === 22 || h === 2 ? 'deep' : 'light') : 'awake';

      // Normal ranges
      // Heart rate: 100-150 bpm for infants
      const heartRate = isSleeping
        ? Math.floor(Math.random() * 15) + 110  // 110-125
        : Math.floor(Math.random() * 25) + 120; // 120-145

      // Respiration rate: 30-60 rpm
      const respirationRate = isSleeping
        ? Math.floor(Math.random() * 8) + 32   // 32-40
        : Math.floor(Math.random() * 15) + 38;  // 38-53

      // Body temperature: 36.5 - 37.5
      const bodyTemperature = 36.5 + (Math.random() * 0.8);

      // Room temperature: recommended range is 20-22
      // Let's make it comfortable, but exceed the range twice today (on the final day)
      let roomTemperature = 21.5 + (Math.random() * 1.0);
      if (d === 0 && h === 14) {
        roomTemperature = 24.2; // exceed first time
      }
      if (d === 0 && h === 16) {
        roomTemperature = 24.8; // exceed second time
      }

      // Humidity: optimal is 30% - 60%
      const humidity = 45.0 + (Math.random() * 10);

      // Cry frequency: cry detected occasionally during awake hours
      const cryDetected = !isSleeping && Math.random() < 0.15;

      // Movement detected: higher when awake
      const movementDetected = !isSleeping ? Math.random() < 0.6 : Math.random() < 0.1;

      // Air quality: 15-40 AQI
      const airQuality = Math.floor(Math.random() * 20) + 15;

      // Battery: slow drain/charge simulation
      const batteryLevel = 80 + Math.floor(h * 0.8);

      telemetryData.push({
        deviceId,
        babyId,
        timestamp: readingTime,
        heartRate,
        respirationRate,
        bodyTemperature: parseFloat(bodyTemperature.toFixed(2)),
        roomTemperature: parseFloat(roomTemperature.toFixed(2)),
        humidity: parseFloat(humidity.toFixed(1)),
        movementDetected,
        cryDetected,
        sleepStage,
        airQuality,
        batteryLevel,
      });
    }

    // Alerts: Seeding alerts on specific days
    if (d === 0) {
      // Seed two alerts for today (10 hours and 8 hours ago)
      const alertTime1 = new Date(now);
      alertTime1.setHours(now.getHours() - 10);
      await prisma.alert.create({
        data: {
          deviceId,
          babyId,
          severity: 'warning',
          type: 'high_room_temp',
          message: 'Room temperature exceeded recommended range (24.2°C)',
          value: 24.2,
          thresholdLimit: 22.2,
          timestamp: alertTime1,
          acknowledged: true,
        }
      });

      const alertTime2 = new Date(now);
      alertTime2.setHours(now.getHours() - 8);
      await prisma.alert.create({
        data: {
          deviceId,
          babyId,
          severity: 'warning',
          type: 'high_room_temp',
          message: 'Room temperature is warm at 24.8°C',
          value: 24.8,
          thresholdLimit: 22.2,
          timestamp: alertTime2,
          acknowledged: true,
        }
      });
    } else if (d === 2) {
      // Seed one alert for 2 days ago
      const alertTime = new Date(now);
      alertTime.setDate(now.getDate() - 2);
      await prisma.alert.create({
        data: {
          deviceId,
          babyId,
          severity: 'warning',
          type: 'unsafe_posture',
          message: 'Safe sleep alert: Side sleeping position detected',
          timestamp: alertTime,
          acknowledged: true,
        }
      });
    }
  }

  // Bulk insert telemetry records
  console.log(`Inserting ${telemetryData.length} telemetry records...`);
  await prisma.telemetry.createMany({
    data: telemetryData
  });

  console.log('✓ Seeding complete! Database is populated with telemetry logs, sleep stages, and historical alerts.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
