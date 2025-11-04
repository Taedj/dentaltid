# 🦷 Product Requirements Document (PRD)  
## Dentist Management System (DMS) — Desktop & Mobile (Flutter Hybrid App)

---

### 🧭 1. Overview

The **Dentist Management System (DMS)** is a hybrid Flutter-based application designed for **dentists and clinic assistants** to manage patients, appointments, emergencies, inventory, and finances.  
The system operates **locally and offline**, while providing a **cloud synchronization option** using **Firebase**.  
All local data is stored securely, and users can **generate and load ZIP backups** for manual or automatic sync to Firebase.

---

### 🎯 2. Goals and Objectives

- Provide a **hybrid, reliable, and secure** dental management app.  
- Allow **offline operation** with **optional online synchronization**.  
- Enable easy **data backup and restore** using ZIP files.  
- Deliver a **modern dark-themed user interface** optimized for both desktop and mobile.  
- Simplify clinic operations: appointments, patient flow, emergency alerts, and finances.

---

### 👥 3. Target Users

| User Type | Role | Access Level |
|------------|------|--------------|
| **Dentist** | Full access | Manage all modules and synchronize data |
| **Assistant** | Partial access | Manage patients and appointments |
| **Receptionist** | Limited access | Schedule appointments and record payments |
| **Admin (optional)** | Superuser | Manage user permissions and perform backups/restores |

---

### 🎨 4. Design & UX Guidelines

- **Theme:** Default dark mode with light mode toggle.  
- **Layout:**  
  - Left **tree navigation panel**.  
  - Main area: dashboard and data panels.  
  - Bottom bar: system status and patient counters.  
- **Interactive Design:**  
  Hover effects reveal quick info (e.g., waiting list, emergency case details).  
- **Responsiveness:**  
  Layout adjusts seamlessly from desktop (multi-pane) to mobile (single-pane).

---

### 🗂️ 5. Core Modules & Features

#### **5.1 Dashboard**
- Displays:
  - Daily summary of patients and appointments.  
  - Bottom bar → “Remaining Patients Count” with hover list preview.  
  - Dashboard shortcut for quick access to upcoming appointments and emergencies.  
- Friendly visual drawing or dental-themed animation for UI warmth.

---

#### **5.2 Emergency Notification System**
- Flag patients as **emergency cases**.  
- Automatically prioritized at the top of the waiting list.  
- Hovering or tapping shows:
  - Health state (e.g., pressure, diabetes, allergy alerts).  
  - Case details and severity indicator.  
- Red icon or animated signal for active emergencies.

---

#### **5.3 Appointment Management**
- Create, edit, or delete appointments.  
- Required fields: **Patient**, **Date**, and **Time**.  
- Shortcuts on dashboard for next appointments.  
- Appointment notifications and reminders (optional Firebase Cloud Messaging).  
- Filter by patient, date, or urgency.

---

#### **5.4 Patients Panel (Daily View)**
- Displays current-day patients only.  
- Fields include:
  - Name, Family Name, Age, Health State, Diagnosis, Treatment, Payment Status.  
- **Color-coded status:**
  - 🟢 Fully Paid  
  - 🔴 Unpaid (negative balance)  
- **Operations:**
  - Add / Edit / Delete / Reorder patients.  
- **Sorting:**
  - Alphabetical, Payment Status, Appointment Time, or Custom Order.  
- On “Register,” patient info is auto-saved to the database and archived in **Patients Database**.

---

#### **5.5 Patients Database (Archive)**
- Located under **“Patients Database”** in navigation.  
- Stores all historical data.  
- Filter by:
  - Day / Week / Month / All.  
- Search by patient name or diagnosis.  
- Export or print report in CSV, Excel, or PDF formats.

---

#### **5.6 Financial & Evaluation Tab**
- Manages **clinic income and expenses**.  
- Calculates:
  - Total income from treatments.  
  - Material and operational costs.  
  - Balance and profit/loss ratios.  
- Visual charts for daily, weekly, or monthly analytics.  
- Highlight unpaid sessions or overdue payments.

---

#### **5.7 Inventory Management**
- Track dental materials and supplies:
  - Quantity, expiration date, and supplier.  
- Automatic low-stock alerts.  
- Integration with finance tab for cost deduction.  
- Optional export of stock reports.

---

### 💾 6. Storage & Synchronization System

#### **Local Storage**
- All app data stored locally in **SQLite**.  
- Auto-backup option (daily or on-exit).  
- Manual **ZIP backup** generation (compresses SQLite + configs + assets).  
- ZIP backup can be loaded anytime to restore data.

#### **Hybrid Cloud Sync (Firebase Backend)**
- Firebase serves as **backup and synchronization backend**.  
- When sync is enabled:
  1. App generates a ZIP backup.  
  2. Uploads ZIP to Firebase Storage.  
  3. Sync metadata (timestamp, user ID, clinic name) stored in Firebase Firestore.  
- Restore by downloading and loading the ZIP.  
- Sync status shown in dashboard footer (“Last Sync: [Date-Time]”).

---

### ⚙️ 7. Technical Stack

| Layer | Technology |
|--------|-------------|
| **Frontend** | Flutter (Material 3, adaptive layout) |
| **Local Database** | SQLite |
| **Storage Format** | JSON + SQLite compressed in ZIP |
| **Cloud Backend** | Firebase (Storage + Firestore + Auth optional) |
| **State Management** | Riverpod or Bloc |
| **Data Visualization** | Syncfusion or charts_flutter |
| **Security** | AES encryption for ZIP backups |
| **Desktop Platforms** | Windows, macOS, Linux |
| **Mobile Platforms** | Android, iOS |

---

### 🔐 8. Functional Requirements

| Feature | Description |
|----------|--------------|
| CRUD Operations | Manage patients, appointments, and inventory. |
| Emergency Handling | Highlight urgent cases with health risk alerts. |
| Local Backup | Generate and load ZIP backups locally. |
| Firebase Sync | Upload and restore ZIP backups to/from Firebase. |
| Finance Management | Track all income, outcome, and balances. |
| Search & Filters | Filter by name, date, payment, or diagnosis. |
| Reports | Export data (CSV, XLS, PDF). |
| Security | Encrypted ZIP backups + optional Firebase Auth. |

---

### ⚙️ 9. Non-Functional Requirements

- **Performance:** Load dashboard under 2s.  
- **Storage Efficiency:** ZIP backups <10 MB for 10,000 records.  
- **Reliability:** Automatic retry for failed Firebase syncs.  
- **Usability:** Mobile-friendly UI, accessible within 3 clicks to core actions.  
- **Security:** Local encryption and password-protected access.  
- **Cross-Platform Stability:** Unified experience across desktop and mobile.

---

### 🚀 10. Future Enhancements (Phase 3+)

- **Automatic periodic cloud sync** without manual action.  
- **Voice note support** for adding quick diagnoses.  
- **AI analytics** for treatment prediction and patient grouping.  
- **Multi-device synchronization** (dentist + assistant live updates).  
- **Smart notifications** (via Firebase Cloud Messaging).

---

### 📅 11. Development Roadmap

| Phase | Deliverable | Duration |
|--------|--------------|-----------|
| **Phase 1** | UI/UX + Local Database + Dashboard | 4 weeks |
| **Phase 2** | Appointments, Patients, and Finance Modules | 4 weeks |
| **Phase 3** | ZIP Backup System + Firebase Sync | 3 weeks |
| **Phase 4** | Inventory + Analytics + Polish | 3 weeks |
| **Phase 5** | Testing, Debugging, Deployment | 2 weeks |

---

### ✅ 12. Success Metrics

- 100% offline operability.  
- Successful ZIP backup/restore rate ≥ 99%.  
- Firebase sync delay < 10s per upload.  
- Crash-free rate ≥ 98% over 1 month.  
- Dentist satisfaction ≥ 90% after pilot testing.

---

**Author:** Dr. Tidjani Ahmed Zitouni  
**Product:** Dentist Management System (DMS)  
**Platform:** Flutter (Hybrid: Desktop + Mobile)  
**Storage:** Local + Firebase ZIP Sync  
**Version:** Final PRD v2.0 — November 2025  


