# Gemini Project: DentalTid

This file provides context for Gemini to understand and assist with the DentalTid project.

## Project Overview

The **Dentist Management System (DMS)** is a hybrid Flutter-based application designed for **dentists and clinic assistants** to manage patients, appointments, emergencies, inventory, and finances.
The system operates **locally and offline**, while providing a **cloud synchronization option** using **Firebase**.
All local data is stored securely, and users can **generate and load ZIP backups** for manual or automatic sync to Firebase.

The initial focus of the development is on the **desktop version** of the application.

## Technical Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Material 3, adaptive layout) |
| **Local Database** | SQLite |
| **Storage Format** | JSON + SQLite compressed in ZIP |
| **Cloud Backend** | Firebase (Storage + Firestore + Auth optional) |
| **State Management** | Riverpod or Bloc |
| **Data Visualization** | Syncfusion or charts_flutter |
| **Security** | AES encryption for ZIP backups |
| **Desktop Platforms** | Windows, macOS, Linux |
| **Mobile Platforms** | Android, iOS |

## Building and Running

*   **Run the app:** `cd dentaltid && flutter run`
*   **Run tests:** `cd dentaltid && flutter test`

## Development Roadmap

| Phase | Deliverable | Duration |
|---|---|---|
| **Phase 1** | UI/UX + Local Database + Dashboard | 4 weeks |
| **Phase 2** | Appointments, Patients, and Finance Modules | 4 weeks |
| **Phase 3** | ZIP Backup System + Firebase Sync | 3 weeks |
| **Phase 4** | Inventory + Analytics + Polish | 3 weeks |
| **Phase 5** | Testing, Debugging, Deployment | 2 weeks |