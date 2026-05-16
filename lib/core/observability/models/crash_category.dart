enum CrashCategory {
  widget,
  api,
  navigation,
  state,
  rendering,
  network,
  unknown;

  String get label => name;
}
