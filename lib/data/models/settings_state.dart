class SettingsState {
  const SettingsState({required this.obsPasswordSet, required this.fsRoot});

  final bool obsPasswordSet;
  final String fsRoot;

  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
    obsPasswordSet: json['obsPasswordSet'] == true,
    fsRoot: json['fsRoot'] as String? ?? '',
  );
}
