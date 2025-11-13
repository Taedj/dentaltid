# DentalTid - Dentist Management System

This is a Flutter project for a Dentist Management System (DMS). The application is designed to manage patients, appointments, emergencies, inventory, and finances. This version of the project is specifically configured for **Windows desktop**.

## Project Overview

The Dentist Management System (DMS) is a hybrid Flutter-based application designed for dentists and clinic assistants. It operates locally and offline, with a cloud synchronization option using Firebase. All local data is stored securely, and users can generate and load ZIP backups.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (ensure you have the latest stable version)
*   [Visual Studio with Desktop development with C++ workload](https://docs.flutter.dev/desktop/windows#install-visual-studio) (required for Windows desktop development)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [repository_url]
    cd dentaltid
    ```
    (Replace `[repository_url]` with the actual URL of your repository)

2.  **Get Flutter dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Enable Windows desktop support (if not already enabled):**
    ```bash
    flutter config --enable-windows-desktop
    ```

### Running the Application

To run the application on Windows:

```bash
flutter run -d windows
```

### Building for Windows

To build a release executable for Windows:

```bash
flutter build windows
```
The executable will be found in `build\windows\runner\Release`.

### Running Tests

To run the unit tests:

```bash
flutter test
```

## Project Structure

The project follows a feature-first architecture with clear separation of concerns:

*   `lib/src/core`: Core services, utilities, and exceptions.
*   `lib/src/features`: Contains individual features (e.g., `patients`, `appointments`, `finance`), each with its own application, data, domain, and presentation layers.
*   `lib/l10n`: Localization files.
*   `test`: Unit and widget tests.

## Localization

The application supports multiple languages. Localization files are located in `lib/l10n`.

## Database

The application uses SQLite for local data storage, managed via `sqflite_common_ffi`. The database schema and migrations are defined in `lib/src/core/database_service.dart`.

## Contributing

(Add contributing guidelines here if applicable)

## License

(Add license information here if applicable)