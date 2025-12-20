# Implementation Plan - Real-Time Synchronization Refactor

## Goal
Enable "instant" real-time updates across all Application features (Patients, Appointments, Inventory, Finance) so that when one user (Dentist or Staff) makes a change, the other user's UI updates immediately without manual refreshing.

## Architecture Change: Reactive Data Streams
The current application uses a **Pull-based** architecture (fetch once). We will shift to a **Push-based** architecture using Dart `Streams` and Riverpod `ref.listen`.

### Core Concept
1.  **The Source**: Each Service (`PatientService`, `AppointmentService`, etc.) will expose a `Stream<void> onDataChanged`.
2.  **The Trigger**: Every write operation (Create, Update, Delete) – whether triggered by the local User or the background `SyncManager` – will emit an event to this stream.
3.  **The Listener**: The Riverpod Providers (which power the UI) will subscribe to this stream. When an event occurs, they will automatically re-fetch the latest data from the Database.

## Proposed Changes

### 1. Patient Module
**File:** `lib/src/features/patients/application/patient_service.dart`
*   **Change:** Add `_dataChangeController` (Broadcast Stream).
*   **Trigger:** Call `_dataChangeController.add(null)` inside `addPatient`, `updatePatient`, `deletePatient`.
*   **Providers:** Update `patientsProvider` and `patientProvider` to listen to this stream and `ref.invalidateSelf()`.

### 2. Appointments Module
**File:** `lib/src/features/appointments/application/appointment_service.dart`
*   **Change:** Add `_dataChangeController`.
*   **Trigger:** Emit events on all appointment modifications.
*   **Providers:** Update `appointmentsProvider`, `upcomingAppointmentsProvider`, `todaysAppointmentsProvider`, etc.
*   **Impact:** This fixes the **Dashboard** counters which rely on these providers.

### 3. Inventory Module
**File:** `lib/src/features/inventory/application/inventory_service.dart`
*   **Change:** Add `_dataChangeController`.
*   **Trigger:** Emit events on `add`, `update`, `delete` (including usage).
*   **Providers:** Update `inventoryItemsProvider`.
*   **Impact:** Ensures "Low Stock" and "Expired" alerts on the Dashboard update instantly.

### 4. Finance Module
**File:** `lib/src/features/finance/application/finance_service.dart`
*   **Refactor:** Currently, this service manually calls `ref.invalidate(...)` on specific providers. This is "High Coupling".
*   **Change:** Replace manual invalidation with the standard `_dataChangeController` stream pattern used in other services.
*   **Providers:** Update `filteredTransactionsProvider`, `actualTransactionsProvider`, and summary providers to watch the stream.

## Verification Plan

### Manual Verification Steps
1.  **Setup**: Run the app on two "devices" (or one Window and one Emulator/different Window).
2.  **Test Case 1 (Patients)**:
    *   Device A (Dentist): Open "Patients" tab.
    *   Device B (Staff): Add a new Patient.
    *   **Expectation**: Device A's list updates *instantly* to show the new patient.
3.  **Test Case 2 (Dashboard)**:
    *   Device A: Open Dashboard. Note "Today's Patients" count.
    *   Device B: Add a patient.
    *   **Expectation**: Device A's counter increments immediately.
4.  **Test Case 3 (Appointments)**:
    *   Device A: Create an appointment.
    *   Device B: See appointment in list. Mark it as "Completed".
    *   **Expectation**: Device A's appointment card status changes to "Completed" (Green) instantly.

### Automated Tests (If applicable)
*   Unit tests can be added to verify that the `Stream` emits events when methods are called.

## Risks & Mitigations
*   **Risk**: Infinite Loops (Provider A updates Service, Service notifies Provider A...).
    *   **Mitigation**: Riverpod's `ref.listen` is passive; it just triggers a refresh. We will ensure we don't trigger write operations inside the read providers.
*   **Risk**: Performance. Frequent updates might cause too many database reads.
    *   **Mitigation**: The local SQLite database is very fast. For this scale (Dental Clinic), re-reading the list on every change is negligible. If needed, we can add `debounce` to the listeners.
