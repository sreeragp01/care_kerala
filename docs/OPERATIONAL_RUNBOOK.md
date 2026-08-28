# 📘 CareLink Kerala — Production Operational Runbook & Emergency Manual

---

## 🎯 1. System Overview & Core Objectives

CareLink Kerala is an enterprise multi-tenant palliative care management platform. Operational survivability is guaranteed through decoupled layer architecture (`Flutter Client -> Django Gunicorn REST API -> Managed PostgreSQL & Redis/Celery`).

| Parameter | Target Objective |
| :--- | :--- |
| **Recovery Point Objective (RPO)** | **≤ 15 minutes** (Maximum tolerable data loss) |
| **Recovery Time Objective (RTO)** | **≤ 45 minutes** (Maximum tolerable service downtime) |
| **Database Strategy** | Managed PostgreSQL (Supabase / AWS RDS) + Point-in-Time Recovery |
| **Audit Log Strategy** | Immutable append-only audit trail |
| **Authentication & RBAC** | JWT with tenant isolation derived from `request.user.organization` |

---

## 💾 2. Database Backup & Disaster Recovery Procedures

### 2.1 Backup Policy
* **Automated Daily Snapshots:** Triggered at `02:00 IST` daily with 30-day retention.
* **Point-in-Time Recovery (PITR):** Transaction logs (WAL) archived every 5 minutes.

### 2.2 Database Loss Emergency Restore Procedure
In the event of database failure or corruption:

1. **Containment:** Temporarily route HTTP traffic to maintenance mode page.
   ```bash
   docker-compose stop backend
   ```
2. **Fetch Last Healthy Snapshot:**
   ```bash
   pg_restore -h aws-0-ap-south-1.pooler.supabase.com -U carelink_prod_user -d carelink_prod_db backup_snapshot_2026-08-26.dump
   ```
3. **Execute Migrations Verification:**
   ```bash
   python manage.py migrate
   ```
4. **Execute Automated Disaster Recovery Validation Script:**
   ```bash
   python scripts/disaster_recovery_test.py
   ```
5. **Resume Application Server:**
   ```bash
   docker-compose start backend
   ```

---

## 🔑 3. Secrets & Credential Rotation Protocol

If an FCM key, JWT secret, or database credential is compromised or revoked:

### 3.1 Django `SECRET_KEY` Rotation
1. Update `SECRET_KEY` in environment config (`.env.production`).
2. Restart Gunicorn app workers:
   ```bash
   docker-compose restart backend
   ```
3. Active user JWT sessions will expire cleanly and prompt users to log in again.

### 3.2 FCM Server Key Rotation
1. Generate new Server Key in Firebase Console.
2. Update `FCM_SERVER_KEY` in `.env.production`.
3. Restart Celery worker:
   ```bash
   docker-compose restart celery
   ```

---

## 🔄 4. Bad Deployment Emergency Rollback Runbook

If a new production deployment encounters unhandled runtime failures:

1. **Trigger Immediate Rollback to Previous Release Candidate Image:**
   ```bash
   docker-compose pull carelink/backend:v1.4-stable
   docker-compose up -d --no-deps backend
   ```
2. **Execute Health Check Probes:**
   ```bash
   curl -I https://api.carelinkkerala.org/health/live/
   curl -I https://api.carelinkkerala.org/health/ready/
   ```
3. **Run Production Smoke & Clinical Safety Test:**
   ```bash
   python scripts/production_smoke_test.py
   ```

---

## 🚨 5. Incident Response Protocols

### Scenario A: Redis / FCM Service Outage
* **Impact:** Push notifications fail to dispatch.
* **Behavior:** Clinical API endpoints (e.g., recording vitals `SpO2 = 88%`) **continue to function normally (HTTP 201 Created)** and write alerts to the database. Notifications are queued in Celery retry loops.
* **Action:** Restart Redis and Celery container when network recovers:
  ```bash
  docker-compose restart redis celery
  ```

### Scenario B: Cross-Tenant Data Access Attempt
* **Impact:** Malicious or compromised credentials attempt to query foreign organization data.
* **Behavior:** Django `IsSameOrganizationTenant` middleware and ViewSet scoping reject requests with `HTTP 404 Not Found` or `HTTP 403 Forbidden`.
* **Action:** Preserved in `PatientAuditLog` for security investigation.
