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
  /// **'Today\'s Appointments Flow'**
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
