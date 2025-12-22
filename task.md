# Implementation Plan: Local Network Staff System

This is a live document tracking the step-by-step implementation of the offline-first staff system as defined in `denstaff.md`.

## Phase 1: Database & Core Models
- [x] **Schema Update**
    - [x] Add `staff_users` table to SQLite database (columns: `id`, `fullName`, `username`, `pin`, `role`, `createdAt`).
    - [x] Create migration script.
- [x] **Data Models**
    - [x] Create `StaffUser` data class (serialization/deserialization).
    - [x] Create `StaffRole` enum (`assistant`, `receptionist`).
- [x] **Local Service**
    - [x] Implement `StaffService` for local CRUD operations.
    - [x] Add Riverpod providers for staff management.

## Phase 2: Dentist Settings (Staff Management)
- [x] **Settings UI Update**
    - [x] Add "Staff Management" tile to the existing Settings screen (Dentist only).
- [x] **Staff CRUD UI**
    - [x] Create `StaffListScreen` to view existing staff.
    - [x] Create `AddStaffDialog` with fields: Full Name, Username, PIN, Role.
    - [x] Implement Edit/Delete functionality.
    - [x] Validate PIN (4 digits) and unique Username.

## Phase 3: Login Portal Overhaul
- [x] **UI Refactoring**
    - [x] Add "Mode Switcher" (Dentist/Staff) to `AuthScreen`.
    - [x] Create `DentistLoginForm` (Email/Password).
    - [x] Create `StaffLoginForm` (Username/PIN).
- [x] **Authentication Logic**
    - [x] Keep existing Firebase Auth for Dentist.
    - [x] Implement `StaffAuthService` to verify credentials against local SQLite DB.
    - [x] Handle session persistence for Staff (local storage only, no Firebase token).

## Phase 4: Staff Dashboard & UI Restrictions
- [x] **Role-Based Access Control (RBAC)**
    - [x] Modify `MainLayout` to accept `UserRole`.
    - [x] Hide "Finance" and "Global Settings" tabs for Staff.
    - [x] Restrict access to specific routes based on role.
- [x] **Staff Settings**
    - [x] Create `StaffSettingsScreen`.
    - [x] Implement local preferences:
        - [x] Language Selector.
        - [x] Theme Toggle.
        - [x] Currency Display.
        - [x] LAN Connection shortcut.

## Phase 5: Networking Infrastructure (Ctrl+T)
- [x] **Network Configuration Dialog**
    - [x] Create `NetworkConfigDialog` widget triggered by `Ctrl + T` on Login Screen.
    - [x] Implement `NetworkInfoService` to fetch local IP address.
- [x] **Port Management**
    - [x] Create `open_port.bat` script for Windows Firewall rules.
    - [x] Implement Dart function to execute `.bat` as Administrator.
    - [x] Add "Check Port" and "Open Port" buttons to UI.
- [x] **Server Mode (Dentist)**
    - [x] Implement `SyncServer` (likely using `shelf` or raw `WebSockets`).
    - [x] UI: Start/Stop Server, Log View, Connection Status.
- [x] **Client Mode (Staff)**
    - [x] Implement `SyncClient` to connect to Dentist IP.
    - [x] Implement UDP Broadcast for "Auto Connect" / Server Discovery.
    - [x] UI: Auto Connect button, Manual IP/Port input, Connection Status.

## Phase 6: Data Synchronization
- [x] **Initial Sync (Handshake)**
    - [x] Implement protocol to export Dentist's full DB (or relevant tables) to JSON/Binary.
    - [x] Implement protocol for Client to receive and overwrite/merge local DB on first connect.
- [x] **Real-Time Sync**
    - [x] Create `SyncEvent` model (Action: Create/Update/Delete, Table, Data).
    - [x] Hook into existing Repositories/Services to broadcast changes.
        - [x] Patient updates.
        - [x] Appointment updates.
        - [x] Inventory updates.
        - [x] Staff updates.
    - [x] Implement `SyncListener` on Client to apply incoming changes instantly.
    - [x] Implement `SyncListener` on Server to accept Staff changes.

## Phase 7: Testing & Polish
- [ ] **Verification**
    - [ ] Test Dentist creating staff.
    - [ ] Test Staff login (offline).
    - [ ] Test "Ctrl+T" menu and Port Opening.
    - [ ] Test Connection establishment.
    - [ ] Test Bi-directional data sync (Dentist <-> Staff).
- [ ] **Refinement**
    - [ ] Add error handling and user feedback for network issues.
    - [ ] Ensure security (sanitize inputs, verify PINs).
    - [ ] Final UI/UX polish.
