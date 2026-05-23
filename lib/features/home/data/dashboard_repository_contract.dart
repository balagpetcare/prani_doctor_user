import '../../../core/error/api_result.dart';
import 'dashboard_context_dto.dart';

abstract class DashboardRepositoryContract {
  Future<ApiResult<DashboardContext>> getDashboardContext({
    bool forceRefresh = false,
  });

  Future<DashboardContext?> readCachedDashboard();
}
