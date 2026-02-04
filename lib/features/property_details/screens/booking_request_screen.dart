import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:motareb/core/extensions/loc_extension.dart';
import '../../../../core/models/property_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/booking_request_provider.dart';
import 'payment_webview_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/services/r2_upload_service.dart';

class BookingRequestScreen extends StatelessWidget {
  final Property property;
  final String selectionDetails;
  final double price;
  final List<String> selections;
  final bool isWhole;

  const BookingRequestScreen({
    super.key,
    required this.property,
    required this.selectionDetails,
    required this.price,
    required this.selections,
    required this.isWhole,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingRequestProvider(
        property: property,
        selectionDetails: selectionDetails,
        price: price,
        selections: selections,
        isWhole: isWhole,
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
  bool _showDateError = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  final TextEditingController _notesController = TextEditingController();

  // ID Images State
  File? _idFrontImage;
  File? _idBackImage;
  String? _idFrontUrl;
  String? _idBackUrl;
  bool _isUploadingImages = false;

  // Payment Selection
  String _paymentMethod = 'card'; // 'card' or 'wallet'
  final TextEditingController _walletNumberController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final R2UploadService _uploadService = R2UploadService();

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final userData = authProvider.userData;

    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: userData?['phone'] ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _walletNumberController.dispose();
    _notesController.dispose();
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${provider.selectionDetails} - ${provider.property.localizedTitle(context)}',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                provider.property.localizedLocation(context),
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
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
                    if (provider.property.requiredDeposit != null &&
                        provider.property.requiredDeposit! > 0) ...[
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.loc.requiredDeposit,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${provider.property.requiredDeposit} ${context.loc.currency}',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD35400),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                              isError:
                                  _showDateError && provider.startDate == null,
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
                              isError:
                                  _showDateError && provider.endDate == null,
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

              // Payment Method Selection
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
                      "طريقة الدفع", // context.loc.paymentMethod
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
                            onTap: () =>
                                setState(() => _paymentMethod = 'card'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'card'
                                    ? const Color(0xFF008695).withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _paymentMethod == 'card'
                                      ? const Color(0xFF008695)
                                      : Theme.of(
                                          context,
                                        ).dividerColor.withOpacity(0.5),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    color: _paymentMethod == 'card'
                                        ? const Color(0xFF008695)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "بطاقة بنكية", // context.loc.payWithCard
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: _paymentMethod == 'card'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _paymentMethod == 'card'
                                          ? const Color(0xFF008695)
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _paymentMethod = 'wallet'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'wallet'
                                    ? const Color(0xFF39BB5E).withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _paymentMethod == 'wallet'
                                      ? const Color(0xFF39BB5E)
                                      : Theme.of(
                                          context,
                                        ).dividerColor.withOpacity(0.5),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: _paymentMethod == 'wallet'
                                        ? const Color(0xFF39BB5E)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "محفظة إلكترونية", // context.loc.payWithWallet
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: _paymentMethod == 'wallet'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _paymentMethod == 'wallet'
                                          ? const Color(0xFF39BB5E)
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_paymentMethod == 'wallet') ...[
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _walletNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "رقم المحفظة", // context.loc.walletNumber
                          hintText: "01xxxxxxxxx",
                          prefixIcon: const Icon(Icons.phone_android),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (_paymentMethod == 'wallet') {
                            if (value == null || value.isEmpty) {
                              return context.loc.required;
                            }
                            if (!RegExp(
                              r'^01[0-2,5]{1}[0-9]{8}$',
                            ).hasMatch(value)) {
                              return "رقم هاتف غير صحيح"; // context.loc.invalidPhoneNumber
                            }
                          }
                          return null;
                        },
                      ),
                    ],
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

              const SizedBox(height: 20),

              // ID Upload Section
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
                      context.loc.idVerificationTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.loc.idVerificationDesc,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildIdImagePicker(
                            title: context.loc.idFront,
                            image: _idFrontImage,
                            onTap: () => _pickIdImage(true),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildIdImagePicker(
                            title: context.loc.idBack,
                            image: _idBackImage,
                            onTap: () => _pickIdImage(false),
                          ),
                        ),
                      ],
                    ),
                    if (_isUploadingImages)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF008695),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.loc.uploadingImages,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: const Color(0xFF008695),
                              ),
                            ),
                          ],
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
                      : () async {
                          // 1. Validate Form
                          if (!_formKey.currentState!.validate()) return;

                          // 2. Validate Dates with Provider
                          if (provider.startDate == null ||
                              provider.endDate == null) {
                            setState(() => _showDateError = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.loc.selectDatesError),
                              ),
                            );
                            return;
                          }

                          // 3. User Info
                          final user = context.read<AuthProvider>().user;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.loc.guestActionRestrictedDesc,
                                ),
                              ),
                            );
                            return;
                          }

                          // 4. Validate ID Images
                          if (_idFrontImage == null || _idBackImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.loc.uploadIdError),
                              ),
                            );
                            return;
                          }

                          // 5. Upload Images if not already uploaded
                          if (_idFrontUrl == null || _idBackUrl == null) {
                            await _uploadIdImages();
                            if (_idFrontUrl == null || _idBackUrl == null)
                              return; // Error occurred and handled in _uploadIdImages
                          }

                          await _showPaymentSummary(context);
                        },
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
                          context.loc.submitRequest, // "دفع العربون وحجز"
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

  Future<void> startDepositPayment() async {
    final provider = context.read<BookingRequestProvider>();
    setState(() {
      // Use helper or provider state later, for now local is fine or provider.isSubmitting
    });

    // We can use provider._isSubmitting but it's private.
    // Let's assume we show loading via the button's state which checks provider.isSubmitting.
    // Since provider methods handle notifies, we can wrap this in a provider method or just do manual set here if we exposed a setter.
    // For simplicity, I'll assume we can trigger the loading state or just show a dialog.

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Prepare User Info
      final userInfo = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text,
        'email': _emailController.text,
        'notes': _notesController.text,
        'idFrontUrl': _idFrontUrl,
        'idBackUrl': _idBackUrl,
      };

      print("Calling cloud function...");
      print("DEBUG user name: ${_nameController.text}");
      print("DEBUG: Sending selections: ${provider.selections}");
      print("DEBUG: Sending isWhole: ${provider.isWhole}");

      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('createDepositBooking')
          .call({
            "propertyId": provider.property.id,
            "userInfo": userInfo,
            "paymentMethod": _paymentMethod,
            "selections": provider.selections,
            "isWhole": provider.isWhole,
            "walletNumber": _paymentMethod == 'wallet'
                ? _walletNumberController.text
                : null,
          });

      Navigator.pop(context); // Close loading dialog

      final data = result.data as Map<String, dynamic>;

      // Handle Wallet Redirection
      // Handle Wallet Redirection
      if (_paymentMethod == 'wallet') {
        final redirectUrl = data['redirectUrl'] as String?;
        print("DEBUG: Wallet Redirect URL: '$redirectUrl'");

        if (redirectUrl != null &&
            redirectUrl.isNotEmpty &&
            redirectUrl.startsWith('http')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(
                url: redirectUrl,
                paymentToken: '', // Not used for direct URL
                iframeId: '',
                paymentId: data['paymentId'].toString(),
                bookingId: data['bookingId'].toString(),
                paymentType: 'deposit',
              ),
            ),
          );
          return;
        } else {
          print("DEBUG: Invalid Redirect URL caught. Url: $redirectUrl");
          // Fall through to error or handle explicitly
          throw 'Invalid wallet redirection URL received';
        }
      }

      final paymentToken = data['paymentToken'];
      final iframeId = data['iframeId'];
      final paymentId = data['paymentId'];
      final bookingId = data['bookingId'];

      if (paymentToken != null && iframeId != null) {
        if (!mounted) return;

        // Navigate to the new Secure WebView Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              paymentToken: paymentToken.toString(),
              iframeId: iframeId.toString(),
              paymentId: paymentId.toString(),
              bookingId: bookingId.toString(),
              paymentType: 'deposit',
            ),
          ),
        );
      } else {
        throw 'Missing payment data from server';
      }
    } on FirebaseFunctionsException catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context); // Close loading

      String errorMessage;

      // Parse known error codes
      if (e.code == 'failed-precondition' &&
          e.message?.contains('being booked') == true) {
        errorMessage = context.loc.paymentErrorPropertyReserved;
      } else if (e.code == 'not-found') {
        errorMessage = context.loc.paymentErrorUnavailable;
      } else {
        errorMessage = context.loc.paymentErrorGeneric(e.message ?? e.code);
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.loc.error),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.loc.confirm),
            ),
          ],
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.loc.error),
          content: Text(context.loc.paymentErrorGeneric(e.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.loc.confirm),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickIdImage(bool isFront) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        if (isFront) {
          _idFrontImage = File(pickedFile.path);
          _idFrontUrl = null; // Reset URL to force re-upload
        } else {
          _idBackImage = File(pickedFile.path);
          _idBackUrl = null;
        }
      });
    }
  }

  Future<void> _uploadIdImages() async {
    setState(() => _isUploadingImages = true);

    try {
      if (_idFrontImage != null && _idFrontUrl == null) {
        _idFrontUrl = await _uploadService.uploadFile(_idFrontImage!);
      }
      if (_idBackImage != null && _idBackUrl == null) {
        _idBackUrl = await _uploadService.uploadFile(_idBackImage!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.uploadFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImages = false);
    }
  }

  Widget _buildIdImagePicker({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
              image: image != null
                  ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
                  : null,
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_outlined,
                        color: Color(0xFF008695),
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.loc.tapToUpload,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(
    BuildContext context,
    String label,
    String date, {
    bool isError = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            Theme.of(context).inputDecorationTheme.fillColor ??
            Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: isError ? Border.all(color: Colors.red, width: 1) : null,
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

  Future<void> _showPaymentSummary(BuildContext context) async {
    final provider = context.read<BookingRequestProvider>();

    final deposit = provider.property.requiredDeposit ?? 0.0;
    final remaining = (provider.price / 2) - deposit;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              context.loc.bookingSummary,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSummaryRow(
              context,
              context.loc.propertyLabel,
              provider.property.localizedTitle(context),
              isBold: true,
            ),
            const Divider(height: 30),
            _buildSummaryRow(
              context,
              context.loc.depositAmount,
              "$deposit ${context.loc.currency}",
              valueColor: const Color(0xFFD35400),
              isBold: true,
            ),
            const SizedBox(height: 10),
            _buildSummaryRow(
              context,
              context.loc.remainingAmount,
              "$remaining ${context.loc.currency}",
              valueColor: Colors.grey,
            ),
            const SizedBox(height: 30),
            // Wallet Specific Notice
            if (_paymentMethod == 'wallet')
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "سيتم تحويلك للدفع عبر المحفظة. تأكد من وجود رصيد كافٍ.",
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF008695).withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFF008695).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF008695),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "سيتم تحويلك لصفحة الدفع الآمنة", // context.loc.paymentRedirectNotice
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: const Color(0xFF008695),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(context.loc.cancel, style: GoogleFonts.cairo()),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        startDepositPayment();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        context.loc.confirmAndPay,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.cairo(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
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
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
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
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
                          : Theme.of(context).inputDecorationTheme.fillColor ??
                                Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.1),
                            ),
                    ),
                    child: Center(
                      child: Text(
                        year.toString(),
                        style: GoogleFonts.cairo(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
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
                          ? const Color(0xFF39BB5E).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActuallySelected
                            ? const Color(0xFF39BB5E)
                            : (isPast
                                  ? Theme.of(
                                      context,
                                    ).disabledColor.withOpacity(0.1)
                                  : Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.1)),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat(
                          'MMM',
                          Localizations.localeOf(context).languageCode,
                        ).format(
                          DateTime(2024, month),
                        ), // Use current locale for month names
                        style: GoogleFonts.cairo(
                          color: isPast
                              ? Theme.of(context).disabledColor
                              : (isActuallySelected
                                    ? const Color(0xFF39BB5E)
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color),
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
