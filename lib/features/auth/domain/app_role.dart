enum AppRole {
  resident('resident', 'Resident'),
  builder('builder', 'Builder'),
  admin('admin', 'Administrator');

  const AppRole(this.key, this.label);

  final String key;
  final String label;

  static AppRole fromKey(String? key) {
    return AppRole.values.firstWhere(
      (role) => role.key == key,
      orElse: () => AppRole.resident,
    );
  }
}
