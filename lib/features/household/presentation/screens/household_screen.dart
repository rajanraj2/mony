import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/household.dart';
import '../providers/household_providers.dart';

class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(activeHouseholdProvider);
    final overviewAsync = ref.watch(householdOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family & Household Sync')),
      body: householdAsync.when(
        data: (household) {
          if (household == null) {
            return _buildNotLinkedView(context, ref);
          }
          return _buildLinkedHouseholdView(context, ref, household, overviewAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildNotLinkedView(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_alt_outlined, size: 72, color: Color(0xFF1B6B3A)),
              const SizedBox(height: 16),
              Text(
                'Sync Finances with Family & Partners',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Link accounts with your spouse, partner, or family members. Track collective spending, split shared bills, and view your joint household net worth.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: () => _showCreateHouseholdDialog(context, ref),
                icon: const Icon(Icons.add_home),
                label: const Text('Create New Household (Invite Code)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6B3A),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => _showJoinHouseholdDialog(context, ref),
                icon: const Icon(Icons.group_add),
                label: const Text('Join with Partner Invite Code'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedHouseholdView(
    BuildContext context,
    WidgetRef ref,
    Household household,
    AsyncValue overviewAsync,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Household Overview Banner
        Card(
          elevation: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [const Color(0xFF1B6B3A), Colors.teal.shade800],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(household.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                      child: Text('${household.memberCount} Members', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Invite Code: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    SelectableText(household.inviteCode, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: household.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied to clipboard!')));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Combined Financial Summary
        overviewAsync.when(
          data: (overview) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Combined Joint Household Wealth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text('₹${overview.combinedNetWorth.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Joint Inflow: ₹${overview.combinedMonthlyInflow.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                        Text('Joint Outflow: ₹${overview.combinedMonthlyOutflow.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // Linked Members List
        const Text('Linked Profiles & Roles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: household.members.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final m = household.members[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: m.role == MemberRole.admin ? Colors.amber.shade100 : Colors.teal.shade100,
                  child: Icon(m.role == MemberRole.admin ? Icons.star : Icons.person, color: m.role == MemberRole.admin ? Colors.orange : Colors.teal),
                ),
                title: Text(m.displayName + (m.isCurrentUser ? ' (You)' : ''), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${m.role.displayName} • ${m.email ?? 'Linked device'}'),
                trailing: m.isCurrentUser
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => ref.read(householdRepositoryProvider).removeMember(m.userId),
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        OutlinedButton.icon(
          onPressed: () => ref.read(householdRepositoryProvider).leaveHousehold(),
          icon: const Icon(Icons.exit_to_app, color: Colors.red),
          label: const Text('Leave Household / Unlink Account', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
        ),
      ],
    );
  }

  void _showCreateHouseholdDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: 'Family Household');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Joint Household'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Household Name (e.g. The Smiths, Alex & Taylor)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(householdRepositoryProvider).createHousehold(
                    name: ctrl.text.trim(),
                    currentUserId: 'usr_primary_owner',
                    currentUserName: 'Primary Account Holder',
                  );
            },
            child: const Text('Create & Generate Code'),
          ),
        ],
      ),
    );
  }

  void _showJoinHouseholdDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Shared Household'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Enter Partner Invite Code (e.g. MONY-8491)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(householdRepositoryProvider).joinHouseholdWithCode(
                    inviteCode: ctrl.text.trim(),
                    currentUserId: 'usr_secondary_partner',
                    currentUserName: 'Linked Partner',
                  );
            },
            child: const Text('Join Household'),
          ),
        ],
      ),
    );
  }
}
