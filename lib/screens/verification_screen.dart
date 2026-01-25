import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mime/mime.dart';

import '../features/auth/providers/auth_provider.dart';
import '../services/r2_upload_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _residenceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedGovernorate;
  File? _idFrontImage;
  File? _idBackImage;

  final ImagePicker _picker = ImagePicker();
  final R2UploadService _r2Service = R2UploadService();

  bool _isSubmitting = false;
  String _loadingMessage = '';
  bool _isRetrying = false;

  final List<String> _governorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الدقهلية',
    'البحر الأحمر',
    'البحيرة',
    'الفيوم',
    'الغربية',
    'الإسماعيلية',
    'المنوفية',
    'المنيا',
    'القليوبية',
    'الوادي الجديد',
    'السويس',
    'أسوان',
    'أسيوط',
    'بني سويف',
    'بورسعيد',
    'دمياط',
    'الشرقية',
    'جنوب سيناء',
    'كفر الشيخ',
    'مطروح',
    'الأقصر',
    'قنا',
    'شمال سيناء',
    'سوهاج',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        if (authProvider.user!.displayName != null &&
            authProvider.user!.displayName!.isNotEmpty) {
          _nameController.text = authProvider.user!.displayName!;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _residenceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'EG'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF39BB5E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy/MM/dd').format(picked);
      });
    }
  }

  Future<void> _pickImage(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        final File file = File(image.path);
        final int sizeInBytes = await file.length();
        if (sizeInBytes / (1024 * 1024) > 20) {
          _showError('حجم الصورة يجب أن لا يتعدى 20 ميجابايت');
          return;
        }
        final String? mimeType = lookupMimeType(file.path);
        if (mimeType == null ||
            !['image/jpeg', 'image/png', 'image/jpg'].contains(mimeType)) {
          _showError('نوع الملف غير مدعوم. يرجى اختيار صور بصيغة JPG أو PNG');
          return;
        }
        setState(() {
          if (isFront) {
            _idFrontImage = file;
          } else {
            _idBackImage = file;
          }
        });
      }
    } catch (e) {
      _showError('حدث خطأ أثناء اختيار الصورة');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    if (_selectedGovernorate == null ||
        _residenceController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _idFrontImage == null ||
        _idBackImage == null) {
      _showError('يرجى إكمال جميع البيانات المطلوبة');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loadingMessage = 'جاري رفع الصور...';
    });

    try {
      final String frontUrl = await _r2Service.uploadFile(
        _idFrontImage!,
        propertyId: 'verification_${user.uid}',
      );
      final String backUrl = await _r2Service.uploadFile(
        _idBackImage!,
        propertyId: 'verification_${user.uid}',
      );

      setState(() {
        _loadingMessage = 'جاري حفظ البيانات...';
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'verificationStatus': 'pending',
        'isVerified': false,
        'fullName': _nameController.text.trim(),
        'governorate': _selectedGovernorate,
        'residence': _residenceController.text.trim(),
        'birthDate': _dateController.text,
        'idFrontUrl': frontUrl,
        'idBackUrl': backUrl,
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
        'rejectionReason': FieldValue.delete(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال طلب التوثيق بنجاح',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError('حدث خطأ أثناء الإرسال: $e');
    } finally {
      if (mounted)
        setState(() {
          _isSubmitting = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userData = authProvider.userData;
    final verificationStatus = userData?['verificationStatus'] ?? 'none';
    final rejectionReason = userData?['rejectionReason'];
    final bool showForm =
        _isRetrying ||
        verificationStatus == 'none' ||
        verificationStatus == null;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'توثيق الحساب',
            style: GoogleFonts.cairo(
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
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF008695), Color(0xFF39BB5E)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
            child: Column(
              children: [
                if (_isSubmitting)
                  _buildLoadingState()
                else if (showForm)
                  _buildForm()
                else if (verificationStatus == 'pending')
                  _buildStatusCard(
                    icon: Icons.history_toggle_off_rounded,
                    color: Colors.orange,
                    title: 'طلبك قيد المراجعة',
                    message:
                        'شكراً لك. نحن نقوم حالياً بمراجعة بياناتك بدقة. سيتم إخطارك بالنتيجة فور الانتهاء.',
                  )
                else if (verificationStatus == 'verified')
                  _buildStatusCard(
                    icon: Icons.verified_rounded,
                    color: const Color(0xFF39BB5E),
                    title: 'تم توثيق حسابك بنجاح',
                    message:
                        'تهانينا! حسابك الآن موثق بالكامل. يمكنك الاستمتاع بكافة الميزات والامتيازات.',
                  )
                else if (verificationStatus == 'rejected')
                  _buildRejectionState(rejectionReason),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const CircularProgressIndicator(color: Color(0xFF39BB5E)),
          const SizedBox(height: 20),
          Text(_loadingMessage, style: GoogleFonts.cairo(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(30),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: color),
            ),
            const SizedBox(height: 25),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionState(String? reason) {
    return FadeInUp(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.red.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 50,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'تم رفض طلب التوثيق',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  'سبب الرفض:',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    reason ?? 'لم يتم تحديد سبب، يرجى التواصل مع الدعم الفني.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildActionButton(
            ' المحاولة مرةأخرى',
            Icons.refresh_rounded,
            () {
              setState(() {
                _isRetrying = true;
                _idFrontImage = null;
                _idBackImage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildStepHeader(
          Icons.person_pin_rounded,
          'المعلومات الشخصية',
          'تأكد من مطابقة البيانات للهوية الرسمية',
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'الاسم الكامل',
          icon: Icons.person_outline,
          controller: _nameController,
        ),
        const SizedBox(height: 15),
        _buildGovernorateDropdown(),
        const SizedBox(height: 15),
        _buildTextField(
          label: "مكان الاقامه (الحي / الشارع)",
          icon: Icons.location_on_outlined,
          controller: _residenceController,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          label: 'تاريخ الميلاد',
          icon: Icons.calendar_month_outlined,
          controller: _dateController,
          readOnly: true,
          onTap: () => _selectDate(context),
        ),
        const SizedBox(height: 40),
        _buildStepHeader(
          Icons.camera_alt_rounded,
          'الوثائق الثبوتية',
          'التقط صورة واضحة للهوية الوطنية (الأصل)',
        ),
        const SizedBox(height: 20),
        _buildIDUploadSection(),
        const SizedBox(height: 50),
        _buildActionButton(
          'إرسال طلب التوثيق',
          Icons.send_rounded,
          _submitVerification,
        ),
      ],
    );
  }

  Widget _buildStepHeader(IconData icon, String title, String subtitle) {
    return FadeInRight(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF008695).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF008695), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGovernorateDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGovernorate,
        decoration: InputDecoration(
          labelText: 'المحافظة',
          labelStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF008695)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _governorates
            .map(
              (g) => DropdownMenuItem(
                value: g,
                child: Text(g, style: GoogleFonts.cairo()),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => _selectedGovernorate = val),
      ),
    );
  }

  Widget _buildIDUploadSection() {
    return Row(
      children: [
        Expanded(
          child: _buildUploadBox(
            'الوجه الأمامي',
            image: _idFrontImage,
            onTap: () => _pickImage(true),
            onDelete: () => setState(() => _idFrontImage = null),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildUploadBox(
            'الوجه الخلفي',
            image: _idBackImage,
            onTap: () => _pickImage(false),
            onDelete: () => setState(() => _idBackImage = null),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008695), Color(0xFF39BB5E)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39BB5E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF008695)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUploadBox(
    String title, {
    File? image,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
      onTap: image == null ? onTap : null,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: image != null
                ? const Color(0xFF39BB5E).withOpacity(0.3)
                : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Image.file(image, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008695).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      size: 32,
                      color: Color(0xFF008695),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'اضغط للرفع',
                    style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }
}
