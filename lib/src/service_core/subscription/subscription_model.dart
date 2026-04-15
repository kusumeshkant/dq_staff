/// Local model for the subscription data returned by featureAccessMap + storeSubscription queries.

class FeatureAccessMap {
  final bool coupons;
  final bool analytics;
  final bool bulkUpload;
  final bool advancedReports;
  final bool staffPerformanceAnalytics;
  final bool customerLtvAnalytics;
  final bool prioritySupport;
  final bool customBranding;
  final bool exportData;

  const FeatureAccessMap({
    required this.coupons,
    required this.analytics,
    required this.bulkUpload,
    required this.advancedReports,
    required this.staffPerformanceAnalytics,
    required this.customerLtvAnalytics,
    required this.prioritySupport,
    required this.customBranding,
    required this.exportData,
  });

  /// All features false — used as safe default before data loads.
  const FeatureAccessMap.locked()
      : coupons                   = false,
        analytics                 = false,
        bulkUpload                = false,
        advancedReports           = false,
        staffPerformanceAnalytics = false,
        customerLtvAnalytics      = false,
        prioritySupport           = false,
        customBranding            = false,
        exportData                = false;

  factory FeatureAccessMap.fromJson(Map<String, dynamic> json) {
    bool b(String key) => json[key] == true;
    return FeatureAccessMap(
      coupons:                   b('coupons'),
      analytics:                 b('analytics'),
      bulkUpload:                b('bulkUpload'),
      advancedReports:           b('advancedReports'),
      staffPerformanceAnalytics: b('staffPerformanceAnalytics'),
      customerLtvAnalytics:      b('customerLtvAnalytics'),
      prioritySupport:           b('prioritySupport'),
      customBranding:            b('customBranding'),
      exportData:                b('exportData'),
    );
  }

  bool operator [](String key) {
    switch (key) {
      case 'coupons':                   return coupons;
      case 'analytics':                 return analytics;
      case 'bulkUpload':                return bulkUpload;
      case 'advancedReports':           return advancedReports;
      case 'staffPerformanceAnalytics': return staffPerformanceAnalytics;
      case 'customerLtvAnalytics':      return customerLtvAnalytics;
      case 'prioritySupport':           return prioritySupport;
      case 'customBranding':            return customBranding;
      case 'exportData':                return exportData;
      default:                          return false;
    }
  }

  @override
  String toString() =>
      'FeatureAccessMap(analytics:$analytics, coupons:$coupons, bulkUpload:$bulkUpload)';
}

class SubscriptionInfo {
  final String status;
  final String planName;
  final String planDisplayName;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEndsAt;
  final DateTime? gracePeriodEndsAt;
  final FeatureAccessMap features;

  const SubscriptionInfo({
    required this.status,
    required this.planName,
    required this.planDisplayName,
    required this.features,
    this.currentPeriodEnd,
    this.trialEndsAt,
    this.gracePeriodEndsAt,
  });

  const SubscriptionInfo.loading()
      : status           = 'loading',
        planName         = '',
        planDisplayName  = '',
        features         = const FeatureAccessMap.locked(),
        currentPeriodEnd = null,
        trialEndsAt      = null,
        gracePeriodEndsAt = null;

  bool get isAccessible => const [
        'trial', 'active', 'grace_period', 'admin_override', 'grandfathered'
      ].contains(status);

  bool get isTrial       => status == 'trial';
  bool get isActive      => status == 'active';
  bool get isGracePeriod => status == 'grace_period';
  bool get isExpired     => status == 'expired';
  bool get isGrandfathered => status == 'grandfathered';

  /// Days left in trial, or null if not on trial / already expired.
  int? get trialDaysLeft {
    if (!isTrial || trialEndsAt == null) return null;
    final diff = trialEndsAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}
