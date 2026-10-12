import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeTilesConfig {
  final bool showQuickAnalytics;
  final bool showQuickInsights;
  final bool showReports;
  final bool showCalendarHeatmap;

  const HomeTilesConfig({
    this.showQuickAnalytics = true,
    this.showQuickInsights = true,
    this.showReports = true,
    this.showCalendarHeatmap = true,
  });

  HomeTilesConfig copyWith({
    bool? showQuickAnalytics,
    bool? showQuickInsights,
    bool? showReports,
    bool? showCalendarHeatmap,
  }) {
    return HomeTilesConfig(
      showQuickAnalytics: showQuickAnalytics ?? this.showQuickAnalytics,
      showQuickInsights: showQuickInsights ?? this.showQuickInsights,
      showReports: showReports ?? this.showReports,
      showCalendarHeatmap: showCalendarHeatmap ?? this.showCalendarHeatmap,
    );
  }

  bool get hasAnyVisible =>
      showQuickAnalytics || showQuickInsights || showReports || showCalendarHeatmap;
}

class HomeTilesNotifier extends StateNotifier<HomeTilesConfig> {
  HomeTilesNotifier() : super(const HomeTilesConfig());

  void setQuickAnalytics(bool val) {
    state = state.copyWith(showQuickAnalytics: val);
  }

  void setQuickInsights(bool val) {
    state = state.copyWith(showQuickInsights: val);
  }

  void setReports(bool val) {
    state = state.copyWith(showReports: val);
  }

  void setCalendarHeatmap(bool val) {
    state = state.copyWith(showCalendarHeatmap: val);
  }

  void toggleAll(bool enable) {
    state = HomeTilesConfig(
      showQuickAnalytics: enable,
      showQuickInsights: enable,
      showReports: enable,
      showCalendarHeatmap: enable,
    );
  }
}

final homeTilesConfigProvider =
    StateNotifierProvider<HomeTilesNotifier, HomeTilesConfig>((ref) {
  return HomeTilesNotifier();
});
