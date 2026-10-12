import 'dart:async';
import '../../domain/models/transaction_template.dart';
import '../../domain/repositories/template_repository.dart';

class TemplateRepositoryImpl implements ITemplateRepository {
  final Map<String, TransactionTemplate> _templates = {};
  final StreamController<List<TransactionTemplate>> _controller =
      StreamController<List<TransactionTemplate>>.broadcast();

  TemplateRepositoryImpl() {
    // Seed default presets
    for (final tpl in TransactionTemplate.defaultTemplates) {
      _templates[tpl.id] = tpl;
    }
  }

  @override
  Stream<List<TransactionTemplate>> watchTemplates() async* {
    yield _templates.values.toList();
    yield* _controller.stream;
  }

  @override
  Future<List<TransactionTemplate>> getTemplates() async {
    return _templates.values.toList();
  }

  @override
  Future<TransactionTemplate?> getTemplateById(String id) async {
    return _templates[id];
  }

  @override
  Future<void> createTemplate(TransactionTemplate template) async {
    _templates[template.id] = template;
    _controller.add(_templates.values.toList());
  }

  @override
  Future<void> updateTemplate(TransactionTemplate template) async {
    _templates[template.id] = template;
    _controller.add(_templates.values.toList());
  }

  @override
  Future<void> deleteTemplate(String id) async {
    _templates.remove(id);
    _controller.add(_templates.values.toList());
  }
}
