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
  String get todaysAppointmentsFlow => 'Today\'s Appointments Flow';

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
}
