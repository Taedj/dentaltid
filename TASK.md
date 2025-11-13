# DentalTid Implementation Tasks

This document outlines the detailed implementation tasks for the DentalTid project, derived from `PLAN.md`. Each task is presented as a checklist item for tracking progress.

## 1. Immediate Fix: GoRouter Configuration
- [x] Resolve `GoException` by updating `lib/src/core/router.dart` to correctly extract `patientId` from path parameters for `/patients/:patientId/visits/add` and `/patients/:patientId/visits/edit` routes.

## 2. Data Model Enhancements
### Patient Model
- [x] Add `bool isBlacklisted` to `Patient` model.

### Visit Model
- [x] Add `int visitNumber` to `Visit` model.
- [x] Add `bool isEmergency` to `Visit` model.
- [x] Add `EmergencySeverity emergencySeverity` to `Visit` model.
- [x] Add `String healthAlerts` to `Visit` model.

### Session Model (New)
- [x] Create `lib/src/features/sessions/domain/session.dart` with fields: `id`, `visitId`, `sessionNumber`, `dateTime`, `notes`, `treatmentDetails`, `totalAmount`, `paidAmount`, `SessionStatus status`.

### Appointment Model
- [x] Modify `Appointment` model to replace `patientId` with `sessionId`.

### Transaction Model
- [x] Modify `Transaction` model to replace `patientId` with `sessionId`.

## 3. Database Schema Changes
- [x] Increment `_databaseVersion` in `lib/src/core/database_service.dart`.
- [x] Add new table `sessions` in `_onCreate` and `_onUpgrade` methods.
- [x] Modify `visits` table in `_onUpgrade` to add `visitNumber`, `isEmergency`, `emergencySeverity`, `healthAlerts` columns.
- [x] Modify `patients` table in `_onUpgrade` to add `isBlacklisted` column.
- [x] Modify `appointments` table in `_onUpgrade` to drop `patientId` and add `sessionId` column.
- [x] Modify `transactions` table in `_onUpgrade` to drop `patientId` and add `sessionId` column.

## 4. Service Layer Modifications
- [x] Create `SessionRepository` (`lib/src/features/sessions/data/session_repository.dart`).
- [x] Create `SessionService` (`lib/src/features/sessions/application/session_service.dart`).
- [x] Update `VisitService` to include methods for `visitNumber`, `isEmergency`, `emergencySeverity`, `healthAlerts`.
- [x] Update `AppointmentService` to adapt methods to use `sessionId`.
- [x] Update `FinanceService` to adapt methods to use `sessionId`.
- [x] Update `PatientService` to add method for `isBlacklisted` status.

## 5. UI/UX Workflow Implementation
### Critical Fixes (Completed)
- [x] Fixed compilation errors in UI components to work with sessionId changes
- [x] Updated test files for new model structures
- [x] Added temporary backward compatibility for existing UI

### A. Appointment Creation/Editing Flow (`AddEditAppointmentScreen`)
- [x] Implement Patient Selection:
    - [x] Display searchable list of patients.
    - [x] Allow selection from "current day's patients" list.
    - [x] Allow searching by name.
    - [x] Display "Previous Visits" indicator if applicable.
    - [x] Implement "Add New Patient" button and navigation.
- [x] Implement Visit Details:
    - [x] Prompt to "Create New Visit" or "Select Existing Visit".
    - [x] Input fields for `reasonForVisit`, `notes` (for the visit).
    - [x] Implement Emergency Section (checkbox, dropdown for severity, text field for alerts).
- [x] Implement Session Details:
    - [x] Input field for "Number of Sessions".
    - [x] For each session:
        - [x] Auto-increment `sessionNumber`.
        - [x] `dateTime` input.
        - [x] `treatmentDetails` (TextFormField).
        - [x] `notes` (TextFormField, session-specific).
        - [x] Payment Section (total, paid, unpaid, payment method, status).
- [x] Implement Patient Notes & Blacklist:
    - [x] `TextFormField` for general patient notes.
    - [x] `CheckboxListTile` for "Blacklist Patient".

### B. Patient Details Screen (`AddEditPatientScreen`)
- [x] Replace current `_PatientVisitHistory` and `_PatientPaymentHistory` with a unified "Visits and Payments History" section.
- [x] Display list of `Visit` entries:
    - [x] Date of Visit.
    - [x] `visitNumber`.
    - [x] `reasonForVisit`.
    - [x] Summary of associated `Session`s.
    - [x] Total payment for the visit.
- [x] Implement expandable `Visit` entry to show `Session` details:
    - [x] Session Number.
    - [x] Session Date/Time.
    - [x] `treatmentDetails`.
    - [x] `notes`.
    - [x] Payment details (Total, Paid, Unpaid) for that specific session.
- [x] Implement "Add New Visit" and "Edit Visit" buttons.
- [x] Implement "Add New Session" and "Edit Session" buttons within a visit.

## 6. Localization Updates
- [x] Add new keys for `addSession`, `editSession`.
- [x] Add new keys for `sessionNumber`, `treatmentDetails`.
- [x] Add new keys for `isBlacklisted`, `blacklistPatient`.
- [x] Add new key for `previousVisits`.


