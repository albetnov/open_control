import 'package:go_router/go_router.dart';
import 'package:open_control/core/router/routes.dart';
import 'package:open_control/presentation/connection/connection_screen.dart';

final appRouter = GoRouter(
  initialLocation: AppRoute.connection.path,
  routes: [
    GoRoute(
      path: AppRoute.connection.path,
      builder: (context, state) => const ConnectionScreen(),
    ),
  ],
);
