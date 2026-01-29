import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final double fontSize;

  const SectionLabel(this.text, {super.key, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        color: const Color(0xFF008695),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final List<Widget> children;
  const GlassCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(25),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
        border: Border.all(
          color: isDark ? const Color(0xFF2F3640) : Colors.white,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? minLines;
  final IconData? icon;
  final Function(String)? onChanged;
  final TextDirection? textDirection;
  final Widget? suffix;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    this.icon,
    this.onChanged,
    this.textDirection,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      onChanged: onChanged,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      textDirection: textDirection,
      style: GoogleFonts.cairo(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.cairo(
          fontSize: 12,
          color: isDark ? Colors.grey.shade500 : Colors.grey,
        ),
        labelStyle: GoogleFonts.cairo(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF008695), size: 20)
            : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2329) : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2F3640) : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF39BB5E), width: 1.5),
        ),
      ),
    );
  }
}
