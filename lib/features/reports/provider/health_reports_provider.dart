import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/providers.dart';
import '../../../domain/repositories/ai_repository.dart';
import '../../../shared/models/health_report.dart';
import '../../dashboard/presentation/providers/dashboard_provider.dart';

enum ReportFilter { daily, weekly, monthly }

class HealthReportsState {
  final ReportFilter selectedFilter;
  final bool isLoading;
  final HealthReport? currentReport;
  final bool hasInsufficientData;
  final String? errorMessage;

  HealthReportsState({
    required this.selectedFilter,
    required this.isLoading,
    this.currentReport,
    required this.hasInsufficientData,
    this.errorMessage,
  });

  HealthReportsState copyWith({
    ReportFilter? selectedFilter,
    bool? isLoading,
    HealthReport? currentReport,
    bool? hasInsufficientData,
    String? errorMessage,
  }) {
    return HealthReportsState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      currentReport: currentReport ?? this.currentReport,
      hasInsufficientData: hasInsufficientData ?? this.hasInsufficientData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class HealthReportsNotifier extends StateNotifier<HealthReportsState> {
  final AiRepository _aiRepo;
  final Ref _ref;

  HealthReportsNotifier(this._aiRepo, this._ref)
      : super(
          HealthReportsState(
            selectedFilter: ReportFilter.daily,
            isLoading: true,
            hasInsufficientData: false,
          ),
        ) {
    loadReport();
  }

  void changeFilter(ReportFilter filter) {
    state = state.copyWith(selectedFilter: filter);
    loadReport();
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true, errorMessage: null, hasInsufficientData: false);

    // Get selected baby from dashboard state
    final dashboard = _ref.read(dashboardProvider);
    final babyId = dashboard.baby?.id;

    if (babyId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please select or register a baby profile first.',
      );
      return;
    }

    try {
      final type = state.selectedFilter.name; // 'daily', 'weekly', 'monthly'
      final report = await _aiRepo.getHealthReport(babyId, type);

      if (report == null) {
        state = state.copyWith(
          isLoading: false,
          currentReport: null,
          hasInsufficientData: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          currentReport: report,
          hasInsufficientData: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
    }
  }
}

final healthReportsProvider =
    StateNotifierProvider<HealthReportsNotifier, HealthReportsState>((ref) {
  final aiRepo = ref.watch(aiRepositoryProvider);
  return HealthReportsNotifier(aiRepo, ref);
});
