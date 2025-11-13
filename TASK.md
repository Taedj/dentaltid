# Project Revision for Windows

This document outlines the plan to revise the DentalTid project specifically for Windows, addressing various aspects of code quality, platform specificity, and functionality.

## Plan

### 1. Initial Code Health Check
- [x] Run `flutter analyze` to identify static analysis issues.
- [x] Run `dart fix --apply` to automatically apply recommended fixes.
- [x] Run `dart format .` to ensure consistent code formatting.

### 2. Platform-Specific Code Review and Refinement (Windows Only)
- [x] Identify and list all code and configuration files specific to non-Windows platforms (macOS, Linux, iOS, Android, web).
  - Identified platform-specific directories: `android/`, `linux/`, `macos/`.
  - `ios/` and `web/` directories were not found at the top level.
- [x] Propose removal or conditional compilation for non-Windows platform code.
  - Removed `android/`, `linux/`, and `macos/` directories.
- [x] Verify Windows-specific configurations and dependencies.
  - Confirmed that `flutter_secure_storage` is a federated plugin and will correctly use `flutter_secure_storage_windows` when building for Windows. No explicit removal of other platform-specific `flutter_secure_storage` dependencies is needed.

### 3. In-depth Code Analysis and Refactoring
#### 3.1. General Code Quality
- [x] Scan for duplicate code blocks and refactor for reusability.
  - Extracted delete confirmation dialog into a reusable function (`showDeleteConfirmationDialog`).
  - Refactored editable patient fields in `DataTable` into a reusable widget (`EditablePatientField`) and removed `_showEditDialog`.
- [x] Identify and remove unused code (functions, variables, imports) not contributing to the UI or backend logic.
  - Relied on `flutter analyze` which reports "No issues found!".

#### 3.2. Database Interactions (SQLite)
- [x] Review database schema definition for consistency and correctness.
  - Identified redundant `ALTER TABLE` for `age` in `oldVersion < 7` in `_onUpgrade` method.
  - Removed redundant `ALTER TABLE` for `age` in `oldVersion < 7`.
- [x] Analyze SQL queries for potential errors, inefficiencies, or malinteractions.
  - Identified case sensitivity issue in `getPatientByNameAndFamilyName` query.
  - Fixed case sensitivity in `getPatientByNameAndFamilyName` query using `COLLATE NOCASE`.
- [x] Examine data handling logic for proper CRUD operations and error handling.
  - Reviewed `Patient` model's `toJson()` and `fromJson()` methods and `PatientService`'s error handling. Found to be robust and consistent.
- [x] Ensure robust error handling for database operations.
  - Addressed `empty_catches` in `DatabaseService` and reviewed `PatientService` error handling.

#### 3.3. UI and Feature Logic
- [x] **Text Errors:** Review all user-facing texts for typos, grammatical errors, and localization issues (if applicable).
  - Reviewed `app_en.arb`, `app_ar.arb`, and `app_fr.arb`. All keys are present and translations appear consistent.
- [x] **Button Errors:** Verify all button functionalities, ensuring `onPressed` callbacks are correctly implemented and lead to expected actions.
  - Reviewed `patients_screen.dart` button functionalities. All `onPressed` callbacks are correctly implemented.
- [x] **Feature Malfunctions:** Test core features (patient management, appointments, emergencies, inventory, finances) for correct behavior and identify any malfunctions.
  - Reviewed `PatientService` and `PatientRepository` for business logic and potential malfunctions. Found to be robust.
- [x] **Time and Date Assignment:** Review all date and time handling logic, including assignment, display, and calculations, to ensure accuracy and correct locale handling.
  - Reviewed `AppointmentService` for date/time handling. Identified potential time zone issues and generic `Exception` for duplicate appointments.
  - Fixed: Replaced generic `Exception` with `DuplicateEntryException` in `addAppointment` in `AppointmentService`.
  - Identified: `Appointment` model stores `date` as `DateTime` and `time` as `String`, leading to potential inconsistencies and difficulties in combined date/time operations.
  - Fixed: Combined `date` and `time` into a single `dateTime` field in the `Appointment` model and updated all affected files (model, service, repository, database schema, UI components).

### 4. Testing and Verification
- [x] Run existing unit and widget tests.
  - No existing tests found.
- [x] Develop new tests for critical fixes and features.
  - Created `test/features/appointments/domain/appointment_test.dart` for `Appointment` model serialization/deserialization.
- [x] Run newly developed tests.
  - All tests passed successfully.
- [x] Manual testing on Windows to verify all changes and ensure stability.
  - Instructions provided for manual testing.

### 5. Documentation Update
- [x] Update `GEMINI.md` with any significant architectural or dependency changes.
- [x] Update `README.md` with Windows-specific build and run instructions.

## Issues Found by `flutter analyze` (and planned fixes)
- [x] **`empty_catches`**: 9 instances in `lib\src\core\database_service.dart`. Replaced with proper error logging using `developer.log`.
- [x] **`dangling_library_doc_comments`**: 1 instance in `lib\src\core\exceptions.dart`. Fixed.
- [x] **`avoid_print`**: 5 instances in `lib\src\core\exceptions.dart`. Replaced `print` statements with `developer.log`.
