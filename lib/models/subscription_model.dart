import 'package:mobile_app/services/localization_service.dart';

enum SubscriptionTier {
  weekly,
  monthly,
  yearly,
  unlimited,
}

enum SubscriptionStatus {
  active,
  cancelled,
  expired,
  none,
}

class SubscriptionInfo {
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime? expiresAt;
  final bool autoRenew;
  final SubscriptionStatus status;

  const SubscriptionInfo({
    required this.tier,
    required this.startDate,
    this.expiresAt,
    this.autoRenew = true,
    this.status = SubscriptionStatus.active,
  });

  /// Aboneliğin şu an aktif ve süresinin dolmamış olup olmadığını doğrular
  bool get isValid {
    if (status == SubscriptionStatus.cancelled ||
        status == SubscriptionStatus.expired ||
        status == SubscriptionStatus.none) {
      return false;
    }
    // Ömür boyu üyelikte süre bitimi yoktur
    if (tier == SubscriptionTier.unlimited) {
      return true;
    }
    if (expiresAt == null) {
      return true;
    }
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Kalan gün sayısı
  int get remainingDays {
    if (tier == SubscriptionTier.unlimited || expiresAt == null) {
      return 99999;
    }
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get tierDisplayName {
    switch (tier) {
      case SubscriptionTier.weekly:
        return LocalizationService.tr('sub_weekly');
      case SubscriptionTier.monthly:
        return LocalizationService.tr('sub_monthly');
      case SubscriptionTier.yearly:
        return LocalizationService.tr('sub_yearly');
      case SubscriptionTier.unlimited:
        return LocalizationService.tr('lifetime_unlimited');
    }
  }

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        'startDate': startDate.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'autoRenew': autoRenew,
        'status': status.name,
      };

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) =>
      SubscriptionInfo(
        tier: SubscriptionTier.values.firstWhere(
          (t) => t.name == json['tier'],
          orElse: () => SubscriptionTier.yearly,
        ),
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate']) ?? DateTime.now()
            : DateTime.now(),
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'])
            : null,
        autoRenew: json['autoRenew'] as bool? ?? true,
        status: SubscriptionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => SubscriptionStatus.none,
        ),
      );

  SubscriptionInfo copyWith({
    SubscriptionTier? tier,
    DateTime? startDate,
    DateTime? expiresAt,
    bool? autoRenew,
    SubscriptionStatus? status,
  }) {
    return SubscriptionInfo(
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      expiresAt: expiresAt ?? this.expiresAt,
      autoRenew: autoRenew ?? this.autoRenew,
      status: status ?? this.status,
    );
  }
}
