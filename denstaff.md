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

### Hidden Features
*   **Finance Tab**: Completely hidden.
*   **Global Settings**: The main settings tab used by the Dentist is hidden.

### Staff Settings Tab
A limited "Special Settings" tab is available for local preferences:
*   **Language**: Local app language.
*   **Theme**: Light/Dark mode.
*   **Currency**: Display preference.
*   **LAN Connection Settings**: To manage connection status.

## 5. Network Configuration & Synchronization (The "Ctrl+T" Menu)
A hidden network configuration panel is accessed by pressing **`Ctrl + T`** on the Login Screen. The interface changes based on the selected Mode (Dentist vs. Staff).

### A. Dentist View (Server Mode)
Used to host the database and listen for staff connections.

**UI Elements:**
1.  **Server IP Display**: Shows the machine's local IP address(es) (e.g., `192.168.1.5`).
2.  **Port Selection**: Input field to define the listening port (default: `8080`).
3.  **Port Management**:
    *   **"Check Port"**: Validates if the port is available.
    *   **"Open Port"**: Executes a `.bat` script with Administrator privileges to add a firewall rule opening the specific port.
4.  **Server Control**:
    *   **"Start Server"**: Initializes the WebSocket/TCP server.
    *   **Status Indicator**: Visual badge (Online - Green / Offline - Red).
5.  **Logs**:
    *   A terminal-like text zone showing server events (e.g., "Client Connected", "Sync Complete", "Error: Port in use").
    *   **Copy Button**: To copy logs to clipboard.

### B. Staff View (Client Mode)
Used to connect to the Dentist's machine and synchronize data.

**UI Elements:**
1.  **Auto Connect**:
    *   Button: "Scan & Connect".
    *   Logic: Scans the local network (UDP Broadcast or IP range scan) to find running Dentist servers and connects automatically.
2.  **Manual Connection**:
    *   **IP Address Input**: To enter the Dentist's IP.
    *   **Port Input**: To enter the Dentist's Port.
    *   **"Connect" Button**: Initiates handshake.
3.  **Port Management** (For Client-side Firewall):
    *   **"Check Port"**: Checks outbound capability.
    *   **"Open Port"**: Executes Admin `.bat` script to allow app communication through firewall.
4.  **Connection Status**: Visual badge (Online - Green / Offline - Red).

### Synchronization Logic
1.  **Initial Handshake**: When a Staff Client connects, it requests a full copy of the Dentist's Database.
2.  **Credential Sync**: This initial sync populates the `StaffUsers` table on the Client device, allowing the Staff member to log in using their Username and PIN.
3.  **Real-Time Sync**:
    *   Any create/update/delete operation (CRUD) performed by Dentist or Staff is broadcast instantly to all connected peers.
    *   Conflict Resolution: "Last Write Wins" or Server (Dentist) timestamp priority.

## 6. Implementation Notes
*   **Offline Capability**: The system functions entirely without Internet. All communication happens via Local LAN.
*   **Security**: The `.bat` script for port opening must trigger a Windows UAC (User Account Control) prompt.
*   **Database**: Uses the existing `sqflite` implementation, extended with a sync layer.
