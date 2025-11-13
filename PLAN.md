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

## 10. Modifications to the 'Patients' Tab for New Appointment Workflow

The 'Patients' tab (`PatientsScreen`) and the 'Add/Edit Patient' screen (`AddEditPatientScreen`) will need significant updates to integrate seamlessly with the new visit and session management.

### A. `PatientsScreen` Enhancements

1.  **"Add Appointment" Button:**
    - A prominent button to initiate the new appointment creation flow. This button will navigate to the `AddEditAppointmentScreen` (or a dedicated "New Appointment Wizard").
2.  **Patient List Interaction:**
    - When a patient is selected from the list, an option to "Schedule New Appointment" or "View Patient History" should be available.
    - "Schedule New Appointment" will pre-select the patient in the `AddEditAppointmentScreen`.
3.  **Search Functionality:**
    - Ensure the existing patient search can quickly retrieve patients for appointment scheduling.
4.  **Blacklisted Patient Indicator:**
    - Visually indicate if a patient is blacklisted directly in the patient list.

### B. `AddEditPatientScreen` Enhancements (Beyond Visit History)

1.  **Patient Notes Section:**
    - A dedicated `TextFormField` for general patient notes (updates `Patient.notes`). This should be easily accessible and editable.
2.  **Blacklist Management:**
    - A `CheckboxListTile` or toggle switch to mark a patient as "Blacklisted" (updates `Patient.isBlacklisted`). This should have a clear warning/confirmation for activation.
3.  **Unified History View:**
    - The "Visits and Payments History" section (as described in 6.B) will be the central hub for all historical data.
    - Ensure easy navigation from this section to add new appointments/visits/sessions or edit existing ones.
4.  **"Schedule New Appointment" Button:**
    - A button within the `AddEditPatientScreen` to directly initiate a new appointment for the current patient, pre-filling their details.

## 11. Example Simulation: Client Interaction Workflow

This simulation outlines how a dentist or assistant would interact with the system for a new or returning patient.

**Scenario: New Patient - First Visit & Appointment**

1.  **Receptionist/Assistant:** A new patient calls to schedule an appointment.
2.  **System Action:** Receptionist navigates to the "Appointments" tab, clicks "Add Appointment".
3.  **System Prompt:** "Select Patient".
4.  **Receptionist Action:** Since it's a new patient, clicks "Add New Patient" button.
5.  **System Action:** `AddEditPatientScreen` opens.
6.  **Receptionist Action:** Fills in patient details (Name, Family Name, Age, Phone Number, etc.). Saves the new patient.
7.  **System Action:** Returns to `AddEditAppointmentScreen` with the new patient pre-selected.
8.  **Receptionist Action:**
    - Enters "Reason for Visit" (e.g., "Initial check-up and cleaning").
    - Marks "Is Emergency?" if applicable.
    - Sets "Number of Sessions" to 1 (for the initial appointment).
    - Enters "Treatment Details" for Session 1 (e.g., "Dental Exam, X-rays, Cleaning").
    - Enters "Total Amount" for Session 1, records "Paid Amount" if any upfront payment is made.
    - Adds general "Notes" about the patient's initial concerns.
    - Schedules the appointment date/time.
9.  **System Action:** Saves the new Visit, Session, and Appointment. The patient's profile now shows their first visit.

**Scenario: Returning Patient - Follow-up Visit with Multiple Sessions**

1.  **Dentist/Assistant:** A patient (e.g., John Doe) needs a root canal, which requires multiple sessions.
2.  **System Action:** Dentist/Assistant navigates to the "Patients" tab, searches for "John Doe", and selects his profile.
3.  **System Action:** On `AddEditPatientScreen`, under "Visits and Payments History", they see John's previous visits.
4.  **Dentist/Assistant Action:** Clicks "Schedule New Appointment" for John Doe.
5.  **System Prompt:** "Create New Visit" or "Select Existing Visit".
6.  **Dentist/Assistant Action:** Clicks "Create New Visit".
7.  **System Action:** Automatically assigns `visitNumber` (e.g., Visit #3).
8.  **Dentist/Assistant Action:**
    - Enters "Reason for Visit" (e.g., "Root Canal Treatment").
    - Sets "Number of Sessions" to 3.
    - **For Session 1:**
        - Sets `dateTime`.
        - Enters "Treatment Details" (e.g., "Pulp removal, temporary filling").
        - Enters "Total Amount" and "Paid Amount".
        - Adds session-specific "Notes".
    - **For Session 2 & 3:** (Can be added later or pre-scheduled)
        - Schedules future `dateTime`s.
        - Leaves "Treatment Details" and "Notes" blank for now.
9.  **System Action:** Saves the new Visit and its associated Sessions and Appointments. The patient's history is updated.

**Scenario: Patient Payment for a Session**

1.  **Receptionist/Assistant:** A patient (e.g., Jane Smith) comes to pay for a completed session.
2.  **System Action:** Receptionist navigates to "Patients", selects "Jane Smith".
3.  **System Action:** On `AddEditPatientScreen`, under "Visits and Payments History", they find the relevant visit and session.
4.  **Receptionist Action:** Clicks "Edit" on the specific session.
5.  **System Action:** `AddEditSessionScreen` (or similar) opens.
6.  **Receptionist Action:** Updates "Paid Amount" for that session. The "Unpaid Amount" automatically adjusts.
7.  **System Action:** Saves the session. The payment is recorded and linked to that specific session.

This detailed plan will guide the implementation of the new features.
