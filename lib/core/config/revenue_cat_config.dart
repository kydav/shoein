// RevenueCat configuration for Shoein'.

const kRevenueCatIosKey = 'appl_akZDSDJGKBGZLIfmSaaaYMGMXpd';
const kRevenueCatAndroidKey = 'goog_fwVYxEzcnCKCuoJyTclamoNVSSZ';

/// Must match the Entitlement identifier created in RevenueCat exactly.
const kEntitlementId = 'Shoein Pro';

/// Length of the app-managed free trial, in days.
const kTrialDays = 14;

/// Lets beta/internal builds bypass the paywall/trial gating without changing
/// source:  --dart-define=PAYWALL_ENABLED=false
const kPaywallEnabled = bool.fromEnvironment(
  'PAYWALL_ENABLED',
  defaultValue: true,
);
