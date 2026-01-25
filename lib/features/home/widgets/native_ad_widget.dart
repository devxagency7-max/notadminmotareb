// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:google_fonts/google_fonts.dart';

// class NativeAdWidget extends StatefulWidget {
//   const NativeAdWidget({super.key});

//   @override
//   State<NativeAdWidget> createState() => _NativeAdWidgetState();
// }

// class _NativeAdWidgetState extends State<NativeAdWidget> {
//   NativeAd? _nativeAd;
//   bool _isAdLoaded = false;

//   // Real ID: ca-app-pub-2375099279419840/6187445807
//   // Test ID: ca-app-pub-3940256099942544/2247696110
//   final String _adUnitId = Platform.isAndroid
//       ? 'ca-app-pub-3940256099942544/2247696110' // Using Test ID for debugging
//       : 'ca-app-pub-3940256099942544/3986624511'; // iOS Test ID

//   @override
//   void initState() {
//     super.initState();
//     _loadAd();
//   }

//   void _loadAd() {
//     _nativeAd = NativeAd(
//       adUnitId: _adUnitId,
//       factoryId: 'listTile', // Must match the ID registered in MainActivity.kt
//       request: const AdRequest(),
//       listener: NativeAdListener(
//         onAdLoaded: (ad) {
//           debugPrint('✅ NativeAd loaded successfully');
//           if (mounted) {
//             setState(() {
//               _isAdLoaded = true;
//             });
//           }
//         },
//         onAdFailedToLoad: (ad, error) {
//           debugPrint('❌ NativeAd failed to load: ${error.message}');
//           ad.dispose();
//           if (mounted) {
//             setState(() {
//               _isAdLoaded = false;
//             });
//           }
//         },
//       ),
//     )..load();
//   }

//   @override
//   void dispose() {
//     _nativeAd?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isAdLoaded || _nativeAd == null) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       height: 320, // Adjust height as needed for the native layout
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//       child: Stack(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(16),
//               child: AdWidget(ad: _nativeAd!),
//             ),
//           ),
//           // "Ad" Badge in top-right
//           Positioned(
//             top: 10,
//             right: 10,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(
//                 color: Colors.amber,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Text(
//                 'إعلان',
//                 style: GoogleFonts.cairo(
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
