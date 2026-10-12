import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/transactions/data/repositories/template_repository_impl.dart';
import 'package:mony/features/transactions/domain/models/transaction.dart';
import 'package:mony/features/transactions/domain/models/transaction_template.dart';

void main() {
  group('TransactionTemplate Model & Presets Tests', () {
    test('Default templates are pre-seeded with essential real-life categories and labels', () {
      final defaults = TransactionTemplate.defaultTemplates;
      expect(defaults.isNotEmpty, isTrue);
      expect(defaults.length, greaterThanOrEqualTo(6));

      // Morning Coffee verification
      final coffee = defaults.firstWhere((t) => t.id == 'tpl-coffee');
      expect(coffee.name, equals('Morning Coffee'));
      expect(coffee.amount, equals(150.0));
      expect(coffee.categoryId, equals('cat-food'));
      expect(coffee.type, equals(TransactionType.expense));
      expect(coffee.labels, contains('#discretionary'));
      expect(coffee.labels, contains('#routine'));

      // Metro Commute verification
      final transit = defaults.firstWhere((t) => t.id == 'tpl-transit');
      expect(transit.amount, equals(60.0));
      expect(transit.categoryId, equals('cat-transport'));
      expect(transit.labels, contains('#commute'));

      // Rent verification
      final rent = defaults.firstWhere((t) => t.id == 'tpl-rent');
      expect(rent.amount, equals(25000.0));
      expect(rent.categoryId, equals('cat-housing'));
      expect(rent.labels, contains('#rent'));

      // Salary verification
      final salary = defaults.firstWhere((t) => t.id == 'tpl-salary');
      expect(salary.type, equals(TransactionType.income));
      expect(salary.amount, equals(85000.0));
    });

    test('copyWith properly overrides template fields', () {
      final tpl = TransactionTemplate.defaultTemplates.first;
      final modified = tpl.copyWith(
        name: 'Special Espresso',
        amount: 220.0,
        labels: ['#coffee', '#artisan'],
      );

      expect(modified.name, equals('Special Espresso'));
      expect(modified.amount, equals(220.0));
      expect(modified.labels, equals(['#coffee', '#artisan']));
      expect(modified.categoryId, equals(tpl.categoryId));
    });
  });

  group('TemplateRepositoryImpl Tests', () {
    late TemplateRepositoryImpl repo;

    setUp(() {
      repo = TemplateRepositoryImpl();
    });

    test('Initializes with default preset templates', () async {
      final list = await repo.getTemplates();
      expect(list.length, equals(TransactionTemplate.defaultTemplates.length));
    });

    test('Allows creating, retrieving, updating and deleting custom templates', () async {
      final custom = TransactionTemplate(
        id: 'tpl-custom-gym',
        name: 'Gym Membership',
        icon: 'fitness_center',
        color: 0xFFEF4444,
        type: TransactionType.expense,
        amount: 2500.0,
        categoryId: 'cat-health',
        payeeName: 'Gold Gym',
        labels: ['#health', '#fitness', '#monthly'],
        isPreset: false,
        createdAt: DateTime.now(),
      );

      // Create
      await repo.createTemplate(custom);
      var fetched = await repo.getTemplateById('tpl-custom-gym');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Gym Membership'));
      expect(fetched.labels, contains('#fitness'));

      // Update
      final updated = custom.copyWith(amount: 2800.0);
      await repo.updateTemplate(updated);
      fetched = await repo.getTemplateById('tpl-custom-gym');
      expect(fetched!.amount, equals(2800.0));

      // Delete
      await repo.deleteTemplate('tpl-custom-gym');
      fetched = await repo.getTemplateById('tpl-custom-gym');
      expect(fetched, isNull);
    });
  });

  group('Transaction Labeling Tests', () {
    test('Transaction preserves multi-selected labels and tags', () {
      final now = DateTime.now();
      final txn = Transaction(
        id: 'txn-101',
        accountId: 'acc-savings',
        amount: 450.0,
        currencyCode: 'INR',
        type: TransactionType.expense,
        name: 'Dinner at Bistro',
        categoryId: 'cat-food',
        date: now,
        labels: ['#essential', '#dining', '#weekend'],
        createdAt: now,
        updatedAt: now,
      );

      expect(txn.labels.length, equals(3));
      expect(txn.labels, contains('#dining'));
      expect(txn.labels, contains('#weekend'));

      // Add tag via copyWith
      final updated = txn.copyWith(
        labels: [...txn.labels, '#family'],
      );
      expect(updated.labels.length, equals(4));
      expect(updated.labels, contains('#family'));
    });
  });
}
