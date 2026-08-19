# Maatriva Operational & Incident Response Runbook

## 1. Incident Severity Classification

| Severity Level | Definition | Response Window | Example Scenarios |
| :--- | :--- | :--- | :--- |
| **P0 (Critical)** | Critical security breach, unencrypted data exposure, or baby safety system failure | Immediate (< 15 mins) | Leaked JWT secret, database exposure, exposed private audio recordings, authentication bypass. |
| **P1 (Major)** | Major production service outage or core dependency failure | < 1 hour | Backend API crash, database connection outage, MQTT broker offline, persistent push notification failure. |
| **P2 (Minor)** | Non-critical operational degradation or minor bugs | < 24 hours | Non-critical UI glitch, AI insight provider timeout (falling back to rule-based insights), high API latency. |

---

## 2. 9-Step Incident Response Checklist

When an operational or security incident occurs, operators must follow this 9-step workflow:

1. **Detect**: Identify anomaly via backend `/health` endpoint status, HTTP error logs (5xx status spikes), or alerting systems.
2. **Contain**: Isolate affected services or network segments immediately to prevent further damage or exposure.
3. **Preserve Evidence**: Export container runtime logs (`docker logs`) and log streams before restarting or destroying instances.
4. **Revoke Compromised Credentials**: Immediately revoke any leaked or compromised API keys, database credentials, or secret keys.
5. **Assess Affected Users & Data**: Identify affected baby profiles, caregiver accounts, and database records.
6. **Restore Service**: Re-deploy clean container images, restore database state, or reconnect brokers.
7. **Verify Security & Functionality**: Execute regression test suite (`npm run test:security`) to confirm stability and access controls.
8. **Document Incident**: Record root cause, timeline, affected resources, and mitigation actions taken.
9. **Prevent Recurrence**: Update validation rules, network firewalls, rate limits, or automated monitoring checks.

---

## 3. Incident Response Protocols

### 3.1 Leaked Credentials Protocol
- **Immediate Action**: Revoke and rotate compromised credentials immediately.
- **Verification**: Ensure no hardcoded credentials remain in environment variables or code repositories.
- **Audit**: Review authentication logs for suspicious activities during the exposure window.

### 3.2 Compromised Database Protocol
- **Network Isolation**: Immediately restrict database access rules (`POSTGRES_HOST`) to internal backend containers only.
- **Credential Rotation**: Change `POSTGRES_PASSWORD` and update `DATABASE_URL` across all environment files.
- **Data Integrity Check**: Verify foreign key relationships and soft-deleted baby profiles (`deletedAt`).
- **Exposure Assessment**: Determine if unauthorized read/write queries were executed against baby telemetry or caregiver tables.

### 3.3 Compromised JWT Secret Protocol
- **Secret Rotation**: Generate a new 64-character cryptographically random `JWT_SECRET`.
- **Session Revocation**: Disconnect active WebSocket connections (`WebsocketServerManager`) and clear active sessions, forcing re-authentication.
- **Token Invalidation**: Previous JWT signatures will fail validation instantly across all API endpoints.

### 3.4 Compromised MQTT Credentials Protocol
- **Broker Update**: Update `EMQX_USER` and `EMQX_PASSWORD` in the EMQX broker configuration.
- **Backend Reconnect**: Update `MQTT_USERNAME` and `MQTT_PASSWORD` in environment variables and restart `maatriva_backend`.
- **Device Access Revocation**: Unpair affected devices via `DeviceAssignment` API to block unauthorized MQTT publication.

### 3.5 Compromised Firebase (FCM) Credentials Protocol
- **Revocate Keys**: Deactivate compromised FCM server keys or Google service account credentials in Firebase Console.
- **Generate Credentials**: Re-issue new service account JSON keys.
- **Re-deploy**: Update backend environment secrets without exposing private payload tokens.

### 3.6 Exposed Private Recordings Protocol
- **Immediate Lock**: Restrict `/uploads/recordings/*` route access.
- **Verify Access Control**: Confirm `authenticateToken` middleware and caregiver permission verification are enforcing active grants.
- **Audit Access**: Query HTTP logs for unauthorized requests attempting path traversal (`..`) or invalid file access.

---

## 4. Operational Secret Rotation Procedures

### 4.1 JWT Secret Rotation
1. Generate new secret: `openssl rand -hex 32`
2. Update `JWT_SECRET` in production `.env`.
3. Restart backend service (`docker-compose restart backend`).

### 4.2 Database Credentials Rotation
1. Execute password change in PostgreSQL: `ALTER USER maatriva WITH PASSWORD 'new_secure_password';`
2. Update `DATABASE_URL` in `.env`.
3. Restart backend service.

### 4.3 MQTT Broker Credentials Rotation
1. Update user credentials in EMQX dashboard or config.
2. Update `MQTT_USERNAME` and `MQTT_PASSWORD` in `.env`.
3. Restart backend service.

### 4.4 Gemini AI API Key Rotation
1. Generate new API Key in Google AI Studio.
2. Update `GEMINI_API_KEY` in `.env`.
3. Restart backend service.

---

## 5. Backup & Disaster Recovery Inventory

- **Database Backups**: Managed TimescaleDB PostgreSQL automated daily snapshots with point-in-time recovery (PITR) or persistent volume volume claims (`timescale_data`).
- **Media Upload Storage**: Disk volume `/uploads/recordings` backed up via filesystem volume snapshots.
- **RPO (Recovery Point Objective)**: NOT DEFINED formally by SLA (Target: < 24 hours).
- **RTO (Recovery Time Objective)**: NOT DEFINED formally by SLA (Target: < 1 hour).
- **Backup Privacy**: Backups contain sensitive baby telemetry and user credentials; backups are stored in encrypted private volumes and must never be exposed publicly or committed to Git.
