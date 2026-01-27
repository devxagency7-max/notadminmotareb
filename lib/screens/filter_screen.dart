import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motareb/core/extensions/loc_extension.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          context.loc.searchFilter,
          style: GoogleFonts.cairo(
            color: Theme.of(context).textTheme.bodyLarge?.color,
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
              context.loc.reset,
              style: GoogleFonts.cairo(
                color: const Color(0xFF39BB5E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 10,
          top: 10,
        ),
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
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? []
                : [
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
              context.loc.applyFilter,
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
              _buildSectionTitle(
                context.loc.priceRangeMonthly(context.loc.currency),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceInput(
                      context,
                      '${_currentRangeValues.start.round()}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '-',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPriceInput(
                      context,
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
                activeColor: const Color(0xFF39BB5E),
                inactiveColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
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
              _buildSectionTitle(context.loc.housingType),
              _buildRadioOption(context.loc.bedInSharedRoom, 'Bed'),
              _buildRadioOption(context.loc.singleRoom, 'Single room'),
              _buildRadioOption(context.loc.fullApartment, 'Apartment'),

              const SizedBox(height: 20),

              // Gender
              _buildSectionTitle(context.loc.allowedGender),
              Row(
                children: [
                  _buildChip(context.loc.males, 'Male'),
                  const SizedBox(width: 10),
                  _buildChip(context.loc.females, 'Female'),
                  // Removed Mixed option
                ],
              ),

              const SizedBox(height: 20),

              // Smoking
              _buildSectionTitle(context.loc.smoking),
              Row(
                children: [
                  _buildChip(context.loc.allowed, 'Allowed'),
                  const SizedBox(width: 10),
                  _buildChip(context.loc.forbidden, 'Forbidden'),
                ],
              ),
            ],
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
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildPriceInput(BuildContext context, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).dividerColor
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardTheme.color
            : Colors.grey.shade50,
      ),
      child: Text(
        value,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildRadioOption(String text, String value) {
    bool isSelected = _selectedHousingType == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border.all(
          color: isSelected
              ? const Color(0xFF39BB5E)
              : Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).dividerColor
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RadioListTile<String>(
        title: Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        value: value,
        groupValue: _selectedHousingType,
        activeColor: const Color(0xFF39BB5E),
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
            color: isSelected
                ? const Color(0xFF39BB5E).withOpacity(0.1)
                : Theme.of(context).cardTheme.color,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF39BB5E)
                  : Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              color: isSelected
                  ? const Color(0xFF39BB5E)
                  : Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
