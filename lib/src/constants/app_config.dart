class AppConfig {
  AppConfig._();

  // Set at build time via --dart-define=APP_FLAVOR=dev|uat|prod
  // Defaults to prod so accidental builds without --dart-define are always safe.
  static const _flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'prod');

  static const String flavor  = _flavor;
  static const bool   isDev   = _flavor == 'dev';
  static const bool   isUat   = _flavor == 'uat';
  static const bool   isProd  = _flavor == 'prod';

  // UAT backend provider — set via --dart-define=BACKEND_PROVIDER=vercel|render|azure
  static const _backendProvider = String.fromEnvironment('BACKEND_PROVIDER', defaultValue: 'azure');

  static const String graphqlEndpoint = _flavor == 'dev'
      ? 'https://de-backend-iota.vercel.app/graphql'
      : _flavor == 'uat'
          ? (_backendProvider == 'vercel'
              ? 'https://de-backend-iota.vercel.app/graphql'
              : _backendProvider == 'render'
                  ? 'https://dq-backend-uat.onrender.com/graphql'
                  : 'https://ca-dq-uat.ashysea-f5376b70.centralindia.azurecontainerapps.io/graphql')
          : 'https://ca-dq-backend.ashysea-f5376b70.centralindia.azurecontainerapps.io/graphql';
}
