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
  String get todaysAppointmentsFlow => 'Flux des rendez-vous d\'aujourd\'hui';

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
}
