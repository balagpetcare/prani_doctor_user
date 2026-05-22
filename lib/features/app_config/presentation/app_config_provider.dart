import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_config_dto.dart';

/// Latest bootstrap config (cache or network). Set during app boot.
final appConfigProvider = StateProvider<AppConfigDto?>((ref) => null);
