import '../models/transaction_template.dart';

abstract class ITemplateRepository {
  Stream<List<TransactionTemplate>> watchTemplates();
  Future<List<TransactionTemplate>> getTemplates();
  Future<TransactionTemplate?> getTemplateById(String id);
  Future<void> createTemplate(TransactionTemplate template);
  Future<void> updateTemplate(TransactionTemplate template);
  Future<void> deleteTemplate(String id);
}
