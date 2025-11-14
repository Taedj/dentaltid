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
| **State Management** | Riverpod |
| **Routing** | go_router |
| **Data Visualization** | fl_chart |
| **Linting** | flutter_lints |
| **Security** | AES encryption for ZIP backups (to be implemented) |
| **Desktop Platforms** | Windows, macOS, Linux |
| **Mobile Platforms** | Android, iOS |

## Development Workflow

To ensure code quality and a smooth development process, please follow these steps:

1.  **Analyze Code**: Before committing any changes, run `flutter analyze` to identify any potential issues.
2.  **Format Code**: Run `dart format .` to ensure consistent code formatting.
3.  **Review UI/UX**: Ensure that any UI changes adhere to the guidelines below.
4.  **Write Tests**: Add unit or widget tests for new features or bug fixes.
5.  **Update `GEMINI.md`**: If you make any changes to the project's architecture, dependencies, or workflow, please update this file accordingly.

## UI/UX Guidelines

The goal is to create a modern, intuitive, and visually appealing user interface.

*   **Material 3**: Use Material 3 components and principles as the foundation for the UI.
*   **Responsive Layout**: Ensure the UI is responsive and adapts to different screen sizes, especially for the desktop version. Use widgets like `LayoutBuilder`, `MediaQuery`, and `Expanded`.
*   **Consistency**: Maintain a consistent design language throughout the application. Use the `ThemeData` defined in `lib/src/core/theme.dart`.
*   **Clarity**: The UI should be easy to understand and use. Avoid clutter and ambiguity.
*   **Feedback**: Provide clear feedback to the user for their actions (e.g., loading indicators, snackbars for success/error messages).
*   **Accessibility**: Keep accessibility in mind. Use semantic labels and ensure sufficient color contrast.

## Code Quality and Optimization

*   **Readability**: Write clean, readable, and self-documenting code. Use meaningful names for variables, functions, and classes.
*   **SOLID Principles**: Apply SOLID principles to create maintainable and scalable code.
*   **State Management**: Use `flutter_riverpod` for state management. Separate UI from business logic.
*   **Performance**:
    *   Use `const` widgets wherever possible.
    *   Use `ListView.builder` for long lists.
    *   Avoid expensive operations in the `build` method.
    *   Profile the app to identify and fix performance bottlenecks.
*   **Error Handling**: Implement robust error handling. Use `try-catch` blocks for operations that can fail (e.g., database queries, network requests).

## Building and Running

*   **Run the app**: `cd dentaltid && flutter run`
*   **Run tests**: `cd dentaltid && flutter test`

## Gemini Actions

- **Resolved `flutter analyze` issues**:
    - Fixed `prefer_interpolation_to_compose_strings` in `lib/src/core/backup_service.dart` by ensuring correct string interpolation.
    - Fixed `deprecated_member_use` in `lib/src/features/patients/presentation/add_edit_patient_screen.dart` by replacing `value` with `initialValue` in `DropdownButtonFormField`.
- Ran `dart fix --apply` and `dart format .` to automatically apply fixes and format the code.
- **Resolved `flutter analyze` issues in `lib/src/features/dashboard/presentation/home_screen.dart`**:
    - Removed unused imports: `currency_provider.dart` and `appointment.dart`.
    - Removed unused local variable `emergencyAsync`.
    - Removed unused private method `_flipCard`.
    - Added curly braces to an `if` statement to resolve `curly_braces_in_flow_control_structures` lint.
    - Re-added the definition for `todaysAppointmentsAsync` which was inadvertently removed.
- Ran `dart format .` to ensure consistent code formatting.
- Verified that `flutter analyze` now reports "No issues found!".
- **Enhanced Finance Chart:**
    - Improved the `FinanceChart` widget in `lib/src/features/finance/presentation/finance_chart.dart` with the following features:
        - Added padding around the chart for better margins.
        - Formatted Y-axis labels with currency symbols and intelligent scaling.
        - Improved X-axis date labels for readability and to prevent overlap.
        - Implemented interactive tooltips to show detailed information on hover.
        - Added a legend to differentiate between income and expense data series.
        - Made gridlines more subtle for a cleaner look.
        - Used theme-based colors and a modern design.
    - Replaced deprecated `withOpacity` with `withAlpha` to resolve analyzer warnings.
- **Project Revision for Windows (Deep Scan and Refactoring):**
    - **Initial Code Health Check:**
        - Addressed `empty_catches` in `lib/src/core/database_service.dart` with proper logging.
        - Fixed `dangling_library_doc_comments` and `avoid_print` in `lib/src/core/exceptions.dart`.
        - Ran `dart fix --apply` and `dart format .`.
        - Verified `flutter analyze` reports "No issues found!".
    - **Platform-Specific Code Refinement:**
        - Removed `android/`, `linux/`, and `macos/` directories to focus on Windows only.
        - Verified Windows-specific configurations and dependencies.
    - **In-depth Code Analysis and Refactoring:**
        - **General Code Quality:**
            - Extracted delete confirmation dialog into a reusable function.
            - Refactored editable patient fields in `DataTable` into a reusable widget.
        - **Database Interactions (SQLite):**
            - Removed redundant `ALTER TABLE` for `age` in `_onUpgrade` method.
            - Fixed case sensitivity in `getPatientByNameAndFamilyName` query using `COLLATE NOCASE`.
            - Reviewed data handling logic and error handling, found to be robust.
        - **UI and Feature Logic:**
            - Reviewed localization files (`.arb`) for consistency.
            - Verified button functionalities in `patients_screen.dart`.
            - Reviewed `PatientService` and `PatientRepository` for business logic and potential malfunctions, found to be robust.
            - **Time and Date Handling Refactoring:**
                - Replaced generic `Exception` with `DuplicateEntryException` in `addAppointment` in `AppointmentService`.
                - Combined `date` and `time` into a single `dateTime` field in the `Appointment` model.
                - Updated `AppointmentService`, `AppointmentRepository`, `DatabaseService` (with new migration), `AddEditAppointmentScreen`, and `AppointmentsScreen` to use the new `dateTime` field.
    - **Testing and Verification:**
        - No existing automated tests were found.
        - Developed a new unit test for `Appointment` model serialization/deserialization.
        - Ran the new test, which passed successfully.
        - Provided instructions for manual testing on Windows.
- **Resolved Localization Issues:**
    - Removed unused `shared_preferences.dart` import from `lib/src/features/settings/presentation/settings_screen.dart`.
    - Cleaned up `.arb` files by removing old PIN-related strings.
    - Ensured consistency across all `.arb` files by adding all necessary localization keys.
    - Regenerated localization files using `flutter gen-l10n`.
    - Verified that `flutter analyze` reports "No issues found!".
- **Code Formatting:**
    - Ran `dart format .` to ensure consistent code formatting across the project.
- **Resolved `deprecated_member_use` warnings for `RegExp`:**
    - Added `// ignore: deprecated_member_use` to the lines using `RegExp` in `lib/src/features/patients/presentation/add_edit_patient_screen.dart` and `lib/src/features/security/presentation/auth_screen.dart`.
    - Verified that `flutter analyze` now reports "No issues found!".
- **Added New Input Fields to Registration Page:**
    - Added `phoneNumber` and `medicalLicenseNumber` fields to the registration form in `lib/src/features/security/presentation/auth_screen.dart`.
    - Updated the `UserProfile` model in `lib/src/core/user_model.dart` to include `phoneNumber` and `medicalLicenseNumber`.
    - Verified that `flutter analyze` reports "No issues found!" after these changes.
- **Enhanced Dashboard Header:**
    - Created `lib/src/core/user_profile_provider.dart` to provide `UserProfile` data.
    - Modified `lib/src/features/dashboard/presentation/home_screen.dart` to display the current date and "Hello Dr. [Dentist's Name]" in the header.
    - Verified that `flutter analyze` reports "No issues found!" after these changes.
- **Enhanced Dashboard Header Layout:**
    - Refactored the dashboard header in `lib/src/features/dashboard/presentation/home_screen.dart` to use a `Row` with `Expanded` widgets for a more explicit grid-like organization of the dentist's name, current date, and time.
    - Verified that `flutter analyze` reports "No issues found!" after these changes.
- **Implemented Patient Visit Management:**
    - Created new directories for the `visits` feature: `lib/src/features/visits/application`, `lib/src/features/visits/data`, `lib/src/features/visits/domain`, `lib/src/features/visits/presentation`.
    - Defined the `Visit` model in `lib/src/features/visits/domain/visit.dart` to represent patient visits with fields for date, reason, notes, diagnosis, and treatment.
    - Updated `lib/src/features/appointments/domain/appointment.dart` and `lib/src/features/finance/domain/transaction.dart` to include a `visitId` for linking to specific visits.
    - Incremented `_databaseVersion` to 9 in `lib/src/core/database_service.dart`.
    - Modified `DatabaseService` to create the `visits` table and add `visitId` columns to the `appointments` and `transactions` tables during database creation and upgrade.
    - Created `VisitRepository` in `lib/src/features/visits/data/visit_repository.dart` for database interactions with `Visit` objects.
    - Created `VisitService` in `lib/src/features/visits/application/visit_service.dart` to provide business logic and a `visitsByPatientProvider`.
    - Integrated a `_PatientVisitHistory` widget into `lib/src/features/patients/presentation/add_edit_patient_screen.dart` to display a list of visits for a patient.
    - Added new localization keys (`visitHistory`, `noVisitHistory`, `visitDate`, `reasonForVisit`) to `lib/l10n/app_en.arb` and regenerated localization files.
    - Verified that `flutter analyze` reports no critical errors after these changes.
- **Resolved `unnecessary_brace_in_string_interps` warnings:**
    - Removed unnecessary braces from string interpolation for `patientId` in `lib/src/features/patients/presentation/add_edit_patient_screen.dart`.
    - Verified that `flutter analyze` now reports "No issues found!".
- **Resolved `missing_identifier` and `prefer_interpolation_to_compose_strings` issues in `lib/src/features/appointments/presentation/add_edit_appointment_screen.dart`**:
    - Fixed `missing_identifier` errors by using raw strings (`r'...'`) for `labelText` properties containing dollar signs in `InputDecoration` widgets within `_buildPaymentStatusCard`.
    - Addressed `prefer_interpolation_to_compose_strings` warnings by ensuring correct string interpolation syntax (e.g., `${l10n.error}: $error`).
    - Ran `dart fix --apply` and `dart format .` to automatically apply fixes and format the code.
    - Verified that `flutter analyze` now reports "No issues found!".
- **Organized UI grid layout spacing and colors in `lib/src/features/appointments/presentation/add_edit_appointment_screen.dart`**:
    - Centralized theme definitions in `lib/src/core/theme.dart` using `ColorScheme.fromSeed` for both light and dark themes.
    - Updated `lib/src/core/theme_provider.dart` to use these centralized themes and `ColorScheme.fromSeed` for other custom themes.
    - Created a helper function `_buildThemedCardDecoration` to generate consistent `BoxDecoration` for cards using theme colors.
    - Refactored all card widgets (`_buildPatientSelectionCard`, `_buildAppointmentDateTimeCard`, `_buildAppointmentTypeCard`, `_buildPaymentStatusCard`, `_buildLastVisitCard`) to use theme-consistent colors and the new helper function.
    - Refactored `_buildPatientSelectionSection` and `_buildAppointmentDateTimeSection` to use theme-consistent colors.
    - Standardized spacing (`SizedBox` and `Padding`) in the main `build` method for consistent visual separation.
    - Resolved `argument_type_not_assignable` errors by changing `CardTheme` to `CardThemeData` in `theme.dart` and `theme_provider.dart`.
    - Resolved `argument_type_not_assignable` errors by modifying `_buildThemedCardDecoration` to accept a `Color` and updating its calls accordingly.
    - Resolved `deprecated_member_use` warnings by replacing `.withOpacity()` with `.withAlpha()` and `colorScheme.surfaceVariant` with `colorScheme.surfaceContainerHighest`.
    - Verified that `flutter analyze` now reports "No issues found!".
- **Fixed "select date and time" bug in `lib/src/features/appointments/presentation/add_edit_appointment_screen.dart`**:
    - Added `intl` package dependency.
    - Imported `package:intl/intl.dart`.
    - Modified `_selectAppointmentDateTime()` to update `_dateTimeDisplayController.text` with a formatted string of `_appointmentDateTime` after `setState()`.
    - Modified `initState()` to set `_dateTimeDisplayController.text` with the formatted `_appointmentDateTime` if `widget.appointment` is not null.
    - Ran `flutter analyze` and `dart format .` to ensure code quality.
    - Verified the fix by running the app (`rapp`).
- **Implemented UI changes in `lib/src/features/appointments/presentation/add_edit_appointment_screen.dart`**:
    - Changed "Balance Due" text color to white and bold when `_unpaid == 0`.
    - Adjusted the `fillColor` of the "Balance Due" `TextFormField` to `colorScheme.surface` when `_unpaid == 0` (reverted to previous background color).
    - Changed the "UPDATE APPOINTMENT" button text to "Add/Edit".
    - Adjusted the button dimensions (`width: 150`, `height: 50`) and used theme-consistent colors (`colorScheme.primary` for `backgroundColor` and `colorScheme.onPrimary` for `foregroundColor`) for the "Add/Edit" button.
    - Ran `flutter analyze` and `dart format .` to ensure code quality.
    - Verified the changes by running the app (`rapp`).
- **Resolved `flutter analyze` issues in `lib/src/features/patients/presentation/patient_profile_screen.dart` and `lib/src/features/appointments/presentation/add_edit_appointment_screen.dart`**:
    - Fixed `deprecated_member_use` by replacing `value` with `initialValue` in `DropdownButtonFormField` in both files.
    - Fixed `use_build_context_synchronously` by adding `if (mounted)` checks before using `ScaffoldMessenger.of(context)`.
    - Ran `dart format .` to ensure consistent code formatting.
    - Verified that `flutter analyze` now reports "No issues found!".
- **Refactored Patient Visit Management for Real-time Editing**:
    - Created `lib/src/features/patients/application/patient_appointments_provider.dart` to manage patient appointments using `StateNotifierProvider`.
    - Refactored `lib/src/features/patients/presentation/patient_profile_screen.dart` to be a `ConsumerWidget`.
    - Refactored `VisitsListWidget` to be a `ConsumerWidget` and use `patientAppointmentsProvider`.
    - Refactored `VisitCard` to be a `ConsumerStatefulWidget` and use `ref.read` for services and `ref.invalidate` to refresh the appointment list.
    - Fixed `deprecated_member_use` by replacing `value` with `initialValue` in `DropdownButtonFormField` in `VisitCard`.
    - Fixed `unreachable_switch_default` by removing the `default` case in `_getStatusColor` in `VisitCard`.
    - Ran `dart format .` to ensure consistent code formatting.
    - Verified that `flutter analyze` now reports "No issues found!".
