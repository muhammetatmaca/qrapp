import 'package:flutter/foundation.dart';

/// AdMob Ad Service for QR App
/// Manages Native Advanced Ads and Rewarded Ads
/// 
/// Note: This service only works on Android/iOS. On web, all methods
/// are no-ops and return immediately.
class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();

  // Production Ad Unit IDs
  static const String _nativeAdUnitId = 'ca-app-pub-8339567586448961/5562897338';
  static const String _rewardedAdUnitId = 'ca-app-pub-8339567586448961/3855704629';
  
  // Test Ad Unit IDs (use these during development)
  static const String _testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  bool _isRewardedAdReady = false;
  bool _isNativeAdReady = false;
  static bool _isInitialized = false;
  
  bool get isRewardedAdReady => _isRewardedAdReady && isSupported;
  bool get isNativeAdReady => _isNativeAdReady && isSupported;

  /// Check if ads are supported on current platform
  static bool get isSupported => !kIsWeb;

  /// Get appropriate ad unit ID based on debug mode
  String get nativeAdUnitId => kDebugMode ? _testNativeAdUnitId : _nativeAdUnitId;
  String get rewardedAdUnitId => kDebugMode ? _testRewardedAdUnitId : _rewardedAdUnitId;

  /// Initialize the Mobile Ads SDK
  static Future<void> initialize() async {
    if (!isSupported) {
      debugPrint('AdMob SDK not supported on this platform');
      return;
    }
    
    // Actual initialization happens in mobile-specific code
    _isInitialized = true;
    debugPrint('AdMob SDK initialization requested');
  }

  /// Load a Rewarded Ad for QR Code generation
  void loadRewardedAd({VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) {
    if (!isSupported || !_isInitialized) {
      onAdFailedToLoad?.call();
      return;
    }
    // Actual loading happens in mobile-specific code
  }

  /// Show the Rewarded Ad and execute callback on reward earned
  void showRewardedAd({
    required Function(dynamic ad, dynamic reward) onUserEarnedReward,
    VoidCallback? onAdNotReady,
  }) {
    if (!isSupported || !_isRewardedAdReady) {
      debugPrint('Rewarded ad is not ready yet');
      onAdNotReady?.call();
      return;
    }
    // Actual showing happens in mobile-specific code
  }

  /// Load a Native Advanced Ad
  void loadNativeAd({
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
  }) {
    if (!isSupported || !_isInitialized) {
      onAdFailedToLoad?.call();
      return;
    }
    // Actual loading happens in mobile-specific code
  }

  /// Dispose Native Ad
  void disposeNativeAd() {
    _isNativeAdReady = false;
  }

  /// Dispose all ads
  void dispose() {
    _isRewardedAdReady = false;
    _isNativeAdReady = false;
  }
}
