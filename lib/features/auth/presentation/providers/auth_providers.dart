import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/user_account.dart';

final authStateProvider = StreamProvider<UserAccount>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});
