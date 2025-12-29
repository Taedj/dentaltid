// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get patients => 'Patients';

  @override
  String get appointments => 'Rendez-vous';

  @override
  String get inventory => 'Inventaire';

  @override
  String get finance => 'Finance';

  @override
  String get advanced => 'Avancé';

  @override
  String get addAppointment => 'Ajouter un rendez-vous';

  @override
  String get editAppointment => 'Modifier le rendez-vous';

  @override
  String get patient => 'Patient';

  @override
  String get selectPatient => 'Veuillez sélectionner un patient';

  @override
  String get dateYYYYMMDD => 'Date (AAAA-MM-JJ)';

  @override
  String get enterDate => 'Veuillez saisir une date';

  @override
  String get invalidDateFormat =>
      'Veuillez saisir une date valide au format AAAA-MM-JJ';

  @override
  String get invalidDate => 'Date invalide';

  @override
  String get dateInPast => 'La date ne peut pas être dans le passé';

  @override
  String get timeHHMM => 'Heure (HH:MM)';

  @override
  String get enterTime => 'Veuillez saisir une heure';

  @override
  String get invalidTimeFormat =>
      'Veuillez saisir une heure valide au format HH:MM';

  @override
  String get add => 'Ajouter';

  @override
  String get update => 'Mettre à jour';

  @override
  String get error => 'Erreur: ';

  @override
  String invalidTime(Object end, Object start) {
    return 'L\'heure doit être comprise entre $start et $end';
  }

  @override
  String get appointmentExistsError =>
      'Un rendez-vous pour ce patient à cette date et heure existe déjà.';

  @override
  String get settings => 'Paramètres';

  @override
  String get account => 'Compte';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get passwordChangedSuccessfully => 'Mot de passe changé avec succès';

  @override
  String get invalidPassword => 'Mot de passe invalide';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get localBackup => 'Sauvegarde locale';

  @override
  String get backupCreatedAt => 'Sauvegarde créée le';

  @override
  String get backupFailedOrCancelled => 'Sauvegarde échouée ou annulée';

  @override
  String get createLocalBackup => 'Créer une sauvegarde locale';

  @override
  String get backupRestoredSuccessfully => 'Sauvegarde restaurée avec succès';

  @override
  String get restoreFailedOrCancelled => 'Restauration échouée ou annulée';

  @override
  String get cloudSync => 'Synchronisation cloud';

  @override
  String get backupUploadedToCloud => 'Sauvegarde téléchargée sur le cloud';

  @override
  String get cloudBackupFailed => 'Échec de la sauvegarde cloud';

  @override
  String get syncToCloud => 'Synchroniser avec le cloud';

  @override
  String get manageCloudBackups => 'Gérer les sauvegardes cloud';

  @override
  String get currency => 'Devise';

  @override
  String get logout => 'Déconnexion';

  @override
  String get showAllAppointments => 'Afficher tous les rendez-vous';

  @override
  String get showUpcomingOnly => 'Afficher uniquement les prochains';

  @override
  String get timeEarliestFirst => 'Heure (la plus tôt en premier)';

  @override
  String get timeLatestFirst => 'Heure (la plus tard en premier)';

  @override
  String get patientId => 'ID du patient';

  @override
  String get searchAppointments => 'Rechercher des rendez-vous';

  @override
  String get noAppointmentsFound => 'Aucun rendez-vous trouvé';

  @override
  String get deleteAppointment => 'Supprimer le rendez-vous';

  @override
  String get confirmDeleteAppointment =>
      'Êtes-vous sûr de vouloir supprimer ce rendez-vous ?';

  @override
  String get confirm => 'Confirmer';

  @override
  String get welcomeDr => 'Bienvenue Dr.';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get totalNumberOfPatients => 'Nombre total de patients';

  @override
  String get emergencyPatients => 'Patients d\'urgence';

  @override
  String get upcomingAppointments => 'Rendez-vous à venir';

  @override
  String get payments => 'Paiements';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get emergencyAlerts => 'Alertes d\'urgence';

  @override
  String get noEmergencies => 'Aucune urgence';

  @override
  String get receipt => 'Reçu';

  @override
  String get total => 'Total';

  @override
  String get outstandingAmount => 'Montant restant';

  @override
  String get close => 'Fermer';

  @override
  String get addPatient => 'Ajouter un patient';

  @override
  String get editPatient => 'Modifier le patient';

  @override
  String get familyName => 'Nom de famille';

  @override
  String get enterFamilyName => 'Veuillez saisir le nom de famille';

  @override
  String get age => 'Âge';

  @override
  String get enterAge => 'Veuillez saisir l\'âge';

  @override
  String get enterValidNumber => 'Veuillez saisir un nombre valide';

  @override
  String get enterAgeBetween => 'Veuillez saisir un âge entre 1 et 120';

  @override
  String get healthState => 'État de santé';

  @override
  String get diagnosis => 'Diagnostic';

  @override
  String get treatment => 'Traitement';

  @override
  String get payment => 'Paiement';

  @override
  String get enterPaymentAmount => 'Veuillez saisir le montant du paiement';

  @override
  String get paymentCannotBeNegative => 'Le paiement ne peut pas être négatif';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get enterValidPhoneNumber =>
      'Veuillez saisir un numéro de téléphone valide';

  @override
  String get emergencyDetails => 'Détails d\'urgence';

  @override
  String get isEmergency => 'Est une urgence';

  @override
  String get severity => 'Sévérité';

  @override
  String get healthAlerts => 'Alertes de santé';

  @override
  String get paymentHistory => 'Historique des paiements';

  @override
  String get noPaymentHistory => 'Aucun historique de paiement';

  @override
  String get edit => 'Modifier';

  @override
  String get save => 'Enregistrer';

  @override
  String get noPatientsYet => 'Aucun patient pour l\'instant';

  @override
  String get noHealthAlerts => 'Aucune alerte de santé';

  @override
  String get createdAt => 'Créé le';

  @override
  String get emergency => 'Urgence';

  @override
  String get number => 'Numéro';

  @override
  String get actions => 'Actions';

  @override
  String get deletePatient => 'Supprimer le patient';

  @override
  String get confirmDeletePatient =>
      'Êtes-vous sûr de vouloir supprimer ce patient ?';

  @override
  String get todaysAppointmentsFlow => 'Rendez-vous d\'aujourd\'hui';

  @override
  String get waiting => 'En attente';

  @override
  String get inProgress => 'En cours';

  @override
  String get completed => 'Terminé';

  @override
  String get mustBeLoggedInToSync =>
      'Vous devez être connecté pour synchroniser avec le cloud.';

  @override
  String get dateNewestFirst => 'Date (la plus récente en premier)';

  @override
  String get dateOldestFirst => 'Date (la plus ancienne en premier)';

  @override
  String get startAppointment => 'Démarrer le rendez-vous';

  @override
  String get completeAppointment => 'Terminer le rendez-vous';

  @override
  String get cancelAppointment => 'Annuler le rendez-vous';

  @override
  String get confirmCancelAppointment =>
      'Êtes-vous sûr de vouloir annuler ce rendez-vous ?';

  @override
  String get addTransaction => 'Ajouter une transaction';

  @override
  String get financialSummary => 'Résumé financier';

  @override
  String get description => 'Description';

  @override
  String get enterDescription => 'Veuillez saisir une description';

  @override
  String get totalAmount => 'Montant total';

  @override
  String get enterTotalAmount => 'Veuillez saisir le montant total';

  @override
  String get enterValidPositiveAmount =>
      'Veuillez saisir un montant positif valide';

  @override
  String get paidAmount => 'Montant payé';

  @override
  String get enterPaidAmount => 'Veuillez saisir le montant payé';

  @override
  String get enterValidNonNegativeAmount =>
      'Veuillez saisir un montant non négatif valide';

  @override
  String get type => 'Type';

  @override
  String get income => 'Revenu';

  @override
  String get expense => 'Dépense';

  @override
  String get paymentMethod => 'Mode de paiement';

  @override
  String get cash => 'Espèces';

  @override
  String get card => 'Carte';

  @override
  String get bankTransfer => 'Virement bancaire';

  @override
  String get searchTransactions => 'Rechercher des transactions';

  @override
  String get allTypes => 'Tous les types';

  @override
  String get amountHighestFirst => 'Montant (le plus élevé en premier)';

  @override
  String get amountLowestFirst => 'Montant (le moins élevé en premier)';

  @override
  String get showAllItems => 'Afficher tous les articles';

  @override
  String get showExpiredOnly => 'Afficher uniquement les articles expirés';

  @override
  String get showLowStockOnly =>
      'Afficher uniquement les articles en faible stock';

  @override
  String get nameAZ => 'Nom (A-Z)';

  @override
  String get nameZA => 'Nom (Z-A)';

  @override
  String get quantityLowToHigh => 'Quantité (croissante)';

  @override
  String get quantityHighToLow => 'Quantité (décroissante)';

  @override
  String get expirySoonestFirst => 'Expiration (la plus proche en premier)';

  @override
  String get expiryLatestFirst => 'Expiration (la plus éloignée en premier)';

  @override
  String get searchInventoryItems => 'Rechercher des articles d\'inventaire';

  @override
  String get name => 'Nom';

  @override
  String get quantity => 'Quantité';

  @override
  String get expirationDate => 'Date d\'expiration';

  @override
  String get supplier => 'Fournisseur';

  @override
  String get addItem => 'Ajouter un article';

  @override
  String get noItemsFound => 'Aucun article trouvé';

  @override
  String get expires => 'Expire';

  @override
  String get expired => 'Expiré';

  @override
  String get lowStock => 'Faible stock';

  @override
  String get deleteItem => 'Supprimer l\'article';

  @override
  String get deleteItemButton => 'Supprimer';

  @override
  String get confirmDeleteItem =>
      'Êtes-vous sûr de vouloir supprimer cet article ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get enterName => 'Veuillez saisir un nom';

  @override
  String get enterQuantity => 'Veuillez saisir une quantité';

  @override
  String get enterSupplier => 'Veuillez saisir un fournisseur';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get restoreFromLocalBackup => 'Restaurer depuis la sauvegarde locale';

  @override
  String get date => 'Date';

  @override
  String get method => 'Méthode';

  @override
  String get paid => 'Payé';

  @override
  String get unpaid => 'Impayé';

  @override
  String get noTransactionsYet => 'Aucune transaction pour l\'instant';

  @override
  String get visitHistory => 'Historique des visites';

  @override
  String get noVisitHistory => 'Aucun historique de visite';

  @override
  String get visitDate => 'Date de visite';

  @override
  String get reasonForVisit => 'Raison de la visite';

  @override
  String get addVisit => 'Ajouter une visite';

  @override
  String get editVisit => 'Modifier la visite';

  @override
  String get notes => 'Notes';

  @override
  String get enterReasonForVisit => 'Veuillez saisir la raison de la visite';

  @override
  String get searchPatient => 'Rechercher un patient';

  @override
  String get showCurrentDayPatients => 'Afficher les patients du jour';

  @override
  String get visitDetails => 'Détails de la visite';

  @override
  String get createNewVisit => 'Créer une nouvelle visite';

  @override
  String get selectExistingVisit => 'Sélectionner une visite existante';

  @override
  String get requiredField => 'Ce champ est obligatoire';

  @override
  String get emergencySeverity => 'Sévérité d\'urgence';

  @override
  String get sessionDetails => 'Détails de la session';

  @override
  String get numberOfSessions => 'Nombre de sessions';

  @override
  String get session => 'Session';

  @override
  String get dateTime => 'Date et heure';

  @override
  String get treatmentDetails => 'Détails du traitement';

  @override
  String get patientNotes => 'Notes du patient';

  @override
  String get blacklistPatient => 'Patient sur liste noire';

  @override
  String get noTransactionsFound => 'Aucune transaction trouvée';

  @override
  String get recurringCharges => 'Frais récurrents';

  @override
  String get noRecurringChargesFound => 'Aucun frais récurrent trouvé';

  @override
  String get addRecurringCharge => 'Ajouter une charge récurrente';

  @override
  String get editRecurringCharge => 'Modifier la charge récurrente';

  @override
  String get amount => 'Montant';

  @override
  String get frequency => 'Fréquence';

  @override
  String get startDate => 'Date de début';

  @override
  String get endDate => 'Date de fin';

  @override
  String get isActive => 'Est actif';

  @override
  String get transactions => 'Transactions';

  @override
  String get overview => 'Aperçu';

  @override
  String get dailySummary => 'Résumé quotidien';

  @override
  String get weeklySummary => 'Résumé hebdomadaire';

  @override
  String get monthlySummary => 'Résumé mensuel';

  @override
  String get yearlySummary => 'Résumé annuel';

  @override
  String get expenses => 'Dépenses';

  @override
  String get profit => 'Bénéfice';

  @override
  String get filters => 'Filtres';

  @override
  String get inventoryExpenses => 'Dépenses d\'inventaire';

  @override
  String get staffSalaries => 'Salaires du personnel';

  @override
  String get rent => 'Loyer';

  @override
  String get changeDate => 'Changer la date';

  @override
  String get transactionAddedSuccessfully => 'Transaction ajoutée avec succès';

  @override
  String get invalidAmount => 'Montant invalide';

  @override
  String get pleaseEnterAmount => 'Veuillez saisir un montant';

  @override
  String get viewDetails => 'Voir détails';

  @override
  String get criticalAlerts => 'Alertes critiques';

  @override
  String get viewCritical => 'Voir critiques';

  @override
  String get viewAppointments => 'Voir rendez-vous';

  @override
  String todayCount(int count) {
    return 'Aujourd\'hui : $count';
  }

  @override
  String waitingCount(int count) {
    return 'En attente : $count';
  }

  @override
  String inProgressCount(int count) {
    return 'En cours : $count';
  }

  @override
  String completedCount(int count) {
    return 'Terminé : $count';
  }

  @override
  String emergencyCountLabel(int count) {
    return 'Urgences : $count';
  }

  @override
  String get expiringSoon => 'Expire bientôt';

  @override
  String expiringSoonCount(int count) {
    return 'Expire bientôt : $count';
  }

  @override
  String lowStockCount(int count) {
    return 'Stock faible : $count';
  }

  @override
  String get patientName => 'Nom du patient';

  @override
  String get itemName => 'Nom de l\'article';

  @override
  String get countdown => 'Compte à rebours';

  @override
  String get currentQuantity => 'Quantité actuelle';

  @override
  String daysLeft(int days) {
    return '${days}j restants';
  }

  @override
  String get noPatientsToday => 'Aucun patient aujourd\'hui';

  @override
  String get noExpiringSoonItems => 'Aucun article expirant bientôt';

  @override
  String get noLowStockItems => 'Aucun article en stock faible';

  @override
  String get noWaitingAppointments => 'Aucun rendez-vous en attente';

  @override
  String get noEmergencyAppointments => 'Aucun rendez-vous d\'urgence';

  @override
  String get noCompletedAppointments => 'Aucun rendez-vous terminé';

  @override
  String get errorLoadingEmergencyAppointments =>
      'Erreur lors du chargement des rendez-vous d\'urgence';

  @override
  String get errorLoadingAppointments =>
      'Erreur lors du chargement des rendez-vous';

  @override
  String get errorLoadingPatientData =>
      'Erreur lors du chargement des données patient';

  @override
  String get errorLoadingInventory =>
      'Erreur lors du chargement de l\'inventaire';

  @override
  String get dateOfBirthLabel => 'Date de naissance';

  @override
  String get selectDateOfBirthError =>
      'Veuillez sélectionner la date de naissance';

  @override
  String get invalidDateFormatError => 'Format de date invalide';

  @override
  String get patientSelectionTitle => 'Sélection du patient';

  @override
  String get choosePatientLabel => 'Choisir un patient';

  @override
  String get selectPatientLabel => 'Sélectionner un patient';

  @override
  String get addNewPatientButton => 'Ajouter un nouveau patient';

  @override
  String get appointmentDateTimeTitle => 'Date et heure du rendez-vous';

  @override
  String get dateTimeLabel => 'Date et heure';

  @override
  String get selectDateTimeLabel => 'Sélectionner la date et l\'heure';

  @override
  String get selectDateTimeError => 'Veuillez sélectionner la date et l\'heure';

  @override
  String get appointmentTypeTitle => 'Type de rendez-vous';

  @override
  String get selectTypeLabel => 'Sélectionner le type';

  @override
  String get paymentStatusTitle => 'Statut du paiement';

  @override
  String get consultationType => 'Consultation';

  @override
  String get followupType => 'Suivi';

  @override
  String get emergencyType => 'Urgence';

  @override
  String get procedureType => 'Procédure';

  @override
  String get failedToSaveItemError =>
      'Échec de l\'enregistrement de l\'élément';

  @override
  String get failedToUseItemError => 'Échec de l\'utilisation de l\'élément';

  @override
  String get failedToDeleteItemError => 'Échec de la suppression de l\'élément';

  @override
  String get useTooltip => 'Utiliser';

  @override
  String get periodToday => 'Aujourd\'hui';

  @override
  String get periodThisWeek => 'Cette semaine';

  @override
  String get periodThisMonth => 'Ce mois-ci';

  @override
  String get periodThisYear => 'Cette année';

  @override
  String get periodGlobal => 'Global';

  @override
  String get periodCustom => 'Personnalisé';

  @override
  String get periodCustomDate => 'Date personnalisée';

  @override
  String get incomeTitle => 'Revenus';

  @override
  String get expensesTitle => 'Dépenses';

  @override
  String get netProfitTitle => 'Bénéfice net';

  @override
  String get taxLabel => 'Taxe';

  @override
  String get monthlyBudgetTitle => 'Budget mensuel';

  @override
  String get budgetExceededAlert => 'Budget dépassé !';

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
  String get noExpensesInPeriod => 'Pas de dépenses au cours de cette période';

  @override
  String get noDataToDisplay => 'Pas de données à afficher';

  @override
  String get cancelled => 'Annulé';

  @override
  String get unknownPatient => 'Patient inconnu';

  @override
  String get loading => 'Chargement...';

  @override
  String get errorLabel => 'Erreur';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteTransaction => 'Supprimer la transaction';

  @override
  String get premiumAccount => 'Compte Premium';

  @override
  String premiumDaysLeft(int days) {
    return 'Premium : $days jours restants';
  }

  @override
  String get premiumExpired => 'Premium Expiré';

  @override
  String trialVersionDaysLeft(int days) {
    return 'Version d\'essai : $days jours restants';
  }

  @override
  String get trialExpired => 'Essai Expiré';

  @override
  String get activatePremium => 'Activer le Premium';

  @override
  String get financeSettings => 'Paramètres Financiers';

  @override
  String get includeInventoryCosts => 'Inclure les Coûts d\'Inventaire';

  @override
  String get includeAppointments => 'Inclure les Rendez-vous';

  @override
  String get includeRecurringCharges => 'Inclure les Frais Récurrents';

  @override
  String get compactNumbers => 'Chiffres Compacts (ex: 1K)';

  @override
  String get compactNumbersSubtitle =>
      'Utiliser un format court pour les grands nombres';

  @override
  String get monthlyBudgetCap => 'Plafond Budgétaire Mensuel';

  @override
  String get taxRatePercentage => 'Taux d\'Imposition (%)';

  @override
  String get staffManagement => 'Gestion du Personnel';

  @override
  String get addAssistant => 'Ajouter un Assistant';

  @override
  String get addReceptionist => 'Ajouter un Réceptionniste';

  @override
  String get currentStaff => 'Personnel Actuel';

  @override
  String get noStaffAdded => 'Aucun membre du personnel ajouté pour l\'instant';

  @override
  String get changePin => 'Changer le PIN';

  @override
  String get removeStaff => 'Supprimer le Personnel';

  @override
  String get updatePin => 'Mettre à jour le PIN';

  @override
  String get newPin => 'Nouveau PIN (4 chiffres)';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get enterUsername =>
      'Entrez le nom d\'utilisateur du membre du personnel';

  @override
  String get addStaff => 'Ajouter du Personnel';

  @override
  String get staffAddedSuccess => 'Membre du personnel ajouté avec succès';

  @override
  String get staffRemovedSuccess => 'Membre du personnel supprimé';

  @override
  String get pinUpdatedSuccess => 'PIN mis à jour avec succès';

  @override
  String get deleteStaffTitle => 'Supprimer un Membre du Personnel';

  @override
  String deleteStaffConfirm(String username) {
    return 'Êtes-vous sûr de vouloir supprimer $username ?';
  }

  @override
  String get roleAssistant => 'Assistant';

  @override
  String get roleReceptionist => 'Réceptionniste';

  @override
  String get roleDentist => 'Dentiste';

  @override
  String get roleDeveloper => 'Développeur';

  @override
  String overpaid(String amount) {
    return 'Trop-perçu : $amount';
  }

  @override
  String due(String amount) {
    return 'Dû : $amount';
  }

  @override
  String get fullyPaid => 'Entièrement Payé';

  @override
  String appointmentPaymentDescription(String type) {
    return 'Paiement du rendez-vous pour $type';
  }

  @override
  String get proratedLabel => 'Prorata';

  @override
  String get days => 'jours';

  @override
  String get status => 'Statut';

  @override
  String get deleteVisit => 'Supprimer la visite';

  @override
  String get connectionSettings => 'Paramètres de connexion';

  @override
  String get networkConnection => 'Connexion réseau';

  @override
  String get serverDeviceNotice =>
      'Cet appareil est le SERVEUR. Partagez l\'IP ci-dessous avec les appareils du personnel.';

  @override
  String get clientDeviceNotice =>
      'Cet appareil est un CLIENT. Entrez l\'IP du serveur pour vous connecter.';

  @override
  String get connectionStatus => 'Statut de la connexion';

  @override
  String get possibleIpAddresses => 'Adresses IP possibles :';

  @override
  String get manualConnection => 'Connexion manuelle';

  @override
  String get serverIpAddress => 'Adresse IP du serveur';

  @override
  String get connectToServer => 'Se connecter au serveur';

  @override
  String get connecting => 'Connexion...';

  @override
  String get connectedSync =>
      'Connecté ! Initialisation de la synchronisation...';

  @override
  String get invalidIpOrPort => 'IP ou port invalide';

  @override
  String get firewallWarning =>
      'Si la connexion échoue, vérifiez votre pare-feu Windows pour autoriser \'DentalTid\' sur les réseaux privés/publics.';

  @override
  String get readyToConnect => 'Prêt à se connecter.';

  @override
  String get serverRunning => 'Serveur en cours d\'exécution';

  @override
  String get serverStopped => 'Serveur arrêté';

  @override
  String get startServer => 'Démarrer le serveur';

  @override
  String get stopServer => 'Arrêter le serveur';

  @override
  String get serverLogs => 'Journaux du serveur';

  @override
  String get copyLogsSuccess => 'Journaux copiés dans le presse-papiers';

  @override
  String get port => 'Port';

  @override
  String get acceptTermsError => 'Veuillez accepter les termes et conditions';

  @override
  String get dentistLogin => 'Connexion Dentiste';

  @override
  String get dentistRegistration => 'Inscription Dentiste';

  @override
  String get staffPortal => 'Portail Personnel';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get authError =>
      'Une erreur est survenue, veuillez vérifier vos identifiants.';

  @override
  String get weakPasswordError => 'Le mot de passe fourni est trop faible.';

  @override
  String get emailInUseError => 'Un compte existe déjà pour cet e-mail.';

  @override
  String get userNotFoundError => 'Aucun utilisateur trouvé pour cet e-mail.';

  @override
  String get wrongPasswordError =>
      'Mot de passe incorrect pour cet utilisateur.';

  @override
  String get networkError => 'Erreur réseau. Vérifiez votre connexion.';

  @override
  String authFailed(String error) {
    return 'Échec de l\'authentification : $error';
  }

  @override
  String get invalidStaffCredentials =>
      'Nom d\'utilisateur ou code PIN invalide';

  @override
  String get enterEmailFirst => 'Veuillez d\'abord saisir votre adresse e-mail';

  @override
  String get passwordResetSent =>
      'E-mail de réinitialisation envoyé ! Consultez votre boîte de réception.';

  @override
  String get contactDeveloperLabel => 'Contacter le développeur';

  @override
  String get contactUs => 'Contactez-nous';

  @override
  String get dentist => 'Dentiste';

  @override
  String get staff => 'Personnel';

  @override
  String get emailAddress => 'Adresse e-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get yourName => 'Votre nom';

  @override
  String get clinicNameLabel => 'Nom de la clinique';

  @override
  String get licenseNumber => 'Numéro de licence';

  @override
  String get acceptTermsAndConditions => 'J\'accepte les termes et conditions';

  @override
  String get pin4Digits => 'PIN (4 chiffres)';

  @override
  String get signIn => 'S\'IDENTIFIER';

  @override
  String get register => 'S\'INSCRIRE';

  @override
  String get loginLabel => 'CONNEXION';

  @override
  String get rememberLabel => 'Se souvenir';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ? ';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? ';

  @override
  String get signUpSmall => 'Inscrivez-vous';

  @override
  String get signInSmall => 'Se connecter';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get scheduledVisits => 'Visites prévues';

  @override
  String get actionNeeded => 'Action nécessaire';

  @override
  String get allGood => 'Tout va bien';

  @override
  String activeStatus(int count) {
    return 'Actif : $count';
  }

  @override
  String doneStatus(int count) {
    return 'Terminé : $count';
  }

  @override
  String get clinicRunningSmoothly => 'La clinique tourne bien aujourd\'hui 🦷';

  @override
  String expiringLabel(int count) {
    return '$count Expirant';
  }

  @override
  String lowStockLabelText(int count) {
    return '$count Stock faible';
  }

  @override
  String get staffActivationNotice =>
      'L\'utilisateur dentiste principal doit activer le premium pour continuer à utiliser l\'application.';

  @override
  String get overviewMenu => 'Aperçu';

  @override
  String get usersMenu => 'Utilisateurs';

  @override
  String get codesMenu => 'Codes';

  @override
  String get broadcastsMenu => 'Diffusions';

  @override
  String get serverOnlineNoStaff =>
      'Serveur en ligne (aucun personnel connecté)';

  @override
  String serverOnlineWithStaffCount(int count) {
    return 'Serveur en ligne ($count personnel connectés)';
  }

  @override
  String staffConnectedList(String names) {
    return 'Connectés : $names';
  }

  @override
  String get connectedToServer => 'Connecté au serveur';

  @override
  String get offline => 'Hors ligne';

  @override
  String get invalidCodeLength =>
      'Longueur de code invalide (doit être de 27 caractères)';

  @override
  String get activationSuccess =>
      'Compte activé avec succès ! Les fonctionnalités Premium sont maintenant activées.';

  @override
  String get invalidActivationCode =>
      'Code d\' d\'activation invalide ou expiré';

  @override
  String activationError(String error) {
    return 'Erreur lors de l\'activation : $error';
  }

  @override
  String get activationRequired => 'Activation requise';

  @override
  String get trialExpiredNotice =>
      'Votre période d\'essai a expiré. Veuillez saisir un code d\'activation valide pour continuer à utiliser DentalTid Premium.';

  @override
  String get activationCodeLabel => 'Code d\'activation (27 chars)';

  @override
  String get needACode => 'Besoin d\'un code ?';

  @override
  String get editDoctorProfile => 'Modifier le profil du docteur';

  @override
  String get updateYourProfile => 'Mettre à jour votre profil';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get enterYourName => 'Veuillez saisir votre nom';

  @override
  String get profileUpdatedSuccess => 'Profil mis à jour avec succès !';

  @override
  String profileUpdateError(String error) {
    return 'Échec de l\'enregistrement du profil : $error';
  }

  @override
  String get loginToSaveProfileError =>
      'Impossible d\'enregistrer le profil. Utilisateur non connecté.';

  @override
  String get required => 'Obligatoire';

  @override
  String get mustBe4Digits => 'Doit être de 4 chiffres';

  @override
  String get editStaff => 'Modifier le personnel';

  @override
  String get addNewStaff => 'Ajouter un nouveau personnel';

  @override
  String get fullName => 'Nom complet';

  @override
  String get systemHealth => 'Santé du système';

  @override
  String get developerOverview => 'Aperçu développeur';

  @override
  String get totalUsers => 'Total utilisateurs';

  @override
  String get activeTrials => 'Essais actifs';

  @override
  String get estRevenue => 'Revenu est.';

  @override
  String noPatientsFoundSearch(String query) {
    return 'Aucun patient trouvé correspondant à \"$query\"';
  }

  @override
  String get paidStatusLabel => 'Payé';

  @override
  String get searchHintSeparator => 'ou Téléphone...';

  @override
  String get savePatientsCsvLabel => 'Enregistrer le CSV des patients';

  @override
  String get localBackupConfirm =>
      'Cette sauvegarde inclura la base de données de votre clinique, les paramètres de l\'application et les comptes du personnel. Voulez-vous continuer ?';

  @override
  String get premiumOnly => 'Premium Uniquement';

  @override
  String get cloudSyncConfirm =>
      'Cela téléchargera la base de données de votre clinique, vos paramètres et les comptes du personnel sur le cloud pour les mettre en sécurité. Voulez-vous continuer ?';

  @override
  String get cloudSyncPremiumNotice =>
      'La synchronisation cloud est une fonctionnalité Premium. Activez-la pour l\'utiliser.';

  @override
  String get manageStaffMembers => 'Gérer les membres du personnel';

  @override
  String get addStaffSubtitle =>
      'Ajouter des assistants ou des réceptionnistes';

  @override
  String get lanSyncSettings => 'Paramètres de synchronisation LAN';

  @override
  String get autoStartServerLabel => 'Démarrage automatique du serveur';

  @override
  String get autoStartServerSubtitle =>
      'Démarrer le serveur de synchronisation au lancement de l\'application';

  @override
  String get serverPortLabel => 'Port du serveur';

  @override
  String get defaultPortHelper => 'Par défaut : 8080';

  @override
  String get advancedNetworkConfig => 'Configuration réseau avancée';

  @override
  String get advancedNetworkConfigSubtitle =>
      'Journaux, pare-feu et paramètres IP';

  @override
  String errorLoadingProfile(String error) {
    return 'Erreur lors du chargement du profil utilisateur : $error';
  }

  @override
  String get deleteTransactionConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette transaction ?';

  @override
  String get transactionDeletedSuccess => 'Transaction supprimée avec succès';

  @override
  String get limitReached => 'Limite atteinte';

  @override
  String get inventoryLimitMessage =>
      'Vous avez atteint la limite de 100 articles en inventaire pour la version d\'essai.\nVeuillez passer à la version Premium pour continuer à ajouter des articles.';

  @override
  String get okButton => 'OK';

  @override
  String get trialActive => 'Essai Actif';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Veuillez entrer un email';

  @override
  String get enterValidEmail => 'Veuillez entrer un email valide';

  @override
  String get enterPassword => 'Veuillez entrer un mot de passe';

  @override
  String get clinicAddress => 'Adresse de la clinique';

  @override
  String get enterClinicAddress => 'Veuillez entrer l\'adresse de la clinique';

  @override
  String get province => 'Province';

  @override
  String get enterProvince => 'Veuillez entrer la province';

  @override
  String get country => 'Pays';

  @override
  String get enterCountry => 'Veuillez entrer le pays';

  @override
  String get supplierContact => 'Contact du fournisseur';

  @override
  String get enterSupplierContact => 'Entrez les informations du fournisseur';

  @override
  String get addLabel => 'Ajouter une étiquette';

  @override
  String get intraoralXrayDefault => 'Radiographie intrabuccale';

  @override
  String get clinicalObservationHint =>
      'Entrez les observations cliniques ici...';

  @override
  String get selectSensorLabel => 'Sélectionner le capteur/scanner';

  @override
  String get initiateCapture => 'Lancer la capture';

  @override
  String get saveToPatientRecord => 'Enregistrer dans le dossier du patient';

  @override
  String get scanFailed => 'Échec de la numérisation';

  @override
  String get saveCopySuccess => 'Copie enregistrée avec succès !';

  @override
  String usageLimitDisplay(Object current, Object max) {
    return '$current/$max';
  }

  @override
  String get negativeFilter => 'Négatif';

  @override
  String todayCountLabel(Object count) {
    return 'Aujourd\'hui : $count';
  }

  @override
  String waitingCountLabel(Object count) {
    return 'En attente : $count';
  }

  @override
  String inProgressCountLabel(Object count) {
    return 'En cours : $count';
  }

  @override
  String completedCountLabel(Object count) {
    return 'Terminé : $count';
  }

  @override
  String get patientSelection => 'Sélection du patient';

  @override
  String get appointmentDateTime => 'Date et heure du rendez-vous';

  @override
  String get appointmentType => 'Type de rendez-vous';

  @override
  String get paymentStatus => 'Statut du paiement';

  @override
  String get incomeLabel => 'Revenu';

  @override
  String get expenseLabel => 'Dépense';

  @override
  String get netProfit => 'Bénéfice net';

  @override
  String get category => 'Catégorie';

  @override
  String get rentLabel => 'Loyer';

  @override
  String get salariesLabel => 'Salaires';

  @override
  String get inventoryLabel => 'Inventaire';

  @override
  String get equipmentLabel => 'Équipement';

  @override
  String get marketingLabel => 'Marketing';

  @override
  String get utilitiesLabel => 'Services publics';

  @override
  String get maintenanceLabel => 'Maintenance';

  @override
  String get taxesLabel => 'Taxes';

  @override
  String get otherLabel => 'Autre';

  @override
  String get productSalesLabel => 'Ventes de produits';

  @override
  String get daily => 'Quotidien';

  @override
  String get weekly => 'Hebdomadaire';

  @override
  String get monthly => 'Mensuel';

  @override
  String get quarterly => 'Trimestriel';

  @override
  String get yearly => 'Annuel';

  @override
  String get custom => 'Personnalisé';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get updateProfile => 'Mettre à jour le profil';

  @override
  String get profileUpdated => 'Profil mis à jour';

  @override
  String get saveFailed => 'Échec de l\'enregistrement';

  @override
  String get deleteVisitConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette visite ?';

  @override
  String get actionNeededLabel => 'Action requise';

  @override
  String get allGoodLabel => 'Tout est correct';

  @override
  String get offlineLabel => 'Hors ligne';

  @override
  String get activationRequiredTitle => 'Activation requise';

  @override
  String get needACodeLabel => 'Besoin d\'un code ?';

  @override
  String get fullNameLabel => 'Nom complet';

  @override
  String get premiumOnlyLabel => 'Premium uniquement';

  @override
  String get limitReachedTitle => 'Limite atteinte';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get clinicAddressLabel => 'Adresse de la clinique';

  @override
  String get provinceLabel => 'Province';

  @override
  String get countryLabel => 'Pays';

  @override
  String get totalAmountLabel => 'Montant total';

  @override
  String get paidAmountLabel => 'Montant payé';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get dentistNotes => 'Notes du dentiste';

  @override
  String get resetAll => 'Tout réinitialiser';

  @override
  String get captureXray => 'Capturer une radiographie';

  @override
  String get waitingForSensorHardware => 'En attente du matériel du capteur...';

  @override
  String get rotate90 => 'Rotation 90°';

  @override
  String get flipHorizontal => 'Retournement horizontal';

  @override
  String get sharpenFilter => 'Filtre Netteté';

  @override
  String get embossFilter => 'Filtre Relief';

  @override
  String get saveCopy => 'Enregistrer une copie';

  @override
  String get smartZoomTool => 'Outil Zoom intelligent';

  @override
  String get measurementTool => 'Outil de mesure';

  @override
  String get draw => 'Dessiner';

  @override
  String get addText => 'Ajouter du texte';

  @override
  String get undo => 'Annuler';

  @override
  String get tabInfo => 'Infos';

  @override
  String get tabVisits => 'Visites';

  @override
  String get tabImaging => 'Imagerie';

  @override
  String get blacklist => 'Liste noire';

  @override
  String get emergencyLabel => 'Urgence';

  @override
  String get notEmergencyLabel => 'Pas d\'urgence';

  @override
  String get blacklistedLabel => 'Sur liste noire';

  @override
  String get notBlacklistedLabel => 'Pas sur liste noire';

  @override
  String healthAlertsLabel(String alerts) {
    return 'Alertes de santé : $alerts';
  }

  @override
  String get accessRestricted => 'Accès restreint';

  @override
  String get onlyDentistsImaging =>
      'Seuls les dentistes peuvent voir les dossiers d\'imagerie.';

  @override
  String imagingHistory(int count) {
    return 'Historique d\'imagerie ($count)';
  }

  @override
  String get imagingStorage => 'Stockage d\'imagerie';

  @override
  String get defaultImagingPath => 'Par défaut (Documents/DentalTid/Imaging)';

  @override
  String get imagingStorageSettings => 'Paramètres de stockage d\'imagerie';

  @override
  String get newXray => 'Nouvelle radiographie';

  @override
  String get gridView => 'Vue en grille';

  @override
  String get listView => 'Vue en liste';

  @override
  String columnsCount(int count) {
    return '$count colonnes';
  }

  @override
  String get sortBy => 'Trier par : ';

  @override
  String get noXraysFound => 'Aucune radiographie trouvée pour ce patient';

  @override
  String get digitalSensor => 'Capteur numérique (TWAIN)';

  @override
  String get uploadFromFile => 'Télécharger à partir d\'un fichier';

  @override
  String get xrayLabel => 'Étiquette de radiographie';

  @override
  String get renameXray => 'Renommer la radiographie';

  @override
  String get deleteXrayConfirmTitle => 'Supprimer la radiographie ?';

  @override
  String get deleteXrayWarning =>
      'Ceci ne peut pas être annulé. Le fichier sera définitivement supprimé.';

  @override
  String capturedDate(Object date) {
    return 'Capturé le : $date';
  }

  @override
  String get importSuccess => 'Importé avec succès';

  @override
  String importError(String error) {
    return 'Échec de l\'importation : $error';
  }

  @override
  String exportSuccess(String path) {
    return 'Exporté vers $path';
  }

  @override
  String exportError(String error) {
    return 'Échec de l\'exportation : $error';
  }

  @override
  String get noNotes => 'Aucune note';

  @override
  String notesLabel(String notes) {
    return 'Notes : $notes';
  }
}
