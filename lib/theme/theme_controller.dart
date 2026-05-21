import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final _lightTheme = AppTheme.light();
final _darkTheme = AppTheme.dark();

final lightThemeProvider = Provider<ThemeData>((ref) => _lightTheme);
final darkThemeProvider = Provider<ThemeData>((ref) => _darkTheme);
