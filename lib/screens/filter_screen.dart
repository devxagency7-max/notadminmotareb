import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({Key? key}) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  RangeValues _currentRangeValues = const RangeValues(500, 3000);
  String _selectedHousingType = 'Single room'; // Default
  String _selectedGender = 'Male';
  String _selectedSmoking = 'Forbidden';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            'تصفية البحث',
            style: GoogleFonts.cairo(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _currentRangeValues = const RangeValues(500, 3000);
                  _selectedHousingType = 'Single room';
                  _selectedGender = 'Male';
                  _selectedSmoking = 'Forbidden';
                });
              },
              child: Text(
                'إعادة تعيين',
                style: GoogleFonts.cairo(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF008695).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'تطبيق التصفية',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price Range
                _buildSectionTitle('نطاق السعر (ر.س/شهر)'),
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceInput(
                        '${_currentRangeValues.start.round()}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('-'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPriceInput(
                        '${_currentRangeValues.end.round()}',
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _currentRangeValues,
                  min: 0,
                  max: 5000,
                  divisions: 50,
                  activeColor: Colors.teal,
                  inactiveColor: Colors.grey.shade300,
                  labels: RangeLabels(
                    _currentRangeValues.start.round().toString(),
                    _currentRangeValues.end.round().toString(),
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _currentRangeValues = values;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Housing Type
                _buildSectionTitle('نوع السكن'),
                _buildRadioOption('سرير في غرفة مشتركة', 'Bed'),
                _buildRadioOption('غرفة مفردة', 'Single room'),
                _buildRadioOption('شقة كاملة', 'Apartment'),

                const SizedBox(height: 20),

                // Gender
                _buildSectionTitle('الجنس المسموح'),
                Row(
                  children: [
                    _buildChip('ذكور', 'Male'),
                    const SizedBox(width: 10),
                    _buildChip('إناث', 'Female'),
                    // Removed Mixed option
                  ],
                ),

                const SizedBox(height: 20),

                // Smoking
                _buildSectionTitle('التدخين'),
                Row(
                  children: [
                    _buildChip('مسموح', 'Allowed'),
                    const SizedBox(width: 10),
                    _buildChip('ممنوع', 'Forbidden'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildPriceInput(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade50,
      ),
      child: Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRadioOption(String text, String value) {
    bool isSelected = _selectedHousingType == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.teal : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RadioListTile<String>(
        title: Text(text, style: GoogleFonts.cairo(fontSize: 14)),
        value: value,
        groupValue: _selectedHousingType,
        activeColor: Colors.teal,
        onChanged: (val) {
          setState(() {
            _selectedHousingType = val!;
          });
        },
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    bool isSelected = false;
    if (['Male', 'Female'].contains(value)) {
      isSelected = _selectedGender == value;
    } else {
      isSelected = _selectedSmoking == value;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (['Male', 'Female'].contains(value)) {
              _selectedGender = value;
            } else {
              _selectedSmoking = value;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isSelected ? Colors.teal : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              color: isSelected ? Colors.teal : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
