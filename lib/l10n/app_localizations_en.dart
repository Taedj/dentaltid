// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboard => 'Dashboard';

  @override
  String get patients => 'Patients';

  @override
  String get appointments => 'Appointments';

  @override
  String get inventory => 'Inventory';

  @override
  String get finance => 'Finance';

  @override
  String get addAppointment => 'Add Appointment';

  @override
  String get editAppointment => 'Edit Appointment';

  @override
  String get patient => 'Patient';

  @override
  String get selectPatient => 'Please select a patient';

  @override
  String get dateYYYYMMDD => 'Date (YYYY-MM-DD)';

  @override
  String get enterDate => 'Please enter a date';

  @override
  String get invalidDateFormat =>
      'Please enter a valid date in YYYY-MM-DD format';

  @override
  String get invalidDate => 'Invalid Date';

  @override
  String get dateInPast => 'Date cannot be in the past';

  @override
  String get timeHHMM => 'Time (HH:MM)';

  @override
  String get enterTime => 'Please enter a time';

  @override
  String get invalidTimeFormat => 'Please enter a valid time in HH:MM format';

  @override
  String get add => 'Add';

  @override
  String get update => 'Update';

  @override
  String get error => 'Error: ';

  @override
  String invalidTime(Object end, Object start) {
    return 'Time must be between $start and $end';
  }

  @override
  String get appointmentExistsError =>
      'An appointment for this patient at this date and time already exists.';

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get changePassword => 'Change Password';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get invalidPassword => 'Invalid password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get localBackup => 'Local Backup';

  @override
  String get backupCreatedAt => 'Backup created at';

  @override
  String get backupFailedOrCancelled => 'Backup failed or cancelled';

  @override
  String get createLocalBackup => 'Create Local Backup';

  @override
  String get backupRestoredSuccessfully => 'Backup restored successfully';

  @override
  String get restoreFailedOrCancelled => 'Restore failed or cancelled';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get backupUploadedToCloud => 'Backup uploaded to cloud';

  @override
  String get cloudBackupFailed => 'Cloud backup failed';

  @override
  String get syncToCloud => 'Sync to Cloud';

  @override
  String get manageCloudBackups => 'Manage Cloud Backups';

  @override
  String get currency => 'Currency';

  @override
  String get logout => 'Logout';

  @override
  String get showAllAppointments => 'Show All Appointments';

  @override
  String get showUpcomingOnly => 'Show Upcoming Only';

  @override
  String get timeEarliestFirst => 'Time (Earliest First)';

  @override
  String get timeLatestFirst => 'Time (Latest First)';

  @override
  String get patientId => 'Patient ID';

  @override
  String get searchAppointments => 'Search Appointments';

  @override
  String get noAppointmentsFound => 'No appointments found';

  @override
  String get deleteAppointment => 'Delete Appointment';

  @override
  String get confirmDeleteAppointment =>
      'Are you sure you want to delete this appointment?';

  @override
  String get confirm => 'Confirm';

  @override
  String get welcomeDr => 'Welcome Dr.';

  @override
  String get welcome => 'Welcome';

  @override
  String get totalNumberOfPatients => 'Total Number of Patients';

  @override
  String get emergencyPatients => 'Emergency Patients';

  @override
  String get upcomingAppointments => 'Upcoming Appointments';

  @override
  String get payments => 'Payments';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get emergencyAlerts => 'Emergency Alerts';

  @override
  String get noEmergencies => 'No Emergencies';

  @override
  String get receipt => 'Receipt';

  @override
  String get total => 'Total';

  @override
  String get outstandingAmount => 'Outstanding Amount';

  @override
  String get close => 'Close';

  @override
  String get addPatient => 'Add Patient';

  @override
  String get editPatient => 'Edit Patient';

  @override
  String get familyName => 'Family Name';

  @override
  String get enterFamilyName => 'Please enter family name';

  @override
  String get age => 'Age';

  @override
  String get enterAge => 'Please enter age';

  @override
  String get enterValidNumber => 'Please enter a valid number';

  @override
  String get enterAgeBetween => 'Please enter age between 1 and 120';

  @override
  String get healthState => 'Health State';

  @override
  String get diagnosis => 'Diagnosis';

  @override
  String get treatment => 'Treatment';

  @override
  String get payment => 'Payment';

  @override
  String get enterPaymentAmount => 'Please enter payment amount';

  @override
  String get paymentCannotBeNegative => 'Payment cannot be negative';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterValidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get emergencyDetails => 'Emergency Details';

  @override
  String get isEmergency => 'Is Emergency';

  @override
  String get severity => 'Severity';

  @override
  String get healthAlerts => 'Health Alerts';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get noPaymentHistory => 'No payment history';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get noPatientsYet => 'No patients yet';

  @override
  String get noHealthAlerts => 'No health alerts';

  @override
  String get createdAt => 'Created At';

  @override
  String get emergency => 'Emergency';

  @override
  String get number => 'Number';

  @override
  String get actions => 'Actions';

  @override
  String get deletePatient => 'Delete Patient';

  @override
  String get confirmDeletePatient =>
      'Are you sure you want to delete this patient?';

  @override
  String get todaysAppointmentsFlow => 'Today\'s Appointments';

  @override
  String get waiting => 'Waiting';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get mustBeLoggedInToSync =>
      'You must be logged in to sync to the cloud.';

  @override
  String get dateNewestFirst => 'Date (Newest First)';

  @override
  String get dateOldestFirst => 'Date (Oldest First)';

  @override
  String get startAppointment => 'Start Appointment';

  @override
  String get completeAppointment => 'Complete Appointment';

  @override
  String get cancelAppointment => 'Cancel Appointment';

  @override
  String get confirmCancelAppointment =>
      'Are you sure you want to cancel this appointment?';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get financialSummary => 'Financial Summary';

  @override
  String get description => 'Description';

  @override
  String get enterDescription => 'Please enter a description';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get enterTotalAmount => 'Please enter total amount';

  @override
  String get enterValidPositiveAmount => 'Please enter a valid positive amount';

  @override
  String get paidAmount => 'Paid Amount';

  @override
  String get enterPaidAmount => 'Please enter paid amount';

  @override
  String get enterValidNonNegativeAmount =>
      'Please enter a valid non-negative amount';

  @override
  String get type => 'Type';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get bankTransfer => 'Bank Transfer';

  @override
  String get searchTransactions => 'Search Transactions';

  @override
  String get allTypes => 'All Types';

  @override
  String get amountHighestFirst => 'Amount (Highest First)';

  @override
  String get amountLowestFirst => 'Amount (Lowest First)';

  @override
  String get showAllItems => 'Show All Items';

  @override
  String get showExpiredOnly => 'Show Expired Only';

  @override
  String get showLowStockOnly => 'Show Low Stock Only';

  @override
  String get nameAZ => 'Name (A-Z)';

  @override
  String get nameZA => 'Name (Z-A)';

  @override
  String get quantityLowToHigh => 'Quantity (Low to High)';

  @override
  String get quantityHighToLow => 'Quantity (High to Low)';

  @override
  String get expirySoonestFirst => 'Expiry (Soonest First)';

  @override
  String get expiryLatestFirst => 'Expiry (Latest First)';

  @override
  String get searchInventoryItems => 'Search Inventory Items';

  @override
  String get name => 'Name';

  @override
  String get quantity => 'Quantity';

  @override
  String get expirationDate => 'Expiration Date';

  @override
  String get supplier => 'Supplier';

  @override
  String get addItem => 'Add Item';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get expires => 'Expires';

  @override
  String get expired => 'Expired';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get deleteItem => 'Delete Item';

  @override
  String get deleteItemButton => 'Delete';

  @override
  String get confirmDeleteItem => 'Are you sure you want to delete this item?';

  @override
  String get cancel => 'Cancel';

  @override
  String get enterName => 'Please enter a name';

  @override
  String get enterQuantity => 'Please enter a quantity';

  @override
  String get enterSupplier => 'Please enter a supplier';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get restoreFromLocalBackup => 'Restore from Local Backup';

  @override
  String get date => 'Date';

  @override
  String get method => 'Method';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get visitHistory => 'Visit History';

  @override
  String get noVisitHistory => 'No visit history';

  @override
  String get visitDate => 'Visit Date';

  @override
  String get reasonForVisit => 'Reason for Visit';

  @override
  String get addVisit => 'Add Visit';

  @override
  String get editVisit => 'Edit Visit';

  @override
  String get notes => 'Notes';

  @override
  String get enterReasonForVisit => 'Please enter a reason for visit';

  @override
  String get searchPatient => 'Search Patient';

  @override
  String get showCurrentDayPatients => 'Show Current Day Patients';

  @override
  String get visitDetails => 'Visit Details';

  @override
  String get createNewVisit => 'Create New Visit';

  @override
  String get selectExistingVisit => 'Select Existing Visit';

  @override
  String get requiredField => 'This field is required';

  @override
  String get emergencySeverity => 'Emergency Severity';

  @override
  String get sessionDetails => 'Session Details';

  @override
  String get numberOfSessions => 'Number of Sessions';

  @override
  String get session => 'Session';

  @override
  String get dateTime => 'Date & Time';

  @override
  String get treatmentDetails => 'Treatment Details';

  @override
  String get patientNotes => 'Patient Notes';

  @override
  String get blacklistPatient => 'Blacklist Patient';

  @override
  String get noTransactionsFound => 'No transactions found for this period';

  @override
  String get recurringCharges => 'Recurring Charges';

  @override
  String get noRecurringChargesFound => 'No recurring charges found';

  @override
  String get addRecurringCharge => 'Add Recurring Charge';

  @override
  String get editRecurringCharge => 'Edit Recurring Charge';

  @override
  String get amount => 'Amount';

  @override
  String get frequency => 'Frequency';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get isActive => 'Is Active';

  @override
  String get transactions => 'Transactions';

  @override
  String get overview => 'Overview';

  @override
  String get dailySummary => 'Daily Summary';

  @override
  String get weeklySummary => 'Weekly Summary';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get yearlySummary => 'Yearly Summary';

  @override
  String get expenses => 'Expenses';

  @override
  String get profit => 'Profit';

  @override
  String get filters => 'Filters';

  @override
  String get inventoryExpenses => 'Inventory Expenses';

  @override
  String get staffSalaries => 'Staff Salaries';

  @override
  String get rent => 'Rent';

  @override
  String get changeDate => 'Change Date';

  @override
  String get transactionAddedSuccessfully => 'Transaction added successfully';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get viewDetails => 'View Details';

  @override
  String get criticalAlerts => 'Critical Alerts';

  @override
  String get viewCritical => 'View Critical';

  @override
  String get viewAppointments => 'View Appointments';

  @override
  String todayCount(int count) {
    return 'Today: $count';
  }

  @override
  String waitingCount(int count) {
    return 'Waiting: $count';
  }

  @override
  String inProgressCount(int count) {
    return 'In Progress: $count';
  }

  @override
  String completedCount(int count) {
    return 'Completed: $count';
  }

  @override
  String emergencyCountLabel(int count) {
    return 'Emergency: $count';
  }

  @override
  String get expiringSoon => 'Expiring Soon';

  @override
  String expiringSoonCount(int count) {
    return 'Expiring Soon: $count';
  }

  @override
  String lowStockCount(int count) {
    return 'Low Stock: $count';
  }

  @override
  String get patientName => 'Patient Name';

  @override
  String get itemName => 'Item Name';

  @override
  String get countdown => 'Countdown';

  @override
  String get currentQuantity => 'Current Quantity';

  @override
  String daysLeft(int days) {
    return '${days}d left';
  }

  @override
  String get noPatientsToday => 'No patients today';

  @override
  String get noExpiringSoonItems => 'No Expiring Soon items';

  @override
  String get noLowStockItems => 'No Low Stock items';

  @override
  String get noWaitingAppointments => 'No Waiting appointments';

  @override
  String get noEmergencyAppointments => 'No Emergency appointments';

  @override
  String get noCompletedAppointments => 'No Completed appointments';

  @override
  String get errorLoadingEmergencyAppointments =>
      'Error loading emergency appointments';

  @override
  String get errorLoadingAppointments => 'Error loading appointments';

  @override
  String get errorLoadingPatientData => 'Error loading patient data';

  @override
  String get errorLoadingInventory => 'Error loading inventory';

  @override
  String get dateOfBirthLabel => 'Date of Birth';

  @override
  String get selectDateOfBirthError => 'Please select date of birth';

  @override
  String get invalidDateFormatError => 'Invalid date format';

  @override
  String get patientSelectionTitle => 'Patient Selection';

  @override
  String get choosePatientLabel => 'Choose Patient';

  @override
  String get selectPatientLabel => 'Select Patient';

  @override
  String get addNewPatientButton => 'Add New Patient';

  @override
  String get appointmentDateTimeTitle => 'Appointment Date & Time';

  @override
  String get dateTimeLabel => 'Date & Time';

  @override
  String get selectDateTimeLabel => 'Select Date & Time';

  @override
  String get selectDateTimeError => 'Please select date and time';

  @override
  String get appointmentTypeTitle => 'Appointment Type';

  @override
  String get selectTypeLabel => 'Select Type';

  @override
  String get paymentStatusTitle => 'Payment Status';

  @override
  String get consultationType => 'Consultation';

  @override
  String get followupType => 'Follow-up';

  @override
  String get emergencyType => 'Emergency';

  @override
  String get procedureType => 'Procedure';

  @override
  String get failedToSaveItemError => 'Failed to save item';

  @override
  String get failedToUseItemError => 'Failed to use item';

  @override
  String get failedToDeleteItemError => 'Failed to delete item';

  @override
  String get useTooltip => 'Use';

  @override
  String get periodToday => 'Today';

  @override
  String get periodThisWeek => 'This Week';

  @override
  String get periodThisMonth => 'This Month';

  @override
  String get periodThisYear => 'This Year';

  @override
  String get periodGlobal => 'Global';

  @override
  String get periodCustom => 'Custom';

  @override
  String get periodCustomDate => 'Custom Date';

  @override
  String get incomeTitle => 'Income';

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get netProfitTitle => 'Net Profit';

  @override
  String get taxLabel => 'Tax';

  @override
  String get monthlyBudgetTitle => 'Monthly Budget';

  @override
  String get budgetExceededAlert => 'Budget exceeded!';

  @override
  String get recurringChargesTooltip => 'Recurring Charges';

  @override
  String get financeSettingsTooltip => 'Finance Settings';

  @override
  String get incomeType => 'Income';

  @override
  String get expenseType => 'Expense';

  @override
  String get dateLabel => 'Date';

  @override
  String get categoryLabel => 'Category';

  @override
  String get deleteRecurringChargeTitle => 'Delete Recurring Charge';

  @override
  String get deleteRecurringChargeContent =>
      'Are you sure you want to delete this recurring charge?';

  @override
  String get transactionAddedSuccess => 'Transaction added successfully';

  @override
  String get catRent => 'Rent';

  @override
  String get catSalaries => 'Salaries';

  @override
  String get catInventory => 'Inventory';

  @override
  String get catEquipment => 'Equipment';

  @override
  String get catMarketing => 'Marketing';

  @override
  String get catUtilities => 'Utilities';

  @override
  String get catMaintenance => 'Maintenance';

  @override
  String get catTaxes => 'Taxes';

  @override
  String get catOther => 'Other';

  @override
  String get catProductSales => 'Product Sales';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqQuarterly => 'Quarterly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String get freqCustom => 'Custom';

  @override
  String get errorSavingRecurringCharge => 'Error saving recurring charge';

  @override
  String get editItem => 'Edit Item';

  @override
  String get costPerUnit => 'Cost per Unit';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get costType => 'Cost Type';

  @override
  String calculatedUnitCost(String currency, String cost) {
    return 'Calculated Unit Cost: $currency$cost';
  }

  @override
  String get enterCost => 'Please enter cost';

  @override
  String get expiresDays => 'Expires (Days)';

  @override
  String get lowStockLevel => 'Low Stock Level';

  @override
  String useItemTitle(String itemName) {
    return 'Use $itemName';
  }

  @override
  String currentStock(int quantity) {
    return 'Current Stock: $quantity';
  }

  @override
  String get quantityToUse => 'Quantity to Use';

  @override
  String get unitsSuffix => 'units';

  @override
  String get enterValidPositiveNumber => 'Please enter a valid positive number';

  @override
  String get cannotUseMoreThanStock => 'Cannot use more than current stock';

  @override
  String remainingStock(int quantity) {
    return 'Remaining Stock: $quantity';
  }

  @override
  String get confirmUse => 'Confirm Use';

  @override
  String get filterAll => 'All';

  @override
  String get filterToday => 'Today';

  @override
  String get filterThisWeek => 'This Week';

  @override
  String get filterThisMonth => 'This Month';

  @override
  String get filterEmergency => 'Emergency';

  @override
  String get patientIdHeader => 'ID';

  @override
  String get dueHeader => 'Due';

  @override
  String get totalCostLabel => 'Total Cost (\$)';

  @override
  String get amountPaidLabel => 'Amount Paid (\$)';

  @override
  String get balanceDueLabel => 'Balance Due';

  @override
  String get visitHistoryTitle => 'Visit History';

  @override
  String lastVisitLabel(String date) {
    return 'Last visit: $date';
  }

  @override
  String get selectPatientToViewHistory =>
      'Select a patient to view\nvisit history';

  @override
  String get addEditButton => 'Add/Edit';

  @override
  String get saveButton => 'Save';

  @override
  String get profitTrend => 'Profit Trend';

  @override
  String get expenseBreakdown => 'Expense Breakdown';

  @override
  String get noExpensesInPeriod => 'No expenses in this period';

  @override
  String get noDataToDisplay => 'No data to display';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get unknownPatient => 'Unknown Patient';

  @override
  String get loading => 'Loading...';

  @override
  String get errorLabel => 'Error';

  @override
  String get delete => 'Delete';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get premiumAccount => 'Premium Account';

  @override
  String premiumDaysLeft(int days) {
    return 'Premium: $days days left';
  }

  @override
  String get premiumExpired => 'Premium Expired';

  @override
  String trialVersionDaysLeft(int days) {
    return 'Trial Version: $days days left';
  }

  @override
  String get trialExpired => 'Trial Expired';

  @override
  String get activatePremium => 'Activate Premium';

  @override
  String get financeSettings => 'Finance Settings';

  @override
  String get includeInventoryCosts => 'Include Inventory Costs';

  @override
  String get includeAppointments => 'Include Appointments';

  @override
  String get includeRecurringCharges => 'Include Recurring Charges';

  @override
  String get compactNumbers => 'Compact Numbers (e.g. 1K)';

  @override
  String get compactNumbersSubtitle => 'Use short format for large numbers';

  @override
  String get monthlyBudgetCap => 'Monthly Budget Cap';

  @override
  String get taxRatePercentage => 'Tax Rate (%)';

  @override
  String get staffManagement => 'Staff Management';

  @override
  String get addAssistant => 'Add Assistant';

  @override
  String get addReceptionist => 'Add Receptionist';

  @override
  String get currentStaff => 'Current Staff';

  @override
  String get noStaffAdded => 'No staff members added yet';

  @override
  String get changePin => 'Change PIN';

  @override
  String get removeStaff => 'Remove Staff';

  @override
  String get updatePin => 'Update PIN';

  @override
  String get newPin => 'New PIN (4 digits)';

  @override
  String get username => 'Username';

  @override
  String get enterUsername => 'Enter username for staff member';

  @override
  String get addStaff => 'Add Staff';

  @override
  String get staffAddedSuccess => 'Staff member added successfully';

  @override
  String get staffRemovedSuccess => 'Staff member removed';

  @override
  String get pinUpdatedSuccess => 'PIN updated successfully';

  @override
  String get deleteStaffTitle => 'Delete Staff Member';

  @override
  String deleteStaffConfirm(String username) {
    return 'Are you sure you want to remove $username?';
  }

  @override
  String get roleAssistant => 'Assistant';

  @override
  String get roleReceptionist => 'Receptionist';

  @override
  String get roleDentist => 'Dentist';

  @override
  String get roleDeveloper => 'Developer';

  @override
  String overpaid(String amount) {
    return 'Overpaid: $amount';
  }

  @override
  String due(String amount) {
    return 'Due: $amount';
  }

  @override
  String get fullyPaid => 'Fully Paid';

  @override
  String appointmentPaymentDescription(String type) {
    return 'Appointment payment for $type';
  }

  @override
  String get proratedLabel => 'Pro-rated';

  @override
  String get days => 'days';

  @override
  String get status => 'Status';

  @override
  String get deleteVisit => 'Delete Visit';
}
