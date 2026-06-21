enum LicenseTier { free, pro, enterprise }

enum LicenseStatus { checking, active, grace, expired, unlicensed }

class LicenseState {
  const LicenseState({
    required this.status,
    required this.tier,
    required this.features,
    this.expiresAt,
    this.gracePeriodRemaining,
  });

  final LicenseStatus status;
  final LicenseTier tier;
  final Set<String> features;
  final DateTime? expiresAt;
  final Duration? gracePeriodRemaining;

  static const LicenseState unlicensed = LicenseState(
    status: LicenseStatus.unlicensed,
    tier: LicenseTier.free,
    features: {},
  );

  bool get isUsable =>
      status == LicenseStatus.active || status == LicenseStatus.grace;

  bool hasFeature(String feature) => features.contains(feature);
}
