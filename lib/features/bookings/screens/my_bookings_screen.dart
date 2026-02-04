import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../property_details/screens/payment_webview_screen.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/loc_extension.dart';
import '../../property_details/screens/property_details_screen.dart';
import '../../../core/models/property_model.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.loc.myBookings)),
        body: const Center(child: Text("Please login first")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.loc.myBookings,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(context.loc.noBookings));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              final bookingId = docs[index].id;

              // Helper to fetch property details for title/image if needed
              // For now we just pass data to card
              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: _BookingTimelineCard(
                  bookingId: bookingId,
                  data: data,
                  bookingDate: date,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingTimelineCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  final DateTime? bookingDate;

  const _BookingTimelineCard({
    required this.bookingId,
    required this.data,
    this.bookingDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Status Logic
    String status = data['status'] ?? 'pending';
    bool isDepositPaid =
        status == 'reserved' ||
        status == 'completed' ||
        status == 'paying_remaining';
    bool isFullyPaid = status == 'completed';

    // Expiry
    final expiresAtTimestamp = data['expiresAt'] as Timestamp?;
    final expiresAt = expiresAtTimestamp?.toDate();
    /*
    String expiryText = "";
    if (expiresAt != null) {
      expiryText = DateFormat('yyyy/MM/dd hh:mm a').format(expiresAt);
    }
    */

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
        border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
      ),
      child: Column(
        children: [
          // Header: Property Info (You might need to fetch this or store it in booking)
          // For now, assume propertyId is available to fetch or title is generic
          _buildHeader(context, data['propertyId']),

          const SizedBox(height: 20),

          // 1. Top Timeline (Horizontal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Step 1 Circle
                _buildStepCircle(context, "1", isDepositPaid),

                // Middle Line & Date
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        color: Colors.grey.withOpacity(0.3),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                (constraints.constrainWidth() / 10).floor(),
                                (_) => SizedBox(
                                  width: 5,
                                  height: 2,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Expiry Countdown centered
                      if ((status == 'reserved' ||
                              status == 'pending_deposit') &&
                          expiresAt != null)
                        CountdownTimer(expiryDate: expiresAt),
                    ],
                  ),
                ),

                // Step 2 Circle
                _buildStepCircle(context, "2", isFullyPaid),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Vertical Timeline & Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side (Deposit)
                Expanded(
                  child: Column(
                    children: [
                      _buildVerticalDashedLine(),
                      _buildDetailCard(
                        context,
                        "Deposit",
                        "${data['depositPaid'] ?? data['amount'] ?? 0} EGP", // Make sure to use correct field
                        isDepositPaid ? Colors.green : Colors.orange,
                        isDepositPaid ? "Paid" : "Pending",
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right Side (Remaining)
                Expanded(
                  child: Column(
                    children: [
                      _buildVerticalDashedLine(),
                      _buildDetailCard(
                        context,
                        "Remaining",
                        "${data['remainingAmount'] ?? 0} EGP",
                        isFullyPaid
                            ? Colors.green
                            : (status == "paying_remaining"
                                  ? Colors.orange
                                  : Colors.grey),
                        isFullyPaid
                            ? "Paid"
                            : (status == "paying_remaining"
                                  ? "Processing"
                                  : "Pending"),
                      ),

                      // Action Button for Remaining if Reserved
                      if (status == 'reserved')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandPrimary,
                              minimumSize: const Size(double.infinity, 30),
                              padding: const EdgeInsets.symmetric(vertical: 5),
                            ),
                            onPressed: () {
                              // Navigate to Payment or call function
                              // For simplicity, user might need to go to details page or trigger here
                              // Ideally trigger 'createRemainingPayment' logic here or navigate
                              _handleRemainingPayment(context);
                            },
                            child: Text(
                              "Pay Now",
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _handleRemainingPayment(BuildContext context) async {
    // 1. Select Payment Method
    String? selectedMethod;
    String? walletNumber;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Choose Payment Method",
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Card Option
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selectedMethod == 'card'
                            ? AppTheme.brandPrimary
                            : Colors.grey.shade300,
                      ),
                    ),
                    leading: const Icon(Icons.credit_card, color: Colors.blue),
                    title: Text(
                      "Credit/Debit Card",
                      style: GoogleFonts.cairo(),
                    ),
                    trailing: selectedMethod == 'card'
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.brandPrimary,
                          )
                        : null,
                    onTap: () => setState(() {
                      selectedMethod = 'card';
                      walletNumber = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  // Wallet Option
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selectedMethod == 'wallet'
                            ? AppTheme.brandPrimary
                            : Colors.grey.shade300,
                      ),
                    ),
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.orange,
                    ),
                    title: Text("Mobile Wallet", style: GoogleFonts.cairo()),
                    trailing: selectedMethod == 'wallet'
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.brandPrimary,
                          )
                        : null,
                    onTap: () => setState(() => selectedMethod = 'wallet'),
                  ),
                  if (selectedMethod == 'wallet') ...[
                    const SizedBox(height: 15),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: "Wallet Number",
                        hintText: "01xxxxxxxxx",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone_android),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => walletNumber = val,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Continue",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selectedMethod == null) return; // Cancelled
    if (selectedMethod == 'wallet' &&
        (walletNumber == null || walletNumber!.length < 11)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid Wallet Number")));
      }
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('createRemainingPayment')
          .call({
            'bookingId': bookingId,
            'paymentMethod': selectedMethod,
            'walletNumber': walletNumber,
          });

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      final resData = result.data as Map<String, dynamic>;
      final paymentToken = resData['paymentToken'];
      final iframeId = resData['iframeId'];
      final paymentId = resData['paymentId'];
      final redirectUrl = resData['redirectUrl'];

      debugPrint("📱 [CLIENT] Remaining Payment Initiated");

      if (selectedMethod == 'wallet' && redirectUrl != null) {
        // Handle Wallet Redirect
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              paymentToken:
                  "WALLET_TOKEN", // Placeholder, not needed for direct URL
              iframeId: "WALLET_ID", // Placeholder
              paymentId: paymentId?.toString() ?? "",
              bookingId: bookingId,
              paymentType: 'remaining',
              url: redirectUrl,
            ),
          ),
        );
      } else if (paymentToken != null && iframeId != null) {
        // Handle Card Iframe
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              paymentToken: paymentToken.toString(),
              iframeId: iframeId.toString(),
              paymentId: paymentId?.toString() ?? "",
              bookingId: bookingId,
              paymentType: 'remaining',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Payment Error: ${e.toString()}")));
    }
  }

  Widget _buildVerticalDashedLine() {
    return SizedBox(
      height: 30,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          4,
          (index) => Container(
            width: 2,
            height: 4,
            color: Colors.grey.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCircle(BuildContext context, String number, bool isActive) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive ? AppTheme.primaryGradient : null,
        color: isActive ? null : Colors.grey.shade300,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.brandPrimary.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Center(
        child: Text(
          number,
          style: GoogleFonts.cairo(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    String amount,
    Color statusColor,
    String statusText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? propertyId) {
    if (propertyId == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final pData = snapshot.data!.data() as Map<String, dynamic>?;
        if (pData == null) return const SizedBox();

        final title = pData['title'] ?? 'Unknown Property';

        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
              image:
                  (pData['images'] != null &&
                      (pData['images'] as List).isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage((pData['images'] as List)[0]),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child:
                (pData['images'] == null || (pData['images'] as List).isEmpty)
                ? const Icon(Icons.home)
                : null,
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "ID: $propertyId",
            style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey,
          ),
          onTap: () {
            // Optional: Navigate to Property Details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailsScreen(
                  property: Property.fromMap(
                    snapshot.data!.data() as Map<String, dynamic>,
                    snapshot.data!.id,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CountdownTimer extends StatefulWidget {
  final DateTime expiryDate;
  const CountdownTimer({super.key, required this.expiryDate});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    if (widget.expiryDate.isAfter(now)) {
      setState(() {
        _duration = widget.expiryDate.difference(now);
      });
    } else {
      setState(() {
        _duration = Duration.zero;
      });
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_duration.isNegative || _duration.inSeconds == 0) {
      return Text(
        "Expired",
        style: GoogleFonts.cairo(
          fontSize: 10,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final days = _duration.inDays;
    final hours = _duration.inHours % 24;
    final minutes = _duration.inMinutes % 60;

    String timeStr = "";
    if (days > 0) timeStr += "${days}d ";
    timeStr += "${hours}h ${minutes}m";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            "Remaining: $timeStr",
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
