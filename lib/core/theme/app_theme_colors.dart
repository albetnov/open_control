import 'package:flutter/material.dart';
import 'package:open_control/core/theme/app_colors.dart';

extension AppThemeColors on BuildContext {
  Color get textColor => AppColors.textBright;
  Color get mutedColor => AppColors.textMuted;
  Color get borderColor => AppColors.divider;
}
