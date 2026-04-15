/// Canonical feature key constants — mirrors backend src/constants/feature_keys.js
///
/// Use these in SubscriptionManager.canUse() and FeatureGuard widgets.
/// Never use raw strings.
abstract class FeatureKeys {
  FeatureKeys._();

  static const String coupons                    = 'coupons';
  static const String analytics                  = 'analytics';
  static const String bulkUpload                 = 'bulkUpload';
  static const String advancedReports            = 'advancedReports';
  static const String staffPerformanceAnalytics  = 'staffPerformanceAnalytics';
  static const String customerLtvAnalytics       = 'customerLtvAnalytics';
  static const String prioritySupport            = 'prioritySupport';
  static const String customBranding             = 'customBranding';
  static const String exportData                 = 'exportData';

  /// All keys in display order — used to build full access maps.
  static const List<String> all = [
    coupons,
    analytics,
    bulkUpload,
    advancedReports,
    staffPerformanceAnalytics,
    customerLtvAnalytics,
    prioritySupport,
    customBranding,
    exportData,
  ];
}

/// Canonical subscription status values — mirrors SUBSCRIPTION_STATUS on backend.
abstract class SubscriptionStatus {
  SubscriptionStatus._();

  static const String trial          = 'trial';
  static const String active         = 'active';
  static const String gracePeriod    = 'grace_period';
  static const String expired        = 'expired';
  static const String cancelled      = 'cancelled';
  static const String adminOverride  = 'admin_override';
  static const String grandfathered  = 'grandfathered';
  static const String none           = 'none';

  /// Statuses that grant access (not hard-locked).
  static const List<String> accessible = [
    trial,
    active,
    gracePeriod,
    adminOverride,
    grandfathered,
  ];
}
