import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/transaction_template.dart';
import '../../domain/repositories/template_repository.dart';

final templateListProvider = StreamProvider<List<TransactionTemplate>>((ref) {
  final repo = ref.watch(templateRepositoryProvider);
  return repo.watchTemplates();
});
