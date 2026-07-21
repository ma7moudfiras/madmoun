///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsAr = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ar>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$common$ar common = Translations$common$ar.internal(_root);
	late final Translations$account$ar account = Translations$account$ar.internal(_root);
	late final Translations$reset$ar reset = Translations$reset$ar.internal(_root);
	late final Translations$enums$ar enums = Translations$enums$ar.internal(_root);
	late final Translations$home$ar home = Translations$home$ar.internal(_root);
	late final Translations$device$ar device = Translations$device$ar.internal(_root);
	late final Translations$reserve$ar reserve = Translations$reserve$ar.internal(_root);
	late final Translations$orders$ar orders = Translations$orders$ar.internal(_root);
	late final Translations$auth$ar auth = Translations$auth$ar.internal(_root);
	late final Translations$seller$ar seller = Translations$seller$ar.internal(_root);
	late final Translations$admin$ar admin = Translations$admin$ar.internal(_root);
	Map<String, String> get errors => {
		'INVALID_STATE_TRANSITION': 'لا يمكن تنفيذ هذا الانتقال في حالة الجهاز.',
		'ADMIN_ONLY_TRANSITION': 'هذا الإجراء متاح لإدارة المنصة فقط.',
		'CHECKLIST_INCOMPLETE': 'أكمل جميع بنود الفحص أولًا.',
		'INSUFFICIENT_PHOTOS': 'أضف 4 صور على الأقل قبل الإرسال.',
		'IMEI_REQUIRED': 'أدخل رقم IMEI للجهاز.',
		'GRADE_REQUIRED': 'لم يُحسب تقييم الجهاز — أكمل الفحص.',
		'DEVICE_NOT_AVAILABLE': 'الجهاز لم يعد متاحًا للحجز.',
		'DEVICE_NOT_FOUND': 'الجهاز غير موجود.',
		'AUTH_REQUIRED': 'سجّل الدخول أولًا.',
		'INVALID_PHONE': 'رقم الهاتف غير صالح.',
		'CITY_REQUIRED': 'أدخل مدينة التسليم.',
		'ADMIN_ONLY': 'صلاحيات غير كافية.',
		'REJECTION_REASON_REQUIRED': 'اكتب سبب الرفض.',
		'SHOP_NOT_APPROVED': 'لا يمكن إضافة أجهزة قبل اعتماد المتجر.',
		'UPDATE_FORBIDDEN': 'لا تملك صلاحية تنفيذ هذا الإجراء.',
	};
}

// Path: common
class Translations$common$ar {
	Translations$common$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'مضمون'
	String get appName => 'مضمون';

	/// ar: 'أجهزة مستعملة بضمان، من متاجر معتمدة'
	String get tagline => 'أجهزة مستعملة بضمان، من متاجر معتمدة';

	/// ar: 'جارٍ التحميل…'
	String get loading => 'جارٍ التحميل…';

	/// ar: 'إعادة المحاولة'
	String get retry => 'إعادة المحاولة';

	/// ar: 'إلغاء'
	String get cancel => 'إلغاء';

	/// ar: 'حفظ'
	String get save => 'حفظ';

	/// ar: 'تأكيد'
	String get confirm => 'تأكيد';

	/// ar: 'إغلاق'
	String get close => 'إغلاق';

	/// ar: 'رجوع'
	String get back => 'رجوع';

	/// ar: 'بحث'
	String get search => 'بحث';

	/// ar: 'الكل'
	String get all => 'الكل';

	/// ar: 'اختياري'
	String get optional => 'اختياري';

	/// ar: 'هذا الحقل مطلوب'
	String get requiredField => 'هذا الحقل مطلوب';

	/// ar: 'رقم الهاتف غير صالح — مثال: 0599123456'
	String get invalidPhone => 'رقم الهاتف غير صالح — مثال: 0599123456';

	/// ar: 'تسجيل الخروج'
	String get signOut => 'تسجيل الخروج';

	/// ar: 'الحساب'
	String get account => 'الحساب';

	/// ar: 'تسجيل الدخول'
	String get login => 'تسجيل الدخول';

	/// ar: 'إنشاء حساب'
	String get register => 'إنشاء حساب';

	/// ar: 'طلباتي'
	String get myOrders => 'طلباتي';

	/// ar: 'بوابة البائع'
	String get sellerPortal => 'بوابة البائع';

	/// ar: 'لوحة الإدارة'
	String get adminPanel => 'لوحة الإدارة';

	/// ar: 'السوق'
	String get marketplace => 'السوق';

	/// ar: 'الصفحة غير موجودة'
	String get notFoundTitle => 'الصفحة غير موجودة';

	/// ar: 'الرابط الذي فتحته غير صحيح أو لم يعد متاحًا.'
	String get notFoundBody => 'الرابط الذي فتحته غير صحيح أو لم يعد متاحًا.';

	/// ar: 'العودة للرئيسية'
	String get backHome => 'العودة للرئيسية';

	/// ar: 'حدث خطأ غير متوقع. حاول مرة أخرى.'
	String get genericError => 'حدث خطأ غير متوقع. حاول مرة أخرى.';

	/// ar: 'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.'
	String get networkError => 'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.';

	/// ar: 'ضمان {days} يوم'
	String warrantyDays({required Object days}) => 'ضمان ${days} يوم';

	/// ar: 'السعر'
	String get priceLabel => 'السعر';

	/// ar: 'المدينة'
	String get cityLabel => 'المدينة';

	/// ar: 'رقم الهاتف'
	String get phoneLabel => 'رقم الهاتف';

	/// ar: '0599123456'
	String get phoneHint => '0599123456';

	/// ar: 'ملاحظة'
	String get noteLabel => 'ملاحظة';

	/// ar: 'البريد الإلكتروني'
	String get emailLabel => 'البريد الإلكتروني';

	/// ar: 'كلمة المرور'
	String get passwordLabel => 'كلمة المرور';

	/// ar: 'الاسم الكامل'
	String get fullNameLabel => 'الاسم الكامل';

	/// ar: 'عرض المزيد'
	String get showMore => 'عرض المزيد';

	/// ar: 'تحديث'
	String get refresh => 'تحديث';

	/// ar: 'تم النسخ'
	String get copied => 'تم النسخ';

	/// ar: 'اليوم'
	String get today => 'اليوم';

	/// ar: 'إعدادات الحساب'
	String get accountSettings => 'إعدادات الحساب';

	/// ar: 'تم الحفظ'
	String get saved => 'تم الحفظ';
}

// Path: account
class Translations$account$ar {
	Translations$account$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'حسابي'
	String get title => 'حسابي';

	/// ar: 'المعلومات الشخصية'
	String get profileSection => 'المعلومات الشخصية';

	/// ar: 'تظهر هذه المعلومات لتنسيق الطلبات والتوصيل.'
	String get profileHint => 'تظهر هذه المعلومات لتنسيق الطلبات والتوصيل.';

	/// ar: 'حفظ المعلومات'
	String get saveProfile => 'حفظ المعلومات';

	/// ar: 'تم تحديث معلوماتك'
	String get profileSaved => 'تم تحديث معلوماتك';

	/// ar: 'البريد الإلكتروني'
	String get emailSection => 'البريد الإلكتروني';

	/// ar: 'بريدك الحالي: {email}'
	String currentEmail({required Object email}) => 'بريدك الحالي: ${email}';

	/// ar: 'البريد الإلكتروني الجديد'
	String get newEmailLabel => 'البريد الإلكتروني الجديد';

	/// ar: 'تغيير البريد'
	String get changeEmail => 'تغيير البريد';

	/// ar: 'أرسلنا رابط تأكيد إلى بريدك الجديد. افتحه لإتمام التغيير.'
	String get emailChangeSent => 'أرسلنا رابط تأكيد إلى بريدك الجديد. افتحه لإتمام التغيير.';

	/// ar: 'كلمة المرور'
	String get passwordSection => 'كلمة المرور';

	/// ar: 'كلمة المرور الجديدة'
	String get newPasswordLabel => 'كلمة المرور الجديدة';

	/// ar: 'تأكيد كلمة المرور'
	String get confirmPasswordLabel => 'تأكيد كلمة المرور';

	/// ar: 'تغيير كلمة المرور'
	String get changePassword => 'تغيير كلمة المرور';

	/// ar: 'تم تغيير كلمة المرور بنجاح'
	String get passwordChanged => 'تم تغيير كلمة المرور بنجاح';

	/// ar: 'كلمتا المرور غير متطابقتين'
	String get passwordMismatch => 'كلمتا المرور غير متطابقتين';

	/// ar: 'نوع الحساب'
	String get roleLabel => 'نوع الحساب';
}

// Path: reset
class Translations$reset$ar {
	Translations$reset$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'نسيت كلمة المرور؟'
	String get forgot => 'نسيت كلمة المرور؟';

	/// ar: 'استعادة كلمة المرور'
	String get title => 'استعادة كلمة المرور';

	/// ar: 'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.'
	String get body => 'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.';

	/// ar: 'إرسال الرابط'
	String get send => 'إرسال الرابط';

	/// ar: 'إذا كان البريد مسجّلًا، ستصلك رسالة لإعادة التعيين.'
	String get sent => 'إذا كان البريد مسجّلًا، ستصلك رسالة لإعادة التعيين.';

	/// ar: 'تعيين كلمة مرور جديدة'
	String get newTitle => 'تعيين كلمة مرور جديدة';

	/// ar: 'اختر كلمة مرور جديدة لحسابك.'
	String get newBody => 'اختر كلمة مرور جديدة لحسابك.';

	/// ar: 'تم تحديث كلمة المرور. يمكنك المتابعة الآن.'
	String get updated => 'تم تحديث كلمة المرور. يمكنك المتابعة الآن.';
}

// Path: enums
class Translations$enums$ar {
	Translations$enums$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	Map<String, String> get deviceStatus => {
		'draft': 'مسودة',
		'under_inspection': 'قيد الفحص',
		'listed': 'معروض',
		'reserved': 'محجوز',
		'sold': 'مُباع',
		'warranty_active': 'ضمان فعّال',
		'warranty_closed': 'انتهى الضمان',
		'rejected': 'مرفوض',
		'returned': 'مُرتجع',
	};
	Map<String, String> get reservationStatus => {
		'pending': 'بانتظار التأكيد',
		'confirmed': 'مؤكد',
		'delivered': 'تم التسليم',
		'cancelled': 'ملغي',
	};
	Map<String, String> get shopStatus => {
		'pending': 'بانتظار الموافقة',
		'approved': 'معتمد',
		'rejected': 'مرفوض',
	};
	Map<String, String> get claimStatus => {
		'open': 'مفتوحة',
		'in_review': 'قيد المراجعة',
		'resolved': 'تم الحل',
		'rejected': 'مرفوضة',
	};
	Map<String, String> get grade => {
		'excellent': 'ممتاز',
		'very_good': 'جيد جدًا',
		'good': 'جيد',
		'fair': 'مقبول',
	};
	Map<String, String> get category => {
		'mobile': 'موبايل',
		'laptop': 'لابتوب',
	};
	Map<String, String> get checklistResult => {
		'pass': 'سليم',
		'minorIssue': 'ملاحظة بسيطة',
		'fail': 'عطل',
	};
	Map<String, String> get currency => {
		'ILS': 'شيكل (₪)',
		'USD': 'دولار (\$)',
	};
}

// Path: home
class Translations$home$ar {
	Translations$home$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'أجهزة مستعملة… مضمونة'
	String get heroTitle => 'أجهزة مستعملة… مضمونة';

	/// ar: 'موبايلات ولابتوبات مفحوصة فنيًا من متاجر معتمدة، بضمان إلزامي والدفع عند الاستلام.'
	String get heroSubtitle => 'موبايلات ولابتوبات مفحوصة فنيًا من متاجر معتمدة، بضمان إلزامي والدفع عند الاستلام.';

	/// ar: '{count} جهازًا أُنقذ من النفايات الإلكترونية'
	String impactDevices({required Object count}) => '${count} جهازًا أُنقذ من النفايات الإلكترونية';

	/// ar: '~{kg} كغم CO₂ تم تجنّبها'
	String impactCo2({required Object kg}) => '~${kg} كغم CO₂ تم تجنّبها';

	/// ar: 'ابحث عن جهاز… (مثال: iPhone 13)'
	String get searchHint => 'ابحث عن جهاز… (مثال: iPhone 13)';

	/// ar: 'التصفية'
	String get filters => 'التصفية';

	/// ar: 'مسح التصفية'
	String get clearFilters => 'مسح التصفية';

	/// ar: 'الفئة'
	String get categoryFilter => 'الفئة';

	/// ar: 'الماركة'
	String get brandFilter => 'الماركة';

	/// ar: 'المدينة'
	String get cityFilter => 'المدينة';

	/// ar: 'العملة'
	String get currencyFilter => 'العملة';

	/// ar: 'الحالة'
	String get gradeFilter => 'الحالة';

	/// ar: 'السعر من'
	String get minPrice => 'السعر من';

	/// ar: 'السعر إلى'
	String get maxPrice => 'السعر إلى';

	/// ar: 'لا توجد أجهزة مطابقة'
	String get emptyTitle => 'لا توجد أجهزة مطابقة';

	/// ar: 'جرّب توسيع البحث أو مسح التصفية للاطلاع على كل الأجهزة المتاحة.'
	String get emptyBody => 'جرّب توسيع البحث أو مسح التصفية للاطلاع على كل الأجهزة المتاحة.';

	/// ar: 'ضمان {days} يوم'
	String warrantyShort({required Object days}) => 'ضمان ${days} يوم';

	/// ar: 'الدفع عند الاستلام'
	String get codBadge => 'الدفع عند الاستلام';
}

// Path: device
class Translations$device$ar {
	Translations$device$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'تقرير الفحص الفني'
	String get checklistTitle => 'تقرير الفحص الفني';

	/// ar: 'IMEI (آخر 4 أرقام)'
	String get imeiLabel => 'IMEI (آخر 4 أرقام)';

	/// ar: 'الرقم التسلسلي (آخر 4)'
	String get serialLabel => 'الرقم التسلسلي (آخر 4)';

	/// ar: 'المتجر'
	String get shopLabel => 'المتجر';

	/// ar: 'الضمان'
	String get warrantyTitle => 'الضمان';

	/// ar: 'يشمل هذا الجهاز ضمانًا إلزاميًا لمدة {days} يومًا من تاريخ الاستلام.'
	String warrantyBody({required Object days}) => 'يشمل هذا الجهاز ضمانًا إلزاميًا لمدة ${days} يومًا من تاريخ الاستلام.';

	/// ar: 'احجز الآن — الدفع عند الاستلام'
	String get reserveCta => 'احجز الآن — الدفع عند الاستلام';

	/// ar: 'الجهاز غير متاح'
	String get notAvailableTitle => 'الجهاز غير متاح';

	/// ar: 'هذا الجهاز لم يعد معروضًا. تصفّح باقي الأجهزة في السوق.'
	String get notAvailableBody => 'هذا الجهاز لم يعد معروضًا. تصفّح باقي الأجهزة في السوق.';

	/// ar: 'الوصف'
	String get descriptionTitle => 'الوصف';

	/// ar: 'رقم الجهاز'
	String get publicIdLabel => 'رقم الجهاز';
}

// Path: reserve
class Translations$reserve$ar {
	Translations$reserve$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'حجز الجهاز'
	String get title => 'حجز الجهاز';

	/// ar: 'أنت تحجز: {title}'
	String deviceSummary({required Object title}) => 'أنت تحجز: ${title}';

	/// ar: 'سنستخدم هذا الرقم للتواصل معك لتنسيق التسليم.'
	String get phoneHelp => 'سنستخدم هذا الرقم للتواصل معك لتنسيق التسليم.';

	/// ar: 'مدينة التسليم'
	String get cityHelp => 'مدينة التسليم';

	/// ar: 'أي تفاصيل إضافية للتسليم (اختياري)'
	String get noteHint => 'أي تفاصيل إضافية للتسليم (اختياري)';

	/// ar: 'تأكيد الحجز'
	String get submit => 'تأكيد الحجز';

	/// ar: 'سجّل الدخول لإتمام الحجز'
	String get loginFirstTitle => 'سجّل الدخول لإتمام الحجز';

	/// ar: 'تصفح السوق متاح للجميع، لكن الحجز يتطلب حسابًا للتواصل معك.'
	String get loginFirstBody => 'تصفح السوق متاح للجميع، لكن الحجز يتطلب حسابًا للتواصل معك.';

	/// ar: 'تم استلام طلبك!'
	String get successTitle => 'تم استلام طلبك!';

	/// ar: 'رقم الحجز الخاص بك: {id}'
	String successBody({required Object id}) => 'رقم الحجز الخاص بك: ${id}';

	/// ar: 'ماذا يحدث الآن؟'
	String get whatNextTitle => 'ماذا يحدث الآن؟';

	/// ar: 'سيتواصل معك المتجر خلال 24 ساعة لتأكيد الحجز.'
	String get whatNext1 => 'سيتواصل معك المتجر خلال 24 ساعة لتأكيد الحجز.';

	/// ar: 'يتم توصيل الجهاز إلى عنوانك وتدفع نقدًا عند الاستلام.'
	String get whatNext2 => 'يتم توصيل الجهاز إلى عنوانك وتدفع نقدًا عند الاستلام.';

	/// ar: 'يبدأ الضمان تلقائيًا من لحظة استلامك للجهاز.'
	String get whatNext3 => 'يبدأ الضمان تلقائيًا من لحظة استلامك للجهاز.';

	/// ar: 'عرض طلباتي'
	String get goToOrders => 'عرض طلباتي';

	/// ar: 'عذرًا، حُجز هذا الجهاز للتو من مشترٍ آخر.'
	String get deviceTaken => 'عذرًا، حُجز هذا الجهاز للتو من مشترٍ آخر.';
}

// Path: orders
class Translations$orders$ar {
	Translations$orders$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'طلباتي'
	String get title => 'طلباتي';

	/// ar: 'لا توجد طلبات بعد'
	String get emptyTitle => 'لا توجد طلبات بعد';

	/// ar: 'عند حجزك لجهاز ستظهر تفاصيل الطلب هنا.'
	String get emptyBody => 'عند حجزك لجهاز ستظهر تفاصيل الطلب هنا.';

	/// ar: 'تصفّح الأجهزة'
	String get browseCta => 'تصفّح الأجهزة';

	/// ar: 'رقم الحجز'
	String get reservationLabel => 'رقم الحجز';

	/// ar: 'فتح مطالبة ضمان'
	String get openClaim => 'فتح مطالبة ضمان';

	/// ar: 'مطالبة ضمان'
	String get claimTitle => 'مطالبة ضمان';

	/// ar: 'صف المشكلة'
	String get claimDescriptionLabel => 'صف المشكلة';

	/// ar: 'مثال: البطارية تفرغ بسرعة غير طبيعية…'
	String get claimDescriptionHint => 'مثال: البطارية تفرغ بسرعة غير طبيعية…';

	/// ar: 'تم فتح المطالبة وسيتم التواصل معك.'
	String get claimSubmitted => 'تم فتح المطالبة وسيتم التواصل معك.';

	/// ar: 'مطالبات الضمان'
	String get claimsTitle => 'مطالبات الضمان';

	/// ar: 'قرار المنصة: {note}'
	String claimResolution({required Object note}) => 'قرار المنصة: ${note}';

	/// ar: 'رد المتجر: {note}'
	String shopResponse({required Object note}) => 'رد المتجر: ${note}';
}

// Path: auth
class Translations$auth$ar {
	Translations$auth$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'تسجيل الدخول'
	String get loginTitle => 'تسجيل الدخول';

	/// ar: 'حساب جديد'
	String get registerTitle => 'حساب جديد';

	/// ar: 'دخول'
	String get submitLogin => 'دخول';

	/// ar: 'إنشاء الحساب'
	String get submitRegister => 'إنشاء الحساب';

	/// ar: 'ليس لديك حساب؟ أنشئ حسابًا'
	String get toRegister => 'ليس لديك حساب؟ أنشئ حسابًا';

	/// ar: 'لديك حساب؟ سجّل الدخول'
	String get toLogin => 'لديك حساب؟ سجّل الدخول';

	/// ar: 'المتابعة بحساب Google'
	String get googleSignIn => 'المتابعة بحساب Google';

	/// ar: 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
	String get invalidCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

	/// ar: 'هذا البريد مسجّل مسبقًا. جرّب تسجيل الدخول.'
	String get emailInUse => 'هذا البريد مسجّل مسبقًا. جرّب تسجيل الدخول.';

	/// ar: 'كلمة المرور قصيرة — 6 أحرف على الأقل.'
	String get weakPassword => 'كلمة المرور قصيرة — 6 أحرف على الأقل.';

	/// ar: 'البريد الإلكتروني غير صالح.'
	String get invalidEmail => 'البريد الإلكتروني غير صالح.';

	/// ar: 'أرسلنا رابط تأكيد إلى بريدك. افتح الرسالة ثم سجّل الدخول.'
	String get confirmEmailSent => 'أرسلنا رابط تأكيد إلى بريدك. افتح الرسالة ثم سجّل الدخول.';

	/// ar: 'هل تملك متجرًا لبيع الأجهزة؟'
	String get sellerCta => 'هل تملك متجرًا لبيع الأجهزة؟';

	/// ar: 'انضم كبائع'
	String get sellerCtaAction => 'انضم كبائع';
}

// Path: seller
class Translations$seller$ar {
	Translations$seller$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'بوابة البائع'
	String get title => 'بوابة البائع';

	/// ar: 'أجهزتي'
	String get navDevices => 'أجهزتي';

	/// ar: 'الحجوزات'
	String get navReservations => 'الحجوزات';

	/// ar: 'الضمان'
	String get navClaims => 'الضمان';

	/// ar: 'متجري'
	String get navShop => 'متجري';

	late final Translations$seller$onboarding$ar onboarding = Translations$seller$onboarding$ar.internal(_root);
	late final Translations$seller$devices$ar devices = Translations$seller$devices$ar.internal(_root);
	late final Translations$seller$deviceForm$ar deviceForm = Translations$seller$deviceForm$ar.internal(_root);
	late final Translations$seller$reservations$ar reservations = Translations$seller$reservations$ar.internal(_root);
	late final Translations$seller$claims$ar claims = Translations$seller$claims$ar.internal(_root);
}

// Path: admin
class Translations$admin$ar {
	Translations$admin$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'لوحة الإدارة'
	String get title => 'لوحة الإدارة';

	/// ar: 'الرئيسية'
	String get navDashboard => 'الرئيسية';

	/// ar: 'المتاجر'
	String get navShops => 'المتاجر';

	/// ar: 'مراجعة الأجهزة'
	String get navReview => 'مراجعة الأجهزة';

	/// ar: 'بنود الفحص'
	String get navTemplates => 'بنود الفحص';

	/// ar: 'المطالبات'
	String get navClaims => 'المطالبات';

	/// ar: 'الحجوزات'
	String get navReservations => 'الحجوزات';

	/// ar: 'المستخدمون'
	String get navUsers => 'المستخدمون';

	/// ar: 'صلاحيات غير كافية'
	String get forbiddenTitle => 'صلاحيات غير كافية';

	/// ar: 'هذه الصفحة مخصصة لمشغّلي المنصة.'
	String get forbiddenBody => 'هذه الصفحة مخصصة لمشغّلي المنصة.';

	late final Translations$admin$users$ar users = Translations$admin$users$ar.internal(_root);
	late final Translations$admin$dashboard$ar dashboard = Translations$admin$dashboard$ar.internal(_root);
	late final Translations$admin$shops$ar shops = Translations$admin$shops$ar.internal(_root);
	late final Translations$admin$review$ar review = Translations$admin$review$ar.internal(_root);
	late final Translations$admin$templates$ar templates = Translations$admin$templates$ar.internal(_root);
	late final Translations$admin$claims$ar claims = Translations$admin$claims$ar.internal(_root);
	late final Translations$admin$reservations$ar reservations = Translations$admin$reservations$ar.internal(_root);
}

// Path: seller.onboarding
class Translations$seller$onboarding$ar {
	Translations$seller$onboarding$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'تسجيل المتجر'
	String get title => 'تسجيل المتجر';

	/// ar: 'سجّل متجرك لبيع الأجهزة المستعملة على مضمون. تراجع المنصة الطلبات خلال يوم عمل.'
	String get intro => 'سجّل متجرك لبيع الأجهزة المستعملة على مضمون. تراجع المنصة الطلبات خلال يوم عمل.';

	/// ar: 'اسم المتجر'
	String get shopNameLabel => 'اسم المتجر';

	/// ar: 'إرسال طلب الانضمام'
	String get submit => 'إرسال طلب الانضمام';

	/// ar: 'طلبك قيد المراجعة'
	String get pendingTitle => 'طلبك قيد المراجعة';

	/// ar: 'استلمنا بيانات متجرك وسنراجعها خلال يوم عمل. ستتمكن من إضافة الأجهزة فور الاعتماد.'
	String get pendingBody => 'استلمنا بيانات متجرك وسنراجعها خلال يوم عمل. ستتمكن من إضافة الأجهزة فور الاعتماد.';

	/// ar: 'لم يتم اعتماد المتجر'
	String get rejectedTitle => 'لم يتم اعتماد المتجر';

	/// ar: 'السبب: {reason}'
	String rejectedReason({required Object reason}) => 'السبب: ${reason}';

	/// ar: 'متجر معتمد'
	String get approvedTitle => 'متجر معتمد';

	/// ar: 'تعديل بيانات المتجر'
	String get editShop => 'تعديل بيانات المتجر';

	/// ar: 'تم تحديث بيانات المتجر'
	String get updated => 'تم تحديث بيانات المتجر';
}

// Path: seller.devices
class Translations$seller$devices$ar {
	Translations$seller$devices$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'أجهزتي'
	String get title => 'أجهزتي';

	/// ar: 'إضافة جهاز'
	String get add => 'إضافة جهاز';

	/// ar: 'لا توجد أجهزة بعد'
	String get emptyTitle => 'لا توجد أجهزة بعد';

	/// ar: 'أضف أول جهاز مستعمل بعد فحصه فنيًا ليظهر للمشترين بعد موافقة المنصة.'
	String get emptyBody => 'أضف أول جهاز مستعمل بعد فحصه فنيًا ليظهر للمشترين بعد موافقة المنصة.';

	/// ar: 'إرسال للفحص'
	String get submitForInspection => 'إرسال للفحص';

	/// ar: 'أُرسل الجهاز لمراجعة المنصة'
	String get submittedForInspection => 'أُرسل الجهاز لمراجعة المنصة';

	/// ar: 'سبب الرفض: {reason}'
	String rejectionReason({required Object reason}) => 'سبب الرفض: ${reason}';

	/// ar: 'حذف المسودة'
	String get deleteDraft => 'حذف المسودة';

	/// ar: 'هل أنت متأكد من حذف هذه المسودة؟'
	String get deleteConfirm => 'هل أنت متأكد من حذف هذه المسودة؟';

	/// ar: 'تم حذف المسودة'
	String get deleted => 'تم حذف المسودة';

	/// ar: 'إرجاع لمسودة'
	String get backToDraft => 'إرجاع لمسودة';

	/// ar: 'إعادة العرض'
	String get relist => 'إعادة العرض';

	/// ar: 'تعديل'
	String get edit => 'تعديل';

	/// ar: 'أي تعديل على جهاز معروض يُعيده للفحص ويخفيه من السوق حتى تعتمده المنصة من جديد.'
	String get editListedNote => 'أي تعديل على جهاز معروض يُعيده للفحص ويخفيه من السوق حتى تعتمده المنصة من جديد.';

	/// ar: 'أُرسل الجهاز لإعادة المراجعة وسيظهر في السوق بعد الاعتماد'
	String get resubmitted => 'أُرسل الجهاز لإعادة المراجعة وسيظهر في السوق بعد الاعتماد';

	/// ar: '{count} صور'
	String photosCount({required Object count}) => '${count} صور';

	/// ar: 'أضف {count} صور على الأقل قبل الإرسال'
	String needsPhotos({required Object count}) => 'أضف ${count} صور على الأقل قبل الإرسال';

	/// ar: 'أكمل جميع بنود الفحص قبل الإرسال'
	String get checklistIncomplete => 'أكمل جميع بنود الفحص قبل الإرسال';
}

// Path: seller.deviceForm
class Translations$seller$deviceForm$ar {
	Translations$seller$deviceForm$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'جهاز جديد'
	String get newTitle => 'جهاز جديد';

	/// ar: 'تعديل الجهاز'
	String get editTitle => 'تعديل الجهاز';

	/// ar: 'الفئة'
	String get categoryLabel => 'الفئة';

	/// ar: 'الماركة'
	String get brandLabel => 'الماركة';

	/// ar: 'Apple, Samsung, Lenovo…'
	String get brandHint => 'Apple, Samsung, Lenovo…';

	/// ar: 'الموديل'
	String get modelLabel => 'الموديل';

	/// ar: 'iPhone 13 Pro, ThinkPad T14…'
	String get modelHint => 'iPhone 13 Pro, ThinkPad T14…';

	/// ar: 'عنوان الإعلان'
	String get titleLabel => 'عنوان الإعلان';

	/// ar: 'iPhone 13 Pro 256GB أزرق — حالة ممتازة'
	String get titleHint => 'iPhone 13 Pro 256GB أزرق — حالة ممتازة';

	/// ar: 'الوصف'
	String get descriptionLabel => 'الوصف';

	/// ar: 'تفاصيل الجهاز وما تم تجديده أو استبداله…'
	String get descriptionHint => 'تفاصيل الجهاز وما تم تجديده أو استبداله…';

	/// ar: 'السعر'
	String get priceLabel => 'السعر';

	/// ar: '1200'
	String get priceHint => '1200';

	/// ar: 'العملة'
	String get currencyLabel => 'العملة';

	/// ar: 'مدة الضمان (أيام)'
	String get warrantyLabel => 'مدة الضمان (أيام)';

	/// ar: 'IMEI'
	String get imeiLabel => 'IMEI';

	/// ar: 'سيظهر للمشتري آخر 4 أرقام فقط'
	String get imeiHint => 'سيظهر للمشتري آخر 4 أرقام فقط';

	/// ar: 'الرقم التسلسلي'
	String get serialLabel => 'الرقم التسلسلي';

	/// ar: 'الفحص الفني'
	String get checklistTitle => 'الفحص الفني';

	/// ar: 'ملاحظة (اختياري)'
	String get checklistNoteHint => 'ملاحظة (اختياري)';

	/// ar: 'التقييم المتوقع: {grade}'
	String gradePreview({required Object grade}) => 'التقييم المتوقع: ${grade}';

	/// ar: 'حفظ كمسودة'
	String get saveDraft => 'حفظ كمسودة';

	/// ar: 'تم الحفظ'
	String get saved => 'تم الحفظ';

	/// ar: 'أدخل سعرًا صحيحًا أكبر من صفر'
	String get invalidPrice => 'أدخل سعرًا صحيحًا أكبر من صفر';

	/// ar: 'صور الجهاز'
	String get photosTitle => 'صور الجهاز';

	/// ar: '4 صور على الأقل — الأولى هي صورة الغلاف. اسحب لإعادة الترتيب.'
	String get photosHint => '4 صور على الأقل — الأولى هي صورة الغلاف. اسحب لإعادة الترتيب.';

	/// ar: 'إضافة صور'
	String get addPhotos => 'إضافة صور';

	/// ar: 'جارٍ الرفع…'
	String get uploading => 'جارٍ الرفع…';

	/// ar: 'فشل رفع الصورة. حاول مستعملًا.'
	String get uploadFailed => 'فشل رفع الصورة. حاول مستعملًا.';

	/// ar: 'إزالة الصورة'
	String get removePhoto => 'إزالة الصورة';
}

// Path: seller.reservations
class Translations$seller$reservations$ar {
	Translations$seller$reservations$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'الحجوزات الواردة'
	String get title => 'الحجوزات الواردة';

	/// ar: 'لا توجد حجوزات'
	String get emptyTitle => 'لا توجد حجوزات';

	/// ar: 'عندما يحجز مشترٍ أحد أجهزتك ستظهر تفاصيل الحجز هنا.'
	String get emptyBody => 'عندما يحجز مشترٍ أحد أجهزتك ستظهر تفاصيل الحجز هنا.';

	/// ar: 'هاتف المشتري'
	String get buyerPhone => 'هاتف المشتري';

	/// ar: 'تأكيد الحجز'
	String get confirmAction => 'تأكيد الحجز';

	/// ar: 'تم التسليم'
	String get deliverAction => 'تم التسليم';

	/// ar: 'إلغاء الحجز'
	String get cancelAction => 'إلغاء الحجز';

	/// ar: 'سيُعاد عرض الجهاز في السوق. متابعة؟'
	String get cancelConfirm => 'سيُعاد عرض الجهاز في السوق. متابعة؟';

	/// ar: 'تم تأكيد الحجز'
	String get confirmed => 'تم تأكيد الحجز';

	/// ar: 'تم تسجيل التسليم وبدأ الضمان'
	String get delivered => 'تم تسجيل التسليم وبدأ الضمان';

	/// ar: 'أُلغي الحجز وأُعيد عرض الجهاز'
	String get cancelled => 'أُلغي الحجز وأُعيد عرض الجهاز';
}

// Path: seller.claims
class Translations$seller$claims$ar {
	Translations$seller$claims$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'مطالبات الضمان'
	String get title => 'مطالبات الضمان';

	/// ar: 'لا توجد مطالبات'
	String get emptyTitle => 'لا توجد مطالبات';

	/// ar: 'مطالبات الضمان على أجهزتك ستظهر هنا.'
	String get emptyBody => 'مطالبات الضمان على أجهزتك ستظهر هنا.';

	/// ar: 'ردّ المتجر'
	String get respondLabel => 'ردّ المتجر';

	/// ar: 'مثال: يرجى إحضار الجهاز للمتجر للفحص…'
	String get respondHint => 'مثال: يرجى إحضار الجهاز للمتجر للفحص…';

	/// ar: 'إرسال الرد'
	String get respondSubmit => 'إرسال الرد';

	/// ar: 'تم حفظ الرد'
	String get responded => 'تم حفظ الرد';
}

// Path: admin.users
class Translations$admin$users$ar {
	Translations$admin$users$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'المستخدمون'
	String get title => 'المستخدمون';

	/// ar: 'ابحث بالاسم أو البريد…'
	String get searchHint => 'ابحث بالاسم أو البريد…';

	/// ar: 'لا يوجد مستخدمون'
	String get emptyTitle => 'لا يوجد مستخدمون';

	/// ar: 'لا توجد نتائج مطابقة لبحثك.'
	String get emptyBody => 'لا توجد نتائج مطابقة لبحثك.';

	/// ar: 'إجمالي المستخدمين'
	String get total => 'إجمالي المستخدمين';

	/// ar: 'مشترون'
	String get buyers => 'مشترون';

	/// ar: 'بائعون'
	String get sellers => 'بائعون';

	/// ar: 'مشرفون'
	String get admins => 'مشرفون';

	/// ar: 'جدد (7 أيام)'
	String get newLast7d => 'جدد (7 أيام)';

	/// ar: 'الدور'
	String get roleLabel => 'الدور';

	/// ar: 'انضم'
	String get joinedLabel => 'انضم';

	/// ar: 'آخر دخول'
	String get lastSeenLabel => 'آخر دخول';

	/// ar: 'لم يسجّل دخولًا'
	String get neverSignedIn => 'لم يسجّل دخولًا';

	/// ar: 'تغيير الدور'
	String get changeRole => 'تغيير الدور';

	/// ar: 'تم تحديث دور المستخدم'
	String get roleChanged => 'تم تحديث دور المستخدم';

	/// ar: 'تغيير دور «{name}» إلى {role}؟'
	String roleChangeConfirm({required Object name, required Object role}) => 'تغيير دور «${name}» إلى ${role}؟';

	/// ar: 'مشترٍ'
	String get roleBuyer => 'مشترٍ';

	/// ar: 'بائع'
	String get roleSeller => 'بائع';

	/// ar: 'مشرف'
	String get roleAdmin => 'مشرف';
}

// Path: admin.dashboard
class Translations$admin$dashboard$ar {
	Translations$admin$dashboard$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'متاجر بانتظار الاعتماد'
	String get pendingShops => 'متاجر بانتظار الاعتماد';

	/// ar: 'أجهزة قيد الفحص'
	String get devicesInReview => 'أجهزة قيد الفحص';

	/// ar: 'حجوزات نشطة'
	String get activeReservations => 'حجوزات نشطة';

	/// ar: 'مطالبات مفتوحة'
	String get openClaims => 'مطالبات مفتوحة';

	/// ar: 'أجهزة أُنقذت'
	String get devicesSaved => 'أجهزة أُنقذت';

	/// ar: 'كغم CO₂ تم تجنّبها'
	String get co2Avoided => 'كغم CO₂ تم تجنّبها';
}

// Path: admin.shops
class Translations$admin$shops$ar {
	Translations$admin$shops$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'طلبات المتاجر'
	String get title => 'طلبات المتاجر';

	/// ar: 'لا توجد متاجر بانتظار الاعتماد'
	String get emptyTitle => 'لا توجد متاجر بانتظار الاعتماد';

	/// ar: 'الطلبات الجديدة ستظهر هنا لمراجعتها.'
	String get emptyBody => 'الطلبات الجديدة ستظهر هنا لمراجعتها.';

	/// ar: 'اعتماد'
	String get approve => 'اعتماد';

	/// ar: 'رفض'
	String get reject => 'رفض';

	/// ar: 'سبب الرفض'
	String get rejectTitle => 'سبب الرفض';

	/// ar: 'اكتب سببًا واضحًا يظهر لصاحب المتجر…'
	String get rejectHint => 'اكتب سببًا واضحًا يظهر لصاحب المتجر…';

	/// ar: 'تم اعتماد المتجر'
	String get approvedMsg => 'تم اعتماد المتجر';

	/// ar: 'تم رفض المتجر'
	String get rejectedMsg => 'تم رفض المتجر';

	/// ar: 'عرض كل المتاجر'
	String get showAll => 'عرض كل المتاجر';
}

// Path: admin.review
class Translations$admin$review$ar {
	Translations$admin$review$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'مراجعة الأجهزة'
	String get title => 'مراجعة الأجهزة';

	/// ar: 'لا توجد أجهزة بانتظار المراجعة'
	String get emptyTitle => 'لا توجد أجهزة بانتظار المراجعة';

	/// ar: 'الأجهزة المرسلة من المتاجر ستظهر هنا للفحص والاعتماد.'
	String get emptyBody => 'الأجهزة المرسلة من المتاجر ستظهر هنا للفحص والاعتماد.';

	/// ar: 'اعتماد وعرض'
	String get approve => 'اعتماد وعرض';

	/// ar: 'رفض'
	String get reject => 'رفض';

	/// ar: 'سبب رفض الجهاز'
	String get rejectTitle => 'سبب رفض الجهاز';

	/// ar: 'اكتب سببًا واضحًا يظهر للمتجر…'
	String get rejectHint => 'اكتب سببًا واضحًا يظهر للمتجر…';

	/// ar: 'تم اعتماد الجهاز وعرضه في السوق'
	String get approvedMsg => 'تم اعتماد الجهاز وعرضه في السوق';

	/// ar: 'تم رفض الجهاز'
	String get rejectedMsg => 'تم رفض الجهاز';
}

// Path: admin.templates
class Translations$admin$templates$ar {
	Translations$admin$templates$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'بنود الفحص'
	String get title => 'بنود الفحص';

	/// ar: 'إضافة بند'
	String get add => 'إضافة بند';

	/// ar: 'المعرّف (لاتيني)'
	String get keyLabel => 'المعرّف (لاتيني)';

	/// ar: 'battery_health'
	String get keyHint => 'battery_health';

	/// ar: 'الاسم بالعربية'
	String get labelArLabel => 'الاسم بالعربية';

	/// ar: 'الترتيب'
	String get sortLabel => 'الترتيب';

	/// ar: 'فعّال'
	String get activeLabel => 'فعّال';

	/// ar: 'معطّل'
	String get disabledBadge => 'معطّل';

	/// ar: 'تم الحفظ'
	String get saved => 'تم الحفظ';

	/// ar: 'تعديل بند'
	String get editTitle => 'تعديل بند';

	/// ar: 'المعرّف: أحرف لاتينية صغيرة وأرقام و _ فقط'
	String get invalidKey => 'المعرّف: أحرف لاتينية صغيرة وأرقام و _ فقط';
}

// Path: admin.claims
class Translations$admin$claims$ar {
	Translations$admin$claims$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'مطالبات الضمان'
	String get title => 'مطالبات الضمان';

	/// ar: 'لا توجد مطالبات'
	String get emptyTitle => 'لا توجد مطالبات';

	/// ar: 'مطالبات الضمان المفتوحة ستظهر هنا للمعالجة.'
	String get emptyBody => 'مطالبات الضمان المفتوحة ستظهر هنا للمعالجة.';

	/// ar: 'بدء المراجعة'
	String get setInReview => 'بدء المراجعة';

	/// ar: 'حلّ المطالبة'
	String get resolve => 'حلّ المطالبة';

	/// ar: 'رفض المطالبة'
	String get reject => 'رفض المطالبة';

	/// ar: 'ملاحظة القرار'
	String get resolutionLabel => 'ملاحظة القرار';

	/// ar: 'القرار النهائي وما تم الاتفاق عليه…'
	String get resolutionHint => 'القرار النهائي وما تم الاتفاق عليه…';

	/// ar: 'تم تحديث المطالبة'
	String get updated => 'تم تحديث المطالبة';
}

// Path: admin.reservations
class Translations$admin$reservations$ar {
	Translations$admin$reservations$ar.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ar: 'كل الحجوزات'
	String get title => 'كل الحجوزات';

	/// ar: 'لا توجد حجوزات'
	String get emptyTitle => 'لا توجد حجوزات';

	/// ar: 'حجوزات المشترين عبر المنصة ستظهر هنا.'
	String get emptyBody => 'حجوزات المشترين عبر المنصة ستظهر هنا.';

	/// ar: 'عمولة المنصة'
	String get commission => 'عمولة المنصة';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.appName' => 'مضمون',
			'common.tagline' => 'أجهزة مستعملة بضمان، من متاجر معتمدة',
			'common.loading' => 'جارٍ التحميل…',
			'common.retry' => 'إعادة المحاولة',
			'common.cancel' => 'إلغاء',
			'common.save' => 'حفظ',
			'common.confirm' => 'تأكيد',
			'common.close' => 'إغلاق',
			'common.back' => 'رجوع',
			'common.search' => 'بحث',
			'common.all' => 'الكل',
			'common.optional' => 'اختياري',
			'common.requiredField' => 'هذا الحقل مطلوب',
			'common.invalidPhone' => 'رقم الهاتف غير صالح — مثال: 0599123456',
			'common.signOut' => 'تسجيل الخروج',
			'common.account' => 'الحساب',
			'common.login' => 'تسجيل الدخول',
			'common.register' => 'إنشاء حساب',
			'common.myOrders' => 'طلباتي',
			'common.sellerPortal' => 'بوابة البائع',
			'common.adminPanel' => 'لوحة الإدارة',
			'common.marketplace' => 'السوق',
			'common.notFoundTitle' => 'الصفحة غير موجودة',
			'common.notFoundBody' => 'الرابط الذي فتحته غير صحيح أو لم يعد متاحًا.',
			'common.backHome' => 'العودة للرئيسية',
			'common.genericError' => 'حدث خطأ غير متوقع. حاول مرة أخرى.',
			'common.networkError' => 'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.',
			'common.warrantyDays' => ({required Object days}) => 'ضمان ${days} يوم',
			'common.priceLabel' => 'السعر',
			'common.cityLabel' => 'المدينة',
			'common.phoneLabel' => 'رقم الهاتف',
			'common.phoneHint' => '0599123456',
			'common.noteLabel' => 'ملاحظة',
			'common.emailLabel' => 'البريد الإلكتروني',
			'common.passwordLabel' => 'كلمة المرور',
			'common.fullNameLabel' => 'الاسم الكامل',
			'common.showMore' => 'عرض المزيد',
			'common.refresh' => 'تحديث',
			'common.copied' => 'تم النسخ',
			'common.today' => 'اليوم',
			'common.accountSettings' => 'إعدادات الحساب',
			'common.saved' => 'تم الحفظ',
			'account.title' => 'حسابي',
			'account.profileSection' => 'المعلومات الشخصية',
			'account.profileHint' => 'تظهر هذه المعلومات لتنسيق الطلبات والتوصيل.',
			'account.saveProfile' => 'حفظ المعلومات',
			'account.profileSaved' => 'تم تحديث معلوماتك',
			'account.emailSection' => 'البريد الإلكتروني',
			'account.currentEmail' => ({required Object email}) => 'بريدك الحالي: ${email}',
			'account.newEmailLabel' => 'البريد الإلكتروني الجديد',
			'account.changeEmail' => 'تغيير البريد',
			'account.emailChangeSent' => 'أرسلنا رابط تأكيد إلى بريدك الجديد. افتحه لإتمام التغيير.',
			'account.passwordSection' => 'كلمة المرور',
			'account.newPasswordLabel' => 'كلمة المرور الجديدة',
			'account.confirmPasswordLabel' => 'تأكيد كلمة المرور',
			'account.changePassword' => 'تغيير كلمة المرور',
			'account.passwordChanged' => 'تم تغيير كلمة المرور بنجاح',
			'account.passwordMismatch' => 'كلمتا المرور غير متطابقتين',
			'account.roleLabel' => 'نوع الحساب',
			'reset.forgot' => 'نسيت كلمة المرور؟',
			'reset.title' => 'استعادة كلمة المرور',
			'reset.body' => 'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.',
			'reset.send' => 'إرسال الرابط',
			'reset.sent' => 'إذا كان البريد مسجّلًا، ستصلك رسالة لإعادة التعيين.',
			'reset.newTitle' => 'تعيين كلمة مرور جديدة',
			'reset.newBody' => 'اختر كلمة مرور جديدة لحسابك.',
			'reset.updated' => 'تم تحديث كلمة المرور. يمكنك المتابعة الآن.',
			'enums.deviceStatus.draft' => 'مسودة',
			'enums.deviceStatus.under_inspection' => 'قيد الفحص',
			'enums.deviceStatus.listed' => 'معروض',
			'enums.deviceStatus.reserved' => 'محجوز',
			'enums.deviceStatus.sold' => 'مُباع',
			'enums.deviceStatus.warranty_active' => 'ضمان فعّال',
			'enums.deviceStatus.warranty_closed' => 'انتهى الضمان',
			'enums.deviceStatus.rejected' => 'مرفوض',
			'enums.deviceStatus.returned' => 'مُرتجع',
			'enums.reservationStatus.pending' => 'بانتظار التأكيد',
			'enums.reservationStatus.confirmed' => 'مؤكد',
			'enums.reservationStatus.delivered' => 'تم التسليم',
			'enums.reservationStatus.cancelled' => 'ملغي',
			'enums.shopStatus.pending' => 'بانتظار الموافقة',
			'enums.shopStatus.approved' => 'معتمد',
			'enums.shopStatus.rejected' => 'مرفوض',
			'enums.claimStatus.open' => 'مفتوحة',
			'enums.claimStatus.in_review' => 'قيد المراجعة',
			'enums.claimStatus.resolved' => 'تم الحل',
			'enums.claimStatus.rejected' => 'مرفوضة',
			'enums.grade.excellent' => 'ممتاز',
			'enums.grade.very_good' => 'جيد جدًا',
			'enums.grade.good' => 'جيد',
			'enums.grade.fair' => 'مقبول',
			'enums.category.mobile' => 'موبايل',
			'enums.category.laptop' => 'لابتوب',
			'enums.checklistResult.pass' => 'سليم',
			'enums.checklistResult.minorIssue' => 'ملاحظة بسيطة',
			'enums.checklistResult.fail' => 'عطل',
			'enums.currency.ILS' => 'شيكل (₪)',
			'enums.currency.USD' => 'دولار (\$)',
			'home.heroTitle' => 'أجهزة مستعملة… مضمونة',
			'home.heroSubtitle' => 'موبايلات ولابتوبات مفحوصة فنيًا من متاجر معتمدة، بضمان إلزامي والدفع عند الاستلام.',
			'home.impactDevices' => ({required Object count}) => '${count} جهازًا أُنقذ من النفايات الإلكترونية',
			'home.impactCo2' => ({required Object kg}) => '~${kg} كغم CO₂ تم تجنّبها',
			'home.searchHint' => 'ابحث عن جهاز… (مثال: iPhone 13)',
			'home.filters' => 'التصفية',
			'home.clearFilters' => 'مسح التصفية',
			'home.categoryFilter' => 'الفئة',
			'home.brandFilter' => 'الماركة',
			'home.cityFilter' => 'المدينة',
			'home.currencyFilter' => 'العملة',
			'home.gradeFilter' => 'الحالة',
			'home.minPrice' => 'السعر من',
			'home.maxPrice' => 'السعر إلى',
			'home.emptyTitle' => 'لا توجد أجهزة مطابقة',
			'home.emptyBody' => 'جرّب توسيع البحث أو مسح التصفية للاطلاع على كل الأجهزة المتاحة.',
			'home.warrantyShort' => ({required Object days}) => 'ضمان ${days} يوم',
			'home.codBadge' => 'الدفع عند الاستلام',
			'device.checklistTitle' => 'تقرير الفحص الفني',
			'device.imeiLabel' => 'IMEI (آخر 4 أرقام)',
			'device.serialLabel' => 'الرقم التسلسلي (آخر 4)',
			'device.shopLabel' => 'المتجر',
			'device.warrantyTitle' => 'الضمان',
			'device.warrantyBody' => ({required Object days}) => 'يشمل هذا الجهاز ضمانًا إلزاميًا لمدة ${days} يومًا من تاريخ الاستلام.',
			'device.reserveCta' => 'احجز الآن — الدفع عند الاستلام',
			'device.notAvailableTitle' => 'الجهاز غير متاح',
			'device.notAvailableBody' => 'هذا الجهاز لم يعد معروضًا. تصفّح باقي الأجهزة في السوق.',
			'device.descriptionTitle' => 'الوصف',
			'device.publicIdLabel' => 'رقم الجهاز',
			'reserve.title' => 'حجز الجهاز',
			'reserve.deviceSummary' => ({required Object title}) => 'أنت تحجز: ${title}',
			'reserve.phoneHelp' => 'سنستخدم هذا الرقم للتواصل معك لتنسيق التسليم.',
			'reserve.cityHelp' => 'مدينة التسليم',
			'reserve.noteHint' => 'أي تفاصيل إضافية للتسليم (اختياري)',
			'reserve.submit' => 'تأكيد الحجز',
			'reserve.loginFirstTitle' => 'سجّل الدخول لإتمام الحجز',
			'reserve.loginFirstBody' => 'تصفح السوق متاح للجميع، لكن الحجز يتطلب حسابًا للتواصل معك.',
			'reserve.successTitle' => 'تم استلام طلبك!',
			'reserve.successBody' => ({required Object id}) => 'رقم الحجز الخاص بك: ${id}',
			'reserve.whatNextTitle' => 'ماذا يحدث الآن؟',
			'reserve.whatNext1' => 'سيتواصل معك المتجر خلال 24 ساعة لتأكيد الحجز.',
			'reserve.whatNext2' => 'يتم توصيل الجهاز إلى عنوانك وتدفع نقدًا عند الاستلام.',
			'reserve.whatNext3' => 'يبدأ الضمان تلقائيًا من لحظة استلامك للجهاز.',
			'reserve.goToOrders' => 'عرض طلباتي',
			'reserve.deviceTaken' => 'عذرًا، حُجز هذا الجهاز للتو من مشترٍ آخر.',
			'orders.title' => 'طلباتي',
			'orders.emptyTitle' => 'لا توجد طلبات بعد',
			'orders.emptyBody' => 'عند حجزك لجهاز ستظهر تفاصيل الطلب هنا.',
			'orders.browseCta' => 'تصفّح الأجهزة',
			'orders.reservationLabel' => 'رقم الحجز',
			'orders.openClaim' => 'فتح مطالبة ضمان',
			'orders.claimTitle' => 'مطالبة ضمان',
			'orders.claimDescriptionLabel' => 'صف المشكلة',
			'orders.claimDescriptionHint' => 'مثال: البطارية تفرغ بسرعة غير طبيعية…',
			'orders.claimSubmitted' => 'تم فتح المطالبة وسيتم التواصل معك.',
			'orders.claimsTitle' => 'مطالبات الضمان',
			'orders.claimResolution' => ({required Object note}) => 'قرار المنصة: ${note}',
			'orders.shopResponse' => ({required Object note}) => 'رد المتجر: ${note}',
			'auth.loginTitle' => 'تسجيل الدخول',
			'auth.registerTitle' => 'حساب جديد',
			'auth.submitLogin' => 'دخول',
			'auth.submitRegister' => 'إنشاء الحساب',
			'auth.toRegister' => 'ليس لديك حساب؟ أنشئ حسابًا',
			'auth.toLogin' => 'لديك حساب؟ سجّل الدخول',
			'auth.googleSignIn' => 'المتابعة بحساب Google',
			'auth.invalidCredentials' => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
			'auth.emailInUse' => 'هذا البريد مسجّل مسبقًا. جرّب تسجيل الدخول.',
			'auth.weakPassword' => 'كلمة المرور قصيرة — 6 أحرف على الأقل.',
			'auth.invalidEmail' => 'البريد الإلكتروني غير صالح.',
			'auth.confirmEmailSent' => 'أرسلنا رابط تأكيد إلى بريدك. افتح الرسالة ثم سجّل الدخول.',
			'auth.sellerCta' => 'هل تملك متجرًا لبيع الأجهزة؟',
			'auth.sellerCtaAction' => 'انضم كبائع',
			'seller.title' => 'بوابة البائع',
			'seller.navDevices' => 'أجهزتي',
			'seller.navReservations' => 'الحجوزات',
			'seller.navClaims' => 'الضمان',
			'seller.navShop' => 'متجري',
			'seller.onboarding.title' => 'تسجيل المتجر',
			'seller.onboarding.intro' => 'سجّل متجرك لبيع الأجهزة المستعملة على مضمون. تراجع المنصة الطلبات خلال يوم عمل.',
			'seller.onboarding.shopNameLabel' => 'اسم المتجر',
			'seller.onboarding.submit' => 'إرسال طلب الانضمام',
			'seller.onboarding.pendingTitle' => 'طلبك قيد المراجعة',
			'seller.onboarding.pendingBody' => 'استلمنا بيانات متجرك وسنراجعها خلال يوم عمل. ستتمكن من إضافة الأجهزة فور الاعتماد.',
			'seller.onboarding.rejectedTitle' => 'لم يتم اعتماد المتجر',
			'seller.onboarding.rejectedReason' => ({required Object reason}) => 'السبب: ${reason}',
			'seller.onboarding.approvedTitle' => 'متجر معتمد',
			'seller.onboarding.editShop' => 'تعديل بيانات المتجر',
			'seller.onboarding.updated' => 'تم تحديث بيانات المتجر',
			'seller.devices.title' => 'أجهزتي',
			'seller.devices.add' => 'إضافة جهاز',
			'seller.devices.emptyTitle' => 'لا توجد أجهزة بعد',
			'seller.devices.emptyBody' => 'أضف أول جهاز مستعمل بعد فحصه فنيًا ليظهر للمشترين بعد موافقة المنصة.',
			'seller.devices.submitForInspection' => 'إرسال للفحص',
			'seller.devices.submittedForInspection' => 'أُرسل الجهاز لمراجعة المنصة',
			'seller.devices.rejectionReason' => ({required Object reason}) => 'سبب الرفض: ${reason}',
			'seller.devices.deleteDraft' => 'حذف المسودة',
			'seller.devices.deleteConfirm' => 'هل أنت متأكد من حذف هذه المسودة؟',
			'seller.devices.deleted' => 'تم حذف المسودة',
			'seller.devices.backToDraft' => 'إرجاع لمسودة',
			'seller.devices.relist' => 'إعادة العرض',
			'seller.devices.edit' => 'تعديل',
			'seller.devices.editListedNote' => 'أي تعديل على جهاز معروض يُعيده للفحص ويخفيه من السوق حتى تعتمده المنصة من جديد.',
			'seller.devices.resubmitted' => 'أُرسل الجهاز لإعادة المراجعة وسيظهر في السوق بعد الاعتماد',
			'seller.devices.photosCount' => ({required Object count}) => '${count} صور',
			'seller.devices.needsPhotos' => ({required Object count}) => 'أضف ${count} صور على الأقل قبل الإرسال',
			'seller.devices.checklistIncomplete' => 'أكمل جميع بنود الفحص قبل الإرسال',
			'seller.deviceForm.newTitle' => 'جهاز جديد',
			'seller.deviceForm.editTitle' => 'تعديل الجهاز',
			'seller.deviceForm.categoryLabel' => 'الفئة',
			'seller.deviceForm.brandLabel' => 'الماركة',
			'seller.deviceForm.brandHint' => 'Apple, Samsung, Lenovo…',
			'seller.deviceForm.modelLabel' => 'الموديل',
			'seller.deviceForm.modelHint' => 'iPhone 13 Pro, ThinkPad T14…',
			'seller.deviceForm.titleLabel' => 'عنوان الإعلان',
			'seller.deviceForm.titleHint' => 'iPhone 13 Pro 256GB أزرق — حالة ممتازة',
			'seller.deviceForm.descriptionLabel' => 'الوصف',
			'seller.deviceForm.descriptionHint' => 'تفاصيل الجهاز وما تم تجديده أو استبداله…',
			'seller.deviceForm.priceLabel' => 'السعر',
			'seller.deviceForm.priceHint' => '1200',
			'seller.deviceForm.currencyLabel' => 'العملة',
			'seller.deviceForm.warrantyLabel' => 'مدة الضمان (أيام)',
			'seller.deviceForm.imeiLabel' => 'IMEI',
			'seller.deviceForm.imeiHint' => 'سيظهر للمشتري آخر 4 أرقام فقط',
			'seller.deviceForm.serialLabel' => 'الرقم التسلسلي',
			'seller.deviceForm.checklistTitle' => 'الفحص الفني',
			'seller.deviceForm.checklistNoteHint' => 'ملاحظة (اختياري)',
			'seller.deviceForm.gradePreview' => ({required Object grade}) => 'التقييم المتوقع: ${grade}',
			'seller.deviceForm.saveDraft' => 'حفظ كمسودة',
			'seller.deviceForm.saved' => 'تم الحفظ',
			'seller.deviceForm.invalidPrice' => 'أدخل سعرًا صحيحًا أكبر من صفر',
			'seller.deviceForm.photosTitle' => 'صور الجهاز',
			'seller.deviceForm.photosHint' => '4 صور على الأقل — الأولى هي صورة الغلاف. اسحب لإعادة الترتيب.',
			'seller.deviceForm.addPhotos' => 'إضافة صور',
			'seller.deviceForm.uploading' => 'جارٍ الرفع…',
			'seller.deviceForm.uploadFailed' => 'فشل رفع الصورة. حاول مستعملًا.',
			'seller.deviceForm.removePhoto' => 'إزالة الصورة',
			'seller.reservations.title' => 'الحجوزات الواردة',
			'seller.reservations.emptyTitle' => 'لا توجد حجوزات',
			'seller.reservations.emptyBody' => 'عندما يحجز مشترٍ أحد أجهزتك ستظهر تفاصيل الحجز هنا.',
			'seller.reservations.buyerPhone' => 'هاتف المشتري',
			'seller.reservations.confirmAction' => 'تأكيد الحجز',
			'seller.reservations.deliverAction' => 'تم التسليم',
			'seller.reservations.cancelAction' => 'إلغاء الحجز',
			'seller.reservations.cancelConfirm' => 'سيُعاد عرض الجهاز في السوق. متابعة؟',
			'seller.reservations.confirmed' => 'تم تأكيد الحجز',
			'seller.reservations.delivered' => 'تم تسجيل التسليم وبدأ الضمان',
			'seller.reservations.cancelled' => 'أُلغي الحجز وأُعيد عرض الجهاز',
			'seller.claims.title' => 'مطالبات الضمان',
			'seller.claims.emptyTitle' => 'لا توجد مطالبات',
			'seller.claims.emptyBody' => 'مطالبات الضمان على أجهزتك ستظهر هنا.',
			'seller.claims.respondLabel' => 'ردّ المتجر',
			'seller.claims.respondHint' => 'مثال: يرجى إحضار الجهاز للمتجر للفحص…',
			'seller.claims.respondSubmit' => 'إرسال الرد',
			'seller.claims.responded' => 'تم حفظ الرد',
			'admin.title' => 'لوحة الإدارة',
			'admin.navDashboard' => 'الرئيسية',
			'admin.navShops' => 'المتاجر',
			'admin.navReview' => 'مراجعة الأجهزة',
			'admin.navTemplates' => 'بنود الفحص',
			'admin.navClaims' => 'المطالبات',
			'admin.navReservations' => 'الحجوزات',
			'admin.navUsers' => 'المستخدمون',
			'admin.forbiddenTitle' => 'صلاحيات غير كافية',
			'admin.forbiddenBody' => 'هذه الصفحة مخصصة لمشغّلي المنصة.',
			'admin.users.title' => 'المستخدمون',
			'admin.users.searchHint' => 'ابحث بالاسم أو البريد…',
			'admin.users.emptyTitle' => 'لا يوجد مستخدمون',
			'admin.users.emptyBody' => 'لا توجد نتائج مطابقة لبحثك.',
			'admin.users.total' => 'إجمالي المستخدمين',
			'admin.users.buyers' => 'مشترون',
			'admin.users.sellers' => 'بائعون',
			'admin.users.admins' => 'مشرفون',
			'admin.users.newLast7d' => 'جدد (7 أيام)',
			'admin.users.roleLabel' => 'الدور',
			'admin.users.joinedLabel' => 'انضم',
			'admin.users.lastSeenLabel' => 'آخر دخول',
			'admin.users.neverSignedIn' => 'لم يسجّل دخولًا',
			'admin.users.changeRole' => 'تغيير الدور',
			'admin.users.roleChanged' => 'تم تحديث دور المستخدم',
			'admin.users.roleChangeConfirm' => ({required Object name, required Object role}) => 'تغيير دور «${name}» إلى ${role}؟',
			'admin.users.roleBuyer' => 'مشترٍ',
			'admin.users.roleSeller' => 'بائع',
			'admin.users.roleAdmin' => 'مشرف',
			'admin.dashboard.pendingShops' => 'متاجر بانتظار الاعتماد',
			'admin.dashboard.devicesInReview' => 'أجهزة قيد الفحص',
			'admin.dashboard.activeReservations' => 'حجوزات نشطة',
			'admin.dashboard.openClaims' => 'مطالبات مفتوحة',
			'admin.dashboard.devicesSaved' => 'أجهزة أُنقذت',
			'admin.dashboard.co2Avoided' => 'كغم CO₂ تم تجنّبها',
			'admin.shops.title' => 'طلبات المتاجر',
			'admin.shops.emptyTitle' => 'لا توجد متاجر بانتظار الاعتماد',
			'admin.shops.emptyBody' => 'الطلبات الجديدة ستظهر هنا لمراجعتها.',
			'admin.shops.approve' => 'اعتماد',
			'admin.shops.reject' => 'رفض',
			'admin.shops.rejectTitle' => 'سبب الرفض',
			'admin.shops.rejectHint' => 'اكتب سببًا واضحًا يظهر لصاحب المتجر…',
			'admin.shops.approvedMsg' => 'تم اعتماد المتجر',
			'admin.shops.rejectedMsg' => 'تم رفض المتجر',
			'admin.shops.showAll' => 'عرض كل المتاجر',
			'admin.review.title' => 'مراجعة الأجهزة',
			'admin.review.emptyTitle' => 'لا توجد أجهزة بانتظار المراجعة',
			'admin.review.emptyBody' => 'الأجهزة المرسلة من المتاجر ستظهر هنا للفحص والاعتماد.',
			'admin.review.approve' => 'اعتماد وعرض',
			'admin.review.reject' => 'رفض',
			'admin.review.rejectTitle' => 'سبب رفض الجهاز',
			'admin.review.rejectHint' => 'اكتب سببًا واضحًا يظهر للمتجر…',
			'admin.review.approvedMsg' => 'تم اعتماد الجهاز وعرضه في السوق',
			'admin.review.rejectedMsg' => 'تم رفض الجهاز',
			'admin.templates.title' => 'بنود الفحص',
			'admin.templates.add' => 'إضافة بند',
			'admin.templates.keyLabel' => 'المعرّف (لاتيني)',
			'admin.templates.keyHint' => 'battery_health',
			'admin.templates.labelArLabel' => 'الاسم بالعربية',
			'admin.templates.sortLabel' => 'الترتيب',
			'admin.templates.activeLabel' => 'فعّال',
			'admin.templates.disabledBadge' => 'معطّل',
			'admin.templates.saved' => 'تم الحفظ',
			'admin.templates.editTitle' => 'تعديل بند',
			'admin.templates.invalidKey' => 'المعرّف: أحرف لاتينية صغيرة وأرقام و _ فقط',
			'admin.claims.title' => 'مطالبات الضمان',
			'admin.claims.emptyTitle' => 'لا توجد مطالبات',
			'admin.claims.emptyBody' => 'مطالبات الضمان المفتوحة ستظهر هنا للمعالجة.',
			'admin.claims.setInReview' => 'بدء المراجعة',
			'admin.claims.resolve' => 'حلّ المطالبة',
			'admin.claims.reject' => 'رفض المطالبة',
			'admin.claims.resolutionLabel' => 'ملاحظة القرار',
			'admin.claims.resolutionHint' => 'القرار النهائي وما تم الاتفاق عليه…',
			'admin.claims.updated' => 'تم تحديث المطالبة',
			'admin.reservations.title' => 'كل الحجوزات',
			'admin.reservations.emptyTitle' => 'لا توجد حجوزات',
			'admin.reservations.emptyBody' => 'حجوزات المشترين عبر المنصة ستظهر هنا.',
			'admin.reservations.commission' => 'عمولة المنصة',
			'errors.INVALID_STATE_TRANSITION' => 'لا يمكن تنفيذ هذا الانتقال في حالة الجهاز.',
			'errors.ADMIN_ONLY_TRANSITION' => 'هذا الإجراء متاح لإدارة المنصة فقط.',
			'errors.CHECKLIST_INCOMPLETE' => 'أكمل جميع بنود الفحص أولًا.',
			'errors.INSUFFICIENT_PHOTOS' => 'أضف 4 صور على الأقل قبل الإرسال.',
			'errors.IMEI_REQUIRED' => 'أدخل رقم IMEI للجهاز.',
			'errors.GRADE_REQUIRED' => 'لم يُحسب تقييم الجهاز — أكمل الفحص.',
			'errors.DEVICE_NOT_AVAILABLE' => 'الجهاز لم يعد متاحًا للحجز.',
			'errors.DEVICE_NOT_FOUND' => 'الجهاز غير موجود.',
			'errors.AUTH_REQUIRED' => 'سجّل الدخول أولًا.',
			'errors.INVALID_PHONE' => 'رقم الهاتف غير صالح.',
			'errors.CITY_REQUIRED' => 'أدخل مدينة التسليم.',
			'errors.ADMIN_ONLY' => 'صلاحيات غير كافية.',
			'errors.REJECTION_REASON_REQUIRED' => 'اكتب سبب الرفض.',
			'errors.SHOP_NOT_APPROVED' => 'لا يمكن إضافة أجهزة قبل اعتماد المتجر.',
			'errors.UPDATE_FORBIDDEN' => 'لا تملك صلاحية تنفيذ هذا الإجراء.',
			_ => null,
		};
	}
}
