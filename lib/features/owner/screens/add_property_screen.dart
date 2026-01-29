import 'dart:async';
import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/loc_extension.dart';
import '../../../core/services/r2_upload_service.dart';
import '../widgets/add_property/available_units_card.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  // Basic Info
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController =
      TextEditingController(); // For AvailableUnitsCard
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bathroomsController = TextEditingController(text: '1');
  final _areaController = TextEditingController();

  // Helper Controllers for AvailableUnitsCard
  final _roomsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _bookingModeNotifier = ValueNotifier<String>('unit');
  final _isFullApartmentNotifier = ValueNotifier<bool>(false);
  final _totalBedsController = TextEditingController();
  final _bedPriceController = TextEditingController();
  final _apartmentRoomsCountController = TextEditingController();
  final _roomTypeController = TextEditingController();

  final ValueNotifier<String?> _videoNotifier = ValueNotifier(null);
  final ValueNotifier<List<String>> _imagesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);

  // Upload progress state
  final Map<String, double> _uploadProgress = {};

  final ValueNotifier<String> _selectedGenderNotifier = ValueNotifier('male');
  final ValueNotifier<String> _selectedGovernorateNotifier = ValueNotifier(
    'بني سويف',
  );

  final ImagePicker _picker = ImagePicker();
  final R2UploadService _uploadService = R2UploadService();

  late String _tempDocId;
  String? _ownerId;

  @override
  void initState() {
    super.initState();
    _tempDocId = FirebaseFirestore.instance
        .collection('pending_properties')
        .doc()
        .id;
    _ownerId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    _imagesNotifier.dispose();
    _isLoadingNotifier.dispose();
    _selectedGenderNotifier.dispose();
    _selectedGovernorateNotifier.dispose();
    _videoNotifier.dispose();
    _roomsNotifier.dispose();
    _bookingModeNotifier.dispose();
    _isFullApartmentNotifier.dispose();
    _totalBedsController.dispose();
    _bedPriceController.dispose();
    _apartmentRoomsCountController.dispose();
    _roomTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('يجب تسجيل الدخول أولاً', isError: true);
      return;
    }

    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage();
      if (pickedImages.isNotEmpty) {
        final files = pickedImages.map((e) => File(e.path)).toList();
        await _processUploads(files);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء اختيار الصور: $e', isError: true);
    }
  }

  Future<void> _pickVideo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('يجب تسجيل الدخول أولاً', isError: true);
      return;
    }

    try {
      final XFile? pickedVideo = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (pickedVideo != null) {
        final file = File(pickedVideo.path);
        await _processVideoUpload(file);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء اختيار الفيديو: $e', isError: true);
    }
  }

  Future<void> _processUploads(List<File> files) async {
    for (final file in files) {
      if (!mounted) return;
      setState(() {
        _uploadProgress[file.path] = 0.1;
      });
      try {
        final url = await _uploadService.uploadFile(
          file,
          ownerId: _ownerId,
          propertyUuid: _tempDocId,
          onProgress: (sent, total) {
            if (mounted)
              setState(() {
                _uploadProgress[file.path] = sent / total;
              });
          },
        );
        if (mounted) {
          final currentImages = List<String>.from(_imagesNotifier.value);
          currentImages.add(url);
          _imagesNotifier.value = currentImages;
          setState(() {
            _uploadProgress.remove(file.path);
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _uploadProgress.remove(file.path);
          });
          _showSnackBar('فشل رفع الصورة: $e', isError: true);
        }
      }
    }
  }

  Future<void> _processVideoUpload(File file) async {
    if (!mounted) return;
    setState(() {
      _uploadProgress[file.path] = 0.1;
    });
    try {
      final url = await _uploadService.uploadFile(
        file,
        ownerId: _ownerId,
        propertyUuid: _tempDocId,
        onProgress: (sent, total) {
          if (mounted)
            setState(() {
              _uploadProgress[file.path] = sent / total;
            });
        },
      );
      if (mounted) {
        _videoNotifier.value = url;
        setState(() {
          _uploadProgress.remove(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadProgress.remove(file.path);
        });
        _showSnackBar('فشل رفع الفيديو: $e', isError: true);
      }
    }
  }

  Future<void> _deleteImage(String url) async {
    final currentImages = List<String>.from(_imagesNotifier.value);
    currentImages.remove(url);
    _imagesNotifier.value = currentImages;
  }

  Future<void> _submitProperty() async {
    // Validation
    if (_titleController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _imagesNotifier.value.isEmpty) {
      _showSnackBar(
        'الرجاء ملء جميع الحقول الأساسية وإضافة صور',
        isError: true,
      );
      return;
    }

    if (_uploadProgress.isNotEmpty) {
      _showSnackBar('الرجاء الانتظار حتى انتهاء رفع الصور', isError: true);
      return;
    }

    _isLoadingNotifier.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Logic to determine counts based on Booking Mode
      int roomsCount = 0;
      int bedsCount = 0;
      int singleRooms = 0;
      int doubleRooms = 0;
      bool isBedForBooking = false;
      bool isRoomForBooking = false;

      if (_bookingModeNotifier.value == 'bed') {
        isBedForBooking = true;
        isRoomForBooking = false;
        bedsCount = int.tryParse(_totalBedsController.text.trim()) ?? 0;
        roomsCount =
            int.tryParse(_apartmentRoomsCountController.text.trim()) ?? 0;
      } else {
        // Unit System
        isRoomForBooking = true;
        isBedForBooking = false;
        final rooms = _roomsNotifier.value;
        roomsCount = rooms.length;

        for (var r in rooms) {
          final type = r['type'] as String;
          final beds = (r['beds'] as int?) ?? 0;
          bedsCount += beds;
          if (type == 'Single') singleRooms += 1;
          if (type == 'Double') doubleRooms += 1;
        }
      }

      final propertyData = {
        'id': _tempDocId,
        'propertyId': _tempDocId,
        'ownerId': user.uid,
        'title': _titleController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'governorate': _selectedGovernorateNotifier.value,
        'gender': _selectedGenderNotifier.value,
        'bathroomsCount': int.tryParse(_bathroomsController.text.trim()) ?? 1,
        'area': double.tryParse(_areaController.text.trim()) ?? 0.0,
        'images': _imagesNotifier.value,
        'videoUrl': _videoNotifier.value,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'rating': 0.0,
        'amenities': [],
        'rules': [],

        // Detailed Configuration
        'bookingMode': _bookingModeNotifier.value,
        'isFullApartmentBooking': _isFullApartmentNotifier.value,
        'roomsCount': roomsCount,
        'bedsCount': bedsCount,
        'singleRoomsCount': singleRooms,
        'doubleRoomsCount': doubleRooms,
        'isBed': isBedForBooking,
        'isRoom':
            isRoomForBooking, // Can be room or full apartment under 'unit' mode
        'unitTypes': _bookingModeNotifier.value == 'bed'
            ? _roomTypeController.text
            : _roomsNotifier.value.map((e) => e['type']).join(', '),
        'rooms': _roomsNotifier.value, // Save the full structure if needed
        // Empty English fields for Admin to fill
        'titleEn': '',
        'locationEn': '',
        'descriptionEn': '',
        'adminNumber': null,
      };

      await FirebaseFirestore.instance
          .collection('pending_properties')
          .doc(_tempDocId)
          .set(propertyData);

      if (mounted) {
        _showSnackBar(
          'تم إرسال العقار للمراجعة بنجاح! سيقوم المشرف بمراجعته قريباً ✅',
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('حدث خطأ: $e', isError: true);
      }
    } finally {
      if (mounted) _isLoadingNotifier.value = false;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.brandPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'إضافة عقار جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('الوسائط (صور وفيديو)'),
              const SizedBox(height: 10),
              _buildImagePicker(),
              const SizedBox(height: 15),
              _buildVideoPicker(),
              const SizedBox(height: 25),

              _buildSectionTitle('المعلومات الأساسية'),
              const SizedBox(height: 15),
              _buildTextField(
                _titleController,
                'عنوان الإعلان',
                Icons.title_rounded,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _priceController,
                'السعر الكلي (ج.م)',
                Icons.payments_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _locationController,
                'الموقع بالتفصيل',
                Icons.location_on_rounded,
              ),
              const SizedBox(height: 15),
              Text(
                'سيقوم المشرف بترجمة البيانات للغة الإنجليزية وإضافة رقم العقار.',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 25),

              _buildSectionTitle('نظام الغرف والتأجير'),
              const SizedBox(height: 15),
              AvailableUnitsCard(
                roomsNotifier: _roomsNotifier,
                bathroomsController: _bathroomsController,
                priceController: _priceController,
                discountPriceController: _discountPriceController,
                bookingModeNotifier: _bookingModeNotifier,
                isFullApartmentNotifier: _isFullApartmentNotifier,
                totalBedsController: _totalBedsController,
                bedPriceController: _bedPriceController,
                apartmentRoomsCountController: _apartmentRoomsCountController,
                roomTypeController: _roomTypeController,
              ),
              const SizedBox(height: 25),

              _buildSectionTitle('التفاصيل الإضافية'),
              const SizedBox(height: 15),
              _buildTextField(
                _descriptionController,
                'وصف العقار والمميزات',
                Icons.description_rounded,
                maxLines: 4,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _areaController,
                'المساحة (متر مربع)',
                Icons.square_foot_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 25),

              _buildSectionTitle('التصنيف'),
              const SizedBox(height: 15),
              _buildDropdownSection(),
              const SizedBox(height: 40),

              ValueListenableBuilder<bool>(
                valueListenable: _isLoadingNotifier,
                builder: (context, isLoading, _) {
                  return GestureDetector(
                    onTap: isLoading ? null : _submitProperty,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandPrimary.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'إرسال للمراجعة',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.brandPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.cairo(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.brandPrimary.withOpacity(0.7)),
          alignLabelWithHint: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.brandPrimary,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSection() {
    return Column(
      children: [
        ValueListenableBuilder<String>(
          valueListenable: _selectedGovernorateNotifier,
          builder: (context, value, _) {
            return _buildDropdownWrapper(
              label: 'المحافظة',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: ['بني سويف', 'القاهرة', 'الجيزة'].map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(val, style: GoogleFonts.cairo()),
                    );
                  }).toList(),
                  onChanged: (val) => _selectedGovernorateNotifier.value = val!,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
        ValueListenableBuilder<String>(
          valueListenable: _selectedGenderNotifier,
          builder: (context, value, _) {
            return _buildDropdownWrapper(
              label: 'الفئة المستهدفة',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items:
                      [
                        {'value': 'male', 'label': 'شباب فقط'},
                        {'value': 'female', 'label': 'بنات فقط'},
                      ].map((Map<String, String> item) {
                        return DropdownMenuItem<String>(
                          value: item['value'],
                          child: Text(
                            item['label']!,
                            style: GoogleFonts.cairo(),
                          ),
                        );
                      }).toList(),
                  onChanged: (val) => _selectedGenderNotifier.value = val!,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDropdownWrapper({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppTheme.brandPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _imagesNotifier,
      builder: (context, images, _) {
        final isUploading = _uploadProgress.isNotEmpty;

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length + 1 + (isUploading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: isUploading ? null : _pickImages,
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: isUploading
                          ? Colors.grey.shade200
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.brandPrimary.withOpacity(0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isUploading)
                          const CircularProgressIndicator(strokeWidth: 2)
                        else ...[
                          const Icon(
                            Icons.add_a_photo_rounded,
                            color: AppTheme.brandPrimary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'إضافة صور',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              if (isUploading && index == 1) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('جاري الرفع...')),
                );
              }

              final urlIndex = index - 1 - (isUploading ? 1 : 0);
              if (urlIndex < 0 || urlIndex >= images.length)
                return const SizedBox();

              final url = images[urlIndex];

              return Container(
                width: 120,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _deleteImage(url),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVideoPicker() {
    return ValueListenableBuilder<String?>(
      valueListenable: _videoNotifier,
      builder: (context, videoUrl, _) {
        final isUploading = _uploadProgress.keys.any(
          (k) =>
              k.toLowerCase().endsWith('.mp4') ||
              k.toLowerCase().endsWith('.mov'),
        );

        return GestureDetector(
          onTap: isUploading ? null : (videoUrl == null ? _pickVideo : null),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: videoUrl != null
                    ? Colors.green
                    : AppTheme.brandPrimary.withOpacity(0.3),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  videoUrl != null
                      ? Icons.check_circle
                      : Icons.videocam_rounded,
                  color: videoUrl != null
                      ? Colors.green
                      : AppTheme.brandPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    videoUrl != null
                        ? 'تم رفع الفيديو بنجاح ✅'
                        : 'إضافة فيديو (اختياري)',
                    style: GoogleFonts.cairo(
                      color: videoUrl != null ? Colors.green : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (videoUrl != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _videoNotifier.value = null,
                  )
                else if (isUploading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
