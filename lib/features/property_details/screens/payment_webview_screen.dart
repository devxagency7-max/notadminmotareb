import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'payment_success_screen.dart';
import 'payment_failed_bottom_sheet.dart';

/// PaymentWebViewScreen
/// Handles Paymob Iframe payments within a WebView.
/// Implements Dual Confirmation Strategy:
/// 1. Intercepts Success URL -> Shows "Verifying..." overlay.
/// 2. Listens to Firestore -> Only closes and shows Success Screen when 'status' is 'paid'.
class PaymentWebViewScreen extends StatefulWidget {
  final String? url;
  final String paymentToken;
  final String iframeId;
  final String paymentId;
  final String bookingId;
  final String paymentType; // 'deposit' or 'remaining'

  const PaymentWebViewScreen({
    super.key,
    this.url,
    required this.paymentToken,
    required this.iframeId,
    required this.paymentId,
    required this.bookingId,
    required this.paymentType,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isVerifying = false; // New state for Dual Confirmation
  StreamSubscription? _paymentSubscription;
  StreamSubscription? _bookingSubscription;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startPaymentListener();
  }

  void _initWebView() {
    final String paymentUrl =
        widget.url ??
        'https://accept.paymob.com/api/acceptance/iframes/${widget.iframeId}?payment_token=${widget.paymentToken}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => setState(() => _isLoading = true),
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            // We check URL here but ONLY to show "Verifying" overlay, not to finish.
            _checkUrl(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(paymentUrl));
  }

  void _startPaymentListener() {
    // 1. Listen to Booking (Success Condition depends on Payment Type)
    _bookingSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            final status = data?['status'];

            // Logic Adjustment:
            // If Deposit -> Success is 'reserved' OR 'completed'
            // If Remaining -> Success is ONLY 'completed'

            bool isSuccess = false;

            if (widget.paymentType == 'deposit') {
              isSuccess = (status == 'reserved' || status == 'completed');
            } else if (widget.paymentType == 'remaining') {
              isSuccess = (status == 'completed');
            }

            if (isSuccess) {
              _onPaymentConfirmed();
            }
          }
        });

    // 2. Listen to Payment (Failure Condition)
    _paymentSubscription = FirebaseFirestore.instance
        .collection('payments')
        .doc(widget.paymentId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            final status = data?['status'];

            if (status == 'failed') {
              _onPaymentFailed();
            }
          }
        });
  }

  /// Checks the URL for Paymob success/fail callbacks
  /// Returns TRUE if we need to prevent navigation (intercept).
  bool _checkUrl(String url) {
    debugPrint('PaymentWebView Intercepting URL: $url');

    // Paymob Iframe usually redirects to a callback URL after completion.
    // We only want to intercept if the URL is a redirection AWAY from Paymob's domain,
    // or if it explicitly contains the success/failure parameters.

    final bool isPaymobDomain = url.contains('accept.paymob.com');
    final bool isSuccess =
        url.contains('success=true') || url.contains('txn_response_code=0');
    final bool isFailure =
        url.contains('success=false') ||
        (url.contains('txn_response_code') &&
            !url.contains('txn_response_code=0'));

    // If it's a success or failure callback
    if ((isSuccess || isFailure) && !isPaymobDomain) {
      if (!_isVerifying) {
        debugPrint('Confirmed Redirect to: $url - Waiting for Firestore...');
        setState(() {
          _isVerifying = true; // Show "Verifying from server..." Overlay
        });
      }
      return true; // Stop navigation, the listener will take it from here
    }

    return false;
  }

  void _onPaymentConfirmed() {
    _paymentSubscription?.cancel();
    _bookingSubscription?.cancel();
    if (!mounted) return;

    // Close WebView and Navigate to Success Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          bookingId: widget.bookingId,
          paymentType: widget.paymentType,
        ),
      ),
    );
  }

  void _onPaymentFailed() {
    // Unlike success, failure can be retried, or we can exit.
    // We don't necessarily close the screen immediately if it's from URL,
    // but typically we want to show the BottomSheet.

    // If it's already verifying (maybe got false positive then fail), stop verifying.
    setState(() => _isVerifying = false);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PaymentFailedBottomSheet(
        onRetry: () {
          Navigator.pop(context); // Close BottomSheet
          _controller.reload(); // Reload WebView to try again
        },
        onSupport: () {
          // Add support logic here
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    _bookingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      // Prevent accidental back navigation during payment or verification
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Secure Payment',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitConfirmation,
          ),
        ),
        body: Stack(
          children: [
            // 1. The WebView itself
            WebViewWidget(controller: _controller),

            // 2. Loading Indicator (Initial Page Load)
            if (_isLoading && !_isVerifying)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF008695)),
              ),

            // 3. Premium Verifying Overlay (Source of Truth waiting area)
            if (_isVerifying)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Container(
                      color: isDark ? const Color(0xFF121212) : Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Icon or Loading
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF008695),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'جارٍ تأكيد العملية...',
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'نحن ننتظر الآن تأكيد البنك الرسمي لتحديث حالة حجزك في ثوانٍ.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                          // Security Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.security,
                                color: Colors.green.withOpacity(0.5),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "دفع آمن ومؤمن بالكامل",
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.grey.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    if (_isVerifying) return; // Don't allow exit during verification phase

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إلغاء العملية؟', style: GoogleFonts.cairo()),
        content: Text(
          'إذا خرجت الآن، قد لا يتم تأكيد حجزك.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بقاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close WebView
            },
            child: const Text(
              'خروج وإلغاء',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
