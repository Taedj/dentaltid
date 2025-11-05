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