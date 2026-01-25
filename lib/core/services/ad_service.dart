import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Interstitial Logic
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  Timer? _timer;

  // Native Ads Pools
  final List<NativeAd> _smallAdsPool = [];
  final List<NativeAd> _mediumAdsPool = [];
  final int _maxPoolSize = 3;
  bool _isSmallLoading = false;
  bool _isMediumLoading = false;

  // Test IDs
  final String _interstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  final String _nativeAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-3940256099942544/3986624511';

  void init() {
    _loadInterstitial();
    _startTimer();
    _fillSmallPool();
    _fillMediumPool();
  }

  // --- Interstitial Ads ---
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1000), (timer) {
      showInterstitialAd();
    });
  }

  void _loadInterstitial() {
    if (_isInterstitialLoading) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          Future.delayed(
            const Duration(seconds: 30),
            () => _loadInterstitial(),
          );
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      _loadInterstitial();
    }
  }

  // --- Native Ads Caching ---
  void _fillSmallPool() {
    if (_smallAdsPool.length >= _maxPoolSize || _isSmallLoading) return;
    _isSmallLoading = true;
    NativeAd(
      adUnitId: _nativeAdUnitId,
      factoryId: 'listTileSmall',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Pre-loaded Native Ad (Small) added to pool');
          _smallAdsPool.add(ad as NativeAd);
          _isSmallLoading = false;
          _fillSmallPool();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            '❌ Pre-loading Native Ad (Small) failed: ${error.message}',
          );
          ad.dispose();
          _isSmallLoading = false;
          Future.delayed(const Duration(seconds: 10), () => _fillSmallPool());
        },
      ),
    )..load();
  }

  void _fillMediumPool() {
    if (_mediumAdsPool.length >= _maxPoolSize || _isMediumLoading) return;
    _isMediumLoading = true;
    NativeAd(
      adUnitId: _nativeAdUnitId,
      factoryId: 'listTileMedium',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Pre-loaded Native Ad (Medium) added to pool');
          _mediumAdsPool.add(ad as NativeAd);
          _isMediumLoading = false;
          _fillMediumPool();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            '❌ Pre-loading Native Ad (Medium) failed: ${error.message}',
          );
          ad.dispose();
          _isMediumLoading = false;
          Future.delayed(const Duration(seconds: 10), () => _fillMediumPool());
        },
      ),
    )..load();
  }

  NativeAd? getNativeAd(String factoryId) {
    if (factoryId == 'listTileSmall') {
      if (_smallAdsPool.isNotEmpty) {
        final ad = _smallAdsPool.removeAt(0);
        _fillSmallPool();
        return ad;
      }
      _fillSmallPool(); // Try to load one if empty
    } else if (factoryId == 'listTileMedium') {
      if (_mediumAdsPool.isNotEmpty) {
        final ad = _mediumAdsPool.removeAt(0);
        _fillMediumPool();
        return ad;
      }
      _fillMediumPool(); // Try to load one if empty
    }
    return null;
  }

  void dispose() {
    _timer?.cancel();
    _interstitialAd?.dispose();
    for (var ad in _smallAdsPool) ad.dispose();
    for (var ad in _mediumAdsPool) ad.dispose();
    _smallAdsPool.clear();
    _mediumAdsPool.clear();
  }
}
