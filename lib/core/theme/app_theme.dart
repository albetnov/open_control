import 'package:flutter/material.dart';
import 'package:open_control/core/theme/app_colors.dart';

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppColors.amber,
    onPrimary: AppColors.charcoal,
    surface: AppColors.graphite,
    onSurface: AppColors.textBright,
    surfaceContainerHighest: AppColors.graphiteHigh,
    error: AppColors.error,
    onError: AppColors.textBright,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.charcoal,
    colorScheme: colorScheme,
    dividerColor: AppColors.divider,
    textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: AppColors.textBright,
          displayColor: AppColors.textBright,
        ),
    listTileTheme: const ListTileThemeData(
      textColor: AppColors.textBright,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.graphite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
