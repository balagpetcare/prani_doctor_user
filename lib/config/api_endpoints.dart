/// Aggregated barrel of all feature API path definitions.
///
/// Each feature continues to own its `*_api_paths.dart` file (feature-first).
/// This barrel provides a single discoverable import for endpoint constants:
/// `import 'package:pranidoctor_user/config/api_endpoints.dart';`
///
/// Existing per-feature imports keep working unchanged (backward compatible).
library;

export '../features/ai/data/ai_api_paths.dart';
export '../features/animals/data/animal_api_paths.dart';
export '../features/app_config/data/app_config_api_paths.dart';
export '../features/auth/data/auth_api_paths.dart';
export '../features/batches/data/batch_api_paths.dart';
export '../features/doctors/data/provider_api_paths.dart';
export '../features/farm/data/farm_api_paths.dart';
export '../features/fattening/data/fattening_api_paths.dart';
export '../features/feed/data/feed_api_paths.dart';
export '../features/feed_catalog/data/feed_catalog_api_paths.dart';
export '../features/finance/data/finance_api_paths.dart';
export '../features/health/data/health_api_paths.dart';
export '../features/home/data/dashboard_api_paths.dart';
export '../features/inventory/data/inventory_api_paths.dart';
export '../features/milk/data/milk_api_paths.dart';
export '../features/notifications/data/notification_api_paths.dart';
export '../features/profile/data/profile_api_paths.dart';
export '../features/service_requests/data/service_request_api_paths.dart';
export '../features/settings/data/settings_api_paths.dart';
export '../features/shared/upload/services/upload_api_paths.dart';
export '../features/support/data/support_api_paths.dart';
export '../features/treatment/data/treatment_api_paths.dart';
export '../features/vaccine/data/vaccine_api_paths.dart';
