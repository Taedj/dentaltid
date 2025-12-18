// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get dashboard => 'لوحة القيادة';

  @override
  String get patients => 'المرضى';

  @override
  String get appointments => 'المواعيد';

  @override
  String get inventory => 'المخزون';

  @override
  String get finance => 'المالية';

  @override
  String get addAppointment => 'إضافة موعد';

  @override
  String get editAppointment => 'تعديل الموعد';

  @override
  String get patient => 'المريض';

  @override
  String get selectPatient => 'الرجاء اختيار مريض';

  @override
  String get dateYYYYMMDD => 'التاريخ (YYYY-MM-DD)';

  @override
  String get enterDate => 'الرجاء إدخال تاريخ';

  @override
  String get invalidDateFormat => 'الرجاء إدخال تاريخ صالح بالتنسيق YYYY-MM-DD';

  @override
  String get invalidDate => 'تاريخ غير صالح';

  @override
  String get dateInPast => 'لا يمكن أن يكون التاريخ في الماضي';

  @override
  String get timeHHMM => 'الوقت (HH:MM)';

  @override
  String get enterTime => 'الرجاء إدخال وقت';

  @override
  String get invalidTimeFormat => 'الرجاء إدخال وقت صالح بالتنسيق HH:MM';

  @override
  String get add => 'إضافة';

  @override
  String get update => 'تحديث';

  @override
  String get error => 'خطأ: ';

  @override
  String invalidTime(Object end, Object start) {
    return 'يجب أن يكون الوقت بين $start و $end';
  }

  @override
  String get appointmentExistsError =>
      'يوجد موعد لهذا المريض في هذا التاريخ والوقت بالفعل.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get account => 'الحساب';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get passwordChangedSuccessfully => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get invalidPassword => 'كلمة مرور خاطئة';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get localBackup => 'النسخ الاحتياطي المحلي';

  @override
  String get backupCreatedAt => 'تم إنشاء النسخ الاحتياطي في';

  @override
  String get backupFailedOrCancelled => 'فشل النسخ الاحتياطي أو تم إلغاؤه';

  @override
  String get createLocalBackup => 'إنشاء نسخ احتياطي محلي';

  @override
  String get backupRestoredSuccessfully => 'تم استعادة النسخ الاحتياطي بنجاح';

  @override
  String get restoreFailedOrCancelled => 'فشل الاستعادة أو تم إلغاؤها';

  @override
  String get cloudSync => 'المزامنة السحابية';

  @override
  String get backupUploadedToCloud => 'تم تحميل النسخ الاحتياطي إلى السحابة';

  @override
  String get cloudBackupFailed => 'فشل النسخ الاحتياطي السحابي';

  @override
  String get syncToCloud => 'المزامنة مع السحابة';

  @override
  String get manageCloudBackups => 'إدارة النسخ الاحتياطية السحابية';

  @override
  String get currency => 'العملة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get showAllAppointments => 'عرض جميع المواعيد';

  @override
  String get showUpcomingOnly => 'عرض القادمة فقط';

  @override
  String get timeEarliestFirst => 'الوقت (الأبكر أولاً)';

  @override
  String get timeLatestFirst => 'الوقت (الأحدث أولاً)';

  @override
  String get patientId => 'معرف المريض';

  @override
  String get searchAppointments => 'البحث في المواعيد';

  @override
  String get noAppointmentsFound => 'لم يتم العثور على مواعيد';

  @override
  String get deleteAppointment => 'حذف الموعد';

  @override
  String get confirmDeleteAppointment =>
      'هل أنت متأكد أنك تريد حذف هذا الموعد؟';

  @override
  String get confirm => 'تأكيد';

  @override
  String get welcomeDr => 'مرحباً د.';

  @override
  String get totalNumberOfPatients => 'إجمالي عدد المرضى';

  @override
  String get emergencyPatients => 'مرضى الطوارئ';

  @override
  String get upcomingAppointments => 'المواعيد القادمة';

  @override
  String get payments => 'المدفوعات';

  @override
  String get quickActions => 'الإجراءات السريعة';

  @override
  String get emergencyAlerts => 'تنبيهات الطوارئ';

  @override
  String get noEmergencies => 'لا توجد طوارئ';

  @override
  String get receipt => 'الإيصال';

  @override
  String get total => 'المجموع';

  @override
  String get outstandingAmount => 'المبلغ المستحق';

  @override
  String get close => 'إغلاق';

  @override
  String get addPatient => 'إضافة مريض';

  @override
  String get editPatient => 'تعديل المريض';

  @override
  String get familyName => 'اسم العائلة';

  @override
  String get enterFamilyName => 'الرجاء إدخال اسم العائلة';

  @override
  String get age => 'العمر';

  @override
  String get enterAge => 'الرجاء إدخال العمر';

  @override
  String get enterValidNumber => 'الرجاء إدخال رقم صحيح';

  @override
  String get enterAgeBetween => 'الرجاء إدخال عمر بين 1 و 120';

  @override
  String get healthState => 'حالة الصحة';

  @override
  String get diagnosis => 'التشخيص';

  @override
  String get treatment => 'العلاج';

  @override
  String get payment => 'الدفع';

  @override
  String get enterPaymentAmount => 'الرجاء إدخال مبلغ الدفع';

  @override
  String get paymentCannotBeNegative => 'لا يمكن أن يكون الدفع سلبياً';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get enterValidPhoneNumber => 'الرجاء إدخال رقم هاتف صحيح';

  @override
  String get emergencyDetails => 'تفاصيل الطوارئ';

  @override
  String get isEmergency => 'هل هو طوارئ';

  @override
  String get severity => 'الشدة';

  @override
  String get healthAlerts => 'تنبيهات الصحة';

  @override
  String get paymentHistory => 'تاريخ المدفوعات';

  @override
  String get noPaymentHistory => 'لا يوجد تاريخ مدفوعات';

  @override
  String get edit => 'تعديل';

  @override
  String get save => 'حفظ';

  @override
  String get noPatientsYet => 'لا يوجد مرضى بعد';

  @override
  String get noHealthAlerts => 'لا توجد تنبيهات صحية';

  @override
  String get createdAt => 'تم الإنشاء في';

  @override
  String get emergency => 'طوارئ';

  @override
  String get number => 'الرقم';

  @override
  String get actions => 'الإجراءات';

  @override
  String get deletePatient => 'حذف المريض';

  @override
  String get confirmDeletePatient => 'هل أنت متأكد أنك تريد حذف هذا المريض؟';

  @override
  String get todaysAppointmentsFlow => 'مواعيد اليوم';

  @override
  String get waiting => 'في الانتظار';

  @override
  String get inProgress => 'قيد التقدم';

  @override
  String get completed => 'مكتمل';

  @override
  String get mustBeLoggedInToSync =>
      'يجب عليك تسجيل الدخول للمزامنة مع السحابة.';

  @override
  String get dateNewestFirst => 'التاريخ (الأحدث أولاً)';

  @override
  String get dateOldestFirst => 'التاريخ (الأقدم أولاً)';

  @override
  String get startAppointment => 'بدء الموعد';

  @override
  String get completeAppointment => 'إنهاء الموعد';

  @override
  String get cancelAppointment => 'إلغاء الموعد';

  @override
  String get confirmCancelAppointment =>
      'هل أنت متأكد أنك تريد إلغاء هذا الموعد؟';

  @override
  String get addTransaction => 'إضافة معاملة';

  @override
  String get financialSummary => 'الملخص المالي';

  @override
  String get description => 'الوصف';

  @override
  String get enterDescription => 'الرجاء إدخال وصف';

  @override
  String get totalAmount => 'المبلغ الإجمالي';

  @override
  String get enterTotalAmount => 'الرجاء إدخال المبلغ الإجمالي';

  @override
  String get enterValidPositiveAmount => 'الرجاء إدخال مبلغ موجب صالح';

  @override
  String get paidAmount => 'المبلغ المدفوع';

  @override
  String get enterPaidAmount => 'الرجاء إدخال المبلغ المدفوع';

  @override
  String get enterValidNonNegativeAmount => 'الرجاء إدخال مبلغ غير سالب صالح';

  @override
  String get type => 'النوع';

  @override
  String get income => 'الدخل';

  @override
  String get expense => 'المصروفات';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get cash => 'نقداً';

  @override
  String get card => 'بطاقة';

  @override
  String get bankTransfer => 'تحويل بنكي';

  @override
  String get searchTransactions => 'البحث في المعاملات';

  @override
  String get allTypes => 'جميع الأنواع';

  @override
  String get amountHighestFirst => 'المبلغ (الأعلى أولاً)';

  @override
  String get amountLowestFirst => 'المبلغ (الأدنى أولاً)';

  @override
  String get showAllItems => 'عرض جميع العناصر';

  @override
  String get showExpiredOnly => 'عرض العناصر منتهية الصلاحية فقط';

  @override
  String get showLowStockOnly => 'عرض العناصر منخفضة المخزون فقط';

  @override
  String get nameAZ => 'الاسم (أ-ي)';

  @override
  String get nameZA => 'الاسم (ي-أ)';

  @override
  String get quantityLowToHigh => 'الكمية (من الأقل للأعلى)';

  @override
  String get quantityHighToLow => 'الكمية (من الأعلى للأقل)';

  @override
  String get expirySoonestFirst => 'الانتهاء (الأقرب أولاً)';

  @override
  String get expiryLatestFirst => 'الانتهاء (الأبعد أولاً)';

  @override
  String get searchInventoryItems => 'البحث في عناصر المخزون';

  @override
  String get name => 'الاسم';

  @override
  String get quantity => 'الكمية';

  @override
  String get expirationDate => 'تاريخ انتهاء الصلاحية';

  @override
  String get supplier => 'المورد';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get noItemsFound => 'لم يتم العثور على عناصر';

  @override
  String get expires => 'ينتهي';

  @override
  String get expired => 'منتهي الصلاحية';

  @override
  String get lowStock => 'مخزون منخفض';

  @override
  String get deleteItem => 'حذف العنصر';

  @override
  String get deleteItemButton => 'حذف';

  @override
  String get confirmDeleteItem => 'هل أنت متأكد أنك تريد حذف هذا العنصر؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get enterName => 'الرجاء إدخال اسم';

  @override
  String get enterQuantity => 'الرجاء إدخال كمية';

  @override
  String get enterSupplier => 'الرجاء إدخال مورد';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get restoreFromLocalBackup => 'استعادة من النسخ الاحتياطي المحلي';

  @override
  String get date => 'التاريخ';

  @override
  String get method => 'الطريقة';

  @override
  String get paid => 'مدفوع';

  @override
  String get unpaid => 'غير مدفوع';

  @override
  String get noTransactionsYet => 'لا توجد معاملات بعد';

  @override
  String get visitHistory => 'تاريخ الزيارات';

  @override
  String get noVisitHistory => 'لا يوجد تاريخ زيارات';

  @override
  String get visitDate => 'تاريخ الزيارة';

  @override
  String get reasonForVisit => 'سبب الزيارة';

  @override
  String get addVisit => 'إضافة زيارة';

  @override
  String get editVisit => 'تعديل الزيارة';

  @override
  String get notes => 'الملاحظات';

  @override
  String get enterReasonForVisit => 'الرجاء إدخال سبب الزيارة';

  @override
  String get searchPatient => 'البحث عن مريض';

  @override
  String get showCurrentDayPatients => 'عرض مرضى اليوم';

  @override
  String get visitDetails => 'تفاصيل الزيارة';

  @override
  String get createNewVisit => 'إنشاء زيارة جديدة';

  @override
  String get selectExistingVisit => 'اختيار زيارة موجودة';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get emergencySeverity => 'شدة الطوارئ';

  @override
  String get sessionDetails => 'تفاصيل الجلسة';

  @override
  String get numberOfSessions => 'عدد الجلسات';

  @override
  String get session => 'الجلسة';

  @override
  String get dateTime => 'التاريخ والوقت';

  @override
  String get treatmentDetails => 'تفاصيل العلاج';

  @override
  String get patientNotes => 'ملاحظات المريض';

  @override
  String get blacklistPatient => 'مريض في القائمة السوداء';

  @override
  String get noTransactionsFound => 'لم يتم العثور على معاملات لهذه الفترة';

  @override
  String get recurringCharges => 'رسوم متكررة';

  @override
  String get noRecurringChargesFound => 'لم يتم العثور على رسوم متكررة';

  @override
  String get addRecurringCharge => 'إضافة رسوم متكررة';

  @override
  String get editRecurringCharge => 'تعديل الرسوم المتكررة';

  @override
  String get amount => 'المبلغ';

  @override
  String get frequency => 'التكرار';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get isActive => 'نشط';

  @override
  String get transactions => 'المعاملات';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get dailySummary => 'ملخص يومي';

  @override
  String get weeklySummary => 'ملخص أسبوعي';

  @override
  String get monthlySummary => 'ملخص شهري';

  @override
  String get yearlySummary => 'ملخص سنوي';

  @override
  String get expenses => 'المصروفات';

  @override
  String get profit => 'الربح';

  @override
  String get filters => 'الفلاتر';

  @override
  String get inventoryExpenses => 'مصاريف المخزون';

  @override
  String get staffSalaries => 'رواتب الموظفين';

  @override
  String get rent => 'الإيجار';

  @override
  String get changeDate => 'تغيير التاريخ';

  @override
  String get transactionAddedSuccessfully => 'تم إضافة المعاملة بنجاح';

  @override
  String get invalidAmount => 'مبلغ غير صالح';

  @override
  String get pleaseEnterAmount => 'الرجاء إدخال مبلغ';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get criticalAlerts => 'تنبيهات حرجة';

  @override
  String get viewCritical => 'عرض الحالات الحرجة';

  @override
  String get viewAppointments => 'عرض المواعيد';

  @override
  String todayCount(int count) {
    return 'اليوم: $count';
  }

  @override
  String waitingCount(int count) {
    return 'قيد الانتظار: $count';
  }

  @override
  String inProgressCount(int count) {
    return 'جارٍ: $count';
  }

  @override
  String completedCount(int count) {
    return 'مكتمل: $count';
  }

  @override
  String emergencyCountLabel(int count) {
    return 'طوارئ: $count';
  }

  @override
  String get expiringSoon => 'تنتهي صلاحيتها قريبًا';

  @override
  String expiringSoonCount(int count) {
    return 'تنتهي قريبًا: $count';
  }

  @override
  String lowStockCount(int count) {
    return 'مخزون منخفض: $count';
  }

  @override
  String get patientName => 'اسم المريض';

  @override
  String get itemName => 'اسم العنصر';

  @override
  String get countdown => 'العد التنازلي';

  @override
  String get currentQuantity => 'الكمية الحالية';

  @override
  String daysLeft(int days) {
    return 'متبقي $days يوم';
  }

  @override
  String get noPatientsToday => 'لا يوجد مرضى اليوم';

  @override
  String get noExpiringSoonItems => 'لا توجد عناصر تنتهي صلاحيتها قريبًا';

  @override
  String get noLowStockItems => 'لا توجد عناصر منخفضة المخزون';

  @override
  String get noWaitingAppointments => 'لا توجد مواعيد قيد الانتظار';

  @override
  String get noEmergencyAppointments => 'لا توجد مواعيد طوارئ';

  @override
  String get noCompletedAppointments => 'لا توجد مواعيد مكتملة';

  @override
  String get errorLoadingEmergencyAppointments => 'خطأ في تحميل مواعيد الطوارئ';

  @override
  String get errorLoadingAppointments => 'خطأ في تحميل المواعيد';

  @override
  String get errorLoadingPatientData => 'خطأ في تحميل بيانات المريض';

  @override
  String get errorLoadingInventory => 'خطأ في تحميل المخزون';

  @override
  String get dateOfBirthLabel => 'تاريخ الميلاد';

  @override
  String get selectDateOfBirthError => 'يرجى اختيار تاريخ الميلاد';

  @override
  String get invalidDateFormatError => 'تنسيق التاريخ غير صالح';

  @override
  String get patientSelectionTitle => 'اختر المريض';

  @override
  String get choosePatientLabel => 'اختر مريضاً';

  @override
  String get selectPatientLabel => 'تحديد المريض';

  @override
  String get addNewPatientButton => 'إضافة مريض جديد';

  @override
  String get appointmentDateTimeTitle => 'تاريخ ووقت الموعد';

  @override
  String get dateTimeLabel => 'التاريخ والوقت';

  @override
  String get selectDateTimeLabel => 'اختر التاريخ والوقت';

  @override
  String get selectDateTimeError => 'يرجى اختيار التاريخ والوقت';

  @override
  String get appointmentTypeTitle => 'نوع الموعد';

  @override
  String get selectTypeLabel => 'اختر النوع';

  @override
  String get paymentStatusTitle => 'حالة الدفع';

  @override
  String get consultationType => 'استشارة';

  @override
  String get followupType => 'متابعة';

  @override
  String get emergencyType => 'طوارئ';

  @override
  String get procedureType => 'إجراء';

  @override
  String get failedToSaveItemError => 'فشل حفظ العنصر';

  @override
  String get failedToUseItemError => 'فشل استخدام العنصر';

  @override
  String get failedToDeleteItemError => 'فشل حذف العنصر';

  @override
  String get useTooltip => 'استخدام';

  @override
  String get periodToday => 'اليوم';

  @override
  String get periodThisWeek => 'هذا الأسبوع';

  @override
  String get periodThisMonth => 'هذا الشهر';

  @override
  String get periodThisYear => 'هذه السنة';

  @override
  String get periodGlobal => 'الكل';

  @override
  String get periodCustom => 'مخصص';

  @override
  String get periodCustomDate => 'تاريخ مخصص';

  @override
  String get incomeTitle => 'الدخل';

  @override
  String get expensesTitle => 'المصاريف';

  @override
  String get netProfitTitle => 'صافي الربح';

  @override
  String get taxLabel => 'الضريبة';

  @override
  String get monthlyBudgetTitle => 'الميزانية الشهرية';

  @override
  String get budgetExceededAlert => 'تم تجاوز الميزانية!';

  @override
  String get recurringChargesTooltip => 'الفواتير المتكررة';

  @override
  String get financeSettingsTooltip => 'إعدادات المالية';

  @override
  String get incomeType => 'دخل';

  @override
  String get expenseType => 'مصروف';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get categoryLabel => 'فئة';

  @override
  String get deleteRecurringChargeTitle => 'حذف الفاتورة المتكررة';

  @override
  String get deleteRecurringChargeContent =>
      'هل أنت متأكد من حذف هذه الفاتورة المتكررة؟';

  @override
  String get transactionAddedSuccess => 'تمت إضافة المعاملة بنجاح';

  @override
  String get catRent => 'إيجار';

  @override
  String get catSalaries => 'رواتب';

  @override
  String get catInventory => 'مخزون';

  @override
  String get catEquipment => 'معدات';

  @override
  String get catMarketing => 'تسويق';

  @override
  String get catUtilities => 'خدمات';

  @override
  String get catMaintenance => 'صيانة';

  @override
  String get catTaxes => 'ضرائب';

  @override
  String get catOther => 'أخرى';

  @override
  String get catProductSales => 'مبيعات المنتجات';

  @override
  String get freqDaily => 'يومي';

  @override
  String get freqWeekly => 'أسبوعي';

  @override
  String get freqMonthly => 'شهري';

  @override
  String get freqQuarterly => 'ربع سنوي';

  @override
  String get freqYearly => 'سنوي';

  @override
  String get freqCustom => 'مخصص';

  @override
  String get errorSavingRecurringCharge => 'خطأ في حفظ الفاتورة المتكررة';

  @override
  String get editItem => 'تعديل العنصر';

  @override
  String get costPerUnit => 'التكلفة لكل وحدة';

  @override
  String get totalCost => 'التكلفة الإجمالية';

  @override
  String get costType => 'نوع التكلفة';

  @override
  String calculatedUnitCost(String currency, String cost) {
    return 'تلكفة الوحدة المحسوبة: $currency$cost';
  }

  @override
  String get enterCost => 'الرجاء إدخال التكلفة';

  @override
  String get expiresDays => 'تنتهي الصلاحية (أيام)';

  @override
  String get lowStockLevel => 'مستوى المخزون المنخفض';

  @override
  String useItemTitle(String itemName) {
    return 'استخدام $itemName';
  }

  @override
  String currentStock(int quantity) {
    return 'المخزون الحالي: $quantity';
  }

  @override
  String get quantityToUse => 'الكمية المراد استخدامها';

  @override
  String get unitsSuffix => 'وحدات';

  @override
  String get enterValidPositiveNumber => 'الرجاء إدخال رقم موجب صحيح';

  @override
  String get cannotUseMoreThanStock => 'لا يمكن استخدام أكثر من المخزون الحالي';

  @override
  String remainingStock(int quantity) {
    return 'المخزون المتبقي: $quantity';
  }

  @override
  String get confirmUse => 'تأكيد الاستخدام';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterToday => 'اليوم';

  @override
  String get filterThisWeek => 'هذا الأسبوع';

  @override
  String get filterThisMonth => 'هذا الشهر';

  @override
  String get filterEmergency => 'طوارئ';

  @override
  String get patientIdHeader => 'المعرف';

  @override
  String get dueHeader => 'مستحق';

  @override
  String get totalCostLabel => 'التكلفة الإجمالية (\$)';

  @override
  String get amountPaidLabel => 'المبلغ المدفوع (\$)';

  @override
  String get balanceDueLabel => 'الرصيد المستحق';

  @override
  String get visitHistoryTitle => 'سجل الزيارات';

  @override
  String lastVisitLabel(String date) {
    return 'آخر زيارة: $date';
  }

  @override
  String get selectPatientToViewHistory => 'اختر مريضاً لعرض\nسجل الزيارات';

  @override
  String get addEditButton => 'إضافة/تعديل';

  @override
  String get saveButton => 'حفظ';

  @override
  String get profitTrend => 'اتجاه الأرباح';

  @override
  String get expenseBreakdown => 'توزيع النفقات';

  @override
  String get noExpensesInPeriod => 'لا توجد نفقات في هذه الفترة';

  @override
  String get noDataToDisplay => 'لا توجد بيانات لعرضها';

  @override
  String get cancelled => 'ملغى';

  @override
  String get unknownPatient => 'مريض غير معروف';

  @override
  String get loading => 'جار التحميل...';

  @override
  String get errorLabel => 'خطأ';
}
