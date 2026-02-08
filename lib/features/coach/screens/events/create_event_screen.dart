import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../../admin/models/user_model.dart';
import '../../../accessibility/providers/accessibility_provider.dart';
import '../../../../core/widgets/map_picker_widget.dart';
import 'package:latlong2/latlong.dart';

/// Premium Create Event Screen with stunning glassmorphic design
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00');
  final _distanceController = TextEditingController();

  EventType _eventType = EventType.daily;
  WeeklyEventSubType _weeklySubType = WeeklyEventSubType.longRun;
  RunningGroup? _selectedGroup = RunningGroup.group1;
  DateTime _selectedDate = DateTime.now();
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  int _currentStep = 0;

  final EventService _eventService = EventService();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : const Color(0xFF0A0A0F);
    final surfaceColor = highContrast ? AppColors.highContrastSurface : const Color(0xFF16161F);
    final cardColor = highContrast ? AppColors.highContrastSurface : const Color(0xFF1A1A24);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Animated Background
          if (!highContrast) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withOpacity(0.2),
                      primaryColor.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
          
          // Main Content
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Premium Header
                    _buildHeader(textScale, primaryColor, highContrast),
                    
                    // Progress Indicator
                    _buildProgressIndicator(primaryColor, textScale),
                    
                    // Form Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(20 * textScale.clamp(1.0, 1.1)),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step Title
                              _buildStepTitle(textScale),
                              SizedBox(height: 24 * textScale),
                              
                              // Form Fields
                              ..._buildFormFields(textScale, primaryColor, cardColor, highContrast),
                              
                              SizedBox(height: 32 * textScale),
                              
                              // Submit Button
                              _buildSubmitButton(primaryColor, textScale),
                              
                              SizedBox(height: 24 * textScale),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double textScale, Color primaryColor, bool highContrast) {
    return Padding(
      padding: EdgeInsets.all(20 * textScale.clamp(1.0, 1.1)),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvel événement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22 * textScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Créez un entraînement ou une course',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13 * textScale,
                  ),
                ),
              ],
            ),
          ),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(Color primaryColor, double textScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * textScale.clamp(1.0, 1.1)),
      child: Row(
        children: [
          _buildProgressStep(0, 'Info', primaryColor, textScale),
          _buildProgressLine(0, primaryColor),
          _buildProgressStep(1, 'Détails', primaryColor, textScale),
          _buildProgressLine(1, primaryColor),
          _buildProgressStep(2, 'Lieu', primaryColor, textScale),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, Color primaryColor, double textScale) {
    final isActive = _currentStep >= step;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentStep = step),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32 * textScale.clamp(1.0, 1.1),
              height: 32 * textScale.clamp(1.0, 1.1),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)])
                    : null,
                color: isActive ? null : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? primaryColor : Colors.white.withOpacity(0.1),
                  width: 2,
                ),
                boxShadow: isActive
                    ? [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12)]
                    : null,
              ),
              child: Center(
                child: isActive && _currentStep > step
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 13 * textScale,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 6 * textScale),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontSize: 11 * textScale,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressLine(int beforeStep, Color primaryColor) {
    final isActive = _currentStep > beforeStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.5)])
              : null,
          color: isActive ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildStepTitle(double textScale) {
    final titles = [
      '📝 Informations de base',
      '⏰ Date et heure',
      '📍 Lieu et distance',
    ];
    
    return Text(
      titles[_currentStep],
      style: TextStyle(
        color: Colors.white,
        fontSize: 18 * textScale,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  List<Widget> _buildFormFields(double textScale, Color primaryColor, Color cardColor, bool highContrast) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Fields(textScale, primaryColor, cardColor, highContrast);
      case 1:
        return _buildStep2Fields(textScale, primaryColor, cardColor, highContrast);
      case 2:
        return _buildStep3Fields(textScale, primaryColor, cardColor, highContrast);
      default:
        return [];
    }
  }

  List<Widget> _buildStep1Fields(double textScale, Color primaryColor, Color cardColor, bool highContrast) {
    return [
      _buildPremiumTextField(
        controller: _titleController,
        label: 'Titre de l\'événement',
        hint: 'Ex: Entraînement matinal',
        icon: Icons.title_rounded,
        isRequired: true,
        primaryColor: primaryColor,
        cardColor: cardColor,
        textScale: textScale,
      ),
      
      SizedBox(height: 16 * textScale),
      
      _buildPremiumTextField(
        controller: _descriptionController,
        label: 'Description',
        hint: 'Décrivez l\'événement...',
        icon: Icons.notes_rounded,
        maxLines: 3,
        primaryColor: primaryColor,
        cardColor: cardColor,
        textScale: textScale,
      ),
      
      SizedBox(height: 16 * textScale),
      
      _buildEventTypeSelector(primaryColor, cardColor, textScale),
      
      if (_eventType == EventType.weekly) ...[
        SizedBox(height: 16 * textScale),
        _buildWeeklySubTypeSelector(primaryColor, cardColor, textScale),
      ],
      
      if (_eventType == EventType.daily) ...[
        SizedBox(height: 16 * textScale),
        _buildGroupSelector(primaryColor, cardColor, textScale),
      ],
      
      SizedBox(height: 24 * textScale),
      
      _buildNavigationButtons(primaryColor, textScale, showNext: true, showPrev: false),
    ];
  }

  List<Widget> _buildStep2Fields(double textScale, Color primaryColor, Color cardColor, bool highContrast) {
    return [
      _buildDateSelector(primaryColor, cardColor, textScale),
      
      SizedBox(height: 16 * textScale),
      
      _buildTimeSelector(primaryColor, cardColor, textScale),
      
      SizedBox(height: 24 * textScale),
      
      _buildNavigationButtons(primaryColor, textScale, showNext: true, showPrev: true),
    ];
  }

  List<Widget> _buildStep3Fields(double textScale, Color primaryColor, Color cardColor, bool highContrast) {
    return [
      _buildPremiumTextField(
        controller: _locationController,
        label: 'Lieu',
        hint: 'Où se déroule l\'événement?',
        icon: Icons.location_on_rounded,
        isRequired: true,
        primaryColor: primaryColor,
        cardColor: cardColor,
        textScale: textScale,
        suffixIcon: IconButton(
          icon: Icon(Icons.map_rounded, color: primaryColor),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapPickerScreen(
                  initialLocation: _latitude != null && _longitude != null
                      ? LatLng(_latitude!, _longitude!)
                      : const LatLng(36.8065, 10.1815), // Default to Tunis
                ),
              ),
            );

            if (result != null) {
              setState(() {
                _locationController.text = result['address'];
                _latitude = result['latitude'];
                _longitude = result['longitude'];
              });
            }
          },
        ),
      ),
      
      if (_latitude != null && _longitude != null)
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            'Coordonnées collectées: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
            style: TextStyle(color: AppColors.success, fontSize: 10 * textScale),
          ),
        ),
      
      SizedBox(height: 16 * textScale),
      
      _buildPremiumTextField(
        controller: _distanceController,
        label: 'Distance (km)',
        hint: 'Ex: 10',
        icon: Icons.straighten_rounded,
        keyboardType: TextInputType.number,
        primaryColor: primaryColor,
        cardColor: cardColor,
        textScale: textScale,
      ),
      
      SizedBox(height: 24 * textScale),
      
      _buildNavigationButtons(primaryColor, textScale, showNext: false, showPrev: true),
    ];
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    required Color primaryColor,
    required Color cardColor,
    required double textScale,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13 * textScale,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isRequired)
                Text(' *', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(color: Colors.white, fontSize: 15 * textScale),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(icon, color: primaryColor, size: 22),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.1)),
            ),
            validator: isRequired
                ? (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEventTypeSelector(Color primaryColor, Color cardColor, double textScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Type d\'événement',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13 * textScale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                icon: Icons.calendar_today_rounded,
                label: 'Quotidien',
                subtitle: 'Par groupe',
                isSelected: _eventType == EventType.daily,
                onTap: () => setState(() {
                  _eventType = EventType.daily;
                  _selectedGroup = RunningGroup.group1;
                }),
                primaryColor: primaryColor,
                cardColor: cardColor,
                textScale: textScale,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                icon: Icons.event_rounded,
                label: 'Hebdomadaire',
                subtitle: 'Tous groupes',
                isSelected: _eventType == EventType.weekly,
                onTap: () => setState(() {
                  _eventType = EventType.weekly;
                  _selectedGroup = null;
                }),
                primaryColor: primaryColor,
                cardColor: cardColor,
                textScale: textScale,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color cardColor,
    required double textScale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.1)),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.2),
                    primaryColor.withOpacity(0.05),
                  ],
                )
              : null,
          color: isSelected ? null : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 12)]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? primaryColor : Colors.grey[500], size: 24),
            ),
            SizedBox(height: 12 * textScale),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 14 * textScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4 * textScale),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11 * textScale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySubTypeSelector(Color primaryColor, Color cardColor, double textScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Sous-type',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13 * textScale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildSubTypeChip(
                label: 'Sortie longue',
                isSelected: _weeklySubType == WeeklyEventSubType.longRun,
                onTap: () => setState(() => _weeklySubType = WeeklyEventSubType.longRun),
                primaryColor: primaryColor,
                textScale: textScale,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSubTypeChip(
                label: 'Course officielle',
                isSelected: _weeklySubType == WeeklyEventSubType.specialEvent,
                onTap: () => setState(() => _weeklySubType = WeeklyEventSubType.specialEvent),
                primaryColor: primaryColor,
                textScale: textScale,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    required double textScale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 16 * textScale.clamp(1.0, 1.1),
          vertical: 14 * textScale.clamp(1.0, 1.1),
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)])
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 12)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[400],
              fontSize: 13 * textScale,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSelector(Color primaryColor, Color cardColor, double textScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Groupe ciblé',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13 * textScale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RunningGroup.values.map((g) {
            final isSelected = _selectedGroup == g;
            final groupColor = _getGroupColor(g);
            return GestureDetector(
              onTap: () => setState(() => _selectedGroup = g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * textScale.clamp(1.0, 1.1),
                  vertical: 10 * textScale.clamp(1.0, 1.1),
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [groupColor, groupColor.withOpacity(0.7)])
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? groupColor : Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: groupColor.withOpacity(0.3), blurRadius: 8)]
                      : null,
                ),
                child: Text(
                  _groupLabel(g),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontSize: 13 * textScale,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector(Color primaryColor, Color cardColor, double textScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                'Date de l\'événement',
                style: TextStyle(color: Colors.grey[400], fontSize: 13 * textScale, fontWeight: FontWeight.w500),
              ),
              Text(' *', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: primaryColor,
                      onPrimary: Colors.white,
                      surface: const Color(0xFF1A1A24),
                      onSurface: Colors.white,
                    ),
                    dialogBackgroundColor: const Color(0xFF1A1A24),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.1)),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_month_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatFullDate(_selectedDate),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * textScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getDayName(_selectedDate.weekday),
                        style: TextStyle(color: Colors.grey[500], fontSize: 13 * textScale),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[600], size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(Color primaryColor, Color cardColor, double textScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                'Heure de début',
                style: TextStyle(color: Colors.grey[400], fontSize: 13 * textScale, fontWeight: FontWeight.w500),
              ),
              Text(' *', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            final parts = _timeController.text.split(':');
            final initialTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 9,
              minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
            );
            
            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: primaryColor,
                      onPrimary: Colors.white,
                      surface: const Color(0xFF1A1A24),
                      onSurface: Colors.white,
                    ),
                    dialogBackgroundColor: const Color(0xFF1A1A24),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              });
            }
          },
          child: Container(
            padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.1)),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.access_time_rounded, color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  _timeController.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * textScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[600], size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(Color primaryColor, double textScale, {required bool showNext, required bool showPrev}) {
    return Row(
      children: [
        if (showPrev)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text('Précédent'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[400],
                side: BorderSide(color: Colors.grey[700]!),
                padding: EdgeInsets.symmetric(vertical: 16 * textScale.clamp(1.0, 1.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        if (showPrev && showNext) const SizedBox(width: 12),
        if (showNext)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _currentStep++),
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                label: Text(
                  'Suivant',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 16 * textScale.clamp(1.0, 1.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(Color primaryColor, double textScale) {
    return Container(
      width: double.infinity,
      height: 56 * textScale.clamp(1.0, 1.1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8 * textScale),
                  Text(
                    'Créer l\'événement',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * textScale,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getGroupColor(RunningGroup g) {
    switch (g) {
      case RunningGroup.group1: return AppColors.beginner;
      case RunningGroup.group2: return AppColors.intermediate;
      case RunningGroup.group3:
      case RunningGroup.group4: return AppColors.advanced;
      case RunningGroup.group5: return AppColors.elite;
    }
  }

  String _groupLabel(RunningGroup g) {
    String label = 'Groupe';
    
    switch (g) {
      case RunningGroup.group1: return '$label 1';
      case RunningGroup.group2: return '$label 2';
      case RunningGroup.group3: return '$label 3';
      case RunningGroup.group4: return '$label 4';
      case RunningGroup.group5: return '$label 5';
    }
  }

  String _formatFullDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _getDayName(int weekday) {
    final daysFr = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return daysFr[weekday - 1];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir les champs requis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_titleController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Titre et lieu sont requis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_eventType == EventType.daily && _selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sélectionnez un groupe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    double? distanceKm;
    final distStr = _distanceController.text.trim();
    if (distStr.isNotEmpty) {
      distanceKm = double.tryParse(distStr.replaceAll(',', '.'));
    }

    final event = EventModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      type: _eventType,
      weeklySubType: _eventType == EventType.weekly ? _weeklySubType : null,
      group: _selectedGroup,
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      time: _timeController.text.trim().isEmpty ? '09:00' : _timeController.text.trim(),
      location: _locationController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      distanceKm: distanceKm,
      createdAt: DateTime.now(),
      createdBy: FirebaseAuth.instance.currentUser?.uid,
    );

    try {
      await _eventService.createEvent(event);
      if (!mounted) return;
      
      // Success animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text('Événement créé avec succès!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
