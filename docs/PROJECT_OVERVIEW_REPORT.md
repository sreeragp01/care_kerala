# 📄 CareLink Kerala — Comprehensive Project Overview & Capability Report
**Universal Palliative & Community Healthcare Operations Platform**

---

## 📌 1. Executive Summary

**CareLink Kerala** is an enterprise-grade, multi-tenant digital healthcare and palliative care platform engineered to streamline and elevate community-based healthcare delivery across Kerala. 

The platform bridges the gap between **patients, caregivers, palliative nurses, specialized doctors, volunteers, ambulances, blood donors, and healthcare organizations**. By integrating field operations, clinical vitals tracking, route optimization for home visits, inventory management, emergency SOS dispatch, and verified medical fundraising, CareLink Kerala empowers healthcare providers to deliver compassionate, efficient, and audited care directly to patients' doorsteps.

---

## 🛠️ 2. Technology Stack Architecture

The system is built on a modern, decoupled, scalable, and secure architecture designed to support high-reliability operations and low-bandwidth rural connectivity.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Cross-Platform Client (Flutter)                      │
│      Android  •  iOS  •  Web  •  Offline-First SQLite Cache            │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │ HTTPS / REST API / JWT
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│               Backend & Application Tier (Django REST Framework)       │
│   • Multi-Tenant Isolation Middleware   • RBAC Security Engine         │
│   • Clinical Triage & AI Services       • Asynchronous Task Workers    │
└───────────────────┬─────────────────────────────────┬──────────────────┘
                    │                                 │
                    ▼                                 ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│ Database Tier (Supabase PostgreSQL)  │  │ Message Broker & Cache       │
│ • Row Level Security (RLS) Enabled   │  │ • Redis / Celery             │
│ • Point-in-Time Recovery (WAL)       │  │ • Firebase Cloud Messaging   │
│ • Encrypted Storage & Audit Logs     │  │   (Realtime Push Alerts)     │
└──────────────────────────────────────┘  └──────────────────────────────┘
```

| Layer | Technologies Used | Key Purpose |
| :--- | :--- | :--- |
| **Mobile & Frontend** | **Flutter (Dart 3)**, Google Fonts, FL Charts, QR Flutter, SQLite | High-performance, cross-platform mobile app (Android/iOS/Web) with offline data sync for rural field workers. |
| **Backend & APIs** | **Python 3.11+, Django 5, Django REST Framework (DRF)** | Enterprise REST API backend, multi-tenant architecture, automated JWT authentication, and clinical business logic. |
| **Database & Cloud** | **Supabase Managed PostgreSQL** | Relational data persistence with strict Row Level Security (RLS), ACID compliance, and automated WAL backups. |
| **Async & Notifications** | **Redis, Celery, Firebase Cloud Messaging (FCM)** | Asynchronous background processing for critical alerts, scheduled home visits, and instant push notifications. |
| **DevOps & Deployment**| **Docker, Docker Compose, Gunicorn, NGINX, GitHub Actions** | Containerized micro-deployments, automated CI/CD pipelines, and zero-downtime rollouts. |

---

## 🌟 3. Core Functions & Features Provided

CareLink Kerala delivers **12 modular functional subsystems**:

### 1. 🩺 Patient & Palliative Care Management (EMR)
* **Comprehensive Patient Profiles:** Full demographic records, palliative disease categorization (oncology, geriatric, chronic kidney disease, etc.), mobility status, and emergency contacts.
* **Clinical Vitals & Trend Tracking:** Real-time logging of SpO₂, Blood Pressure, Blood Glucose, Pulse, Temperature, and Pain Scale ratings with dynamic trend graphs (`fl_chart`).
* **Individualized Care Plans & Care Goals:** Multi-disciplinary care goal setting and customized palliative treatment protocols.
* **Medication Administration Records (MAR):** Daily dosage tracking, schedules, and caregiver medication verification.
* **Medical Equipment Loaning:** Tracking of issued high-value palliative equipment (oxygen concentrators, suction machines, hospital beds, wheelchairs) with return dates and maintenance tracking.
* **Caregiver Delegation:** Secure read/write access delegation for primary family caregivers.

### 2. 🚐 Palliative Home Visit & Field Operations
* **Home Visit Scheduling:** Direct scheduling and priority dispatch for nurses and community palliative teams.
* **Route & Multi-Stop Optimization:** Geolocation-assisted route planning to minimize travel time between patient homes in rural wards.
* **Field Check-In / Check-Out:** Time-stamped visit confirmation, geo-tagged clinical observations, and follow-up reminders.

### 3. 🏥 Doctor Network & OPD Queue Management
* **Doctor & Specialist Registry:** Directory of general physicians, oncologists, pain management specialists, and palliative consultants.
* **Digital OPD Queue & Token System:** Live token generation, wait-time estimation, patient check-in workflows, and queue pause/resume controls.
* **Tele-Consultation & Appointment Requests:** Patient booking workflows with confirmation, rescheduling, and doctor availability calendars.

### 4. 🚨 Emergency SOS & Ambulance Fleet Dispatch
* **1-Tap Distress Button:** Instant emergency broadcasting sending patient medical background and live GPS coordinates.
* **Ambulance Fleet Management:** Real-time driver dispatching, status tracking (Available, En Route, On-Scene, Hospital Inbound), and hospital hand-off protocols.

### 5. 🩸 Emergency Blood Donor Directory
* **Geo-Localized Donor Directory:** Filter donors instantly by Blood Group (`A+`, `B+`, `O+`, `AB+`, `O-`, Bombay blood group, etc.) and Panchayat/District.
* **Urgent Blood Broadcasts:** Automated broadcast alerts for emergency hospital transfusions and surgical needs.
* **Donation History & Eligibility Checker:** Tracking last donation dates to ensure donor safety (90-day intervals).

### 6. 💊 Pharmacy & Medical Inventory Control
* **Palliative Drug & Consumables Tracking:** Real-time inventory of analgesics, morphine/palliative drugs, dressings, catheter sets, and nutritional feeds.
* **Batch & Expiry Management:** Automated alerts for approaching expiry dates and critical low-stock thresholds.
* **Transparent Dispensing Audit:** Log of every medicine transaction linked to specific patient prescriptions.

### 7. 🤝 Volunteer Coordination & Community Network
* **Volunteer Onboarding & Skill Mapping:** Tagging volunteers by availability and skills (transport assistance, elderly companionship, nursing aid, event support).
* **Community Task Allocation:** Assigning volunteers to support patient families with errands, grocery deliveries, or respite care.

### 8. 💝 Medical Crowdfunding & Transparent Donations
* **Verified Patient Fundraisers:** Need-based medical fundraising for treatments, procedures, and daily palliative supplies.
* **Transparent Donation Ledger:** Direct donation tracking, public campaign progress bars, and financial transparency receipts.

### 9. 🤖 AI Clinical Triage & Assistant
* **Intelligent Clinical Risk Assessment:** AI-driven triage scoring based on vital anomalies (e.g., sudden drop in SpO₂ or hypertensive crises).
* **Care Protocol Recommendations:** Automated symptom management suggestions based on standard palliative care protocols.

### 10. 🔒 Multi-Tenant Enterprise Isolation & Security
* **Multi-Tenant Architecture:** Independent data partitions for different palliative NGOs, government clinics, and private hospitals within a single unified platform.
* **Role-Based Access Control (RBAC):** Dedicated views and permissions for **SuperAdmin, Organization Admin, Doctor, Nurse, Field Coordinator, Volunteer, Donor, and Patient/Caregiver**.
* **Supabase Row-Level Security (RLS):** Military-grade database security ensuring no unauthorized data access across the network.
* **Immutable Audit Trail:** Complete audit logging (`PatientAuditLog`, `DomainEventLog`) for regulatory compliance.

---

## 🎯 4. Value Proposition for Supporters & Stakeholders

| Stakeholder | Key Benefits Delivered |
| :--- | :--- |
| **Patients & Families** | Immediate access to home palliative visits, free equipment loans, emergency SOS, and dignified home care. |
| **Palliative Nurses & Doctors** | Drastically reduced paperwork, digital vitals charting, smart route planning, and real-time alerts for critical patient degradation. |
| **NGOs & Clinics** | Full operational visibility, automated donor & inventory tracking, verified compliance reports, and multi-tenant scalability. |
| **Government & Health Depts.** | Unified health data telemetry, regional palliative coverage insights, and disaster response readiness. |
| **Donors & Philanthropists** | 100% transparency on donation utilization, verified patient campaigns, and direct impact tracking. |

---

## 🚀 5. Future Roadmap & Growth Milestones

1. **Govt. Health Grid (e-Health Kerala / ABDM) Integration:** Direct interoperability with Ayushman Bharat Digital Mission (ABDM) ABHA health IDs.
2. **Offline-Mesh Field Sync:** Bluetooth/Wi-Fi direct peer-to-peer sync between nurses and ambulances in zero-network hill/forest regions.
3. **Automated Multilingual Voice Assistant (Malayalam / English):** Voice-guided symptom logging for elderly patients and palliative nurses.
