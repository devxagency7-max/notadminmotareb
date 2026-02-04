import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RamadanOverlay extends StatefulWidget {
  final Widget? child;

  const RamadanOverlay({super.key, this.child});

  @override
  State<RamadanOverlay> createState() => _RamadanOverlayState();
}

class _RamadanOverlayState extends State<RamadanOverlay> {
  bool _isVisible = false;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  @override
  void initState() {
    super.initState();
    _checkConfig();
    _listenToConfigChanges();
  }

  void _checkConfig() {
    bool enabled = _remoteConfig.getBool('show_ramadan_theme');
    debugPrint('🔥 [RamadanOverlay] show_ramadan_theme: $enabled');
    setState(() {
      _isVisible = enabled;
    });
  }

  void _listenToConfigChanges() {
    _remoteConfig.onConfigUpdated.listen((event) async {
      await _remoteConfig.activate();
      debugPrint('🔥 [RamadanOverlay] Config Updated!');
      _checkConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        if (_isVisible) ...[
          // Top Right Fixed Overlay
          Positioned(
            top: 0,
            right: 0, // Align to right
            child: IgnorePointer(
              child: SafeArea(
                // Try removing this if it's still weird, but first check visibility
                child: SizedBox(
                  // color: Colors.red.withOpacity(0.3), // DEBUG REMOVED
                  width:
                      250, // Added explicit width to allow alignment within it
                  height: 170, // Preserve user's last size change
                  child: DotLottieLoader.fromAsset(
                    'assets/lottie/Ramadan eid moubarak_APPBAR.lottie',
                    frameBuilder: (context, dotLottie) {
                      if (dotLottie != null &&
                          dotLottie.animations.isNotEmpty) {
                        debugPrint(
                          '✅ Rendering Top Lottie (${dotLottie.animations.values.first.length} bytes)',
                        );
                        return Lottie.memory(
                          dotLottie.animations.values.first,
                          fit: BoxFit.contain, // Changed back to contain
                          alignment:
                              Alignment.topRight, // Align animation to right
                          repeat: true, // Ensure it loops
                          animate: true, // Ensure it plays
                        );
                      } else {
                        debugPrint('⚠️ Top Lottie loaded but empty or null');
                      }
                      return const SizedBox();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ Error loading top lottie: $error');
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),

          // Bottom Left Floating Overlay
          Positioned(
            bottom: 90, // Raised higher per request
            left: -10, // Moved more to left per request
            child: IgnorePointer(
              child: SizedBox(
                width: 140, // Kept user's preferred size
                height: 140, // Kept user's preferred size
                child: DotLottieLoader.fromAsset(
                  'assets/lottie/bedug ramadanBOTTON LEFT.lottie',
                  frameBuilder: (context, dotLottie) {
                    if (dotLottie != null && dotLottie.animations.isNotEmpty) {
                      return Lottie.memory(
                        dotLottie.animations.values.first,
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      );
                    }
                    return const SizedBox();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('❌ Error loading bottom lottie: $error');
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
