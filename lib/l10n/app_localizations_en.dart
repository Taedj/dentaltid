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
  String get advanced => 'Advanced';

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
  String get activatePremium => 'Upgrade your plan';

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

  @override
  String get connectionSettings => 'Connection Settings';

  @override
  String get networkConnection => 'Network Connection';

  @override
  String get serverDeviceNotice =>
      'This device is the SERVER. Share the IP below with staff devices.';

  @override
  String get clientDeviceNotice =>
      'This device is a CLIENT. Enter the Server IP to connect.';

  @override
  String get connectionStatus => 'Connection Status';

  @override
  String get possibleIpAddresses => 'Possible IP Addresses:';

  @override
  String get manualConnection => 'Manual Connection';

  @override
  String get serverIpAddress => 'Server IP Address';

  @override
  String get connectToServer => 'Connect to Server';

  @override
  String get connecting => 'Connecting...';

  @override
  String get connectedSync => 'Connected! Initializing sync...';

  @override
  String get invalidIpOrPort => 'Invalid IP or Port';

  @override
  String get firewallWarning =>
      'If connection fails, check your Windows Firewall to allow \'DentalTid\' on Private/Public networks.';

  @override
  String get readyToConnect => 'Ready to connect.';

  @override
  String get serverRunning => 'Server Running';

  @override
  String get serverStopped => 'Server Stopped';

  @override
  String get startServer => 'Start Server';

  @override
  String get stopServer => 'Stop Server';

  @override
  String get serverLogs => 'Server Logs';

  @override
  String get copyLogsSuccess => 'Logs copied to clipboard';

  @override
  String get port => 'Port';

  @override
  String get acceptTermsError => 'Please accept the terms and conditions';

  @override
  String get dentistLogin => 'Dentist Login';

  @override
  String get dentistRegistration => 'Dentist Registration';

  @override
  String get staffPortal => 'Staff Portal';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get authError => 'An error occurred, please check your credentials.';

  @override
  String get weakPasswordError => 'The password provided is too weak.';

  @override
  String get emailInUseError => 'An account already exists for that email.';

  @override
  String get userNotFoundError => 'No user found for that email.';

  @override
  String get wrongPasswordError => 'Wrong password provided for that user.';

  @override
  String get networkError => 'Network error. check your connection.';

  @override
  String authFailed(String error) {
    return 'Authentication failed: $error';
  }

  @override
  String get invalidStaffCredentials => 'Invalid Username or PIN';

  @override
  String get enterEmailFirst => 'Please enter your email address first';

  @override
  String get passwordResetSent =>
      'Password reset email sent! Check your inbox.';

  @override
  String get contactDeveloperLabel => 'Contact Developer';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get dentist => 'Dentist';

  @override
  String get staff => 'Staff';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get yourName => 'Your Name';

  @override
  String get clinicNameLabel => 'Clinic Name';

  @override
  String get licenseNumber => 'License Number';

  @override
  String get acceptTermsAndConditions => 'I accept the Terms and Conditions';

  @override
  String get pin4Digits => 'PIN (4 Digits)';

  @override
  String get signIn => 'SIGN IN';

  @override
  String get register => 'REGISTER';

  @override
  String get loginLabel => 'LOGIN';

  @override
  String get rememberLabel => 'Remember';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signUpSmall => 'Sign up';

  @override
  String get signInSmall => 'Sign in';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get scheduledVisits => 'Scheduled Visits';

  @override
  String get actionNeeded => 'Action Needed';

  @override
  String get allGood => 'All Good';

  @override
  String activeStatus(int count) {
    return 'Active: $count';
  }

  @override
  String doneStatus(int count) {
    return 'Done: $count';
  }

  @override
  String get clinicRunningSmoothly => 'Clinic running smoothly today 🦷';

  @override
  String expiringLabel(int count) {
    return '$count Expiring';
  }

  @override
  String lowStockLabelText(int count) {
    return '$count Low Stock';
  }

  @override
  String get staffActivationNotice =>
      'The main dentist user must activate premium to continue using the application.';

  @override
  String get overviewMenu => 'Overview';

  @override
  String get usersMenu => 'Users';

  @override
  String get codesMenu => 'Codes';

  @override
  String get broadcastsMenu => 'Broadcasts';

  @override
  String get serverOnlineNoStaff => 'Server Online (No staff connected)';

  @override
  String serverOnlineWithStaffCount(int count) {
    return 'Server Online ($count staff connected)';
  }

  @override
  String staffConnectedList(String names) {
    return 'Connected: $names';
  }

  @override
  String get connectedToServer => 'Connected to Server';

  @override
  String get offline => 'Offline';

  @override
  String get invalidCodeLength => 'Invalid code length (must be 27 characters)';

  @override
  String get activationSuccess =>
      'Account Activated Successfully! Premium features are now enabled.';

  @override
  String get invalidActivationCode => 'Invalid or expired activation code';

  @override
  String activationError(String error) {
    return 'Error during activation: $error';
  }

  @override
  String get activationRequired => 'Activation Required';

  @override
  String get trialExpiredNotice =>
      'Your trial period has expired. Please enter a valid activation code to continue using DentalTid Premium.';

  @override
  String get activationCodeLabel => 'Activation Code (27 chars)';

  @override
  String get needACode => 'Need a code?';

  @override
  String get editDoctorProfile => 'Edit Doctor Profile';

  @override
  String get updateYourProfile => 'Update Your Profile';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get enterYourName => 'Please enter your name';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully!';

  @override
  String profileUpdateError(String error) {
    return 'Failed to save profile: $error';
  }

  @override
  String get loginToSaveProfileError =>
      'Could not save profile. User not logged in.';

  @override
  String get required => 'Required';

  @override
  String get mustBe4Digits => 'Must be 4 digits';

  @override
  String get editStaff => 'Edit Staff';

  @override
  String get addNewStaff => 'Add New Staff';

  @override
  String get fullName => 'Full Name';

  @override
  String get systemHealth => 'System Health';

  @override
  String get developerOverview => 'Developer Overview';

  @override
  String get totalUsers => 'Total Users';

  @override
  String get activeTrials => 'Active Trials';

  @override
  String get estRevenue => 'Est. Revenue';

  @override
  String noPatientsFoundSearch(String query) {
    return 'No patients found matching \"$query\"';
  }

  @override
  String get paidStatusLabel => 'Paid';

  @override
  String get searchHintSeparator => 'or Phone...';

  @override
  String get savePatientsCsvLabel => 'Save Patients CSV';

  @override
  String get localBackupConfirm =>
      'This backup will include your clinic database, app settings, and staff accounts. Do you want to proceed?';

  @override
  String get premiumOnly => 'Premium Only';

  @override
  String get cloudSyncConfirm =>
      'This will upload your clinic database, settings, and staff accounts to the cloud for safe keeping. Do you want to proceed?';

  @override
  String get cloudSyncPremiumNotice =>
      'Cloud Sync is a detailed Premium feature. Activate to enable.';

  @override
  String get manageStaffMembers => 'Manage Staff Members';

  @override
  String get addStaffSubtitle => 'Add Assistants or Receptionists';

  @override
  String get lanSyncSettings => 'LAN Sync Settings';

  @override
  String get autoStartServerLabel => 'Auto-start Server';

  @override
  String get autoStartServerSubtitle => 'Start sync server on app launch';

  @override
  String get serverPortLabel => 'Server Port';

  @override
  String get defaultPortHelper => 'Default: 8080';

  @override
  String get advancedNetworkConfig => 'Advanced Network Configuration';

  @override
  String get advancedNetworkConfigSubtitle => 'Logs, Firewall, and IP settings';

  @override
  String errorLoadingProfile(String error) {
    return 'Error loading user profile: $error';
  }

  @override
  String get deleteTransactionConfirm =>
      'Are you sure you want to delete this transaction?';

  @override
  String get transactionDeletedSuccess => 'Transaction deleted successfully';

  @override
  String get limitReached => 'Limit Reached';

  @override
  String get inventoryLimitMessage =>
      'You have reached the limit of 100 inventory items for the Trial version.\nPlease upgrade to Premium to continue adding items.';

  @override
  String get okButton => 'OK';

  @override
  String get trialActive => 'Trial Active';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Please enter an email';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get enterPassword => 'Please enter a password';

  @override
  String get clinicAddress => 'Clinic Address';

  @override
  String get enterClinicAddress => 'Please enter clinic address';

  @override
  String get province => 'Province';

  @override
  String get enterProvince => 'Please enter province';

  @override
  String get country => 'Country';

  @override
  String get enterCountry => 'Please enter country';

  @override
  String get supplierContact => 'Supplier Contact';

  @override
  String get enterSupplierContact => 'Enter supplier info';

  @override
  String get addLabel => 'Add Label';

  @override
  String get intraoralXrayDefault => 'Intraoral X-Ray';

  @override
  String get clinicalObservationHint => 'Enter clinical observations here...';

  @override
  String get selectSensorLabel => 'Select Sensor/Scanner';

  @override
  String get initiateCapture => 'Initiate Capture';

  @override
  String get saveToPatientRecord => 'Save to Patient Record';

  @override
  String get scanFailed => 'Scan failed';

  @override
  String get saveCopySuccess => 'Saved copy successfully!';

  @override
  String usageLimitDisplay(Object current, Object max) {
    return '$current/$max';
  }

  @override
  String get negativeFilter => 'Negative';

  @override
  String todayCountLabel(Object count) {
    return 'Today: $count';
  }

  @override
  String waitingCountLabel(Object count) {
    return 'Waiting: $count';
  }

  @override
  String inProgressCountLabel(Object count) {
    return 'In Progress: $count';
  }

  @override
  String completedCountLabel(Object count) {
    return 'Completed: $count';
  }

  @override
  String get patientSelection => 'Patient Selection';

  @override
  String get appointmentDateTime => 'Appointment Date & Time';

  @override
  String get appointmentType => 'Appointment Type';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get incomeLabel => 'Income';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get category => 'Category';

  @override
  String get rentLabel => 'Rent';

  @override
  String get salariesLabel => 'Salaries';

  @override
  String get inventoryLabel => 'Inventory';

  @override
  String get equipmentLabel => 'Equipment';

  @override
  String get marketingLabel => 'Marketing';

  @override
  String get utilitiesLabel => 'Utilities';

  @override
  String get maintenanceLabel => 'Maintenance';

  @override
  String get taxesLabel => 'Taxes';

  @override
  String get otherLabel => 'Other';

  @override
  String get productSalesLabel => 'Product Sales';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get quarterly => 'Quarterly';

  @override
  String get yearly => 'Yearly';

  @override
  String get custom => 'Custom';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get updateProfile => 'Update Profile';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get deleteVisitConfirm =>
      'Are you sure you want to delete this visit?';

  @override
  String get actionNeededLabel => 'Action Needed';

  @override
  String get allGoodLabel => 'All Good';

  @override
  String get offlineLabel => 'Offline';

  @override
  String get activationRequiredTitle => 'Activation Required';

  @override
  String get needACodeLabel => 'Need a code?';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get premiumOnlyLabel => 'Premium Only';

  @override
  String get limitReachedTitle => 'Limit Reached';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get clinicAddressLabel => 'Clinic Address';

  @override
  String get provinceLabel => 'Province';

  @override
  String get countryLabel => 'Country';

  @override
  String get totalAmountLabel => 'Total Amount';

  @override
  String get paidAmountLabel => 'Paid Amount';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get dentistNotes => 'Dentist Notes';

  @override
  String get resetAll => 'Reset All';

  @override
  String get captureXray => 'Capture X-Ray';

  @override
  String get waitingForSensorHardware => 'Waiting for sensor hardware...';

  @override
  String get rotate90 => 'Rotate 90°';

  @override
  String get flipHorizontal => 'Flip Horizontal';

  @override
  String get sharpenFilter => 'Sharpen Filter';

  @override
  String get embossFilter => 'Emboss Filter';

  @override
  String get saveCopy => 'Save Copy';

  @override
  String get smartZoomTool => 'Smart Zoom Tool';

  @override
  String get measurementTool => 'Measurement Tool';

  @override
  String get draw => 'Draw';

  @override
  String get addText => 'Add Text';

  @override
  String get undo => 'Undo';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabVisits => 'Visits';

  @override
  String get tabImaging => 'Imaging';

  @override
  String get blacklist => 'Blacklist';

  @override
  String get emergencyLabel => 'Emergency';

  @override
  String get notEmergencyLabel => 'Not Emergency';

  @override
  String get blacklistedLabel => 'Blacklisted';

  @override
  String get notBlacklistedLabel => 'Not Blacklisted';

  @override
  String healthAlertsLabel(String alerts) {
    return 'Health Alerts: $alerts';
  }

  @override
  String get accessRestricted => 'Access Restricted';

  @override
  String get onlyDentistsImaging => 'Only dentists can view imaging records.';

  @override
  String imagingHistory(int count) {
    return 'Imaging History ($count)';
  }

  @override
  String get imagingStorage => 'Imaging Storage';

  @override
  String get defaultImagingPath => 'Default (Documents/DentalTid/Imaging)';

  @override
  String get imagingStorageSettings => 'Imaging Storage Settings';

  @override
  String get newXray => 'New X-Ray';

  @override
  String get gridView => 'Grid View';

  @override
  String get listView => 'List View';

  @override
  String columnsCount(int count) {
    return '$count columns';
  }

  @override
  String get sortBy => 'Sort by: ';

  @override
  String get noXraysFound => 'No X-Rays found for this patient';

  @override
  String get digitalSensor => 'Digital Sensor (TWAIN)';

  @override
  String get uploadFromFile => 'Upload from File';

  @override
  String get xrayLabel => 'X-Ray Label';

  @override
  String get renameXray => 'Rename X-Ray';

  @override
  String get deleteXrayConfirmTitle => 'Delete X-Ray?';

  @override
  String get deleteXrayWarning =>
      'This cannot be undone. The file will be permanently removed.';

  @override
  String capturedDate(Object date) {
    return 'Captured: $date';
  }

  @override
  String get importSuccess => 'Imported successfully';

  @override
  String importError(String error) {
    return 'Import failed: $error';
  }

  @override
  String exportSuccess(String path) {
    return 'Exported to $path';
  }

  @override
  String exportError(String error) {
    return 'Export failed: $error';
  }

  @override
  String get noNotes => 'No notes';

  @override
  String notesLabel(String notes) {
    return 'Notes: $notes';
  }

  @override
  String get nanopixSyncTitle => 'NanoPix Sync';

  @override
  String get nanopixSyncPathLabel => 'NanoPix Data Path';

  @override
  String get nanopixSyncPathNotSet => 'Not set';

  @override
  String get nanopixSyncNowButton => 'Sync Now';

  @override
  String get nanopixSyncStarted => 'Sync started...';
}
