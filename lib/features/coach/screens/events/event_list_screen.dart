import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/accessibility_service.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../../admin/models/user_model.dart';
import '../../../accessibility/providers/accessibility_provider.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

/// Premium Event List with stunning animations and glassmorphism
class EventListScreen extends StatefulWidget {
  final bool canCreate;
  final bool hideAppBar;
  final bool showPastOnly;

  const EventListScreen({
    super.key,
    this.canCreate = false,
    this.hideAppBar = false,
    this.showPastOnly = false,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  DateTime? _filterFrom;
  DateTime? _filterTo;
  RunningGroup? _filterGroup;
  String _searchQuery = '';
  
  late AnimationController _staggerController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _searchController.dispose();
    super.dispose();
  }



  Future<void> _speakSelection(String title) async {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    final profile = accessibility.profile;
    
    // Only speak if TTS is enabled AND (user needs it OR explicitly enabled)
    final shouldSpeak = profile.ttsEnabled && 
                       (profile.visualNeeds == 'blind' || profile.visualNeeds == 'low_vision');

    if (shouldSpeak) {
      Provider.of<AccessibilityService>(context, listen: false).speak('Ouverture de $title');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : const Color(0xFF0A0A0F);
    final surfaceColor = highContrast ? AppColors.highContrastSurface : const Color(0xFF1A1A24);
    final textColor = highContrast ? Colors.white : Colors.white;

    Widget content = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Search and Filters
        SliverToBoxAdapter(
          child: _buildSearchAndFilters(textScale, primaryColor, surfaceColor, textColor, highContrast),
        ),
        
        // Events List
        StreamBuilder<List<EventModel>>(
          stream: _eventService.getEventsStream(
            fromDate: widget.showPastOnly ? null : _filterFrom,
            toDate: widget.showPastOnly ? DateTime.now() : _filterTo,
            group: _filterGroup,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SliverToBoxAdapter(child: _buildLoadingState(primaryColor));
            }
            if (snapshot.hasError) {
              return SliverToBoxAdapter(child: _buildErrorState(snapshot.error.toString(), primaryColor));
            }

            var events = snapshot.data ?? [];
            
            // Filter by search query
            if (_searchQuery.isNotEmpty) {
              events = events.where((e) =>
                  e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  e.location.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList();
            }
            
            // Filter past events if needed
            if (widget.showPastOnly) {
              events = events.where((e) => e.date.isBefore(DateTime.now())).toList();
            }

            if (events.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(primaryColor, textScale),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, widget.canCreate ? 100 : 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = events[index];
                    return _buildAnimatedEventCard(context, event, index, textScale, highContrast);
                  },
                  childCount: events.length,
                ),
              ),
            );
          },
        ),
      ],
    );

    if (widget.hideAppBar) {
      return Container(
        color: bgColor,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildPremiumAppBar(textScale, primaryColor, textColor),
      body: content,
      floatingActionButton: widget.canCreate
          ? _buildPremiumFAB(primaryColor, textScale)
          : null,
    );
  }

  PreferredSizeWidget _buildPremiumAppBar(double textScale, Color primaryColor, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Événements',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20 * textScale,
              color: textColor,
            ),
          ),
        ],
      ),
      actions: [
        if (widget.canCreate)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add, color: primaryColor),
            ),
            onPressed: () => _navigateToCreate(context),
            tooltip: 'Créer un événement',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchAndFilters(double textScale, Color primaryColor, Color surfaceColor, Color textColor, bool highContrast) {
    return Container(
      padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.1)),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: textColor, fontSize: 15 * textScale),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.grey[500]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: surfaceColor,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          
          SizedBox(height: 12 * textScale),
          
          // Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterPill(
                  icon: Icons.calendar_today_rounded,
                  label: _filterFrom == null && _filterTo == null
                      ? 'Date'
                      : _formatDateRange(),
                  isActive: _filterFrom != null || _filterTo != null,
                  onTap: () => _pickDateRange(context),
                  primaryColor: primaryColor,
                  textScale: textScale,
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  icon: Icons.group_rounded,
                  label: _filterGroup == null
                      ? 'Groupe'
                      : _groupLabel(_filterGroup!),
                  isActive: _filterGroup != null,
                  onTap: () => _showGroupPicker(primaryColor),
                  primaryColor: primaryColor,
                  textScale: textScale,
                ),
                if (_filterFrom != null || _filterTo != null || _filterGroup != null) ...[
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    icon: Icons.clear_all_rounded,
                    label: 'Réinitialiser',
                    isActive: false,
                    onTap: () => setState(() {
                      _filterFrom = null;
                      _filterTo = null;
                      _filterGroup = null;
                    }),
                    primaryColor: Colors.grey,
                    textScale: textScale,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required Color primaryColor,
    required double textScale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 14 * textScale.clamp(1.0, 1.1),
          vertical: 10 * textScale.clamp(1.0, 1.1),
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)])
              : null,
          color: isActive ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? primaryColor : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isActive
              ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[400],
                fontSize: 13 * textScale,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupPicker(Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choisir un groupe',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.groups_rounded, color: primaryColor),
              title: Text('Tous les groupes',
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _filterGroup = null);
                Navigator.pop(ctx);
              },
              selected: _filterGroup == null,
              selectedTileColor: primaryColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            ...RunningGroup.values.map((g) => ListTile(
              leading: Icon(Icons.group_rounded, color: _getGroupColor(g)),
              title: Text(_groupLabel(g), style: const TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _filterGroup = g);
                Navigator.pop(ctx);
              },
              selected: _filterGroup == g,
              selectedTileColor: _getGroupColor(g).withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedEventCard(BuildContext context, EventModel event, int index, double textScale, bool highContrast) {
    final groupColor = _getGroupColor(event.group);
    final delay = index * 0.1;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E28),
              const Color(0xFF16161F),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: groupColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              _speakSelection(event.title);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => EventDetailScreen(eventId: event.id),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(20 * textScale.clamp(1.0, 1.1)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Box with Glow
                  _buildDateBox(event, groupColor, textScale),
                  SizedBox(width: 16 * textScale.clamp(1.0, 1.1)),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges
                        _buildBadges(event, groupColor, textScale),
                        SizedBox(height: 10 * textScale.clamp(1.0, 1.1)),

                        // Title
                        Hero(
                          tag: 'event_title_${event.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 17 * textScale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        SizedBox(height: 12 * textScale.clamp(1.0, 1.1)),

                        // Details Row
                        _buildDetailsRow(event, textScale),
                      ],
                    ),
                  ),

                  // Arrow Indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBox(EventModel event, Color groupColor, double textScale) {
    return Container(
      width: 60 * textScale.clamp(1.0, 1.1),
      padding: EdgeInsets.symmetric(vertical: 12 * textScale.clamp(1.0, 1.1)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            groupColor.withOpacity(0.2),
            groupColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: groupColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: groupColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            event.date.day.toString(),
            style: TextStyle(
              fontSize: 24 * textScale,
              fontWeight: FontWeight.bold,
              color: groupColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getMonthName(event.date.month),
            style: TextStyle(
              fontSize: 11 * textScale,
              fontWeight: FontWeight.w700,
              color: groupColor.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(EventModel event, Color groupColor, double textScale) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildBadge(
          text: event.groupDisplayName,
          color: groupColor,
          textScale: textScale,
        ),
        _buildBadge(
          text: event.typeDisplayName,
          color: Colors.grey,
          isSecondary: true,
          textScale: textScale,
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String text,
    required Color color,
    bool isSecondary = false,
    required double textScale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * textScale.clamp(1.0, 1.1),
        vertical: 4 * textScale.clamp(1.0, 1.1),
      ),
      decoration: BoxDecoration(
        gradient: isSecondary
            ? null
            : LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
        color: isSecondary ? Colors.white.withOpacity(0.05) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSecondary ? Colors.white.withOpacity(0.1) : color.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSecondary ? Colors.grey[400] : color,
          fontSize: 10 * textScale,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDetailsRow(EventModel event, double textScale) {
    return Row(
      children: [
        _buildDetailItem(
          icon: Icons.access_time_rounded,
          text: event.time,
          textScale: textScale,
        ),
        SizedBox(width: 16 * textScale.clamp(1.0, 1.1)),
        Expanded(
          child: _buildDetailItem(
            icon: Icons.location_on_outlined,
            text: event.location,
            textScale: textScale,
            overflow: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String text,
    required double textScale,
    bool overflow = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14 * textScale, color: Colors.grey[500]),
        SizedBox(width: 4 * textScale.clamp(1.0, 1.1)),
        overflow
            ? Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12 * textScale,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 12 * textScale,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
      ],
    );
  }

  Widget _buildLoadingState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement...',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, double textScale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 56,
              color: primaryColor.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 24 * textScale),
          Text(
            'Aucun événement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20 * textScale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8 * textScale),
          Text(
            'Créez votre premier événement!',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14 * textScale,
            ),
          ),
          if (widget.canCreate) ...[
            SizedBox(height: 24 * textScale),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreate(context),
              icon: const Icon(Icons.add_rounded),
              label: Text('Créer un événement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumFAB(Color primaryColor, double textScale) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Créer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14 * textScale,
          ),
        ),
      ),
    );
  }

  Color _getGroupColor(RunningGroup? group) {
    if (group == null) return AppColors.info;
    switch (group) {
      case RunningGroup.group1: return AppColors.beginner;
      case RunningGroup.group2: return AppColors.intermediate;
      case RunningGroup.group3:
      case RunningGroup.group4: return AppColors.advanced;
      case RunningGroup.group5: return AppColors.elite;
    }
  }

  String _formatDateRange() {
    if (_filterFrom != null && _filterTo != null) {
      return '${_formatDate(_filterFrom!)} - ${_formatDate(_filterTo!)}';
    }
    if (_filterFrom != null) return 'Dès ${_formatDate(_filterFrom!)}';
    if (_filterTo != null) return 'Jusqu\'au ${_formatDate(_filterTo!)}';
    return 'Date';
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
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

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _filterFrom != null && _filterTo != null
          ? DateTimeRange(start: _filterFrom!, end: _filterTo!)
          : DateTimeRange(
              start: now,
              end: now.add(const Duration(days: 30)),
            ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
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
    if (picked != null && mounted) {
      setState(() {
        _filterFrom = picked.start;
        _filterTo = picked.end;
      });
    }
  }

  String _getMonthName(int month) {
    const months = ['JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUIN', 'JUIL', 'AOÛT', 'SEP', 'OCT', 'NOV', 'DÉC'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreateEventScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => setState(() {}));
  }
}
