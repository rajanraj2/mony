import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/household.dart';
import '../../domain/models/household_summary.dart';

final activeHouseholdProvider = StreamProvider<Household?>((ref) {
  return ref.watch(householdRepositoryProvider).watchActiveHousehold();
});

final householdOverviewProvider = FutureProvider<HouseholdFinancialOverview>((ref) {
  return ref.watch(householdRepositoryProvider).getCombinedFinancialOverview();
});
