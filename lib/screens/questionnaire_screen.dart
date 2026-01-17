import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'booking_request_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Answers storage
  String? _smokingAnswer;
  String? _genderAnswer;
  String? _ageAnswer;

  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to Booking Request Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BookingRequestScreen()),
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

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
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Text(
                'السؤال ${_currentStep + 1} من $_totalSteps',
                style: GoogleFonts.cairo(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: const Color(0xFFE0F2F1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF008695), // Primary Turquoise
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(((_currentStep + 1) / _totalSteps) * 100).toInt()}%',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF008695),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  // Step 1: Smoking
                  _buildQuestionStep(
                    icon: Icons.smoking_rooms,
                    question: 'ما هو موقفك من التدخين؟',
                    subTitle: 'هذا السؤال إلزامي لضمان التوافق',
                    options: ['لا أدخن', 'أدخن', 'أدخن في الخارج فقط'],
                    selectedOption: _smokingAnswer,
                    onOptionSelected: (val) {
                      setState(() {
                        _smokingAnswer = val;
                      });
                    },
                  ),
                  // Step 2: Gender
                  _buildQuestionStep(
                    icon: Icons.people_outline,
                    question: 'الجنس',
                    subTitle: 'سؤال إلزامي',
                    options: ['ذكر', 'أنثى'],
                    selectedOption: _genderAnswer,
                    onOptionSelected: (val) {
                      setState(() {
                        _genderAnswer = val;
                      });
                    },
                  ),
                  // Step 3: Age
                  _buildQuestionStep(
                    icon: Icons.person_outline,
                    question: 'الفئة العمرية',
                    subTitle: 'سؤال إلزامي',
                    options: ['18-22 سنة', '23-27 سنة', '28-32 سنة', '33+ سنة'],
                    selectedOption: _ageAnswer,
                    onOptionSelected: (val) {
                      setState(() {
                        _ageAnswer = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: _isCurrentStepValid()
                          ? const LinearGradient(
                              colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _isCurrentStepValid()
                          ? null
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: _isCurrentStepValid()
                          ? [
                              BoxShadow(
                                color: const Color(0xFF39BB5E).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : [],
                    ),
                    child: ElevatedButton(
                      onPressed: _isCurrentStepValid() ? _nextPage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'التالي',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _previousPage,
                    child: Text(
                      'رجوع',
                      style: GoogleFonts.cairo(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        return _smokingAnswer != null;
      case 1:
        return _genderAnswer != null;
      case 2:
        return _ageAnswer != null;
      default:
        return false;
    }
  }

  Widget _buildQuestionStep({
    required IconData icon,
    required String question,
    required String subTitle,
    required List<String> options,
    required String? selectedOption,
    required Function(String) onOptionSelected,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1).withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF008695).withOpacity(0.2),
                ),
              ),
              child: Icon(icon, size: 50, color: const Color(0xFF008695)),
            ),
            const SizedBox(height: 30),
            Text(
              question,
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003D4D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subTitle,
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // "Obligatory" tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFF008695),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'سؤال إلزامي',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF008695),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedOption == option;
                return GestureDetector(
                  onTap: () => onOptionSelected(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF39BB5E) // Green for selection
                            : Colors.transparent,
                        width: isSelected ? 2 : 1,
                      ),
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF39BB5E).withOpacity(0.1),
                                const Color(0xFF008695).withOpacity(0.1),
                              ],
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF008695).withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF003D4D)
                                : Colors.black87,
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF39BB5E)
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.circle,
                                    size: 14,
                                    color: Color(0xFF39BB5E),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
