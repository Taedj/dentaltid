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
  String get welcome => 'مرحباً';

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

  @override
  String get delete => 'حذف';

  @override
  String get deleteTransaction => 'حذف المعاملة';

  @override
  String get premiumAccount => 'حساب مميز';

  @override
  String premiumDaysLeft(int days) {
    return 'مميز: $days أيام متبقية';
  }

  @override
  String get premiumExpired => 'انتهى البريميوم';

  @override
  String trialVersionDaysLeft(int days) {
    return 'نسخة تجريبية: $days أيام متبقية';
  }

  @override
  String get trialExpired => 'انتهت الفترة التجريبية';

  @override
  String get activatePremium => 'تفعيل البريميوم';

  @override
  String get financeSettings => 'إعدادات المالية';

  @override
  String get includeInventoryCosts => 'تضمين تكاليف المخزون';

  @override
  String get includeAppointments => 'تضمين المواعيد';

  @override
  String get includeRecurringCharges => 'تضمين الرسوم المتكررة';

  @override
  String get compactNumbers => 'أرقام مدمجة (مثال: 1K)';

  @override
  String get compactNumbersSubtitle => 'استخدم تنسيقاً قصيراً للأرقام الكبيرة';

  @override
  String get monthlyBudgetCap => 'الحد الأقصى للميزانية الشهرية';

  @override
  String get taxRatePercentage => 'معدل الضريبة (%)';

  @override
  String get staffManagement => 'إدارة الموظفين';

  @override
  String get addAssistant => 'إضافة مساعد';

  @override
  String get addReceptionist => 'إضافة موظف استقبال';

  @override
  String get currentStaff => 'الموظفون الحاليون';

  @override
  String get noStaffAdded => 'لم يتم إضافة موظفين بعد';

  @override
  String get changePin => 'تغيير رمز PIN';

  @override
  String get removeStaff => 'إزالة الموظف';

  @override
  String get updatePin => 'تحديث رمز PIN';

  @override
  String get newPin => 'رمز PIN جديد (4 أرقام)';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get enterUsername => 'أدخل اسم المستخدم للموظف';

  @override
  String get addStaff => 'إضافة موظف';

  @override
  String get staffAddedSuccess => 'تم إضافة الموظف بنجاح';

  @override
  String get staffRemovedSuccess => 'تم إزالة الموظف';

  @override
  String get pinUpdatedSuccess => 'تم تحديث رمز PIN بنجاح';

  @override
  String get deleteStaffTitle => 'حذف موظف';

  @override
  String deleteStaffConfirm(String username) {
    return 'هل أنت متأكد أنك تريد إزالة $username؟';
  }

  @override
  String get roleAssistant => 'مساعد';

  @override
  String get roleReceptionist => 'موظف استقبال';

  @override
  String get roleDentist => 'طبيب أسنان';

  @override
  String get roleDeveloper => 'مطور';

  @override
  String overpaid(String amount) {
    return 'مدفوع بالزيادة: $amount';
  }

  @override
  String due(String amount) {
    return 'مستحق: $amount';
  }

  @override
  String get fullyPaid => 'مدفوع بالكامل';

  @override
  String appointmentPaymentDescription(String type) {
    return 'دفع موعد لـ $type';
  }

  @override
  String get proratedLabel => 'تناسبي';

  @override
  String get days => 'أيام';

  @override
  String get status => 'الحالة';

  @override
  String get deleteVisit => 'حذف الزيارة';

  @override
  String get connectionSettings => 'إعدادات الاتصال';

  @override
  String get networkConnection => 'اتصال الشبكة';

  @override
  String get serverDeviceNotice =>
      'هذا الجهاز هو الخادم. شارك عنوان IP أدناه مع أجهزة الموظفين.';

  @override
  String get clientDeviceNotice =>
      'هذا الجهاز هو عميل. أدخل عنوان IP للخادم للاتصال.';

  @override
  String get connectionStatus => 'حالة الاتصال';

  @override
  String get possibleIpAddresses => 'عناوين IP الممكنة:';

  @override
  String get manualConnection => 'اتصال يدوي';

  @override
  String get serverIpAddress => 'عنوان IP للخادم';

  @override
  String get connectToServer => 'الاتصال بالخادم';

  @override
  String get connecting => 'جاري الاتصال...';

  @override
  String get connectedSync => 'تم الاتصال! جاري بدء المزامنة...';

  @override
  String get invalidIpOrPort => 'عنوان IP أو منفذ غير صالح';

  @override
  String get firewallWarning =>
      'إذا فشل الاتصال، فافحص جدار حماية Windows للسماح بـ \'DentalTid\' على الشبكات الخاصة/العامة.';

  @override
  String get readyToConnect => 'جاهز للاتصال.';

  @override
  String get serverRunning => 'الخادم قيد التشغيل';

  @override
  String get serverStopped => 'تم إيقاف الخادم';

  @override
  String get startServer => 'بدء تشغيل الخادم';

  @override
  String get stopServer => 'إيقاف الخادم';

  @override
  String get serverLogs => 'سجلات الخادم';

  @override
  String get copyLogsSuccess => 'تم نسخ السجلات إلى الحافظة';

  @override
  String get port => 'المنفذ';

  @override
  String get acceptTermsError => 'يرجى قبول الشروط والأحكام';

  @override
  String get dentistLogin => 'دخول طبيب الأسنان';

  @override
  String get dentistRegistration => 'تسجيل طبيب الأسنان';

  @override
  String get staffPortal => 'بوابة الموظفين';

  @override
  String get forgotPassword => 'هل نسيت كلمة السر؟';

  @override
  String get authError => 'حدث خطأ، يرجى التحقق من بيانات الاعتماد الخاصة بك.';

  @override
  String get weakPasswordError => 'كلمة المرور المقدمة ضعيفة للغاية.';

  @override
  String get emailInUseError => 'يوجد حساب بالفعل لهذا البريد الإلكتروني.';

  @override
  String get userNotFoundError =>
      'لم يتم العثور على مستخدم لهذا البريد الإلكتروني.';

  @override
  String get wrongPasswordError => 'كلمة مرور خاطئة لهذا المستخدم.';

  @override
  String get networkError => 'خطأ في الشبكة. تحقق من اتصالك.';

  @override
  String authFailed(String error) {
    return 'فشل المصادقة: $error';
  }

  @override
  String get invalidStaffCredentials => 'اسم المستخدم أو رمز PIN غير صحيح';

  @override
  String get enterEmailFirst => 'يرجى إدخال عنوان بريدك الإلكتروني أولاً';

  @override
  String get passwordResetSent =>
      'تم إرسال بريد إلكتروني لإعادة تعيين كلمة المرور! تحقق من بريدك الوارد.';

  @override
  String get contactDeveloperLabel => 'اتصل بالمطور';

  @override
  String get contactUs => 'اتصل بنا';

  @override
  String get dentist => 'طبيب أسنان';

  @override
  String get staff => 'موظف';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get yourName => 'اسمك';

  @override
  String get clinicNameLabel => 'اسم العيادة';

  @override
  String get licenseNumber => 'رقم الترخيص';

  @override
  String get acceptTermsAndConditions => 'أوافق على الشروط والأحكام';

  @override
  String get pin4Digits => 'رمز PIN (4 أرقام)';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get register => 'تسجيل';

  @override
  String get loginLabel => 'دخول';

  @override
  String get rememberLabel => 'تذكرني';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ ';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get signUpSmall => 'سجل الآن';

  @override
  String get signInSmall => 'سجل الدخول';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String get scheduledVisits => 'الزيارات المجدولة';

  @override
  String get actionNeeded => 'إجراء مطلوب';

  @override
  String get allGood => 'كل شيء جيد';

  @override
  String activeStatus(int count) {
    return 'نشط: $count';
  }

  @override
  String doneStatus(int count) {
    return 'تم: $count';
  }

  @override
  String get clinicRunningSmoothly => 'العيادة تعمل بسلاسة اليوم 🦷';

  @override
  String expiringLabel(int count) {
    return '$count تنتهي صلاحيتها';
  }

  @override
  String lowStockLabelText(int count) {
    return '$count مخزون منخفض';
  }

  @override
  String get staffActivationNotice =>
      'يجب على طبيب الأسنان الرئيسي تفعيل العضوية المميزة للاستمرار في استخدام التطبيق.';

  @override
  String get overviewMenu => 'نظرة عامة';

  @override
  String get usersMenu => 'المستخدمين';

  @override
  String get codesMenu => 'الأكواد';

  @override
  String get broadcastsMenu => 'البث';

  @override
  String get serverOnlineNoStaff => 'الخادم متصل (لا يوجد موظفين متصلين)';

  @override
  String serverOnlineWithStaffCount(int count) {
    return 'الخادم متصل ($count موظفين متصلين)';
  }

  @override
  String staffConnectedList(String names) {
    return 'المتصلون: $names';
  }

  @override
  String get connectedToServer => 'متصل بالخادم';

  @override
  String get offline => 'غير متصل';

  @override
  String get invalidCodeLength => 'طول الكود غير صحيح (يجب أن يكون 27 حرفاً)';

  @override
  String get activationSuccess =>
      'تم تفعيل الحساب بنجاح! الميزات المميزة مفعلة الآن.';

  @override
  String get invalidActivationCode => 'كود التفعيل غير صحيح أو منتهي الصلاحية';

  @override
  String activationError(String error) {
    return 'خطأ أثناء التفعيل: $error';
  }

  @override
  String get activationRequired => 'التفعيل مطلوب';

  @override
  String get trialExpiredNotice =>
      'انتهت الفترة التجريبية الخاصة بك. يرجى إدخال كود تفعيل صالح للاستمرار في استخدام DentalTid Premium.';

  @override
  String get activationCodeLabel => 'كود التفعيل (27 حرفاً)';

  @override
  String get needACode => 'هل تحتاج إلى كود؟';

  @override
  String get editDoctorProfile => 'تعديل الملف الشخصي للطبيب';

  @override
  String get updateYourProfile => 'تحديث ملفك الشخصي';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get enterYourName => 'يرجى إدخال اسمك';

  @override
  String get profileUpdatedSuccess => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String profileUpdateError(String error) {
    return 'فشل في حفظ الملف الشخصي: $error';
  }

  @override
  String get loginToSaveProfileError =>
      'تعذر حفظ الملف الشخصي. المستخدم غير مسجل الدخول.';

  @override
  String get required => 'مطلوب';

  @override
  String get mustBe4Digits => 'يجب أن يكون 4 أرقام';

  @override
  String get editStaff => 'تعديل الموظف';

  @override
  String get addNewStaff => 'إضافة موظف جديد';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get systemHealth => 'صحة النظام';

  @override
  String get developerOverview => 'نظرة عامة للمطور';

  @override
  String get totalUsers => 'إجمالي المستخدمين';

  @override
  String get activeTrials => 'التجارب النشطة';

  @override
  String get estRevenue => 'الإيرادات المقدرة';

  @override
  String noPatientsFoundSearch(String query) {
    return 'لم يتم العثور على مرضى يطابقون \"$query\"';
  }

  @override
  String get paidStatusLabel => 'مدفوع';

  @override
  String get searchHintSeparator => 'أو الهاتف...';

  @override
  String get savePatientsCsvLabel => 'حفظ ملف المرضى CSV';

  @override
  String get localBackupConfirm =>
      'سيشمل هذا النسخ الاحتياطي قاعدة بيانات عيادتك وإعدادات التطبيق وحسابات الموظفين. هل تريد الاستمرار؟';

  @override
  String get premiumOnly => 'للمشتركين فقط';

  @override
  String get cloudSyncConfirm =>
      'سيؤدي هذا إلى رفع قاعدة بيانات عيادتك وإعداداتك وحسابات الموظفين إلى السحابة للحفاظ عليها. هل تريد الاستمرار؟';

  @override
  String get cloudSyncPremiumNotice =>
      'المزامنة السحابية هي ميزة متقدمة للمشتركين. قم بالتفعيل للتمكين.';

  @override
  String get manageStaffMembers => 'إدارة أعضاء الفريق';

  @override
  String get addStaffSubtitle => 'إضافة مساعدين أو موظفي استقبال';

  @override
  String get lanSyncSettings => 'إعدادات مزامنة الشبكة المحلية';

  @override
  String get autoStartServerLabel => 'تشغيل الخادم تلقائياً';

  @override
  String get autoStartServerSubtitle =>
      'بدء تشغيل خادم المزامنة عند فتح التطبيق';

  @override
  String get serverPortLabel => 'منفذ الخادم';

  @override
  String get defaultPortHelper => 'الافتراضي: 8080';

  @override
  String get advancedNetworkConfig => 'تكوين الشبكة المتقدم';

  @override
  String get advancedNetworkConfigSubtitle =>
      'السجلات، جدار الحماية، وإعدادات IP';

  @override
  String errorLoadingProfile(String error) {
    return 'خطأ في تحميل الملف الشخصي: $error';
  }

  @override
  String get deleteTransactionConfirm =>
      'هل أنت متأكد أنك تريد حذف هذه العملية؟';

  @override
  String get transactionDeletedSuccess => 'تم حذف العملية بنجاح';

  @override
  String get limitReached => 'تم الوصول إلى الحد الأقصى';

  @override
  String get inventoryLimitMessage =>
      'لقد وصلت إلى الحد الأقصى وهو 100 عنصر مخزون للنسخة التجريبية.\nيرجى الترقية إلى النسخة المميزة لمتابعة إضافة العناصر.';

  @override
  String get okButton => 'حسناً';

  @override
  String get trialActive => 'فترة تجريبية';
}
