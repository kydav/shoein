// RevenueCat configuration for Shoein'.
//
// Fill these in from the Shoein' RevenueCat project (its own project — see the
// per-app RevenueCat setup). Public app-specific SDK keys:
//   iOS:     App → API Keys → key starting with "appl_"
//   Android: App → API Keys → key starting with "goog_"
const kRevenueCatIosKey = 'appl_REPLACE_ME';
const kRevenueCatAndroidKey = 'goog_REPLACE_ME';

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
