enum AppRoute {
  connection('/'),
  remote('/remote'),
  files('/remote/files');

  const AppRoute(this.path);

  final String path;
}
