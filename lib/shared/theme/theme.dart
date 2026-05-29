/// Barrel for the shared design-system / theme layer.
///
/// New canonical home for spacing, radius, colors and text styles, plus a
/// bridge to the existing `ThemeData` and brand colors so callers can use a
/// single import: `import 'package:pranidoctor_user/shared/theme/theme.dart';`
library;

export 'app_colors.dart';
export 'app_radius.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

// Bridges to existing (unmoved) theme implementation for backward compatibility.
export '../../theme/app_theme.dart';
export '../../theme/theme_controller.dart';
export '../../core/branding/brand_theme.dart' show BrandColors, BrandTheme;
