import 'package:bms/licensing/license_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LicenseState', () {
    group('unlicensed constant', () {
      test('has status unlicensed', () {
        expect(LicenseState.unlicensed.status, LicenseStatus.unlicensed);
      });

      test('has tier free', () {
        expect(LicenseState.unlicensed.tier, LicenseTier.free);
      });

      test('has empty features', () {
        expect(LicenseState.unlicensed.features, isEmpty);
      });

      test('isUsable is false', () {
        expect(LicenseState.unlicensed.isUsable, isFalse);
      });
    });

    group('isUsable', () {
      test('true when status is active', () {
        final state = LicenseState(
          status: LicenseStatus.active,
          tier: LicenseTier.pro,
          features: const {'invoices'},
        );
        expect(state.isUsable, isTrue);
      });

      test('true when status is grace', () {
        final state = LicenseState(
          status: LicenseStatus.grace,
          tier: LicenseTier.pro,
          features: const {},
          gracePeriodRemaining: const Duration(days: 3),
        );
        expect(state.isUsable, isTrue);
      });

      test('false when status is expired', () {
        final state = LicenseState(
          status: LicenseStatus.expired,
          tier: LicenseTier.pro,
          features: const {},
        );
        expect(state.isUsable, isFalse);
      });

      test('false when status is checking', () {
        final state = LicenseState(
          status: LicenseStatus.checking,
          tier: LicenseTier.free,
          features: const {},
        );
        expect(state.isUsable, isFalse);
      });
    });

    group('hasFeature', () {
      final state = LicenseState(
        status: LicenseStatus.active,
        tier: LicenseTier.enterprise,
        features: const {'invoices', 'reports', 'sync'},
      );

      test('returns true when feature is present', () {
        expect(state.hasFeature('invoices'), isTrue);
        expect(state.hasFeature('sync'), isTrue);
      });

      test('returns false when feature is absent', () {
        expect(state.hasFeature('payroll'), isFalse);
        expect(state.hasFeature(''), isFalse);
      });
    });

    group('expiresAt and gracePeriodRemaining', () {
      test('are null by default', () {
        final state = LicenseState(
          status: LicenseStatus.active,
          tier: LicenseTier.pro,
          features: const {},
        );
        expect(state.expiresAt, isNull);
        expect(state.gracePeriodRemaining, isNull);
      });

      test('can be set via constructor', () {
        final exp = DateTime(2026, 12, 31);
        final state = LicenseState(
          status: LicenseStatus.active,
          tier: LicenseTier.pro,
          features: const {},
          expiresAt: exp,
          gracePeriodRemaining: const Duration(days: 7),
        );
        expect(state.expiresAt, exp);
        expect(state.gracePeriodRemaining, const Duration(days: 7));
      });
    });
  });
}
