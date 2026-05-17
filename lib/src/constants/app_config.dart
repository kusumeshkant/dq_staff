class AppConfig {
  AppConfig._();

  // Set at build time via --dart-define=APP_FLAVOR=dev|uat|prod
  // Defaults to prod so accidental builds without --dart-define are always safe.
  static const _flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'prod');

  static const String graphqlEndpoint = _flavor == 'dev'
      ? 'https://de-backend-iota.vercel.app/graphql'
      : _flavor == 'uat'
          ? 'https://ca-dq-uat.ashysea-f5376b70.centralindia.azurecontainerapps.io/graphql'
          : 'https://ca-dq-backend.ashysea-f5376b70.centralindia.azurecontainerapps.io/graphql';
}
