import 'package:dentaltid/src/features/finance/domain/recurring_charge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurringCharge', () {
    test('toMap should return a map containing the correct data', () {
      final recurringCharge = RecurringCharge(
        id: 1,
        name: 'Monthly Subscription',
        amount: 25.0,
        frequency: RecurringChargeFrequency.monthly,
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2024, 1, 1),
        isActive: true,
        description: 'Monthly dental plan subscription',
      );

      final map = recurringCharge.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Monthly Subscription');
      expect(map['amount'], 25.0);
      expect(map['frequency'], 'RecurringChargeFrequency.monthly');
      expect(map['startDate'], DateTime(2023, 1, 1).toIso8601String());
      expect(map['endDate'], DateTime(2024, 1, 1).toIso8601String());
      expect(map['isActive'], 1);
      expect(map['description'], 'Monthly dental plan subscription');
    });

    test('fromMap should create a RecurringCharge object from a map', () {
      final map = {
        'id': 1,
        'name': 'Monthly Subscription',
        'amount': 25.0,
        'frequency': 'RecurringChargeFrequency.monthly',
        'startDate': DateTime(2023, 1, 1).toIso8601String(),
        'endDate': DateTime(2024, 1, 1).toIso8601String(),
        'isActive': 1,
        'description': 'Monthly dental plan subscription',
      };

      final recurringCharge = RecurringCharge.fromMap(map);

      expect(recurringCharge.id, 1);
      expect(recurringCharge.name, 'Monthly Subscription');
      expect(recurringCharge.amount, 25.0);
      expect(recurringCharge.frequency, RecurringChargeFrequency.monthly);
      expect(recurringCharge.startDate, DateTime(2023, 1, 1));
      expect(recurringCharge.endDate, DateTime(2024, 1, 1));
      expect(recurringCharge.isActive, true);
      expect(recurringCharge.description, 'Monthly dental plan subscription');
    });

    test('fromMap should handle null endDate', () {
      final map = {
        'id': 2,
        'name': 'Annual Fee',
        'amount': 100.0,
        'frequency': 'RecurringChargeFrequency.yearly',
        'startDate': DateTime(2023, 1, 1).toIso8601String(),
        'endDate': null,
        'isActive': 1,
        'description': 'Annual service fee',
      };

      final recurringCharge = RecurringCharge.fromMap(map);

      expect(recurringCharge.id, 2);
      expect(recurringCharge.name, 'Annual Fee');
      expect(recurringCharge.amount, 100.0);
      expect(recurringCharge.frequency, RecurringChargeFrequency.yearly);
      expect(recurringCharge.startDate, DateTime(2023, 1, 1));
      expect(recurringCharge.endDate, isNull);
      expect(recurringCharge.isActive, true);
      expect(recurringCharge.description, 'Annual service fee');
    });
  });
}
