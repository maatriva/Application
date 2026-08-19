# Maatriva Smart Cradle Ecosystem

Production-ready, end-to-end Smart Baby Monitor and Automated Cradle Care platform designed for real-time infant health monitoring, telemetry processing, caregiver access control, and intelligent soothing controls.

---

## Overview

Maatriva is a multi-tenant IoT ecosystem for infant care that connects physical Smart Cradle hardware to a secure cloud backend and Flutter mobile applications. The platform handles real-time biometric telemetry (heart rate, nursery ambient temperature, humidity, noise/crying detection), automated cradle motion and music controls, pediatrician reporting, and multi-role caregiver permission sharing.

### Key Capabilities
* **Real-time Telemetry & Soothing**: Ingestion of cradle sensor metrics via MQTT with automated threshold checking and WebSocket alerts.
* **Multi-Role Caregiver Access**: Granular parent-to-caregiver invitation system with temporary or `LIVE_MONITOR_ONLY` restricted scopes.
* **Server-Side Session Security**: Short-lived access tokens with SHA-256 hashed refresh-token session revocation and automatic token rotation.
* **AI Pediatric Insights**: Biometric analysis powered by Google Gemini API with fallback rule-based diagnostic engines.
* **Custom Soothing Audio**: Upload and streaming of parent voice recordings, lullabies, and white noise.

---

## System Architecture

```text
       ┌─────────────────────────────────────────┐
       │   Smart Cradle Hardware (IoT Sensors)   │
       └────────────────────┬────────────────────┘
                            │
                            │ MQTT Telemetry (Topic: maatriva/cradle/{deviceId}/telemetry)
                            ▼
       ┌─────────────────────────────────────────┐
       │             MQTT Broker                 │
       └────────────────────┬────────────────────┘
                            │
                            │ Ingestion Client (MqttClientManager + AlertEngine)
                            ▼
       ┌─────────────────────────────────────────┐
       │          Maatriva Backend API           │
       │                                         │
       │  • Helmet Security     • Rate Limiting  │
       │  • Strict CORS         • Auth & Session │
       │  • Caregiver Guard     • 2MB Body Limit │
       └───────────┬─────────────────┬───────────┘
                   │                 │
      Prisma ORM   │                 │ WebSocket Alerts / REST
                   ▼                 ▼
       ┌───────────────────┐   ┌───────────────────┐
       │ PostgreSQL DB     │   │ Flutter App       │
       │ (Sessions/Users/  │   │ (iOS / Android /  │
       │  Telemetry/Babies)│   │  Web)             │
       └───────────────────┘   └───────────────────┘
```

---

## Tech Stack

| Domain | Technology / Library | Description |
| :--- | :--- | :--- |
| **Mobile App** | Flutter 3.x / Dart 3.x | Cross-platform mobile & web client app |
| **State Management** | Riverpod | Reactive state management for Flutter |
| **Backend Runtime** | Node.js (v20+) / Express 4.x | RESTful API server written in TypeScript |
| **Language** | TypeScript 5.4 | Type-safe backend application logic |
| **Database** | PostgreSQL | Relational storage for users, babies, and sessions |
| **ORM** | Prisma ORM 6.x | Schema migrations and type-safe database queries |
| **IoT Protocol** | MQTT 5.0 (`mqtt` client) | Lightweight pub/sub protocol for cradle telemetry |
| **WebSockets** | Socket.IO / `ws` | Real-time alert broadcasting to mobile clients |
| **Security Headers** | Helmet | Express HTTP security response headers |
| **Rate Limiting** | `express-rate-limit` | IP-based request throttling for API & auth endpoints |
| **AI Processing** | Google Gemini API (`@google/genai`) | Intelligent baby biometric analysis |

---

## Repository Structure

```text
maatriva/
├── backend/                        # Express API & Server Codebase
│   ├── prisma/                     # Database Schema & Migrations
│   │   └── schema.prisma
│   ├── src/
│   │   ├── config/                 # Env validation, DB, & upload paths
│   │   ├── middleware/             # Auth, CORS, Helmet, Rate Limiter, Error handler
│   │   ├── modules/                # Feature modules (auth, babies, caregivers, devices, etc.)
│   │   ├── mqtt/                   # MQTT Subscriber & Ingestion Engine
│   │   ├── routes/                 # Canonical /api router index
│   │   ├── scripts/                # Admin seeding & 43-test security verification suite
│   │   ├── services/               # Alert Engine & AI Insights Service
│   │   ├── utils/                  # Sanitizer & security helpers
│   │   └── app.ts                  # Main Express application initialization
│   ├── server.ts                   # Production server entrypoint
│   ├── package.json
│   └── tsconfig.json
├── lib/                            # Flutter Application Codebase
│   ├── core/                       # Network client, ApiConfig, Storage, Services
│   │   ├── config/                 # Platform-aware ApiConfig & base URLs
│   │   └── network/                # Dio ApiClient & Auth Interceptors
│   ├── features/                   # Flutter UI features (auth, babies, caregivers, dashboard)
│   └── main.dart                   # Flutter app entrypoint
├── test/                           # Flutter Unit & Integration Tests
│   └── core/config/api_config_test.dart
├── .gitignore
├── docker-compose.yml              # Local PostgreSQL & MQTT Broker compose file
└── README.md
```

---

## Prerequisites

* **Node.js**: `v20.x` or higher
* **npm**: `v10.x` or higher
* **Flutter SDK**: `v3.19.0` or higher
* **PostgreSQL**: `v14.x` or higher (or Docker)
* **MQTT Broker**: Eclipse Mosquitto (or Docker)

---

## Backend Setup

1. **Navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Install Node.js dependencies**:
   ```bash
   npm install
   ```

3. **Configure Environment Variables**:
   Copy `.env.example` to `.env` and populate required keys:
   ```bash
   cp .env.example .env
   ```

4. **Start PostgreSQL & MQTT via Docker (Optional)**:
   ```bash
   docker-compose up -d
   ```

5. **Run Prisma Database Push & Generate Client**:
   ```bash
   npx prisma db push
   npx prisma generate
   ```

6. **Start Backend Server in Development Mode**:
   ```bash
   npm run dev
   ```
   The backend will start at `http://localhost:3000`.

---

## Environment Variables

| Variable Name | Required | Default Value | Purpose |
| :--- | :---: | :--- | :--- |
| `DATABASE_URL` | **Yes** | — | PostgreSQL connection string (`postgresql://user:pass@host:5432/db`) |
| `JWT_SECRET` | **Yes** | — | Cryptographically random secret string for JWT signing |
| `PORT` | No | `3000` | HTTP server port |
| `HOST` | No | `0.0.0.0` | Network binding host address |
| `NODE_ENV` | No | `development` | Environment mode (`development`, `test`, `production`) |
| `DEBUG_MODE` | No | `false` | Enables `/api/debug/*` routes (MUST be `false` in production) |
| `CORS_ORIGINS` | No | Approved defaults | Comma-separated list of approved browser origins |
| `JSON_BODY_LIMIT` | No | `2mb` | Maximum allowed size for JSON request payloads |
| `URLENCODED_BODY_LIMIT` | No | `2mb` | Maximum allowed size for URL-encoded payloads |
| `MAX_AUDIO_UPLOAD_MB` | No | `10` | Maximum file size for parent voice recordings |
| `MAX_MUSIC_UPLOAD_MB` | No | `15` | Maximum file size for custom lullabies |
| `MAX_IMAGE_UPLOAD_MB` | No | `5` | Maximum file size for profile image uploads |
| `MQTT_HOST` | No | `localhost` | MQTT broker hostname |
| `MQTT_PORT` | No | `1883` | MQTT broker port |
| `GEMINI_API_KEY` | No | `undefined` | Google Gemini API key for pediatric AI insights |
| `ADMIN_EMAIL` | Seed | — | Required during `npm run seed:admin` |
| `ADMIN_PASSWORD` | Seed | — | Required during `npm run seed:admin` |

---

## Admin Account Initialization

Admin accounts are **never** created automatically on server startup. To create an initial administrator account securely:

1. Set `ADMIN_EMAIL` and `ADMIN_PASSWORD` in your environment (or `.env` file).
2. Run the explicit admin seeding script:
   ```bash
   npm run seed:admin
   ```
3. The script validates that the password meets security requirements (minimum 8 characters, no insecure default passwords like `Admin@123456`) and creates the admin user with role `ADMIN`.
4. If an admin account with that email already exists, the script safely exits without overwriting existing password hashes.

---

## Security & Debug Environment Isolation

* **Debug Endpoints (`/api/debug/*`)**: Destructive endpoints (e.g. database reset, mock telemetry injection) are unmounted by default. They are mounted **ONLY** when `NODE_ENV !== 'production'` **AND** `DEBUG_MODE=true`.
* **CORS Restrictions**: Incoming requests are validated against `CORS_ORIGINS`. Preflight `OPTIONS` requests from unapproved origins return `403 Forbidden`. Requests with missing origin headers (mobile apps, cURL) are permitted.
* **Rate Limiting**:
  - **General API**: 300 requests per 15 minutes per IP (`generalApiLimiter`). Skips `/health`.
  - **Auth Endpoints**: 15 attempts per 15 minutes per IP on `/api/auth/login`, `/api/auth/register`, `/api/auth/refresh`.
* **Helmet Security Headers**: Enforces `X-Content-Type-Options: nosniff`, `X-Frame-Options: SAMEORIGIN`, and resource policies.
* **Payload Limits**: Global JSON bodies are restricted to `2mb`. Upload endpoints enforce file extension and MIME type validation.

---

## Authentication & Session Lifecycle

```text
┌──────────────┐                 ┌──────────────────┐                 ┌──────────────────┐
│ Mobile Client│                 │   Backend API    │                 │   PostgreSQL     │
└──────┬───────┘                 └────────┬─────────┘                 └────────┬─────────┘
       │                                  │                                    │
       │ POST /api/auth/login             │                                    │
       ├─────────────────────────────────►│ Verify Password (bcrypt)           │
       │                                  │ Generate Access Token (15m)        │
       │                                  │ Generate Refresh Token (7d)        │
       │                                  │ Hash Refresh Token (SHA-256)       │
       │                                  ├───────────────────────────────────►│ Save Session
       │ 200 OK (AccessToken, RefreshToken)│                                    │
       │◄─────────────────────────────────┤                                    │
       │                                  │                                    │
       │ POST /api/auth/refresh           │                                    │
       ├─────────────────────────────────►│ SHA-256 Hash incoming RefreshToken │
       │                                  ├───────────────────────────────────►│ Check Active Session
       │                                  │ Revoke Old Session                 │
       │                                  │ Issue Rotated Tokens               │
       │ 200 OK (New Tokens)              ├───────────────────────────────────►│ Create New Session
       │◄─────────────────────────────────┤                                    │
       │                                  │                                    │
       │ POST /api/auth/logout            │                                    │
       ├─────────────────────────────────►│ Hash RefreshToken                  │
       │                                  ├───────────────────────────────────►│ Set revokedAt = NOW()
       │ 200 OK ("Logged out")            │                                    │
       │◄─────────────────────────────────┤                                    │
```

* **Access Token**: Short-lived JWT (15 minutes).
* **Refresh Token**: 7-day expiration with **Refresh Token Rotation**.
* **Database Session Storage**: Only cryptographic SHA-256 hashes of refresh tokens (`tokenHash`) are saved in the `sessions` table. Raw refresh tokens are never persisted in the database.
* **Logout**: Actively revokes the matching session (`revokedAt = new Date()`). Revoked refresh tokens immediately return `401 Unauthorized`.

---

## Caregiver Access & Authorization Model

Caregiver access is enforced **server-side** inside [`backend/src/middleware/auth.middleware.ts`](file:///d:/ORGO%20bhaiya/maatriva/backend/src/middleware/auth.middleware.ts):

1. **Active Permission Check**: Requests from users with role `CAREGIVER` are checked against active, non-expired, non-revoked permission records in `temporaryCaregiverPermission` and `caregiver` tables.
2. **Scope Isolation**: Caregivers assigned `LIVE_MONITOR_ONLY` access level can only view real-time telemetry, alerts, and baby profiles. Attempting to modify cradle settings, invite other caregivers, or access unauthorized babies returns `403 Forbidden`.
3. **Multi-Device Isolation**: Logging out on Device A revokes only Device A's session. Other device sessions belonging to the same user remain valid.

---

## Database Setup & Management

Maatriva uses PostgreSQL managed via Prisma ORM.

### Key Prisma Commands
* **Apply Schema Changes (Safe Sync)**:
  ```bash
  npx prisma db push
  ```
* **Generate Prisma Client**:
  ```bash
  npx prisma generate
  ```
* **Open Database Studio**:
  ```bash
  npx prisma studio
  ```

> [!CAUTION]
> **NEVER** run `npx prisma db push --force-reset` or `npx prisma migrate reset` in staging or production environments.

---

## MQTT Telemetry Pipeline

The Smart Cradle publishes real-time sensor telemetry to the MQTT broker.

* **MQTT Topic Pattern**: `maatriva/cradle/{deviceId}/telemetry`
* **JSON Payload Format**:
  ```json
  {
    "deviceId": "CRADLE_001",
    "babyId": "uuid-v4-string",
    "heartRate": 115,
    "temperature": 24.2,
    "humidity": 55.0,
    "isCrying": false,
    "noiseLevel": 35.0,
    "motionDetected": false,
    "cradleSpeed": 2
  }
  ```
* **Ingestion Logic**: `MqttClientManager` subscribes to incoming telemetry, logs data to PostgreSQL, passes metrics to `AlertEngine` for threshold evaluation, and broadcasts alert events over WebSockets to connected Flutter apps.

---

## API Reference

All backend REST API endpoints are mounted under the canonical **/api** namespace:

| Module | Route Prefix | Primary Purpose | Authentication Required |
| :--- | :--- | :--- | :---: |
| **Auth** | `/api/auth` | Login, Register, Token Refresh, Logout, User Profile | Partial (Login/Register public) |
| **Babies** | `/api/babies` | Baby profile management, growth tracking, sleep logs | **Yes** |
| **Caregivers**| `/api/caregivers` | Invitation workflow, permission management | **Yes** |
| **Devices** | `/api/devices` | Cradle device pairing, status, Wi-Fi provisioning | **Yes** |
| **Telemetry** | `/api/telemetry` | Real-time sensor metrics & historical readings | **Yes** |
| **AI Insights**| `/api/ai` | Gemini-powered baby sleep & biometric insights | **Yes** |
| **Cradle** | `/api/cradle` | Motor swing speeds, auto-soothe rules | **Yes** |
| **Alerts** | `/api/alerts` | Safety alert history and dismissal | **Yes** |
| **Music** | `/api/music` | Lullabies, white noise, custom parent recordings | **Yes** |
| **Sensors** | `/api/sensors` | High/low threshold configurations | **Yes** |
| **Reports** | `/api/reports` | Exportable pediatrician health summaries | **Yes** |
| **Health Check**| `/health` | Server, DB, & MQTT operational status probe | **No** (Public) |

---

## Flutter Mobile App Setup

1. **Navigate to root directory**:
   ```bash
   cd maatriva
   ```

2. **Fetch Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Mobile App with Environment Configuration**:
   Pass the target API base URL at build/run time using `--dart-define=API_BASE_URL=...`:

   * **Development (Web / Desktop)**:
     ```bash
     flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
     ```

   * **Android Emulator**:
     ```bash
     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
     ```

   * **Physical Android / iOS Device on Local Wi-Fi**:
     ```bash
     flutter run --dart-define=API_BASE_URL=http://<YOUR_LOCAL_IP>:3000/api
     ```

   * **Production Release Build**:
     ```bash
     flutter build apk --release --dart-define=API_BASE_URL=https://api.maatriva.co.in/api
     ```

---

## Testing & Verification

### Backend Automated Test Suite
The backend includes a 43-test automated security and integration suite covering environment validation, admin seeding, debug route isolation, CORS hardening, request sanitization, server-side session revocation, middleware consolidation, rate limiting, body size enforcement, canonical routing, and file upload validation.

Run backend tests:
```bash
cd backend
npm test
```

Run TypeScript compilation check:
```bash
npm run build
```

### Flutter Test Suite
Run Flutter unit tests:
```bash
flutter test
```

Run Flutter static analysis:
```bash
flutter analyze
```

---

## Production Deployment & Security Checklist

- [ ] **Database Credentials**: Ensure `DATABASE_URL` uses strong passwords and SSL mode.
- [ ] **JWT Secret**: Generate a secure 64-character random string for `JWT_SECRET`.
- [ ] **Disable Debug Routes**: Verify `DEBUG_MODE=false` in production.
- [ ] **CORS Allowlist**: Set `CORS_ORIGINS` to exact production domain origins.
- [ ] **HTTPS Enforcement**: Ensure production backend runs behind an SSL termination proxy (e.g. Nginx, Cloudflare, Render).
- [ ] **Reverse Proxy IP Trust**: Set `TRUST_PROXY=true` when running behind load balancers for accurate rate-limiting.
- [ ] **No Hardcoded Secrets**: Audit codebase before release to ensure no API keys or local IPs are committed.

---

## Troubleshooting

### 1. `Connection refused at http://192.168.x.x:3000`
* Ensure your backend server is running (`npm run dev`).
* Verify that physical mobile devices are connected to the same Wi-Fi network as your backend host.
* Run Flutter with `--dart-define=API_BASE_URL=http://<YOUR_COMPUTER_IP>:3000/api`.

### 2. `Database connection failed`
* Verify PostgreSQL is running (`docker-compose ps` or system service).
* Test credentials in `DATABASE_URL`. Run `npx prisma db push`.

### 3. `413 Payload Too Large` on File Upload
* Ensure custom lullabies do not exceed `MAX_MUSIC_UPLOAD_MB` (default 15MB).
* Verify request JSON payload size is under `JSON_BODY_LIMIT` (default 2MB).

---

## Scope & Technical Limitations

* **Medical Disclaimer**: Maatriva Smart Cradle is an infant monitoring assistant and is **not** a certified medical device.
* **Hardware Connection**: IoT cradle communication relies on MQTT broker availability; if MQTT connection is lost, real-time alerts fall back to REST polling.
