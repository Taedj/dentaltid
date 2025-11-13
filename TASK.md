# DentalTid Implementation Tasks

This document outlines the detailed implementation tasks for the DentalTid project, derived from `PLAN.md`. Each task is presented as a checklist item for tracking progress.

## 1. Immediate Fix: GoRouter Configuration
- [x] Resolve `GoException` by updating `lib/src/core/router.dart` to correctly extract `patientId` from path parameters for `/patients/:patientId/visits/add` and `/patients/:patientId/visits/edit` routes.

## 2. Data Model Enhancements
### Patient Model
- [ ] Add `bool isBlacklisted` to `Patient` model.

### Visit Model
- [ ] Add `int visitNumber` to `Visit` model.
- [ ] Add `bool isEmergency` to `Visit` model.
- [ ] Add `EmergencySeverity emergencySeverity` to `Visit` model.
- [ ] Add `String healthAlerts` to `Visit` model.

### Session Model (New)
- [ ] Create `lib/src/features/sessions/domain/session.dart` with fields: `id`, `visitId`, `sessionNumber`, `dateTime`, `notes`, `treatmentDetails`, `totalAmount`, `paidAmount`, `SessionStatus status`.

### Appointment Model
- [ ] Modify `Appointment` model to replace `patientId` with `sessionId`.

### Transaction Model
- [ ] Modify `Transaction` model to replace `patientId` with `sessionId`.

## 3. Database Schema Changes
- [ ] Increment `_databaseVersion` in `lib/src/core/database_service.dart`.
- [ ] Add new table `sessions` in `_onCreate` and `_onUpgrade` methods of `DatabaseService`.
- [ ] Modify `visits` table in `_onUpgrade` to add `visitNumber`, `isEmergency`, `emergencySeverity`, `healthAlerts` columns.
- [ ] Modify `patients` table in `_onUpgrade` to add `isBlacklisted` column.
- [ ] Modify `appointments` table in `_onUpgrade` to drop `patientId` and add `sessionId` column.
- [ ] Modify `transactions` table in `_onUpgrade` to drop `patientId` and add `sessionId` column.

## 4. Service Layer Modifications
- [ ] Create `SessionRepository` (`lib/src/features/sessions/data/session_repository.dart`).
- [ ] Create `SessionService` (`lib/src/features/sessions/application/session_service.dart`).
- [ ] Update `VisitService` to include methods for `visitNumber`, `isEmergency`, `emergencySeverity`, `healthAlerts`.
- [ ] Update `AppointmentService` to adapt methods to use `sessionId`.
- [ ] Update `FinanceService` to adapt methods to use `sessionId`.
- [ ] Update `PatientService` to add method for `isBlacklisted` status.

## 5. UI/UX Workflow Implementation
### A. Appointment Creation/Editing Flow (`AddEditAppointmentScreen`)
- [ ] Implement Patient Selection:
    - [ ] Display searchable list of patients.
    - [ ] Allow selection from "current day's patients" list.
    - [ ] Allow searching by name.
    - [ ] Display "Previous Visits" indicator if applicable.
    - [ ] Implement "Add New Patient" button and navigation.
- [ ] Implement Visit Details:
    - [ ] Prompt to "Create New Visit" or "Select Existing Visit".
    - [ ] Input fields for `reasonForVisit`, `notes` (for the visit).
    - [ ] Implement Emergency Section (checkbox, dropdown for severity, text field for alerts).
- [ ] Implement Session Details:
    - [ ] Input field for "Number of Sessions".
    - [ ] For each session:
        - [ ] Auto-increment `sessionNumber`.
        - [ ] `dateTime` input.
        - [ ] `treatmentDetails` (TextFormField).
        - [ ] `notes` (TextFormField, session-specific).
        - [ ] Payment Section (total, paid, unpaid, payment method, status).
- [ ] Implement Patient Notes & Blacklist:
    - [ ] `TextFormField` for general patient notes.
    - [ ] `CheckboxListTile` for "Blacklist Patient".

### B. Patient Details Screen (`AddEditPatientScreen`)
- [ ] Replace current `_PatientVisitHistory` and `_PatientPaymentHistory` with a unified "Visits and Payments History" section.
- [ ] Display list of `Visit` entries:
    - [ ] Date of Visit.
    - [ ] `visitNumber`.
    - [ ] `reasonForVisit`.
    - [ ] Summary of associated `Session`s.
    - [ ] Total payment for the visit.
- [ ] Implement expandable `Visit` entry to show `Session` details:
    - [ ] Session Number.
    - [ ] Session Date/Time.
    - [ ] `treatmentDetails`.
    - [ ] `notes`.
    - [ ] Payment details (Total, Paid, Unpaid) for that specific session.
- [ ] Implement "Add New Visit" and "Edit Visit" buttons.
- [ ] Implement "Add New Session" and "Edit Session" buttons within a visit.

## 6. Localization Updates
- [ ] Add new keys for `addSession`, `editSession`.
- [ ] Add new keys for `sessionNumber`, `treatmentDetails`.
- [ ] Add new keys for `isBlacklisted`, `blacklistPatient`.
- [ ] Add new key for `previousVisits`.

## 7. Testing Strategy
- [ ] Write Unit Tests for new `Session` model, `SessionRepository`, `SessionService`.
- [ ] Write Integration Tests for the entire appointment creation/editing flow.
- [ ] Write UI Tests for the new UI elements and navigation flows.
- [ ] Perform Manual Testing of all new features and modified workflows.
