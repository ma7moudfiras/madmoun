/// Data models mapping Supabase rows to typed Dart objects.
library;

import 'domain.dart';

DateTime _date(dynamic value) => DateTime.parse(value as String).toLocal();

int _int(dynamic value) => (value as num).toInt();

List<ChecklistEntry> _checklist(dynamic value) => (value as List<dynamic>? ??
        const [])
    .map((e) => ChecklistEntry.fromJson(Map<String, dynamic>.from(e as Map)))
    .toList();

class Profile {
  const Profile({
    required this.id,
    required this.role,
    this.fullName,
    this.phoneE164,
  });

  final String id;
  final UserRole role;
  final String? fullName;
  final String? phoneE164;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        role: UserRole.fromDb(json['role'] as String),
        fullName: json['full_name'] as String?,
        phoneE164: json['phone_e164'] as String?,
      );
}

/// A user as the admin panel sees it (profile + auth email/timestamps).
class AdminUser {
  const AdminUser({
    required this.id,
    required this.role,
    required this.createdAt,
    this.email,
    this.fullName,
    this.phoneE164,
    this.lastSignInAt,
  });

  final String id;
  final String? email;
  final String? fullName;
  final UserRole role;
  final String? phoneE164;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        fullName: json['full_name'] as String?,
        role: UserRole.fromDb(json['role'] as String),
        phoneE164: json['phone_e164'] as String?,
        createdAt: _date(json['created_at']),
        lastSignInAt: json['last_sign_in_at'] == null
            ? null
            : _date(json['last_sign_in_at']),
      );
}

class UserStats {
  const UserStats({
    required this.total,
    required this.buyers,
    required this.sellers,
    required this.admins,
    required this.newLast7d,
  });

  final int total;
  final int buyers;
  final int sellers;
  final int admins;
  final int newLast7d;

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        total: _int(json['total'] ?? 0),
        buyers: _int(json['buyers'] ?? 0),
        sellers: _int(json['sellers'] ?? 0),
        admins: _int(json['admins'] ?? 0),
        newLast7d: _int(json['new_last_7d'] ?? 0),
      );
}

class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.city,
    required this.status,
    this.phoneE164,
    this.address,
    this.rejectionReason,
    this.ownerId,
  });

  final int id;
  final String name;
  final String city;
  final ShopStatus status;

  /// Present only when read through my_shop()/admin_shops().
  final String? phoneE164;
  final String? address;
  final String? rejectionReason;
  final String? ownerId;

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: _int(json['id']),
        name: json['name'] as String,
        city: json['city'] as String,
        status: ShopStatus.fromDb(json['status'] as String),
        phoneE164: json['phone_e164'] as String?,
        address: json['address'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
        ownerId: json['owner_id'] as String?,
      );
}

class DevicePhoto {
  const DevicePhoto({
    required this.id,
    required this.deviceId,
    required this.storagePath,
    required this.sortOrder,
  });

  final int id;
  final int deviceId;
  final String storagePath;
  final int sortOrder;

  factory DevicePhoto.fromJson(Map<String, dynamic> json) => DevicePhoto(
        id: _int(json['id']),
        deviceId: _int(json['device_id']),
        storagePath: json['storage_path'] as String,
        sortOrder: _int(json['sort_order'] ?? 0),
      );
}

/// A marketplace listing as exposed by the public_listings view.
class Listing {
  const Listing({
    required this.id,
    required this.publicId,
    required this.category,
    required this.brand,
    required this.model,
    required this.title,
    required this.price,
    required this.warrantyDays,
    required this.checklist,
    required this.shopCity,
    required this.createdAt,
    this.description,
    this.grade,
    this.imeiLast4,
    this.photoPaths = const [],
  });

  final int id;
  final String publicId;
  final DeviceCategory category;
  final String brand;
  final String model;
  final String title;
  final String? description;
  final Money price;
  final Grade? grade;
  final int warrantyDays;
  final String? imeiLast4;
  final List<ChecklistEntry> checklist;
  final String shopCity;
  final DateTime createdAt;
  final List<String> photoPaths;

  String? get coverPhotoPath => photoPaths.isEmpty ? null : photoPaths.first;

  factory Listing.fromJson(
    Map<String, dynamic> json, {
    List<String> photoPaths = const [],
  }) =>
      Listing(
        id: _int(json['id']),
        publicId: json['public_id'] as String,
        category: DeviceCategory.fromDb(json['category'] as String),
        brand: json['brand'] as String,
        model: json['model'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        price: Money(
          _int(json['price_minor']),
          Currency.fromDb(json['currency'] as String),
        ),
        grade: json['grade'] == null
            ? null
            : Grade.fromDb(json['grade'] as String),
        warrantyDays: _int(json['warranty_days']),
        imeiLast4: json['imei_last4'] as String?,
        checklist: _checklist(json['checklist']),
        shopCity: json['shop_city'] as String,
        createdAt: _date(json['created_at']),
        photoPaths: photoPaths,
      );

  Listing withPhotos(List<String> paths) => Listing(
        id: id,
        publicId: publicId,
        category: category,
        brand: brand,
        model: model,
        title: title,
        description: description,
        price: price,
        grade: grade,
        warrantyDays: warrantyDays,
        imeiLast4: imeiLast4,
        checklist: checklist,
        shopCity: shopCity,
        createdAt: createdAt,
        photoPaths: paths,
      );
}

/// A device row as its owning seller (or an admin) sees it.
class SellerDevice {
  const SellerDevice({
    required this.id,
    required this.publicId,
    required this.shopId,
    required this.category,
    required this.brand,
    required this.model,
    required this.title,
    required this.price,
    required this.warrantyDays,
    required this.status,
    required this.checklist,
    required this.createdAt,
    this.description,
    this.grade,
    this.imeiLast4,
    this.rejectionReason,
    this.photos = const [],
  });

  final int id;
  final String publicId;
  final int shopId;
  final DeviceCategory category;
  final String brand;
  final String model;
  final String title;
  final String? description;
  final Money price;
  final Grade? grade;
  final int warrantyDays;
  final String? imeiLast4;
  final List<ChecklistEntry> checklist;
  final DeviceStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final List<DevicePhoto> photos;

  factory SellerDevice.fromJson(Map<String, dynamic> json) {
    final photosJson = json['device_photos'] as List<dynamic>? ?? const [];
    final photos = photosJson
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((e) => e['is_deleted'] != true)
        .map(DevicePhoto.fromJson)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return SellerDevice(
      id: _int(json['id']),
      publicId: json['public_id'] as String,
      shopId: _int(json['shop_id']),
      category: DeviceCategory.fromDb(json['category'] as String),
      brand: json['brand'] as String,
      model: json['model'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: Money(
        _int(json['price_minor']),
        Currency.fromDb(json['currency'] as String),
      ),
      grade:
          json['grade'] == null ? null : Grade.fromDb(json['grade'] as String),
      warrantyDays: _int(json['warranty_days']),
      imeiLast4: json['imei_last4'] as String?,
      checklist: _checklist(json['checklist']),
      status: DeviceStatus.fromDb(json['status'] as String),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: _date(json['created_at']),
      photos: photos,
    );
  }
}

class Reservation {
  const Reservation({
    required this.id,
    required this.publicId,
    required this.deviceId,
    required this.buyerId,
    this.buyerPhone,
    required this.deliveryCity,
    required this.price,
    required this.commissionMinor,
    required this.status,
    required this.createdAt,
    this.deliveryNote,
    this.deliveryAddress,
    this.deviceTitle,
    this.devicePublicId,
    this.deviceCoverPath,
    this.settlementStatus,
    this.shopName,
    this.shopCity,
    this.shopAddress,
    this.shopPhone,
  });

  final int id;
  final String publicId;
  final int deviceId;
  final String buyerId;
  final String? buyerPhone;
  final String deliveryCity;
  final String? deliveryNote;
  final Money price;
  final int commissionMinor;
  final ReservationStatus status;
  final DateTime createdAt;

  final String? deliveryAddress;
  final String? deviceTitle;
  final String? devicePublicId;
  final String? deviceCoverPath;
  final String? settlementStatus;

  /// Shop pickup details — populated only for the admin (opaque to others).
  final String? shopName;
  final String? shopCity;
  final String? shopAddress;
  final String? shopPhone;

  /// Amount owed to the shop after the platform's commission.
  Money get netToShop => Money(price.minor - commissionMinor, price.currency);

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final device = json['devices'] == null
        ? null
        : Map<String, dynamic>.from(json['devices'] as Map);
    final shop = device?['shops'] == null
        ? null
        : Map<String, dynamic>.from(device!['shops'] as Map);
    String? cover;
    if (device?['device_photos'] is List) {
      final photos = (device!['device_photos'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => e['is_deleted'] != true)
          .toList()
        ..sort(
            (a, b) => _int(a['sort_order']).compareTo(_int(b['sort_order'])));
      if (photos.isNotEmpty) cover = photos.first['storage_path'] as String?;
    }
    return Reservation(
      id: _int(json['id']),
      publicId: json['public_id'] as String,
      deviceId: _int(json['device_id']),
      buyerId: json['buyer_id'] as String,
      buyerPhone: json['buyer_phone_e164'] as String?,
      deliveryCity: json['delivery_city'] as String,
      deliveryNote: json['delivery_note'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      price: Money(
        _int(json['price_minor']),
        Currency.fromDb(json['currency'] as String),
      ),
      commissionMinor: _int(json['commission_minor']),
      status: ReservationStatus.fromDb(json['status'] as String),
      createdAt: _date(json['created_at']),
      // Nested keys come from the buyer/seller embeds; flat device_/shop_ keys
      // come from the admin_reservations() RPC.
      deviceTitle: (device?['title'] ?? json['device_title']) as String?,
      devicePublicId:
          (device?['public_id'] ?? json['device_public_id']) as String?,
      deviceCoverPath: cover,
      settlementStatus: json['settlement_status'] as String?,
      shopName: (shop?['name'] ?? json['shop_name']) as String?,
      shopCity: (shop?['city'] ?? json['shop_city']) as String?,
      shopAddress: (shop?['address'] ?? json['shop_address']) as String?,
      shopPhone: (shop?['phone_e164'] ?? json['shop_phone']) as String?,
    );
  }
}

/// Per-currency commission totals over completed orders (admin ledger).
class CommissionSummary {
  const CommissionSummary({
    required this.currency,
    required this.orders,
    required this.gross,
    required this.commission,
    required this.settled,
    required this.pending,
  });

  final Currency currency;
  final int orders;
  final Money gross;
  final Money commission;
  final Money settled;
  final Money pending;

  factory CommissionSummary.fromJson(Map<String, dynamic> json) {
    final currency = Currency.fromDb(json['currency'] as String);
    Money money(String key) => Money(_int(json[key]), currency);
    return CommissionSummary(
      currency: currency,
      orders: _int(json['orders']),
      gross: money('gross_minor'),
      commission: money('commission_minor'),
      settled: money('settled_minor'),
      pending: money('pending_minor'),
    );
  }
}

/// Admin-only, computed trust signal for a shop — derived purely from real
/// transactions (deliveries, cancellations, warranty claims, device review
/// outcomes). Never shown to buyers or sellers.
class ShopReputation {
  const ShopReputation({
    required this.shopId,
    required this.shopName,
    required this.shopCity,
    required this.shopStatus,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.activeOrders,
    required this.claims,
    required this.devicesSubmitted,
    required this.devicesRejected,
    required this.cancellationRate,
    required this.claimRate,
    required this.rejectionRate,
    required this.trustScore,
    required this.tier,
  });

  final int shopId;
  final String shopName;
  final String shopCity;
  final ShopStatus shopStatus;
  final int completedOrders;
  final int cancelledOrders;
  final int activeOrders;
  final int claims;
  final int devicesSubmitted;
  final int devicesRejected;
  final double cancellationRate;
  final double claimRate;
  final double rejectionRate;
  final double trustScore;

  /// `new` | `excellent` | `good` | `watch` | `critical`.
  final String tier;

  factory ShopReputation.fromJson(Map<String, dynamic> json) {
    double rate(String key) => double.parse(json[key].toString());
    return ShopReputation(
      shopId: _int(json['shop_id']),
      shopName: json['shop_name'] as String,
      shopCity: json['shop_city'] as String,
      shopStatus: ShopStatus.fromDb(json['shop_status'] as String),
      completedOrders: _int(json['completed_orders']),
      cancelledOrders: _int(json['cancelled_orders']),
      activeOrders: _int(json['active_orders']),
      claims: _int(json['claims']),
      devicesSubmitted: _int(json['devices_submitted']),
      devicesRejected: _int(json['devices_rejected']),
      cancellationRate: rate('cancellation_rate'),
      claimRate: rate('claim_rate'),
      rejectionRate: rate('rejection_rate'),
      trustScore: rate('trust_score'),
      tier: json['tier'] as String,
    );
  }
}

class WarrantyClaim {
  const WarrantyClaim({
    required this.id,
    required this.deviceId,
    required this.reservationId,
    required this.openedBy,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolutionNote,
    this.shopResponse,
    this.deviceTitle,
    this.devicePublicId,
  });

  final int id;
  final int deviceId;
  final int reservationId;
  final String openedBy;
  final String description;
  final ClaimStatus status;
  final String? resolutionNote;
  final String? shopResponse;
  final DateTime createdAt;
  final String? deviceTitle;
  final String? devicePublicId;

  factory WarrantyClaim.fromJson(Map<String, dynamic> json) {
    final device = json['devices'] == null
        ? null
        : Map<String, dynamic>.from(json['devices'] as Map);
    return WarrantyClaim(
      id: _int(json['id']),
      deviceId: _int(json['device_id']),
      reservationId: _int(json['reservation_id']),
      openedBy: json['opened_by'] as String,
      description: json['description'] as String,
      status: ClaimStatus.fromDb(json['status'] as String),
      resolutionNote: json['resolution_note'] as String?,
      shopResponse: json['shop_response'] as String?,
      createdAt: _date(json['created_at']),
      deviceTitle: device?['title'] as String?,
      devicePublicId: device?['public_id'] as String?,
    );
  }
}

class ChecklistTemplate {
  const ChecklistTemplate({
    required this.id,
    required this.category,
    required this.key,
    required this.labelAr,
    required this.sortOrder,
    required this.isActive,
  });

  final int id;
  final DeviceCategory category;
  final String key;
  final String labelAr;
  final int sortOrder;
  final bool isActive;

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) =>
      ChecklistTemplate(
        id: _int(json['id']),
        category: DeviceCategory.fromDb(json['category'] as String),
        key: json['key'] as String,
        labelAr: json['label_ar'] as String,
        sortOrder: _int(json['sort_order'] ?? 0),
        isActive: json['is_active'] as bool? ?? true,
      );
}

class ImpactStats {
  const ImpactStats({required this.devicesSaved, required this.estCo2Kg});

  final int devicesSaved;
  final int estCo2Kg;

  factory ImpactStats.fromJson(Map<String, dynamic> json) => ImpactStats(
        devicesSaved: _int(json['devices_saved'] ?? 0),
        estCo2Kg: _int(json['est_co2_kg'] ?? 0),
      );
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.pendingShops,
    required this.devicesInReview,
    required this.activeReservations,
    required this.openClaims,
    required this.impact,
  });

  final int pendingShops;
  final int devicesInReview;
  final int activeReservations;
  final int openClaims;
  final ImpactStats impact;

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) =>
      AdminDashboardStats(
        pendingShops: _int(json['pending_shops'] ?? 0),
        devicesInReview: _int(json['devices_in_review'] ?? 0),
        activeReservations: _int(json['active_reservations'] ?? 0),
        openClaims: _int(json['open_claims'] ?? 0),
        impact: ImpactStats.fromJson(json),
      );
}
