# Paid Plan & Trial System Specification

## Overview
A trial and premium system for dentist accounts involving a 30-day free trial, usage limits, and an activation code system.

## Account Lifecycle
1.  **Registration**: New dentist accounts start a 30-day free trial.
2.  **First Login**: Requires internet to sync and initialize.
3.  **Trial Period**:
    *   Offline usage allowed.
    *   "Remember Me" keeps user logged in.
    *   **Limitations**:
        *   No Cloud Sync/Backup management.
        *   Max 100 Patients (Cumulative).
        *   Max 100 Appointments (Cumulative).
        *   Max 100 Inventory Items (Cumulative).
    *   **UI Indicators**:
        *   Counters (e.g., "15/100") on relevant tabs.
        *   Days remaining countdown on Dashboard.
        *   Trial Active badge.
4.  **Expiration (Day 30+)**:
    *   App forces logout.
    *   Login blocked until activation.
    *   Dialog to contact developer or enter activation code.
5.  **Premium/Activated**:
    *   Unlimited usage.
    *   All features enabled.
    *   Dashboard shows "Premium Account".

## Technical Requirements

### User Model Updates
*   `trialStartDate`: Timestamp.
*   `isPremium`: Boolean.
*   `premiumExpiryDate`: Timestamp (optional, if activation is for limited time).
*   `cumulativePatients`: Integer (Only increments).
*   `cumulativeAppointments`: Integer (Only increments).
*   `cumulativeInventory`: Integer (Only increments).

### Authentication & Security
*   **Remember Me**: Persist session locally.
*   **License Check**:
    *   On Login: Check `isPremium` and `trialStartDate`.
    *   If expired and not premium -> Show Activation Dialog.
    *   If valid -> Allow access.

### Activation System
*   **Codes**: 27-character alphanumeric codes.
*   **Validation**: Check code against database, apply duration to account.
*   **Developer Role**:
    *   New User Role: `developer`.
    *   Dashboard capability to generate codes for specific durations (e.g., 1 month, 6 months, 1 year).

### UI Changes
*   **Login Screen**: Add "Remember Me" toggle.
*   **Dashboard**: Add Trial/Premium status widget and Countdown.
*   **Settings**: Add "Activate Premium" section.
*   **Patients/Appointments/Inventory**: Add limitation logic and counter display.
*   **Backup/Sync**: Disable buttons for trial users.

### Developer Dashboard
*   Input for duration (months).
*   Button to generate code.
*   Display generated code.
