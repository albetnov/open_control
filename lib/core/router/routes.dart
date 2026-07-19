enum AppRoute {
  connection('/'),
  remote('/remote');

  const AppRoute(this.path);

  final String path;
}
