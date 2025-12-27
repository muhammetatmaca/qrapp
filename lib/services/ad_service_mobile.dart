import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' show Color;
import 'dart:io' show Platform;

/// AdMob Ad Service for QR App - Mobile Implementation
/// Manages Native Advanced Ads and Rewarded Ads
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

  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;
  bool _isRewardedAdReady = false;
  bool _isNativeAdReady = false;
  static bool _isInitialized = false;
  
  bool get isRewardedAdReady => _isRewardedAdReady && isSupported;
  bool get isNativeAdReady => _isNativeAdReady && isSupported;
  NativeAd? get nativeAd => _nativeAd;

  /// Check if ads are supported on current platform
  static bool get isSupported {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Get appropriate ad unit ID based on debug mode
  String get nativeAdUnitId => kDebugMode ? _testNativeAdUnitId : _nativeAdUnitId;
  String get rewardedAdUnitId => kDebugMode ? _testRewardedAdUnitId : _rewardedAdUnitId;

  /// Initialize the Mobile Ads SDK
  static Future<void> initialize() async {
    if (!isSupported) {
      debugPrint('AdMob SDK not supported on this platform');
      return;
    }
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob SDK initialized');
      
      // Preload ads after initialization
      instance.loadRewardedAd();
    } catch (e) {
      debugPrint('Failed to initialize AdMob SDK: $e');
    }
  }

  /// Load a Rewarded Ad for QR Code generation
  void loadRewardedAd({VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) {
    if (!isSupported || !_isInitialized) {
      onAdFailedToLoad?.call();
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          debugPrint('Rewarded ad loaded successfully');
          onAdLoaded?.call();
          
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Rewarded ad dismissed');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Failed to show rewarded ad: $error');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load rewarded ad: $error');
          _isRewardedAdReady = false;
          onAdFailedToLoad?.call();
        },
      ),
    );
  }

  /// Show the Rewarded Ad and execute callback on reward earned
  void showRewardedAd({
    required Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdNotReady,
  }) {
    if (!isSupported || _rewardedAd == null || !_isRewardedAdReady) {
      debugPrint('Rewarded ad is not ready yet');
      onAdNotReady?.call();
      return;
    }

    _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
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

    _nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Native ad loaded successfully');
          _isNativeAdReady = true;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Failed to load native ad: $error');
          ad.dispose();
          _isNativeAdReady = false;
          onAdFailedToLoad?.call();
        },
        onAdClicked: (ad) {
          debugPrint('Native ad clicked');
        },
        onAdImpression: (ad) {
          debugPrint('Native ad impression');
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: const Color(0xFF1C3022),
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF000000),
          backgroundColor: const Color(0xFF13EC49),
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFFFFFFF),
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF888888),
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF888888),
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    );
    
    _nativeAd!.load();
  }

  /// Dispose Native Ad
  void disposeNativeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isNativeAdReady = false;
  }

  /// Dispose all ads
  void dispose() {
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
    _rewardedAd = null;
    _nativeAd = null;
    _isRewardedAdReady = false;
    _isNativeAdReady = false;
  }
}
