import 'package:flutter/material.dart';
import 'package:open_control/core/locator.dart';
import 'package:open_control/core/router/app_router.dart';
import 'package:open_control/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
