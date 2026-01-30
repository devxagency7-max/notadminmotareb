import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:motareb/core/extensions/loc_extension.dart';
import '../../../../core/models/property_model.dart';
import '../../../../core/theme/app_theme.dart';

class PropertyActions extends StatelessWidget {
  final Property property;
  final double? selectedPrice;
  final String? selectionLabel;
  final VoidCallback onBook;
  final bool isVerified;

  const PropertyActions({
    super.key,
    required this.property,
    required this.selectedPrice,
    required this.selectionLabel,
    required this.onBook,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              Theme.of(context).bottomAppBarTheme.color ??
              Theme.of(context).cardTheme.color,
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      selectionLabel ?? context.loc.price,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${NumberFormat.decimalPattern().format(selectedPrice ?? 0)} ${context.loc.currency}',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFE6F4F4)
                          : const Color(0xFF008695),
                    ),
                  ),
                  if (property.discountPrice != null)
                    Text(
                      NumberFormat.decimalPattern().format(property.price),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey.withOpacity(0.6),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isVerified)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      context.loc.verificationRequired,
                      style: GoogleFonts.cairo(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF008695).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: onBook,
                    child: Center(
                      child: Text(
                        context.loc.bookNow,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
