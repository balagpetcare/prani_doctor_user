/// Standardized barrel for the error/result layer.
///
/// The canonical implementations live in `core/error/*` (singular). This
/// `core/errors` barrel adds typed network-error classification and a single
/// import surface: `import 'package:pranidoctor_user/core/errors/errors.dart';`
library;

export '../error/api_result.dart';
export '../error/app_exception.dart';
export '../error/http_error_mapper.dart';
export 'global_error_handler.dart';
export 'network_exception.dart';
export 'safe_async.dart';
export 'safe_parse.dart';
export 'user_error_mapper.dart';
