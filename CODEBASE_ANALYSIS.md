# DentalTid Codebase Analysis & Recommendations

## 1. Project Overview
**Architecture:**
- **Framework:** Flutter with GoRouter for navigation.
- **State Management:** Riverpod.
- **Database:** Hybrid approach using `sqflite_sqlcipher` (Encrypted SQLite) for local data and `firebase_core/cloud_firestore` for cloud features.
- **Structure:** Feature-based Clean Architecture (Domain/Data/Presentation layers).

**Current State:**
The application has a solid foundation for a general practice management software. The code is clean, modular, and follows modern Flutter best practices.

## 2. Implemented Features
- **Patient Management:** Basic demographics, visit history, severity levels, and blacklist functionality.
- **Appointment Scheduling:** Calendar view, waiting lists, and session management.
- **Finance:** Income/Expense tracking, recurring charges, and linking transactions to sessions.
- **Inventory:** Basic item tracking.
- **Settings:** Cloud backups and profile settings.
- **Recent Updates:** A migration to a `Session` based model allows for better tracking of multi-visit treatments.

## 3. Critical Missing Features (The "Dentist" Specifics)
The current application is a generic "Clinic Manager" rather than a specific "Dental Manager". To be a true tool for dentists, it misses the following core components:

### A. Odontogram (Teeth Charting) [CRTIICAL]
- **Current State:** No existant logic for teeth.
- **Requirement:** An interactive visual representation of the mouth (Adult/Child dentition).
- **Functionality:**
    - Ability to select specific teeth (e.g., #18, #30).
    - Mark conditions (Caries, Missing, Endodontic treatment).
    - Mark existing restorations (Amalgam, Composite, Crown).
    - Link treatments directly to specific teeth.

### B. Treatment Planning
- **Current State:** `Patient` model has simple string fields for `diagnosis` and `treatment`.
- **Requirement:** A structured "Plan" capability.
    - Create a treatment plan containing multiple procedures.
    - Phase management (e.g., Phase 1: Hygiene, Phase 2: Restorative).
    - Cost estimation per plan vs. per single visit.

### C. Prescriptions (Rx)
- **Current State:** Non-existent.
- **Requirement:**
    - Module to generate PDF prescriptions.
    - Database of common drugs/dosages.
    - Template management.

### D. Lab Order Management
- **Current State:** Non-existent.
- **Requirement:** Tracking of prosthetics (Crowns, Dentures) sent to external labs (Sent Date, Due Date, Status: In-Lab/Received).

## 4. Proposed Enhancements

### A. Structured Medical History (Anamnesis)
Instead of a simple string `healthState`, implement a questionnaire:
- *Are you diabetic?* (Yes/No + details)
- *Do you have heart conditions?*
- *Allergies?* (e.g., Penicillin, Latex)
These should appear as "Red Flags" on the appointment screen (already partially implemented with `healthAlerts`, but can be more structured).

### B. Inventory Linkage
Automatically deduct inventory items when a treatment is performed (e.g., deduct "1x Anesthesia Cartridge" when "Extraction" is performed).

### C. Insurance Logic
There is a `PaymentMethod.insurance` enum, but no logic to track:
- Coverage percentages (e.g., Insurance covers 80%).
- Deductibles.
- Claim status tracking.

## Summary
The "skeleton" is excellent. The next phase of development should focus strictly on **dental domain specifics**, starting with the **Odontogram**, as this is the primary interface for any dentist.
