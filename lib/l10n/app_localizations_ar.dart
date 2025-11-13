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
  String get todaysAppointmentsFlow => 'تدفق مواعيد اليوم';

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
}
