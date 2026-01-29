import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:motareb/core/extensions/loc_extension.dart';
import '../../../../core/models/property_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/booking_request_provider.dart';

class BookingRequestScreen extends StatelessWidget {
  final Property property;
  final String selectionDetails;
  final double price;

  const BookingRequestScreen({
    super.key,
    required this.property,
    required this.selectionDetails,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingRequestProvider(
        property: property,
        selectionDetails: selectionDetails,
        price: price,
      ),
      child: const _BookingRequestContent(),
    );
  }
}

class _BookingRequestContent extends StatefulWidget {
  const _BookingRequestContent();

  @override
  State<_BookingRequestContent> createState() => _BookingRequestContentState();
}

class _BookingRequestContentState extends State<_BookingRequestContent> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _idNameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController();
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _idNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectMonthYear(BuildContext context, bool isStart) async {
    final provider = context.read<BookingRequestProvider>();
    // If no date selected, default to current month/year
    final initialDate = isStart
        ? (provider.startDate ?? DateTime.now())
        : (provider.endDate ?? provider.startDate ?? DateTime.now());

    // Ensure initialDate is not before today (so we default to now if it is)
    final DateTime now = DateTime.now();
    final DateTime safeInitial =
        initialDate.isBefore(DateTime(now.year, now.month)) ? now : initialDate;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MonthYearPickerSheet(
        initialDate: safeInitial,
        isStart: isStart,
        onDateSelected: (selectedDate) {
          if (isStart) {
            provider.setStartDate(selectedDate);
          } else {
            // Validation
            if (provider.startDate != null &&
                selectedDate.isBefore(provider.startDate!)) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(context.loc.endDateError)));
              return;
            }
            provider.setEndDate(selectedDate);
          }
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BookingRequestProvider>();
    final user = context.read<AuthProvider>().user;

    if (user == null) return;

    final success = await provider.submitOrder(
      userId: user.uid,
      userEmail: _emailController.text,
      userName: _nameController.text,
      userPhone: _phoneController.text,
      idName: _idNameController.text,
      idNumber: _idNumberController.text,
      notes: _notesController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.loc.requestSentSuccess)));
        Navigator.popUntil(context, (route) => route.isFirst);
      } else if (provider.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(provider.error!)));
      } else if (provider.startDate == null || provider.endDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.loc.selectDatesError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingRequestProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            gradient: LinearGradient(
              colors: [Color(0xFF39BB5E), Color(0xFF008695)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          context.loc.bookingRequest, // "طلب الحجز"
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Under Review Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF422006)
                      : const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF9A5B13)
                        : const Color(0xFFFFEEBA),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: isDark
                              ? const Color(0xFFFFB74D)
                              : const Color(0xFFD35400),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.loc.underReview,
                          style: GoogleFonts.cairo(
                            color: isDark
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFFD35400),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.loc.reviewNotice,
                      style: GoogleFonts.cairo(
                        color: isDark
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFFD35400),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Booking Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.bookingDetails,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.selectionDetails,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              provider.property.location,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF008695),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.loc.monthlyPriceLabel,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${provider.price} ${context.loc.currency}',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF008695),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // User Data Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.yourData,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _nameController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: context.loc.name,
                        labelStyle: GoogleFonts.cairo(fontSize: 13),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? context.loc.required
                          : null,
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: context.loc.phone,
                        labelStyle: GoogleFonts.cairo(fontSize: 13),
                        prefixIcon: const Icon(Icons.phone_outlined),
                        hintText: context.loc.examplePhoneNumber,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? context.loc.required
                          : null,
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: context.loc.email,
                        labelStyle: GoogleFonts.cairo(fontSize: 13),
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Duration Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.stayDuration,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectMonthYear(context, true),
                            child: _buildDateBox(
                              context,
                              context.loc.startDate,
                              provider.startDate != null
                                  ? DateFormat(
                                      'MM/yyyy',
                                      'en',
                                    ).format(provider.startDate!)
                                  : context.loc.selectStartMonth,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectMonthYear(context, false),
                            child: _buildDateBox(
                              context,
                              context.loc.endDate,
                              provider.endDate != null
                                  ? DateFormat(
                                      'MM/yyyy',
                                      'en',
                                    ).format(provider.endDate!)
                                  : context.loc.selectEndMonth,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFE0F2F1,
                        ).withOpacity(isDark ? 0.1 : 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          context.loc.totalDuration(provider.totalMonths),
                          style: GoogleFonts.cairo(
                            color: isDark
                                ? const Color(0xFF80CBC4)
                                : const Color(0xFF008695),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Identity Verification
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.loc.identityVerification,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            context.loc.required,
                            style: GoogleFonts.cairo(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFE0F2F1,
                        ).withOpacity(isDark ? 0.1 : 0.5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFF80CBC4).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF80CBC4)
                                : const Color(0xFF008695),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.dataProtectedNotice,
                              style: GoogleFonts.cairo(
                                color: isDark
                                    ? const Color(0xFF80CBC4)
                                    : const Color(0xFF00695C),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      context.loc.fullNameInId,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _idNameController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: context.loc.fullNameHint,
                        hintStyle: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      context.loc.nationalIdNumber,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _idNumberController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: context.loc.idNumberHint,
                        hintStyle: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      context.loc.uploadIdPhoto,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildUploadBox(context, context.loc.idFrontFace),
                    const SizedBox(height: 10),
                    _buildUploadBox(context, context.loc.idBackFace),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Additional Notes
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.additionalNotes,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: context.loc.notesHint,
                        hintStyle: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Submit
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: provider.isSubmitting
                      ? null
                      : () => _submit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: provider.isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          context.loc.submitRequest,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBox(BuildContext context, String label, String date) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            Theme.of(context).inputDecorationTheme.fillColor ??
            Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: Color(0xFF008695)),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Theme.of(context).hintColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            date,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            Theme.of(context).inputDecorationTheme.fillColor ??
            Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF008695),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.file_upload_outlined,
                  size: 18,
                  color: Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 8),
                Text(
                  context.loc.pickPhotoHint,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthYearPickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final bool isStart;
  final Function(DateTime) onDateSelected;

  const _MonthYearPickerSheet({
    required this.initialDate,
    required this.isStart,
    required this.onDateSelected,
  });

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _selectedYear;
  late int _selectedMonth;
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isStart
                      ? context.loc.selectStartMonth
                      : context.loc.selectEndMonth,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF003D4D),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Year Selector
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              itemCount: 5, // Show next 5 years
              itemBuilder: (context, index) {
                final year = _currentYear + index;
                final isSelected = year == _selectedYear;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedYear = year;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF008695)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        year.toString(),
                        style: GoogleFonts.cairo(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Month Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;

                // Correct logic: strictly check against currently selected year in state
                final isActuallySelected = month == _selectedMonth;

                // Disable past months if current year
                final isPast =
                    _selectedYear == _currentYear &&
                    month < DateTime.now().month;

                return InkWell(
                  onTap: isPast
                      ? null
                      : () {
                          setState(() {
                            _selectedMonth = month;
                          });
                          // Return result and close
                          widget.onDateSelected(
                            DateTime(_selectedYear, month, 1),
                          );
                          Navigator.pop(context);
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActuallySelected
                          ? const Color(0xFF39BB5E).withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActuallySelected
                            ? const Color(0xFF39BB5E)
                            : (isPast
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade300),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('MMM', 'ar').format(
                          DateTime(2024, month),
                        ), // Use 'ar' locale for month names
                        style: GoogleFonts.cairo(
                          color: isPast
                              ? Colors.grey
                              : (isActuallySelected
                                    ? const Color(0xFF39BB5E)
                                    : Colors.black87),
                          fontWeight: isActuallySelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
