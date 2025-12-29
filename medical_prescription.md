# Medical Prescription Template System

This document outlines the design and requirements for the Medical Prescription Template System in the DentalTid application.

## 1. Objectives
- Provide a professional way for dentists to issue and track medical prescriptions.
- Implement a live-preview editor for easy prescription creation.
- Support multiple templates for professional variety.
- Maintain a sequential history of prescriptions per dentist.

## 2. Data Requirements

### 2.1 Dentist Information (From Profile)
- **Clinic Name**: `clinicName`
- **Clinic Address**: `clinicAddress`
- **Dentist Name**: `dentistName` (Full name)
- **Phone Number**: `phoneNumber`
- **Order number**: A sequential counter (1 to N) maintained per dentist.

### 2.2 Patient Information (From Capture/Visit)
- **Full Name**: `patient.name` + `patient.familyName`
- **Age**: `patient.age`
- **Date**: The date the prescription is issued (defaults to today).

### 2.3 Prescription Content (Medicine Table)
Each entry in the prescription will include:
- **Medicine Name**: The name of the drug.
- **Quantity**: Dosage (e.g., 500mg, 1 box).
- **Frequency**: How many times per day (e.g., 2 times).
- **How to take**: Route of administration (e.g., Orally, After meals).
- **Time/Duration**: Specific timing or duration (e.g., for 5 days).

## 3. User Interface Design

### 3.1 Entry Point
A new button labeled **"Medical Prescription"** will be added to the `VisitCard` widget in `patient_profile_screen.dart`, positioned between the **"Save"** and **"Delete Visit"** buttons.

### 3.2 Prescription Editor (Split Screen)
When clicked, a full-screen or large dialog editor opens, split into two main zones:

#### Left Side (Input Zone) - 50% Width
- **Top Section**: Options to add medicines manually.
- **Medicine Table**: 
  - Dynamic rows where the dentist adds medicine details.
  - Columns: Medicine, Quantity, Frequency, Route, Time.
  - Ability to add/remove rows.
  - Changes here trigger a live update on the right side.

#### Right Side (Preview Zone) - 50% Width
- **Live Preview**: Shows exactly how the printed prescription will look.
- **Template Selection**: A toolbar at the top or bottom to switch between different professional templates.
- **Dynamic Content**: Data from the left side (and profile/patient data) is formatted and displayed in real-time.
- **Formatted Text**: While the input is a table, the preview translates this into a clean, professional list format as seen in traditional prescriptions.

## 4. Database & Persistence

### 4.1 Prescription History
A new collection (or sub-collection) will be added to store prescription data:
```json
{
  "dentistId": "uid",
  "patientId": "pid",
  "orderNumber": 42,
  "date": "2023-10-27",
  "patientInfo": {
     "fullName": "John Doe",
     "age": 30
  },
  "content": [
    {
      "medicine": "Amoxicillin",
      "quantity": "500mg",
      "frequency": "3 times/day",
      "route": "Orally",
      "time": "7 days"
    }
  ],
  "templateId": "classic_blue"
}
```

### 4.2 Sequential Order Number
To ensure each dentist has a 1..N order number:
- A `counters` field in the dentist's profile or a separate `counters` collection will track the `lastPrescriptionNumber`.
- Each time a new prescription is saved, this number is incremented.

## 5. Templates Preview
- **Template A**: Modern (Centered logo, clean fonts).
- **Template B**: Classic (Header with dentist info on top-left, clinic info on top-right).
- **Template C**: Minimalist (Single tooth icon, simple typography).

## 6. Implementation Steps
1. Create `Prescription` and `Medicine` models.
2. Update `UserProfile` or create a service to manage the sequential order number.
3. Build the `PrescriptionEditorScreen` with the split-view layout.
4. Implement the live-update logic (using `StatefulWidget` or `Riverpod`).
5. Design the printable templates using Flutter's layout system.
6. Integrate the "Medical Prescription" button into the patient profile.
