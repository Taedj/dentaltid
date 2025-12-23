# DentalTid App - UI & Theme Analysis Report

## 1. Global Theme & Colors

The application uses `flutter/material.dart` with a custom `ThemeData`.

### Light Theme
*   **Base:** `ThemeData.light()`
*   **Color Scheme:** Generated from Seed `Colors.blue`.
    *   **Primary:** Blue variants.
*   **Card Theme:**
    *   **Elevation:** 2
    *   **Shape:** RoundedRectangleBorder (Radius: 16)

### Dark Theme
*   **Base:** `ThemeData.dark()`
*   **Color Scheme:** Generated from Seed `Colors.deepPurple`.
    *   **Primary:** Deep Purple variants.
*   **Card Theme:** Same as Light (Elevation 2, Radius 16).

### Custom App Colors (`AppColors`)
*   **Primary:** `Colors.blue` (Static definition).

---

## 2. Dashboard Screen (`HomeScreen`)

This is the central hub of the application with a distinct, visually rich design.

### UI Structure
*   **AppBar:** Standard, title "Dashboard".
*   **Body:** Column layout.
    1.  **Broadcast Banner:** Dynamic alert box.
    2.  **Header Section:** Date/Time and User Welcome/Status.
    3.  **Cards Section:** Row of 3D Flip Cards (Responsive width).

### Detailed Component Styling

#### A. Broadcast Banner
*   **Container:**
    *   **Background:** Color with 10% opacity (`alpha: 0.1`).
    *   **Border:** Solid Color.
    *   **Radius:** 8.
*   **Colors (Dynamic based on type):**
    *   `warning` -> **Orange**
    *   `maintenance` -> **Red**
    *   *default* -> **Blue**
*   **Typography:** Bold title, standard body text.

#### B. Header Section (Date & User)
*   **Date/Time:** Font size 20, Weight 500.
*   **Welcome Text:** Font size 28, Bold.
*   **Status Badge (Premium/Trial):**
    *   **Background:** Status Color with 10% opacity.
    *   **Border:** Solid Status Color.
    *   **Radius:** 20.
    *   **Text:** Bold, size 14.
    *   **Colors:**
        *   Premium Active: **Green**
        *   Premium Expired: **Red**
        *   Trial Active: **Orange**
        *   Trial Expired: **Red**
*   **Usage Dots (Trial only):**
    *   Similar pill shape (Radius 12), 10% opacity background.
    *   **Blue** (Normal) or **Red** (Limit Reached).

#### C. 3D Flip Cards (The Core UI)
These are the main navigational and informational elements. They feature a 3D rotation effect on hover.

*   **Common Card Style:**
    *   **Radius:** 20.
    *   **Shadow:** Black (Alpha 100), Blur 15.
    *   **Decorations:** 3 semi-transparent white circles overlaying the gradient.
*   **Typography:** White text for all card content.

**1. Patients Card**
*   **Gradient:** `Colors.blue.shade400` → `Colors.blue.shade800`.
*   **Icon:** `Icons.people` (White).
*   **Back Content:** List of today's patients.

**2. Critical Alerts (Inventory) Card**
*   **Gradient (Normal):** Dark Green (`#1E4D2B`) → Medium Green (`#2E5A3C`).
*   **Gradient (Alert - Expiring/Low Stock):** `Colors.red.shade400` → `Colors.red.shade800`.
*   **Icon:** `Icons.warning_amber`.
*   **Back Content:** Tabbed view for "Expiring Soon" vs "Low Stock".

**3. Appointments Card**
*   **Gradient:** `Colors.teal.shade400` → `Colors.teal.shade800`.
*   **Icon:** `Icons.access_time`.
*   **Back Content:** Tabbed view for Waiting, Emergency, Completed.

---

## 3. Feature Screens Overview

### Patients Screen
*   **Header:** Standard AppBar.
    *   **Usage Limit Badge:** Orange pill shape (Alpha 0.2 background).
*   **List View (Mobile < 600px):**
    *   **Card:** Standard Material Card.
    *   **Total Due Text:** **Red** (if > 0) else **Green**.
*   **Data Table (Desktop > 600px):**
    *   **Borders:** White (Alpha 100).
    *   **Text:** Follows theme (White/Black).
    *   **Total Due:** **Red** (if > 0) else **Green**.

### Appointments Screen
*   **Cards:**
    *   **Waiting:**
        *   **Border/Status:** **Blue** (Primary).
        *   **Icon:** Hourglass.
    *   **In Progress:**
        *   **Border/Status:** **Orange** (Secondary).
        *   **Icon:** Play Circle.
    *   **Completed:**
        *   **Background:** Surface color (Alpha 128).
        *   **Status/Icon:** **Green**.
    *   **Cancelled:**
        *   **Background:** Surface color (Alpha 128).
        *   **Status/Icon:** **Red** (Error).

### Finance Screen
*   **Filters:** `ChoiceChip` widgets.
*   **KPI Cards:**
    *   **Income:** **Green** Text.
    *   **Expenses:** **Red** Text.
    *   **Net Profit:** **Primary Blue** (Positive) or **Orange** (Negative).
*   **Budget Card:**
    *   **Progress Bar:** **Green** → **Orange** (>80%) → **Red** (Over Budget).
*   **Transaction List:**
    *   **Income:** **Green** Icon (Arrow Down) & Text.
    *   **Expense:** **Red** Icon (Arrow Up) & Text.
    *   **Background:** Surface Container Highest (Alpha 0.3).

---

## 4. UI/UX Summary for Modifications

When modifying the app, adhere to these patterns:

1.  **Translucency:** Use `Color.withValues(alpha: 0.1)` (or `0.2`) for backgrounds of badges, alerts, and pill-shaped containers. Keep borders solid.
2.  **Status Colors:**
    *   **Good/Income/Completed:** Green.
    *   **Warning/Trial/In Progress:** Orange.
    *   **Error/Expired/Cancelled/Expense:** Red.
    *   **Neutral/Info:** Blue (Primary).
3.  **Gradients:** Use linear gradients for primary "Hero" elements (like the Dashboard cards).
4.  **Responsive Design:** Always check for `LayoutBuilder` constraints (Mobile vs Desktop layouts).
