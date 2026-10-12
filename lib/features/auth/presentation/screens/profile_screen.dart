import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../settings/domain/models/app_theme_config.dart';
import '../../../settings/presentation/providers/home_tiles_provider.dart';
import '../../../settings/presentation/providers/theme_providers.dart';
import '../../domain/models/user_account.dart';
import '../providers/auth_providers.dart';
import 'auth_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).value;
    final themeConfig = ref.watch(themeConfigProvider).value ?? const AppThemeConfig();
    final tilesConfig = ref.watch(homeTilesConfigProvider);

    final userName = authState?.displayName ?? 'Zorax';
    final userEmail = authState?.email ?? 'zorax@mony.app';
    final isSignedIn = authState?.authProvider != AuthProviderType.localGuest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. User Profile Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF2C2623)),
            ),
            color: const Color(0xFF1E1A18),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFF48C6A).withOpacity(0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'Z',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF48C6A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: const TextStyle(fontSize: 13, color: Colors.white60),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D09C).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_done, size: 12, color: Color(0xFF00D09C)),
                                  const SizedBox(width: 4),
                                  Text(
                                    isSignedIn ? 'Cloud Sync Active' : 'Local Vault Mode',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF00D09C),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ),
                      icon: Icon(isSignedIn ? Icons.switch_account : Icons.login, size: 18),
                      label: Text(isSignedIn ? 'Manage Account / Switch' : 'Sign In to Sync Devices'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF48C6A),
                        side: const BorderSide(color: Color(0xFFF48C6A)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Appearance & Theme Switcher
          const Text(
            'Appearance & Theme Mode',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF2C2623)),
            ),
            color: const Color(0xFF1E1A18),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildThemeOption(
                    context: context,
                    ref: ref,
                    title: 'Dark Mode',
                    icon: Icons.dark_mode,
                    isSelected: themeConfig.themeMode == AppThemeMode.dark ||
                        themeConfig.themeMode == AppThemeMode.amoledBlack,
                    onTap: () {
                      ref.read(themeRepositoryProvider).updateThemeConfig(
                            themeConfig.copyWith(themeMode: AppThemeMode.dark),
                          );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    context: context,
                    ref: ref,
                    title: 'Light Mode',
                    icon: Icons.light_mode,
                    isSelected: themeConfig.themeMode == AppThemeMode.light,
                    onTap: () {
                      ref.read(themeRepositoryProvider).updateThemeConfig(
                            themeConfig.copyWith(themeMode: AppThemeMode.light),
                          );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    context: context,
                    ref: ref,
                    title: 'System',
                    icon: Icons.brightness_auto,
                    isSelected: themeConfig.themeMode == AppThemeMode.system,
                    onTap: () {
                      ref.read(themeRepositoryProvider).updateThemeConfig(
                            themeConfig.copyWith(themeMode: AppThemeMode.system),
                          );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Home Screen Quick Tiles Customization
          const Text(
            'Home Overview Quick Tiles',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toggle tiles to show or hide them from your main home dashboard.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF2C2623)),
            ),
            color: const Color(0xFF1E1A18),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const CircleAvatar(
                    backgroundColor: Color(0x26F97316),
                    child: Icon(Icons.bar_chart, color: Color(0xFFF97316), size: 20),
                  ),
                  title: const Text('Quick Analytics', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('Month spending & trend metrics', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  value: tilesConfig.showQuickAnalytics,
                  activeColor: const Color(0xFFF48C6A),
                  onChanged: (val) => ref.read(homeTilesConfigProvider.notifier).setQuickAnalytics(val),
                ),
                const Divider(height: 1, color: Color(0xFF2C2623)),
                SwitchListTile(
                  secondary: const CircleAvatar(
                    backgroundColor: Color(0x26FBBF24),
                    child: Icon(Icons.lightbulb_outline, color: Color(0xFFFBBF24), size: 20),
                  ),
                  title: const Text('Quick Insights', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('Savings rate & daily average spending', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  value: tilesConfig.showQuickInsights,
                  activeColor: const Color(0xFFF48C6A),
                  onChanged: (val) => ref.read(homeTilesConfigProvider.notifier).setQuickInsights(val),
                ),
                const Divider(height: 1, color: Color(0xFF2C2623)),
                SwitchListTile(
                  secondary: const CircleAvatar(
                    backgroundColor: Color(0x2638BDF8),
                    child: Icon(Icons.pie_chart_outline, color: Color(0xFF38BDF8), size: 20),
                  ),
                  title: const Text('Reports & Breakdown', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('Category shares & include/exclude filters', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  value: tilesConfig.showReports,
                  activeColor: const Color(0xFFF48C6A),
                  onChanged: (val) => ref.read(homeTilesConfigProvider.notifier).setReports(val),
                ),
                const Divider(height: 1, color: Color(0xFF2C2623)),
                SwitchListTile(
                  secondary: const CircleAvatar(
                    backgroundColor: Color(0x26A855F7),
                    child: Icon(Icons.calendar_month, color: Color(0xFFA855F7), size: 20),
                  ),
                  title: const Text('Calendar Heatmap', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('Color-coded daily spend tracker', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  value: tilesConfig.showCalendarHeatmap,
                  activeColor: const Color(0xFFF48C6A),
                  onChanged: (val) => ref.read(homeTilesConfigProvider.notifier).setCalendarHeatmap(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. App Info
          const Center(
            child: Text(
              'Mony v0.10.0 • AI Financial OS',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF48C6A).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFF48C6A) : const BorderSide().color.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFF48C6A) : Colors.white60,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
