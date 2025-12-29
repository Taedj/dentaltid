# Plan: Bidirectional Live Sync (DentalTID <-> NanoPix)

This document outlines the implementation plan for real-time, bidirectional synchronization between DentalTID and the NanoPix X-ray software.

## 1. Core Objectives
*   **Automatic Import**: DentalTID monitors NanoPix and adds new patients automatically.
*   **Automatic Export**: DentalTID creates matching records and folders in NanoPix when a new patient is added in DentalTID.
*   **Live Toggle**: A new "Live Sync" checkbox in Settings to enable/disable this behavior.
*   **UI Identification**: Clear visual indicators for patients originating from NanoPix.
*   **Advanced Filtering**: New filters to isolate externally added patients.

## 2. Technical Strategy

### A. Database Enhancements (DentalTID)
*   Add a `source` column to the `patients` table (values: `internal`, `nanopix`).
*   Add an `external_id` column to store the NanoPix string ID (e.g., `20251229_160011`).
*   Update the `Patient` domain model and `fromJson`/`toJson` logic.

### B. The Live Sync Engine (`NanoPixSyncService`)
*   **Instant Monitoring**: Use a `DirectoryWatcher` on the NanoPix `PatientData` folder to detect changes immediately rather than polling.
*   **NanoPix -> DentalTID**:
    *   When a new folder or DB entry is detected in NanoPix, extract `first_name`, `last_name`, `birthdate`, and `created_datetime`.
    *   Check for duplicates in DentalTID.
    *   Insert into DentalTID with `source: 'nanopix'`.
*   **DentalTID -> NanoPix**:
    *   When `addPatient` is called in DentalTID and Live Sync is ON:
        1. Generate a NanoPix-compatible ID (Timestamp format: `YYYYMMDD_HHMMSS`).
        2. Insert record into `NanoPix.db3` (`Patient` table).
        3. Create the physical folder in `PatientData`.
        4. (Optional) Create subfolders if NanoPix requires them.

### C. UI/UX implementation
*   **Settings**: Add `live_sync_enabled` checkbox.
*   **Patients Table**:
    *   Conditional styling: Rows with `source: 'nanopix'` get a distinct background color.
    *   Actions Column: Insert a "Source Info" icon between Delete and Edit.
*   **Filters**: Add `Today By External` and `All By External` to the existing filter logic.

---

## 3. Clarification Questions

Before I begin the implementation, I need your input on these 5 points:

1.  **Duplicate Detection**: If a patient is added manually in DentalTID AND manually in NanoPix with the exact same name/DOB, should the system link them together as one, or keep them separate?
2.  **NanoPix Folder Structure**: When DentalTID creates a folder in NanoPix, is it enough to create just the main folder (e.g., `D:\PatientData\20251229_160011\`), or does NanoPix expect empty subfolders (like `\images`, `\thumbnails`) to be there immediately?
3.  **Color Preference**: What specific color would you like for the "NanoPix background"? (e.g., a subtle light blue, a soft purple, or a light amber?)
4.  **Deleted Patients**: If a dentist deletes a patient in DentalTID, should they also be deleted from the NanoPix database/folder? (This is risky for medical data, so I recommend "No" or "Ask every time").
5.  **Creation Date**: For patients imported from NanoPix, should the "Today" filter in DentalTID use the date the patient was **originally created in NanoPix**, or the date they were **first synced into DentalTID**?

---

## 4. Proposed Action Plan
1.  **Phase 1**: Update `Patient` model and database schema to support `source` and `external_id`.
2.  **Phase 2**: Implement the "Export" logic (DentalTID -> NanoPix).
3.  **Phase 3**: Upgrade `NanoPixSyncService` to use a File Watcher for "Instant" updates.
4.  **Phase 4**: Implement UI changes (Checkbox, Row Colors, New Filters).
5.  **Phase 5**: Verification and Stress Testing.
