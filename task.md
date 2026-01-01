# 📋 MASTER TASK TRACKER: Trial & Crown Logic Refactoring

This file tracks the live progress of the "Dual-Key" system implementation and Trial restrictions.

## 🚀 Milestone 1: Core Logic & Identity
- [x] **Step 1.1**: Refactor `clinic_usage_provider.dart`. 
    - [x] Set `isCrown` to `SubscriptionPlan.enterprise` only.
    - [x] Create/Update `canUseAdvancedFeatures` logic (Added `isTrial` key).
    - [x] Strictly enforce 100 limit for non-premium (Patients/Appointments).
- [x] **Step 1.2**: Cross-file scan for `isCrown` dependencies.

## 🔒 Milestone 2: The Hard Lock (30-Day Guard)
- [x] **Step 2.1**: Update `main_layout.dart`.
    - [x] Implement `daysLeft <= 0` guard.
    - [x] Block tabs: Patients, Appointments, Inventory, Advanced.
    - [x] Add "Trial Expired" forced dialog.

## 🛠️ Milestone 3: Settings & Features
- [x] **Step 3.1**: Restrict `settings_screen.dart` buttons.
    - [x] Block "Restore from Local Backup".
    - [x] Block "Sync to Cloud".
    - [x] Block "Manage Cloud Backups".
    - [x] Add "Premium Required" feedback.
- [x] **Step 3.2**: Update `patient_profile_screen.dart`.
    - [x] Enable Prescriptions for Trial users.

## 🌐 Milestone 4: Website & Quality

- [x] **Step 4.1**: Align `WEBSITE.md` content with new rules.

- [x] **Step 4.2**: Final Quality Audit.

    - [x] Run `flutter analyze`.

    - [x] Achieve 0 errors, 0 warnings.
