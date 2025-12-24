# Local Network Staff System (Offline-First)

## 1. Overview
This module introduces a **100% Local LAN (Local Area Network)** system allowing a Dentist (Host/Server) and their Staff (Clients) to work on the same database simultaneously without requiring an internet connection. Synchronization is instant across the local network.

## 2. Staff Management (Dentist Side)
The Dentist can manage staff members via a new section in the **Settings Tab**.

### Create Staff Member
Fields required:
*   **Full Name**: String
*   **Username**: String (Unique identifier for login)
*   **PIN**: 4-digit number (Secure access)
*   **Role**: Enum Selection
    *   `Assistant`
    *   `Receptionist`

### Data Storage
Staff credentials and profiles are stored in the local SQLite database and synchronized to connected clients.

## 3. Login Portal Overhaul
The login screen is modified to accommodate two modes of authentication.

### UI Changes
*   **Mode Selector**: A toggle or dropdown to switch between "Dentist" and "Staff".

### Dentist Mode
*   **Input Fields**: `Email` and `Password`.
*   **Auth Method**: Standard Firebase Auth (with local persistence for offline access).

### Staff Mode
*   **Input Fields**: `Username` and `PIN` (4 digits).
*   **Auth Method**: Local authentication against the synchronized database.
*   **Requirement**: The Client must be connected to the Dentist Server (via LAN) to receive the initial database update containing their credentials.

## 4. Staff User Experience
The Staff interface mirrors the Dentist interface but with specific restrictions based on security and relevance.

### Feature Access Table
| Feature | Dentist | Assistant | Receptionist |
| :--- | :---: | :---: | :---: |
| **Dashboard** | ✅ | ✅ | ✅ |
| **Patients** | ✅ | ✅ | ✅ |
| **Appointments** | ✅ | ✅ | ✅ |
| **Inventory** | ✅ | ✅ | ❌ |
| **Finance** | ✅ | ❌ | ❌ |
| **Settings** | ✅ (Full) | ❌ (Limited) | ❌ (Limited) |

### Hidden Features
*   **Finance Tab**: Completely hidden for Staff. **However**, staff actions (e.g., Inventory Purchase, Appointment Payment) **automatically** generate financial transactions in the background to keep the Dentist's records accurate.
*   **Global Settings**: The main settings tab used by the Dentist is hidden.

### Staff Settings Tab
A limited "Staff Settings" screen is available for local preferences:
*   **Language**: Local app language.
*   **Theme**: Light/Dark mode.
*   **Currency**: Display preference.
*   **LAN Connection Settings**: To manage connection status.
*   **Logout**: Securely clears local session data.

## 5. Network Configuration & Synchronization
A hidden network configuration panel is accessed by pressing **`Ctrl + T`** on the Login Screen or via Settings.

### A. Dentist View (Server Mode)
Used to host the database and listen for staff connections.
*   **Auto-Start**: Can be configured to start automatically on app launch.
*   **Port Management**: Includes tools to check and open firewall ports via Admin `.bat` scripts.

### B. Staff View (Client Mode)
Used to connect to the Dentist's machine and synchronize data.
*   **Auto-Connect**: Tries to connect to the last known IP.
*   **Initial Sync**: Downloads the full database and Dentist Profile (for license validation) upon first connection.

### Synchronization Logic
1.  **SyncBroadcaster**: A unified service ensures all CRUD operations (Create, Update, Delete) are broadcast to the network.
2.  **Optimized Deletes**: Large deletion operations (like deleting a Patient) use optimized bulk database queries locally while still broadcasting necessary events to keep peers in sync.
3.  **Conflict Resolution**: "Last Write Wins" strategy.

## 6. Implementation Notes
*   **Offline Capability**: The system functions entirely without Internet. All communication happens via Local LAN.
*   **Settings Persistence**: All local settings are stored in `Documents/DentalTid/settings/settings.json` for portability and reliability.
*   **License Check**: Staff apps validate their license status against the synchronized Dentist Profile.