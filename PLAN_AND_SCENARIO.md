# Plan and Scenario: Role-Based Settings & LAN-Based Multi-User System

This document outlines the plan and scenarios for implementing role-based restrictions in the settings tab and a LAN-based multi-user system.

## 1. High-Level Goals

-   **Goal 1:** Restrict access to certain settings for `assistant` and `receptionist` roles.
-   **Goal 2:** Introduce a LAN-based system where `assistant` and `receptionist` users are managed by a `dentist` and do not need their own email/password to log in.
-   **Goal 3:** The `dentist`'s device will act as the primary data source on the LAN, with other devices acting as clients.

## 2. Decisions Made

Based on our discussion, we have made the following key decisions:

1.  **Authentication for Managed Users:** `assistant` and `receptionist` users will use a simple numeric **PIN** to log in.
2.  **LAN Discovery:** The application will support both **manual IP configuration** and **automatic discovery** for connecting client devices to the primary device. The user can choose the method that best suits their needs.
3.  **Offline Access for Clients:** If a client device is disconnected from the LAN, it will be **unusable**. A clear message will be displayed, instructing the user to check their network connection to reconnect.

## 3. Implementation Plan

### Part 1: Role-Based Restrictions in the Settings Tab

1.  **Analyze the existing Settings screen:** I will start by thoroughly analyzing the code for the settings screen to identify the widgets that need to be hidden or made non-editable.
2.  **Implement UI changes based on role:**
    -   Hide "Cloud Sync" and "Finance Settings" for non-dentist roles.
    -   Make "Currency" and "Edit Profile" options view-only for non-dentist roles, displaying the configuration set by the `dentist`.
    -   Hide the "Change Password" button for non-dentist roles.
3.  **Implement PIN management for the dentist:**
    -   Add a new section in the `dentist`'s settings to manage their staff.
    -   In this section, the `dentist` will be able to see a list of their `assistant` and `receptionist` users.
    -   For each user, the `dentist` will have an option to set or change their PIN.

### Part 2: LAN-Based Multi-User System

1.  **Introduce a "Managed User" concept:**
    -   I will modify the `UserProfile` model to differentiate between a primary `dentist` account and a "managed" `assistant` or `receptionist` account.
    -   Managed accounts will be linked to a `dentist` account.
2.  **Develop a User Management UI for the dentist:**
    -   Create a new screen where the `dentist` can create, edit, and delete `assistant` and `receptionist` users.
    -   When creating a new managed user, the `dentist` will define their username and role, and set an initial PIN.
3.  **Implement a LAN-based login flow for managed users:**
    -   On app startup, the application will check if it is running on the primary `dentist`'s device or a client device.
    -   If it's a client device, it will not show the standard email/password login screen. Instead, it will present a list of available managed users for the clinic.
    -   The user will select their username and enter their PIN to log in.
4.  **Implement LAN-based data synchronization:**
    -   This is the most complex part of the plan. I will use a networking library to enable communication between the devices on the LAN.
    -   The `dentist`'s device will act as a "server" for the local database.
    -   When a client device (e.g., a receptionist's computer) makes a change (like booking an appointment), it will send the change to the `dentist`'s device, which will then update the master database. The change will then be propagated to all other connected clients.

## 4. Scenarios

### Scenario 1: Dr. Smith (Dentist) Manages His Staff

1.  Dr. Smith logs into the app with his email and password.
2.  He navigates to "Settings" and then to a new "Staff Management" section.
3.  He clicks "Add New Staff" and creates a new user:
    -   **Username:** "Alice"
    -   **Role:** "Receptionist"
    -   **PIN:** "1234"
4.  He then creates another user:
    -   **Username:** "Bob"
    -   **Role:** "Assistant"
    -   **PIN:** "5678"

### Scenario 2: Alice (Receptionist) Logs In

1.  Alice opens the DentalTid app on her computer at the front desk.
2.  The app automatically detects that it is a client device on the clinic's LAN.
3.  Instead of a login screen, she sees a list of users: "Alice (Receptionist)" and "Bob (Assistant)".
4.  She clicks on her name, enters her PIN "1234", and is logged into the app.
5.  She can access the "Appointments" and "Patients" sections, but the "Finance" and "Inventory" sections are not visible in her navigation menu.
6.  When she books a new appointment, the appointment is saved to Dr. Smith's main computer, and it appears on all other connected devices in the clinic.

### Scenario 3: Bob (Assistant) Logs In

1.  Bob opens the app on a tablet in the treatment room.
2.  He sees the same user selection screen as Alice.
3.  He clicks on his name, enters his PIN "5678", and is logged in.
4.  He can access the "Inventory" and "Patients" sections, but "Appointments" and "Finance" are not visible.

### Scenario 4: Network Disconnection

1.  The clinic's Wi-Fi network goes down.
2.  Alice, who is currently logged in, tries to book a new appointment.
3.  A dialog box appears with a message: "Connection to the primary device has been lost. Please check your network connection."
4.  The app becomes unusable until the network connection is restored.