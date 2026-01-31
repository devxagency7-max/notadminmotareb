import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String bookingId;

  const PaymentSuccessScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .get(),
        builder: (context, snapshot) {
          final bookingData = snapshot.data?.data() as Map<String, dynamic>?;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon with Ring
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'تهانينا! تم الحجز',
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // The Ticket
                  _BookingTicket(
                    bookingId: bookingId,
                    bookingData: bookingData,
                  ),

                  const SizedBox(height: 48),

                  // Actions
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008695),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'العودة للرئيسية',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingTicket extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic>? bookingData;

  const _BookingTicket({required this.bookingId, this.bookingData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final createdAt =
        (bookingData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Upper Part
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  "كود الحجز",
                  "#${bookingId.substring(0, 8).toUpperCase()}",
                  isBold: true,
                ),
                const SizedBox(height: 15),
                _buildInfoRow(
                  context,
                  "التوقيت",
                  DateFormat('dd/MM/yyyy hh:mm a').format(createdAt),
                ),
                const SizedBox(height: 15),
                _buildInfoRow(
                  context,
                  "الاسم",
                  bookingData?['userInfo']?['name'] ?? "---",
                ),
              ],
            ),
          ),

          // Dashed Divider with Cutouts
          Row(
            children: [
              _buildCutout(context, isLeft: true),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          (constraints.constrainWidth() / 10).floor(),
                          (_) => SizedBox(
                            width: 5,
                            height: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              _buildCutout(context, isLeft: false),
            ],
          ),

          // Lower Part
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  "المبلغ المدفوع",
                  "${bookingData?['depositPaid'] ?? '---'} EGP",
                  valueColor: Colors.green,
                  isBold: true,
                ),
                const SizedBox(height: 8),
                Text(
                  "هذا المبلغ كعربون لضمان الحجز لمدة 7 أيام",
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
            color:
                valueColor ??
                (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildCutout(BuildContext context, {required bool isLeft}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor, // Matches Scaffold background
        borderRadius: BorderRadius.only(
          topRight: isLeft ? const Radius.circular(10) : Radius.zero,
          bottomRight: isLeft ? const Radius.circular(10) : Radius.zero,
          topLeft: isLeft ? Radius.zero : const Radius.circular(10),
          bottomLeft: isLeft ? Radius.zero : const Radius.circular(10),
        ),
      ),
    );
  }
}
