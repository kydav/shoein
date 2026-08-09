import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shoein/core/config/revenue_cat_config.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/core/services/firebase_bootstrap.dart';

/// Configure RevenueCat once at startup, after Firebase. No-op in demo mode.
/// Guarded so a placeholder/invalid key (before the real keys are added) or an
/// offline start can't crash the app — subscription features just stay inert
/// while the trial + read-only gating keep working.
Future<void> configureRevenueCat() async {
  if (!firebaseReady) return;
  try {
    final apiKey = Platform.isIOS ? kRevenueCatIosKey : kRevenueCatAndroidKey;
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));
  } catch (e) {
    debugPrint(e.toString());
  }
}

/// Current RevenueCat customer info. Re-identifies with the signed-in Firebase
/// UID so entitlements follow the account across devices.
class SubscriptionNotifier extends AsyncNotifier<CustomerInfo?> {
  @override
  Future<CustomerInfo?> build() async {
    if (!firebaseReady) return null;
    final user = ref.watch(authNotifierProvider);
    if (!user.isLoggedIn) {
      try {
        await Purchases.logOut();
      } catch (_) {}
      return null;
    }
    final result = await Purchases.logIn(user.uid);
    // Surface the customer in the RevenueCat dashboard (e.g. to grant a
    // promotional entitlement). Never let this block anything.
    try {
      if (user.userEmail.isNotEmpty) await Purchases.setEmail(user.userEmail);
    } catch (_) {}
    return result.customerInfo;
  }

  bool get isProActive {
    final info = state.valueOrNull;
    if (info == null) return false;
    return info.entitlements.active.containsKey(kEntitlementId);
  }

  /// Purchase a specific package (monthly/annual). Returns true if the Pro
  /// entitlement is active afterward.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      state = AsyncData(result.customerInfo);
      return result.customerInfo.entitlements.active.containsKey(
        kEntitlementId,
      );
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  Future<void> restore() async {
    final info = await Purchases.restorePurchases();
    state = AsyncData(info);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => Purchases.getCustomerInfo());
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, CustomerInfo?>(
      SubscriptionNotifier.new,
    );

/// The current (default) offering's available packages, for the paywall.
final offeringsProvider = FutureProvider<Offering?>((ref) async {
  if (!firebaseReady) return null;
  // Rebuild when the customer changes so a fresh login re-fetches.
  ref.watch(subscriptionProvider);
  try {
    final offerings = await Purchases.getOfferings();
    return offerings.current;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
});
