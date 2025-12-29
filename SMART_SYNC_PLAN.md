# NanoPix Smart Sync Feature: Implementation Plan

This document outlines the plan to implement a smart synchronization feature that automatically imports patient X-rays from a local NanoPix installation into the DentalTID application.

## 1. Objective

The goal is to create a seamless, background synchronization process that:
1.  Allows the user to specify the location of the NanoPix `PatientData` folder.
2.  Monitors this folder for new X-ray images.
3.  Intelligently matches patients between the NanoPix database and the DentalTID database based on **Full Name** and **Date of Birth**.
4.  Automatically imports new X-ray images for matched patients, making them visible in the patient's "Imaging History" screen in DentalTID.
5.  Adheres to DentalTID's existing data-handling and file-naming conventions.

## 2. Proposed Architecture

The feature will be built around a new background service that handles all the synchronization logic.

- **Settings UI:** A new section will be added to the DentalTID settings screen where the user can input the path to the NanoPix `PatientData` folder.
- **`NanoPixSyncService`:** A new background service that will run periodically (e.g., on app startup and every few minutes). This service will be the core of the feature.
- **Data Flow:** The `NanoPixSyncService` will read from both the DentalTID and NanoPix databases, find matches, and then use the existing `ImagingService` in DentalTID to import the images. This ensures that the new feature integrates perfectly with the existing application logic.

## 3. Synchronization Workflow

The synchronization process will follow these steps:

### Step 1: Initialization
- When the DentalTID application starts, it will check if a `PatientData` path has been set in the settings.
- If the path is set, the `NanoPixSyncService` will be initialized and start its first sync cycle.

### Step 2: Data Loading
The service will load patient data from both applications:
- **DentalTID Patients:** Load the list of all patients from the internal DentalTID database.
- **NanoPix Patients:** Open the `NanoPix.db3` SQLite database file located within the specified `PatientData` path. It will then query this database to extract a list of all NanoPix patients, including their names, birth dates, and unique IDs.

### Step 3: Patient Matching
- The service will iterate through every patient in the DentalTID database.
- For each DentalTID patient, it will attempt to find a matching patient in the NanoPix data.
- A match will be confirmed only if **all** of the following conditions are met:
    - The **last names** are identical.
    - The **first names** are identical.
    - The **dates of birth** are identical.
- The matching logic will be designed to handle minor differences in capitalization or spacing.

### Step 4: Image Discovery and Import
- Once a patient match is confirmed, the service will identify the corresponding image folder for the NanoPix patient.
- It will scan this folder for new X-ray images (`.jpg` thumbnails and `.iosb` main image files) that have not already been imported into DentalTID.
- For each new image found, it will use the existing `imagingServiceProvider.saveXray()` function. This is a critical step because it guarantees that:
    - The image is copied to the correct location for DentalTID.
    - The file is renamed according to DentalTID's standard naming convention.
    - The new X-ray record is correctly associated with the patient in the DentalTID database.

### Step 5: Handling the Proprietary `.iosb` Image Format
This is the most challenging part of the implementation, as the `.iosb` file format is unknown.

- **Primary Goal:** I will attempt to convert the `.iosb` file into a standard PNG image. My approach will be to treat it as a raw bitmap (BMP) file, potentially with a custom header that needs to be bypassed.
- **Fallback:** If the conversion of the `.iosb` file is unsuccessful, the feature will gracefully fall back to importing only the `.jpg` thumbnail. This ensures that the user still gets a visual record in the patient's history, even if it's at a lower resolution.
- **Transparency:** This part of the feature is **experimental**. Its success depends on the complexity of the proprietary format.

## 4. UI/UX Changes

1.  **Settings Screen:** A new text field will be added to the settings area for the user to enter the full path to the `PatientData` directory.
2.  **Manual Sync:** A "Sync Now" button will be provided next to the path setting to allow the user to trigger a manual synchronization at any time.
3.  **Status Feedback:** The application will provide feedback on the sync status, such as "Last synced: Just now" or "Error: NanoPix folder not found."

## 5. Action Plan

I will now begin implementing this feature in the following order:

1.  **Add Dependencies:** Add the `sqflite` and `sqflite_common_ffi` packages to the project to enable SQLite database access.
2.  **Create UI:** Implement the settings UI for specifying the NanoPix folder path.
3.  **Build Service Skeleton:** Create the `NanoPixSyncService` file and set up the background execution logic.
4.  **Implement Database Logic:** Write the code to read the patient tables from both the DentalTID and `NanoPix.db3` databases.
5.  **Implement Matching Logic:** Create the function to intelligently match patients.
6.  **Implement Import Logic:** Write the code that discovers new images and uses the existing `saveXray()` service to import them.
7.  **Attempt `.iosb` Conversion:** Develop and test the experimental function to convert `.iosb` files.
8.  **Testing:** Thoroughly test the end-to-end feature to ensure its reliability and accuracy.
