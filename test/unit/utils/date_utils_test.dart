import 'package:bms/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BmsDateUtils', () {
    final fixed = DateTime(2024, 3, 5, 14, 30, 45);

    group('formatDate', () {
      test('formats as dd MMM yyyy', () {
        expect(BmsDateUtils.formatDate(fixed), '05 Mar 2024');
      });
    });

    group('formatDateTime', () {
      test('formats as dd MMM yyyy HH:mm', () {
        expect(BmsDateUtils.formatDateTime(fixed), '05 Mar 2024 14:30');
      });
    });

    group('formatTime', () {
      test('formats as HH:mm', () {
        expect(BmsDateUtils.formatTime(fixed), '14:30');
      });

      test('pads hours and minutes', () {
        expect(BmsDateUtils.formatTime(DateTime(2024, 1, 1, 9, 5)), '09:05');
      });
    });

    group('toIsoDate', () {
      test('formats as yyyy-MM-dd', () {
        expect(BmsDateUtils.toIsoDate(fixed), '2024-03-05');
      });

      test('pads month and day with leading zero', () {
        expect(BmsDateUtils.toIsoDate(DateTime(2024, 1, 9)), '2024-01-09');
      });
    });

    group('startOfDay', () {
      test('returns midnight of the same date', () {
        final result = BmsDateUtils.startOfDay(fixed);
        expect(result, DateTime(2024, 3, 5, 0, 0, 0));
      });
    });

    group('endOfDay', () {
      test('returns 23:59:59.999 of the same date', () {
        final result = BmsDateUtils.endOfDay(fixed);
        expect(result, DateTime(2024, 3, 5, 23, 59, 59, 999));
      });
    });

    group('isToday', () {
      test('returns true for DateTime.now()', () {
        expect(BmsDateUtils.isToday(DateTime.now()), isTrue);
      });

      test('returns false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(BmsDateUtils.isToday(yesterday), isFalse);
      });

      test('returns false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(BmsDateUtils.isToday(tomorrow), isFalse);
      });

      test('ignores time component', () {
        final todayMidnight = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        expect(BmsDateUtils.isToday(todayMidnight), isTrue);
      });
    });

    group('daysBetween', () {
      test('returns 0 for same day', () {
        final d = DateTime(2024, 6, 1);
        expect(BmsDateUtils.daysBetween(d, d), 0);
      });

      test('returns 1 for consecutive days', () {
        expect(
          BmsDateUtils.daysBetween(DateTime(2024, 6, 1), DateTime(2024, 6, 2)),
          1,
        );
      });

      test('ignores time component', () {
        final from = DateTime(2024, 6, 1, 23, 59);
        final to = DateTime(2024, 6, 2, 0, 1);
        expect(BmsDateUtils.daysBetween(from, to), 1);
      });

      test('returns negative when from is after to', () {
        expect(
          BmsDateUtils.daysBetween(DateTime(2024, 6, 2), DateTime(2024, 6, 1)),
          -1,
        );
      });
    });

    group('agingBucket', () {
      test('returns 0-30 days for recent invoice', () {
        final recent = DateTime.now().subtract(const Duration(days: 10));
        expect(BmsDateUtils.agingBucket(recent), '0-30 days');
      });

      test('returns 31-60 days for 45-day-old invoice', () {
        final old = DateTime.now().subtract(const Duration(days: 45));
        expect(BmsDateUtils.agingBucket(old), '31-60 days');
      });

      test('returns 60+ days for 90-day-old invoice', () {
        final veryOld = DateTime.now().subtract(const Duration(days: 90));
        expect(BmsDateUtils.agingBucket(veryOld), '60+ days');
      });

      test('returns 0-30 days for exactly 30 days', () {
        final exactly = DateTime.now().subtract(const Duration(days: 30));
        expect(BmsDateUtils.agingBucket(exactly), '0-30 days');
      });
    });
  });
}
