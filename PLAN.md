# DentalTid Development Plan

## 1. Problem Statement

The current DentalTid application lacks comprehensive features for managing patient visits, sessions, and detailed historical data. Specifically, the user requires:
- A robust system to track multiple visits and sessions for each patient.
- The ability to link payments directly to specific sessions or visits.
- Comprehensive note-taking capabilities per visit and session.
- Enhanced workflow for appointment creation, including patient selection (existing/new), visit/session details, emergency handling, and integrated payment processing.
- Improved visualization of patient history, including visit numbers, session counts, and payment details, on the patient's profile screen.
- A mechanism to blacklist patients.

## 2. Immediate Fix: GoRouter Configuration

**Issue:** `GoException: no routes for location: /patients/1/visits/add`
**Resolution:** The `GoRouter` configuration in `lib/src/core/router.dart` was updated to correctly extract `patientId` from path parameters for `/patients/:patientId/visits/add` and `/patients/:patientId/visits/edit` routes.

## 3. Proposed Data Model Enhancements

To support the new requirements, the following data models will be introduced or modified:

### `Patient` Model (lib/src/features/patients/domain/patient.dart)
- **Add:** `bool isBlacklisted` (default `false`)

### `Visit` Model (lib/src/features/visits/domain/visit.dart)
- **Existing Fields:** `id`, `patientId`, `dateTime`, `reasonForVisit`, `notes`, `diagnosis`, `treatment`
- **Add:**
    - `int visitNumber` (sequential for patient, e.g., 1st visit, 2nd visit)
    - `bool isEmergency`
    - `EmergencySeverity emergencySeverity`
    - `String healthAlerts` (specific to this visit)

### `Session` Model (New: lib/src/features/sessions/domain/session.dart)
- **Fields:**
    - `int? id`
    - `int visitId` (Foreign key to `Visit`)
    - `int sessionNumber` (sequential within a visit, e.g., session 1 of 3)
    - `DateTime dateTime` (start time of the session)
    - `String? notes` (session-specific notes)
    - `String? treatmentDetails` (details of treatment performed in this session)
    - `double totalAmount` (cost for this session)
    - `double paidAmount` (amount paid for this session)
    - `SessionStatus status` (e.g., `scheduled`, `completed`, `cancelled`)

### `Appointment` Model (lib/src/features/appointments/domain/appointment.dart)
- **Modify:**
    - Replace `patientId` with `sessionId` (Foreign key to `Session`).
    - Keep `dateTime` and `status`.
    - *Note:* `patientId` can be derived from `Session` -> `Visit` -> `Patient`.

### `Transaction` Model (lib/src/features/finance/domain/transaction.dart)
- **Modify:**
    - Replace `patientId` with `sessionId` (Foreign key to `Session`).
    - Keep `description`, `totalAmount`, `paidAmount`, `type`, `date`, `status`, `paymentMethod`.

## 4. Database Schema Changes

- **Increment `_databaseVersion`** in `lib/src/core/database_service.dart`.
- **New Table: `sessions`**
    ```sql
    CREATE TABLE sessions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      visitId INTEGER,
      sessionNumber INTEGER,
      dateTime TEXT,
      notes TEXT,
      treatmentDetails TEXT,
      totalAmount REAL,
      paidAmount REAL,
      status TEXT
    )
    ```
- **Modify `visits` table:**
    - Add `visitNumber INTEGER`
    - Add `isEmergency INTEGER`
    - Add `emergencySeverity TEXT`
    - Add `healthAlerts TEXT`
- **Modify `patients` table:**
    - Add `isBlacklisted INTEGER`
- **Modify `appointments` table:**
    - Drop `patientId` column.
    - Add `sessionId INTEGER` column.
- **Modify `transactions` table:**
    - Drop `patientId` column.
    - Add `sessionId INTEGER` column.

## 5. Service Layer Modifications

- **New `SessionRepository` and `SessionService`**: Similar to `Visit` for managing sessions.
- **Update `VisitService`**:
    - Methods to calculate `visitNumber` for a patient.
    - Methods to manage `isEmergency`, `emergencySeverity`, `healthAlerts`.
- **Update `AppointmentService`**:
    - Adapt methods to use `sessionId` instead of `patientId`.
- **Update `FinanceService`**:
    - Adapt methods to use `sessionId` instead of `patientId`.
- **Update `PatientService`**:
    - Add method to update `isBlacklisted` status.

## 6. UI/UX Workflow

### A. Appointment Creation/Editing Flow (from `AddEditAppointmentScreen`)

1.  **Patient Selection:**
    - **Existing Patient:**
        - Display a searchable list of patients.
        - Allow selection from "current day's patients" list.
        - Allow searching by name to retrieve patients from the database.
        - If patient has previous visits, display a "Previous Visits" indicator.
    - **New Patient:**
        - "Add New Patient" button.
        - On click, navigate to `AddEditPatientScreen` (modal or new route).
        - After adding, return to `AddEditAppointmentScreen` with the new patient selected.

2.  **Visit Details:**
    - After patient selection, prompt to either:
        - **Create New Visit:** Automatically assign next `visitNumber`.
        - **Select Existing Visit:** If patient has open visits, allow selection.
    - Input fields for `reasonForVisit`, `notes` (for the visit).
    - **Emergency Section:**
        - Checkbox: "Is Emergency?"
        - If checked, display `DropdownButtonFormField` for `EmergencySeverity` and `TextFormField` for `healthAlerts`.

3.  **Session Details:**
    - Input field for "Number of Sessions" (default to 1).
    - For each session:
        - `sessionNumber` (auto-incremented).
        - `dateTime` (default to appointment date/time, allow modification).
        - `treatmentDetails` (TextFormField).
        - `notes` (TextFormField, session-specific).
        - **Payment Section (per session):**
            - `totalAmount` (TextFormField).
            - `paidAmount` (TextFormField).
            - `unpaidAmount` (Calculated: `totalAmount - paidAmount`, read-only).
            - `paymentMethod` (Dropdown).
            - `status` (Dropdown: `paid`, `unpaid`).

4.  **Patient Notes & Blacklist:**
    - `TextFormField` for general patient notes (updates `Patient.notes` field).
    - `CheckboxListTile` for "Blacklist Patient" (updates `Patient.isBlacklisted`).

### B. Patient Details Screen (`AddEditPatientScreen`)

1.  **"Visits and Payments History" Section:**
    - Replace current `_PatientVisitHistory` and `_PatientPaymentHistory` with a unified view.
    - Display a list of `Visit` entries, ordered by `dateTime` (newest first).
    - Each `Visit` entry will show:
        - Date of Visit.
        - `visitNumber`.
        - `reasonForVisit`.
        - Summary of associated `Session`s (e.g., "3 sessions, 2 completed").
        - Total payment for the visit (sum of all session payments).
    - Expandable `Visit` entry to show details of each `Session`:
        - Session Number.
        - Session Date/Time.
        - `treatmentDetails`.
        - `notes`.
        - Payment details (Total, Paid, Unpaid) for that specific session.
    - Buttons to "Add New Visit" and "Edit Visit" (navigates to `AddEditVisitScreen`).
    - Buttons to "Add New Session" and "Edit Session" within a visit.

## 7. Localization Updates

New keys will be required for:
- `addSession`, `editSession`
- `sessionNumber`, `treatmentDetails`
- `isBlacklisted`, `blacklistPatient`
- `previousVisits`
- `enterReasonForVisit` (already added)
- `notes` (already added)
- `addVisit`, `editVisit` (already added)

## 8. Testing Strategy

- **Unit Tests:** For new `Session` model, `SessionRepository`, `SessionService`.
- **Integration Tests:** For the entire appointment creation/editing flow, ensuring data consistency across `Patient`, `Visit`, `Session`, `Appointment`, and `Transaction` models.
- **UI Tests:** For the new UI elements and navigation flows.
- **Manual Testing:** Thorough end-to-end testing of all new features and modified workflows.

## 9. Implementation Order (High-Level)

1.  Fix `GoException` (Done).
2.  Create `Session` model, repository, and service.
3.  Update `DatabaseService` for `sessions` table and foreign keys.
4.  Modify `Patient` model (`isBlacklisted`).
5.  Modify `Visit` model (add `visitNumber`, `isEmergency`, `emergencySeverity`, `healthAlerts`).
6.  Modify `Appointment` model (link to `sessionId`).
7.  Modify `Transaction` model (link to `sessionId`).
8.  Update `AddEditAppointmentScreen` for the new workflow.
9.  Update `AddEditPatientScreen` for the unified "Visits and Payments History" display.
10. Update localization files.
11. Implement UI for blacklist and patient notes.
