import '../models/household.dart';
import '../models/household_summary.dart';

abstract class IHouseholdRepository {
  Stream<Household?> watchActiveHousehold();
  Future<Household?> getActiveHousehold();

  Future<Household> createHousehold({
    required String name,
    required String currentUserId,
    required String currentUserName,
    String? currentUserEmail,
  });

  Future<Household> joinHouseholdWithCode({
    required String inviteCode,
    required String currentUserId,
    required String currentUserName,
    String? currentUserEmail,
  });

  Future<void> leaveHousehold();

  Future<void> removeMember(String memberUserId);

  Future<HouseholdFinancialOverview> getCombinedFinancialOverview();
}
