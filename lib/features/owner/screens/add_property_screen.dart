import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/custom_snackbar.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bedsController = TextEditingController();
  final _roomsController = TextEditingController();
  final _customUniversityController = TextEditingController();
  bool _isAddingUniversity = false;

  // Image Upload
  final List<String> _base64Images = [];
  final ImagePicker _picker = ImagePicker();

  // Features / Amenities
  final Map<String, bool> _amenities = {
    'wifi': false,
    'furnished': false,
    'kitchen': false,
    'ac': false,
  };

  // Rules
  final Map<String, bool> _rules = {
    'no_smoking': false,
    'quiet_hours': false,
    'visitors_allowed': false,
  };

  // Unit Type
  String _selectedUnitType = 'room'; // bed, room, studio

  // New Features State
  String _selectedGender = 'male';
  final List<String> _paymentMethods = [];
  final List<String> _selectedUniversities = [];
  final List<String> _availableUniversities = [
    'جامعة النهضة',
    'جامعة بني سويف الأهلية',
    'جامعة تعليم صناعي',
    'جامعة علوم اداريه',
  ];

  // Governorate
  final List<String> _governorates = [
    'القاهرة',
    'الجيزة',
    'القليوبية',
    'الإسكندرية',
    'البحيرة',
    'مطروح',
    'كفر الشيخ',
    'الدقهلية',
    'دمياط',
    'الغربية',
    'المنوفية',
    'الشرقية',
    'بورسعيد',
    'الإسماعيلية',
    'السويس',
    'شمال سيناء',
    'جنوب سيناء',
    'الفيوم',
    'بني سويف',
    'المنيا',
    'أسيوط',
    'سوهاج',
    'قنا',
    'الأقصر',
    'أسوان',
    'البحر الأحمر',
    'الوادي الجديد',
  ];
  String _selectedGovernorate = 'بني سويف';

  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final String base64String = base64Encode(bytes);
        setState(() {
          _base64Images.add(base64String);
        });
      }
    } catch (e) {
      CustomSnackBar.show(
        context: context,
        message: 'فشل اختيار الصورة: $e',
        isError: true,
      );
    }
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_base64Images.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'يجب إضافة صورة واحدة على الأقل',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      final selectedAmenities = _amenities.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final selectedRules = _rules.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final propertyData = {
        'ownerId': user.uid,
        'title': _titleController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'location': _locationController.text.trim(),
        'governorate': _selectedGovernorate,
        'description': _descriptionController.text.trim(),
        'images': _base64Images, // Storing Base64 directly as requested
        'amenities': selectedAmenities,
        'rules': selectedRules,
        'isBed': _selectedUnitType == 'bed',
        'isRoom': _selectedUnitType == 'room',
        'isStudio': _selectedUnitType == 'studio',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'ratingCount': 0,
        'agentName': user.displayName ?? 'Owner',
        // New Fields
        'gender': _selectedGender,
        'paymentMethods': _paymentMethods,

        'universities': _selectedUniversities,
        'bedsCount': int.tryParse(_bedsController.text.trim()) ?? 0,
        'roomsCount': int.tryParse(_roomsController.text.trim()) ?? 0,
      };

      await FirebaseFirestore.instance
          .collection('properties')
          .add(propertyData);

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'تم إرسال عقارك للمراجعة بنجاح! ⏳',
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'حدث خطأ: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إضافة عقار جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos Section
              Text(
                'صور العقار',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _base64Images.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    final base64Image = _base64Images[index - 1];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: MemoryImage(base64Decode(base64Image)),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _base64Images.removeAt(index - 1);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'عنوان الإعلان',
                controller: _titleController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'الإيجار الشهري (ج.م)',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              // Governorate Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedGovernorate,
                decoration: InputDecoration(
                  labelText: 'المحافظة',
                  labelStyle: GoogleFonts.cairo(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF39BB5E)),
                  ),
                ),
                items: _governorates.map((String gov) {
                  return DropdownMenuItem<String>(
                    value: gov,
                    child: Text(gov, style: GoogleFonts.cairo()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGovernorate = newValue!;
                  });
                },
              ),
              const SizedBox(height: 15),

              _buildTextField(
                label: 'الموقع / الحي',
                controller: _locationController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'وصف تفصيلي',
                controller: _descriptionController,
                maxLines: 4,
              ),

              const SizedBox(height: 25),

              // Unit Type
              Text(
                'نوع الوحدة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildRadioType('سرير', 'bed'),
                  _buildRadioType('غرفة', 'room'),
                  _buildRadioType('شقة / ستوديو', 'studio'),
                ],
              ),
              const SizedBox(height: 25),

              // Gender / Housing Type
              Text(
                'نوع السكن',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildGenderRadio('شباب', 'male'),
                  const SizedBox(width: 20),
                  _buildGenderRadio('بنات', 'female'),
                ],
              ),
              const SizedBox(height: 25),

              // Payment Methods
              Text(
                'نظام الدفع',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 10,
                children: [
                  FilterChip(
                    label: Text('شهري', style: GoogleFonts.cairo()),
                    selected: _paymentMethods.contains('monthly'),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _paymentMethods.add('monthly');
                        } else {
                          _paymentMethods.remove('monthly');
                        }
                      });
                    },
                    selectedColor: const Color(0xFF39BB5E).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF39BB5E),
                  ),
                  FilterChip(
                    label: Text('بالترم', style: GoogleFonts.cairo()),
                    selected: _paymentMethods.contains('term'),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _paymentMethods.add('term');
                        } else {
                          _paymentMethods.remove('term');
                        }
                      });
                    },
                    selectedColor: const Color(0xFF39BB5E).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF39BB5E),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Universities
              Text(
                'الجامعات القريبة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 10,
                children: [
                  ..._availableUniversities.map((uni) {
                    return FilterChip(
                      label: Text(uni, style: GoogleFonts.cairo()),
                      selected: _selectedUniversities.contains(uni),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedUniversities.add(uni);
                          } else {
                            _selectedUniversities.remove(uni);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF008695).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF008695),
                    );
                  }),
                  ActionChip(
                    avatar: Icon(
                      _isAddingUniversity ? Icons.close : Icons.add,
                      size: 16,
                    ),
                    label: Text(
                      _isAddingUniversity ? 'إلغاء' : 'أخرى',
                      style: GoogleFonts.cairo(),
                    ),
                    onPressed: () {
                      setState(() {
                        _isAddingUniversity = !_isAddingUniversity;
                      });
                    },
                  ),
                ],
              ),
              if (_isAddingUniversity)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'اسم الجامعة / الكلية',
                          controller: _customUniversityController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          if (_customUniversityController.text.isNotEmpty) {
                            setState(() {
                              final newUni = _customUniversityController.text
                                  .trim();
                              _availableUniversities.add(newUni);
                              _selectedUniversities.add(newUni);
                              _customUniversityController.clear();
                              _isAddingUniversity = false;
                            });
                          }
                        },
                        icon: const CircleAvatar(
                          backgroundColor: Color(0xFF008695),
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 25),

              // Amenities
              Text(
                'المميزات',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 10,
                children: _amenities.keys.map((key) {
                  return FilterChip(
                    label: Text(
                      _getAmenityLabel(key),
                      style: GoogleFonts.cairo(),
                    ),
                    selected: _amenities[key]!,
                    onSelected: (bool selected) {
                      setState(() {
                        _amenities[key] = selected;
                      });
                    },
                    selectedColor: const Color(0xFF39BB5E).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF39BB5E),
                  );
                }).toList(),
              ),

              const SizedBox(height: 25),

              // Rules
              Text(
                'القواعد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 10,
                children: _rules.keys.map((key) {
                  return FilterChip(
                    label: Text(_getRuleLabel(key), style: GoogleFonts.cairo()),
                    selected: _rules[key]!,
                    onSelected: (bool selected) {
                      setState(() {
                        _rules[key] = selected;
                      });
                    },
                    selectedColor: Colors.orange.withOpacity(0.2),
                    checkmarkColor: Colors.orange,
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProperty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39BB5E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'إرسال طلب',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) =>
          value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF39BB5E)),
        ),
      ),
    );
  }

  Widget _buildRadioType(String label, String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedUnitType,
          activeColor: const Color(0xFF39BB5E),
          onChanged: (String? newValue) {
            setState(() {
              _selectedUnitType = newValue!;
            });
          },
        ),
        Text(label, style: GoogleFonts.cairo()),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildGenderRadio(String label, String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedGender,
          activeColor: const Color(0xFF39BB5E),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue!;
            });
          },
        ),
        Text(label, style: GoogleFonts.cairo()),
      ],
    );
  }

  String _getAmenityLabel(String key) {
    switch (key) {
      case 'wifi':
        return 'واى فاى';
      case 'furnished':
        return 'مؤثثة';
      case 'kitchen':
        return 'مطبخ';
      case 'ac':
        return 'تكييف';
      default:
        return key;
    }
  }

  String _getRuleLabel(String key) {
    switch (key) {
      case 'no_smoking':
        return 'ممنوع التدخين';
      case 'quiet_hours':
        return 'ساعات هدوء';
      case 'visitors_allowed':
        return 'مسموح بالزيارات';
      default:
        return key;
    }
  }
}
