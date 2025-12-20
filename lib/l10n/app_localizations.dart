import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @addAppointment.
  ///
  /// In en, this message translates to:
  /// **'Add Appointment'**
  String get addAppointment;

  /// No description provided for @editAppointment.
  ///
  /// In en, this message translates to:
  /// **'Edit Appointment'**
  String get editAppointment;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @selectPatient.
  ///
  /// In en, this message translates to:
  /// **'Please select a patient'**
  String get selectPatient;

  /// No description provided for @dateYYYYMMDD.
  ///
  /// In en, this message translates to:
  /// **'Date (YYYY-MM-DD)'**
  String get dateYYYYMMDD;

  /// No description provided for @enterDate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a date'**
  String get enterDate;

  /// No description provided for @invalidDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid date in YYYY-MM-DD format'**
  String get invalidDateFormat;

  /// No description provided for @invalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid Date'**
  String get invalidDate;

  /// No description provided for @dateInPast.
  ///
  /// In en, this message translates to:
  /// **'Date cannot be in the past'**
  String get dateInPast;

  /// No description provided for @timeHHMM.
  ///
  /// In en, this message translates to:
  /// **'Time (HH:MM)'**
  String get timeHHMM;

  /// No description provided for @enterTime.
  ///
  /// In en, this message translates to:
  /// **'Please enter a time'**
  String get enterTime;

  /// No description provided for @invalidTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid time in HH:MM format'**
  String get invalidTimeFormat;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get error;

  /// No description provided for @invalidTime.
  ///
  /// In en, this message translates to:
  /// **'Time must be between {start} and {end}'**
  String invalidTime(Object end, Object start);

  /// No description provided for @appointmentExistsError.
  ///
  /// In en, this message translates to:
  /// **'An appointment for this patient at this date and time already exists.'**
  String get appointmentExistsError;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid password'**
  String get invalidPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @localBackup.
  ///
  /// In en, this message translates to:
  /// **'Local Backup'**
  String get localBackup;

  /// No description provided for @backupCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Backup created at'**
  String get backupCreatedAt;

  /// No description provided for @backupFailedOrCancelled.
  ///
  /// In en, this message translates to:
  /// **'Backup failed or cancelled'**
  String get backupFailedOrCancelled;

  /// No description provided for @createLocalBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Local Backup'**
  String get createLocalBackup;

  /// No description provided for @backupRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully'**
  String get backupRestoredSuccessfully;

  /// No description provided for @restoreFailedOrCancelled.
  ///
  /// In en, this message translates to:
  /// **'Restore failed or cancelled'**
  String get restoreFailedOrCancelled;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @backupUploadedToCloud.
  ///
  /// In en, this message translates to:
  /// **'Backup uploaded to cloud'**
  String get backupUploadedToCloud;

  /// No description provided for @cloudBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup failed'**
  String get cloudBackupFailed;

  /// No description provided for @syncToCloud.
  ///
  /// In en, this message translates to:
  /// **'Sync to Cloud'**
  String get syncToCloud;

  /// No description provided for @manageCloudBackups.
  ///
  /// In en, this message translates to:
  /// **'Manage Cloud Backups'**
  String get manageCloudBackups;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @showAllAppointments.
  ///
  /// In en, this message translates to:
  /// **'Show All Appointments'**
  String get showAllAppointments;

  /// No description provided for @showUpcomingOnly.
  ///
  /// In en, this message translates to:
  /// **'Show Upcoming Only'**
  String get showUpcomingOnly;

  /// No description provided for @timeEarliestFirst.
  ///
  /// In en, this message translates to:
  /// **'Time (Earliest First)'**
  String get timeEarliestFirst;

  /// No description provided for @timeLatestFirst.
  ///
  /// In en, this message translates to:
  /// **'Time (Latest First)'**
  String get timeLatestFirst;

  /// No description provided for @patientId.
  ///
  /// In en, this message translates to:
  /// **'Patient ID'**
  String get patientId;

  /// No description provided for @searchAppointments.
  ///
  /// In en, this message translates to:
  /// **'Search Appointments'**
  String get searchAppointments;

  /// No description provided for @noAppointmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No appointments found'**
  String get noAppointmentsFound;

  /// No description provided for @deleteAppointment.
  ///
  /// In en, this message translates to:
  /// **'Delete Appointment'**
  String get deleteAppointment;

  /// No description provided for @confirmDeleteAppointment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this appointment?'**
  String get confirmDeleteAppointment;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @welcomeDr.
  ///
  /// In en, this message translates to:
  /// **'Welcome Dr.'**
  String get welcomeDr;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @totalNumberOfPatients.
  ///
  /// In en, this message translates to:
  /// **'Total Number of Patients'**
  String get totalNumberOfPatients;

  /// No description provided for @emergencyPatients.
  ///
  /// In en, this message translates to:
  /// **'Emergency Patients'**
  String get emergencyPatients;

  /// No description provided for @upcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointments'**
  String get upcomingAppointments;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @emergencyAlerts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alerts'**
  String get emergencyAlerts;

  /// No description provided for @noEmergencies.
  ///
  /// In en, this message translates to:
  /// **'No Emergencies'**
  String get noEmergencies;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @outstandingAmount.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Amount'**
  String get outstandingAmount;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @addPatient.
  ///
  /// In en, this message translates to:
  /// **'Add Patient'**
  String get addPatient;

  /// No description provided for @editPatient.
  ///
  /// In en, this message translates to:
  /// **'Edit Patient'**
  String get editPatient;

  /// No description provided for @familyName.
  ///
  /// In en, this message translates to:
  /// **'Family Name'**
  String get familyName;

  /// No description provided for @enterFamilyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter family name'**
  String get enterFamilyName;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @enterAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter age'**
  String get enterAge;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @enterAgeBetween.
  ///
  /// In en, this message translates to:
  /// **'Please enter age between 1 and 120'**
  String get enterAgeBetween;

  /// No description provided for @healthState.
  ///
  /// In en, this message translates to:
  /// **'Health State'**
  String get healthState;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosis;

  /// No description provided for @treatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatment;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @enterPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter payment amount'**
  String get enterPaymentAmount;

  /// No description provided for @paymentCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Payment cannot be negative'**
  String get paymentCannotBeNegative;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get enterValidPhoneNumber;

  /// No description provided for @emergencyDetails.
  ///
  /// In en, this message translates to:
  /// **'Emergency Details'**
  String get emergencyDetails;

  /// No description provided for @isEmergency.
  ///
  /// In en, this message translates to:
  /// **'Is Emergency'**
  String get isEmergency;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @healthAlerts.
  ///
  /// In en, this message translates to:
  /// **'Health Alerts'**
  String get healthAlerts;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @noPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'No payment history'**
  String get noPaymentHistory;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @noPatientsYet.
  ///
  /// In en, this message translates to:
  /// **'No patients yet'**
  String get noPatientsYet;

  /// No description provided for @noHealthAlerts.
  ///
  /// In en, this message translates to:
  /// **'No health alerts'**
  String get noHealthAlerts;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @deletePatient.
  ///
  /// In en, this message translates to:
  /// **'Delete Patient'**
  String get deletePatient;

  /// No description provided for @confirmDeletePatient.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this patient?'**
  String get confirmDeletePatient;

  /// No description provided for @todaysAppointmentsFlow.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Appointments'**
  String get todaysAppointmentsFlow;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @mustBeLoggedInToSync.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to sync to the cloud.'**
  String get mustBeLoggedInToSync;

  /// No description provided for @dateNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Date (Newest First)'**
  String get dateNewestFirst;

  /// No description provided for @dateOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Date (Oldest First)'**
  String get dateOldestFirst;

  /// No description provided for @startAppointment.
  ///
  /// In en, this message translates to:
  /// **'Start Appointment'**
  String get startAppointment;

  /// No description provided for @completeAppointment.
  ///
  /// In en, this message translates to:
  /// **'Complete Appointment'**
  String get completeAppointment;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// No description provided for @confirmCancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this appointment?'**
  String get confirmCancelAppointment;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @financialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get financialSummary;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get enterDescription;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @enterTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter total amount'**
  String get enterTotalAmount;

  /// No description provided for @enterValidPositiveAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive amount'**
  String get enterValidPositiveAmount;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @enterPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter paid amount'**
  String get enterPaidAmount;

  /// No description provided for @enterValidNonNegativeAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid non-negative amount'**
  String get enterValidNonNegativeAmount;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search Transactions'**
  String get searchTransactions;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @amountHighestFirst.
  ///
  /// In en, this message translates to:
  /// **'Amount (Highest First)'**
  String get amountHighestFirst;

  /// No description provided for @amountLowestFirst.
  ///
  /// In en, this message translates to:
  /// **'Amount (Lowest First)'**
  String get amountLowestFirst;

  /// No description provided for @showAllItems.
  ///
  /// In en, this message translates to:
  /// **'Show All Items'**
  String get showAllItems;

  /// No description provided for @showExpiredOnly.
  ///
  /// In en, this message translates to:
  /// **'Show Expired Only'**
  String get showExpiredOnly;

  /// No description provided for @showLowStockOnly.
  ///
  /// In en, this message translates to:
  /// **'Show Low Stock Only'**
  String get showLowStockOnly;

  /// No description provided for @nameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get nameAZ;

  /// No description provided for @nameZA.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get nameZA;

  /// No description provided for @quantityLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Quantity (Low to High)'**
  String get quantityLowToHigh;

  /// No description provided for @quantityHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Quantity (High to Low)'**
  String get quantityHighToLow;

  /// No description provided for @expirySoonestFirst.
  ///
  /// In en, this message translates to:
  /// **'Expiry (Soonest First)'**
  String get expirySoonestFirst;

  /// No description provided for @expiryLatestFirst.
  ///
  /// In en, this message translates to:
  /// **'Expiry (Latest First)'**
  String get expiryLatestFirst;

  /// No description provided for @searchInventoryItems.
  ///
  /// In en, this message translates to:
  /// **'Search Inventory Items'**
  String get searchInventoryItems;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @expirationDate.
  ///
  /// In en, this message translates to:
  /// **'Expiration Date'**
  String get expirationDate;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @deleteItemButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteItemButton;

  /// No description provided for @confirmDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirmDeleteItem;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get enterName;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a quantity'**
  String get enterQuantity;

  /// No description provided for @enterSupplier.
  ///
  /// In en, this message translates to:
  /// **'Please enter a supplier'**
  String get enterSupplier;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @restoreFromLocalBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Local Backup'**
  String get restoreFromLocalBackup;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @visitHistory.
  ///
  /// In en, this message translates to:
  /// **'Visit History'**
  String get visitHistory;

  /// No description provided for @noVisitHistory.
  ///
  /// In en, this message translates to:
  /// **'No visit history'**
  String get noVisitHistory;

  /// No description provided for @visitDate.
  ///
  /// In en, this message translates to:
  /// **'Visit Date'**
  String get visitDate;

  /// No description provided for @reasonForVisit.
  ///
  /// In en, this message translates to:
  /// **'Reason for Visit'**
  String get reasonForVisit;

  /// No description provided for @addVisit.
  ///
  /// In en, this message translates to:
  /// **'Add Visit'**
  String get addVisit;

  /// No description provided for @editVisit.
  ///
  /// In en, this message translates to:
  /// **'Edit Visit'**
  String get editVisit;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @enterReasonForVisit.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason for visit'**
  String get enterReasonForVisit;

  /// No description provided for @searchPatient.
  ///
  /// In en, this message translates to:
  /// **'Search Patient'**
  String get searchPatient;

  /// No description provided for @showCurrentDayPatients.
  ///
  /// In en, this message translates to:
  /// **'Show Current Day Patients'**
  String get showCurrentDayPatients;

  /// No description provided for @visitDetails.
  ///
  /// In en, this message translates to:
  /// **'Visit Details'**
  String get visitDetails;

  /// No description provided for @createNewVisit.
  ///
  /// In en, this message translates to:
  /// **'Create New Visit'**
  String get createNewVisit;

  /// No description provided for @selectExistingVisit.
  ///
  /// In en, this message translates to:
  /// **'Select Existing Visit'**
  String get selectExistingVisit;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @emergencySeverity.
  ///
  /// In en, this message translates to:
  /// **'Emergency Severity'**
  String get emergencySeverity;

  /// No description provided for @sessionDetails.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetails;

  /// No description provided for @numberOfSessions.
  ///
  /// In en, this message translates to:
  /// **'Number of Sessions'**
  String get numberOfSessions;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTime;

  /// No description provided for @treatmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Treatment Details'**
  String get treatmentDetails;

  /// No description provided for @patientNotes.
  ///
  /// In en, this message translates to:
  /// **'Patient Notes'**
  String get patientNotes;

  /// No description provided for @blacklistPatient.
  ///
  /// In en, this message translates to:
  /// **'Blacklist Patient'**
  String get blacklistPatient;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found for this period'**
  String get noTransactionsFound;

  /// No description provided for @recurringCharges.
  ///
  /// In en, this message translates to:
  /// **'Recurring Charges'**
  String get recurringCharges;

  /// No description provided for @noRecurringChargesFound.
  ///
  /// In en, this message translates to:
  /// **'No recurring charges found'**
  String get noRecurringChargesFound;

  /// No description provided for @addRecurringCharge.
  ///
  /// In en, this message translates to:
  /// **'Add Recurring Charge'**
  String get addRecurringCharge;

  /// No description provided for @editRecurringCharge.
  ///
  /// In en, this message translates to:
  /// **'Edit Recurring Charge'**
  String get editRecurringCharge;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @isActive.
  ///
  /// In en, this message translates to:
  /// **'Is Active'**
  String get isActive;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dailySummary;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @monthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get monthlySummary;

  /// No description provided for @yearlySummary.
  ///
  /// In en, this message translates to:
  /// **'Yearly Summary'**
  String get yearlySummary;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @inventoryExpenses.
  ///
  /// In en, this message translates to:
  /// **'Inventory Expenses'**
  String get inventoryExpenses;

  /// No description provided for @staffSalaries.
  ///
  /// In en, this message translates to:
  /// **'Staff Salaries'**
  String get staffSalaries;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @changeDate.
  ///
  /// In en, this message translates to:
  /// **'Change Date'**
  String get changeDate;

  /// No description provided for @transactionAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Transaction added successfully'**
  String get transactionAddedSuccessfully;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @criticalAlerts.
  ///
  /// In en, this message translates to:
  /// **'Critical Alerts'**
  String get criticalAlerts;

  /// No description provided for @viewCritical.
  ///
  /// In en, this message translates to:
  /// **'View Critical'**
  String get viewCritical;

  /// No description provided for @viewAppointments.
  ///
  /// In en, this message translates to:
  /// **'View Appointments'**
  String get viewAppointments;

  /// No description provided for @todayCount.
  ///
  /// In en, this message translates to:
  /// **'Today: {count}'**
  String todayCount(int count);

  /// No description provided for @waitingCount.
  ///
  /// In en, this message translates to:
  /// **'Waiting: {count}'**
  String waitingCount(int count);

  /// No description provided for @inProgressCount.
  ///
  /// In en, this message translates to:
  /// **'In Progress: {count}'**
  String inProgressCount(int count);

  /// No description provided for @completedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed: {count}'**
  String completedCount(int count);

  /// No description provided for @emergencyCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency: {count}'**
  String emergencyCountLabel(int count);

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get expiringSoon;

  /// No description provided for @expiringSoonCount.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon: {count}'**
  String expiringSoonCount(int count);

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'Low Stock: {count}'**
  String lowStockCount(int count);

  /// No description provided for @patientName.
  ///
  /// In en, this message translates to:
  /// **'Patient Name'**
  String get patientName;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @countdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get countdown;

  /// No description provided for @currentQuantity.
  ///
  /// In en, this message translates to:
  /// **'Current Quantity'**
  String get currentQuantity;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String daysLeft(int days);

  /// No description provided for @noPatientsToday.
  ///
  /// In en, this message translates to:
  /// **'No patients today'**
  String get noPatientsToday;

  /// No description provided for @noExpiringSoonItems.
  ///
  /// In en, this message translates to:
  /// **'No Expiring Soon items'**
  String get noExpiringSoonItems;

  /// No description provided for @noLowStockItems.
  ///
  /// In en, this message translates to:
  /// **'No Low Stock items'**
  String get noLowStockItems;

  /// No description provided for @noWaitingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No Waiting appointments'**
  String get noWaitingAppointments;

  /// No description provided for @noEmergencyAppointments.
  ///
  /// In en, this message translates to:
  /// **'No Emergency appointments'**
  String get noEmergencyAppointments;

  /// No description provided for @noCompletedAppointments.
  ///
  /// In en, this message translates to:
  /// **'No Completed appointments'**
  String get noCompletedAppointments;

  /// No description provided for @errorLoadingEmergencyAppointments.
  ///
  /// In en, this message translates to:
  /// **'Error loading emergency appointments'**
  String get errorLoadingEmergencyAppointments;

  /// No description provided for @errorLoadingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Error loading appointments'**
  String get errorLoadingAppointments;

  /// No description provided for @errorLoadingPatientData.
  ///
  /// In en, this message translates to:
  /// **'Error loading patient data'**
  String get errorLoadingPatientData;

  /// No description provided for @errorLoadingInventory.
  ///
  /// In en, this message translates to:
  /// **'Error loading inventory'**
  String get errorLoadingInventory;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirthLabel;

  /// No description provided for @selectDateOfBirthError.
  ///
  /// In en, this message translates to:
  /// **'Please select date of birth'**
  String get selectDateOfBirthError;

  /// No description provided for @invalidDateFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid date format'**
  String get invalidDateFormatError;

  /// No description provided for @patientSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient Selection'**
  String get patientSelectionTitle;

  /// No description provided for @choosePatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose Patient'**
  String get choosePatientLabel;

  /// No description provided for @selectPatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Patient'**
  String get selectPatientLabel;

  /// No description provided for @addNewPatientButton.
  ///
  /// In en, this message translates to:
  /// **'Add New Patient'**
  String get addNewPatientButton;

  /// No description provided for @appointmentDateTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Date & Time'**
  String get appointmentDateTimeTitle;

  /// No description provided for @dateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTimeLabel;

  /// No description provided for @selectDateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTimeLabel;

  /// No description provided for @selectDateTimeError.
  ///
  /// In en, this message translates to:
  /// **'Please select date and time'**
  String get selectDateTimeError;

  /// No description provided for @appointmentTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Type'**
  String get appointmentTypeTitle;

  /// No description provided for @selectTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Type'**
  String get selectTypeLabel;

  /// No description provided for @paymentStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatusTitle;

  /// No description provided for @consultationType.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consultationType;

  /// No description provided for @followupType.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get followupType;

  /// No description provided for @emergencyType.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyType;

  /// No description provided for @procedureType.
  ///
  /// In en, this message translates to:
  /// **'Procedure'**
  String get procedureType;

  /// No description provided for @failedToSaveItemError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save item'**
  String get failedToSaveItemError;

  /// No description provided for @failedToUseItemError.
  ///
  /// In en, this message translates to:
  /// **'Failed to use item'**
  String get failedToUseItemError;

  /// No description provided for @failedToDeleteItemError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item'**
  String get failedToDeleteItemError;

  /// No description provided for @useTooltip.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useTooltip;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get periodThisWeek;

  /// No description provided for @periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get periodThisMonth;

  /// No description provided for @periodThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get periodThisYear;

  /// No description provided for @periodGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get periodGlobal;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get periodCustom;

  /// No description provided for @periodCustomDate.
  ///
  /// In en, this message translates to:
  /// **'Custom Date'**
  String get periodCustomDate;

  /// No description provided for @incomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeTitle;

  /// No description provided for @expensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTitle;

  /// No description provided for @netProfitTitle.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfitTitle;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @monthlyBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlyBudgetTitle;

  /// No description provided for @budgetExceededAlert.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded!'**
  String get budgetExceededAlert;

  /// No description provided for @recurringChargesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recurring Charges'**
  String get recurringChargesTooltip;

  /// No description provided for @financeSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Finance Settings'**
  String get financeSettingsTooltip;

  /// No description provided for @incomeType.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeType;

  /// No description provided for @expenseType.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseType;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @deleteRecurringChargeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Recurring Charge'**
  String get deleteRecurringChargeTitle;

  /// No description provided for @deleteRecurringChargeContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this recurring charge?'**
  String get deleteRecurringChargeContent;

  /// No description provided for @transactionAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction added successfully'**
  String get transactionAddedSuccess;

  /// No description provided for @catRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get catRent;

  /// No description provided for @catSalaries.
  ///
  /// In en, this message translates to:
  /// **'Salaries'**
  String get catSalaries;

  /// No description provided for @catInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get catInventory;

  /// No description provided for @catEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get catEquipment;

  /// No description provided for @catMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get catMarketing;

  /// No description provided for @catUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get catUtilities;

  /// No description provided for @catMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get catMaintenance;

  /// No description provided for @catTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get catTaxes;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @catProductSales.
  ///
  /// In en, this message translates to:
  /// **'Product Sales'**
  String get catProductSales;

  /// No description provided for @freqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// No description provided for @freqQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get freqQuarterly;

  /// No description provided for @freqYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get freqYearly;

  /// No description provided for @freqCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get freqCustom;

  /// No description provided for @errorSavingRecurringCharge.
  ///
  /// In en, this message translates to:
  /// **'Error saving recurring charge'**
  String get errorSavingRecurringCharge;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// No description provided for @costPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Cost per Unit'**
  String get costPerUnit;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @costType.
  ///
  /// In en, this message translates to:
  /// **'Cost Type'**
  String get costType;

  /// No description provided for @calculatedUnitCost.
  ///
  /// In en, this message translates to:
  /// **'Calculated Unit Cost: {currency}{cost}'**
  String calculatedUnitCost(String currency, String cost);

  /// No description provided for @enterCost.
  ///
  /// In en, this message translates to:
  /// **'Please enter cost'**
  String get enterCost;

  /// No description provided for @expiresDays.
  ///
  /// In en, this message translates to:
  /// **'Expires (Days)'**
  String get expiresDays;

  /// No description provided for @lowStockLevel.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Level'**
  String get lowStockLevel;

  /// No description provided for @useItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Use {itemName}'**
  String useItemTitle(String itemName);

  /// No description provided for @currentStock.
  ///
  /// In en, this message translates to:
  /// **'Current Stock: {quantity}'**
  String currentStock(int quantity);

  /// No description provided for @quantityToUse.
  ///
  /// In en, this message translates to:
  /// **'Quantity to Use'**
  String get quantityToUse;

  /// No description provided for @unitsSuffix.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitsSuffix;

  /// No description provided for @enterValidPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive number'**
  String get enterValidPositiveNumber;

  /// No description provided for @cannotUseMoreThanStock.
  ///
  /// In en, this message translates to:
  /// **'Cannot use more than current stock'**
  String get cannotUseMoreThanStock;

  /// No description provided for @remainingStock.
  ///
  /// In en, this message translates to:
  /// **'Remaining Stock: {quantity}'**
  String remainingStock(int quantity);

  /// No description provided for @confirmUse.
  ///
  /// In en, this message translates to:
  /// **'Confirm Use'**
  String get confirmUse;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get filterThisWeek;

  /// No description provided for @filterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get filterThisMonth;

  /// No description provided for @filterEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get filterEmergency;

  /// No description provided for @patientIdHeader.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get patientIdHeader;

  /// No description provided for @dueHeader.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueHeader;

  /// No description provided for @totalCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Cost (\$)'**
  String get totalCostLabel;

  /// No description provided for @amountPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid (\$)'**
  String get amountPaidLabel;

  /// No description provided for @balanceDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance Due'**
  String get balanceDueLabel;

  /// No description provided for @visitHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit History'**
  String get visitHistoryTitle;

  /// No description provided for @lastVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'Last visit: {date}'**
  String lastVisitLabel(String date);

  /// No description provided for @selectPatientToViewHistory.
  ///
  /// In en, this message translates to:
  /// **'Select a patient to view\nvisit history'**
  String get selectPatientToViewHistory;

  /// No description provided for @addEditButton.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit'**
  String get addEditButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @profitTrend.
  ///
  /// In en, this message translates to:
  /// **'Profit Trend'**
  String get profitTrend;

  /// No description provided for @expenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expense Breakdown'**
  String get expenseBreakdown;

  /// No description provided for @noExpensesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period'**
  String get noExpensesInPeriod;

  /// No description provided for @noDataToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No data to display'**
  String get noDataToDisplay;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @unknownPatient.
  ///
  /// In en, this message translates to:
  /// **'Unknown Patient'**
  String get unknownPatient;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @premiumAccount.
  ///
  /// In en, this message translates to:
  /// **'Premium Account'**
  String get premiumAccount;

  /// No description provided for @premiumDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Premium: {days} days left'**
  String premiumDaysLeft(int days);

  /// No description provided for @premiumExpired.
  ///
  /// In en, this message translates to:
  /// **'Premium Expired'**
  String get premiumExpired;

  /// No description provided for @trialVersionDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Trial Version: {days} days left'**
  String trialVersionDaysLeft(int days);

  /// No description provided for @trialExpired.
  ///
  /// In en, this message translates to:
  /// **'Trial Expired'**
  String get trialExpired;

  /// No description provided for @activatePremium.
  ///
  /// In en, this message translates to:
  /// **'Activate Premium'**
  String get activatePremium;

  /// No description provided for @financeSettings.
  ///
  /// In en, this message translates to:
  /// **'Finance Settings'**
  String get financeSettings;

  /// No description provided for @includeInventoryCosts.
  ///
  /// In en, this message translates to:
  /// **'Include Inventory Costs'**
  String get includeInventoryCosts;

  /// No description provided for @includeAppointments.
  ///
  /// In en, this message translates to:
  /// **'Include Appointments'**
  String get includeAppointments;

  /// No description provided for @includeRecurringCharges.
  ///
  /// In en, this message translates to:
  /// **'Include Recurring Charges'**
  String get includeRecurringCharges;

  /// No description provided for @compactNumbers.
  ///
  /// In en, this message translates to:
  /// **'Compact Numbers (e.g. 1K)'**
  String get compactNumbers;

  /// No description provided for @compactNumbersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use short format for large numbers'**
  String get compactNumbersSubtitle;

  /// No description provided for @monthlyBudgetCap.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget Cap'**
  String get monthlyBudgetCap;

  /// No description provided for @taxRatePercentage.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate (%)'**
  String get taxRatePercentage;

  /// No description provided for @staffManagement.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get staffManagement;

  /// No description provided for @addAssistant.
  ///
  /// In en, this message translates to:
  /// **'Add Assistant'**
  String get addAssistant;

  /// No description provided for @addReceptionist.
  ///
  /// In en, this message translates to:
  /// **'Add Receptionist'**
  String get addReceptionist;

  /// No description provided for @currentStaff.
  ///
  /// In en, this message translates to:
  /// **'Current Staff'**
  String get currentStaff;

  /// No description provided for @noStaffAdded.
  ///
  /// In en, this message translates to:
  /// **'No staff members added yet'**
  String get noStaffAdded;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @removeStaff.
  ///
  /// In en, this message translates to:
  /// **'Remove Staff'**
  String get removeStaff;

  /// No description provided for @updatePin.
  ///
  /// In en, this message translates to:
  /// **'Update PIN'**
  String get updatePin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN (4 digits)'**
  String get newPin;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter username for staff member'**
  String get enterUsername;

  /// No description provided for @addStaff.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get addStaff;

  /// No description provided for @staffAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Staff member added successfully'**
  String get staffAddedSuccess;

  /// No description provided for @staffRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Staff member removed'**
  String get staffRemovedSuccess;

  /// No description provided for @pinUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN updated successfully'**
  String get pinUpdatedSuccess;

  /// No description provided for @deleteStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Staff Member'**
  String get deleteStaffTitle;

  /// No description provided for @deleteStaffConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {username}?'**
  String deleteStaffConfirm(String username);

  /// No description provided for @roleAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get roleAssistant;

  /// No description provided for @roleReceptionist.
  ///
  /// In en, this message translates to:
  /// **'Receptionist'**
  String get roleReceptionist;

  /// No description provided for @roleDentist.
  ///
  /// In en, this message translates to:
  /// **'Dentist'**
  String get roleDentist;

  /// No description provided for @roleDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get roleDeveloper;

  /// No description provided for @overpaid.
  ///
  /// In en, this message translates to:
  /// **'Overpaid: {amount}'**
  String overpaid(String amount);

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due: {amount}'**
  String due(String amount);

  /// No description provided for @fullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully Paid'**
  String get fullyPaid;

  /// No description provided for @appointmentPaymentDescription.
  ///
  /// In en, this message translates to:
  /// **'Appointment payment for {type}'**
  String appointmentPaymentDescription(String type);

  /// No description provided for @proratedLabel.
  ///
  /// In en, this message translates to:
  /// **'Pro-rated'**
  String get proratedLabel;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @deleteVisit.
  ///
  /// In en, this message translates to:
  /// **'Delete Visit'**
  String get deleteVisit;

  /// No description provided for @connectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Connection Settings'**
  String get connectionSettings;

  /// No description provided for @networkConnection.
  ///
  /// In en, this message translates to:
  /// **'Network Connection'**
  String get networkConnection;

  /// No description provided for @serverDeviceNotice.
  ///
  /// In en, this message translates to:
  /// **'This device is the SERVER. Share the IP below with staff devices.'**
  String get serverDeviceNotice;

  /// No description provided for @clientDeviceNotice.
  ///
  /// In en, this message translates to:
  /// **'This device is a CLIENT. Enter the Server IP to connect.'**
  String get clientDeviceNotice;

  /// No description provided for @connectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Connection Status'**
  String get connectionStatus;

  /// No description provided for @possibleIpAddresses.
  ///
  /// In en, this message translates to:
  /// **'Possible IP Addresses:'**
  String get possibleIpAddresses;

  /// No description provided for @manualConnection.
  ///
  /// In en, this message translates to:
  /// **'Manual Connection'**
  String get manualConnection;

  /// No description provided for @serverIpAddress.
  ///
  /// In en, this message translates to:
  /// **'Server IP Address'**
  String get serverIpAddress;

  /// No description provided for @connectToServer.
  ///
  /// In en, this message translates to:
  /// **'Connect to Server'**
  String get connectToServer;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @connectedSync.
  ///
  /// In en, this message translates to:
  /// **'Connected! Initializing sync...'**
  String get connectedSync;

  /// No description provided for @invalidIpOrPort.
  ///
  /// In en, this message translates to:
  /// **'Invalid IP or Port'**
  String get invalidIpOrPort;

  /// No description provided for @firewallWarning.
  ///
  /// In en, this message translates to:
  /// **'If connection fails, check your Windows Firewall to allow \'DentalTid\' on Private/Public networks.'**
  String get firewallWarning;

  /// No description provided for @readyToConnect.
  ///
  /// In en, this message translates to:
  /// **'Ready to connect.'**
  String get readyToConnect;

  /// No description provided for @serverRunning.
  ///
  /// In en, this message translates to:
  /// **'Server Running'**
  String get serverRunning;

  /// No description provided for @serverStopped.
  ///
  /// In en, this message translates to:
  /// **'Server Stopped'**
  String get serverStopped;

  /// No description provided for @startServer.
  ///
  /// In en, this message translates to:
  /// **'Start Server'**
  String get startServer;

  /// No description provided for @stopServer.
  ///
  /// In en, this message translates to:
  /// **'Stop Server'**
  String get stopServer;

  /// No description provided for @serverLogs.
  ///
  /// In en, this message translates to:
  /// **'Server Logs'**
  String get serverLogs;

  /// No description provided for @copyLogsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get copyLogsSuccess;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
