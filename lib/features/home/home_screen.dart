import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../accessibility/providers/accessibility_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home Screen - Main dashboard for Adhérant (Regular Member)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}



class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLanguage();
  }

  Future<void> _syncLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('languageCode');
    if (langCode != null) _updateTTSLanguage(langCode);
  }

  Future<void> _updateTTSLanguage(String langCode) async {
    String ttsCode = 'fr-FR';
    if (langCode == 'ar') ttsCode = 'ar-SA';
    if (langCode == 'en') ttsCode = 'en-US';
    await _tts.setLanguage(ttsCode);
  }

  Future<void> _initTTS() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('languageCode') ?? 'fr';
    
    String ttsCode = 'fr-FR';
    if (langCode == 'ar') ttsCode = 'ar-SA';
    if (langCode == 'en') ttsCode = 'en-US';
    
    await _tts.setLanguage(ttsCode);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    final profile = Provider.of<AccessibilityProvider>(context, listen: false).profile;
    if (profile.visualNeeds == 'blind') {
      await _tts.speak(text);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    
    final tabs = ['Accueil', 'Événements', 'Le Club', 'Profil'];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          _EventsTab(),
          _ClubTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          _speak("Onglet ${tabs[index]} sélectionné");
        },
        backgroundColor: highContrast ? AppColors.highContrastSurface : null,
        indicatorColor: highContrast ? AppColors.highContrastPrimary : AppColors.primary.withOpacity(0.2),
        height: 65 * textScale.clamp(1.0, 1.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 24 * textScale.clamp(1.0, 1.2)),
            selectedIcon: Icon(Icons.home, size: 24 * textScale.clamp(1.0, 1.2)),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined, size: 24 * textScale.clamp(1.0, 1.2)),
            selectedIcon: Icon(Icons.event, size: 24 * textScale.clamp(1.0, 1.2)),
            label: 'Événements',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outlined, size: 24 * textScale.clamp(1.0, 1.2)),
            selectedIcon: Icon(Icons.info, size: 24 * textScale.clamp(1.0, 1.2)),
            label: 'Le Club',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined, size: 24 * textScale.clamp(1.0, 1.2)),
            selectedIcon: Icon(Icons.person, size: 24 * textScale.clamp(1.0, 1.2)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Home Tab - Today's run + quick actions + upcoming events
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _notificationCount = 2; // Placeholder

  Stream<QuerySnapshot>? _eventsStream;

  @override
  void initState() {
    super.initState();
    _initTTS();
    _loadUserData();
    _initEventsStream();
    
    // Ensure we have the latest profile for this user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccessibilityProvider>(context, listen: false).loadProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLanguage();
  }

  Future<void> _syncLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('languageCode');
    if (langCode != null) _updateTTSLanguage(langCode);
  }

  Future<void> _updateTTSLanguage(String langCode) async {
    String ttsCode = 'fr-FR';
    if (langCode == 'ar') ttsCode = 'ar-SA';
    if (langCode == 'en') ttsCode = 'en-US';
    await _tts.setLanguage(ttsCode);
  }

  void _initEventsStream() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    _eventsStream = FirebaseFirestore.instance
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('date')
        .limit(10)
        .snapshots();
  }

  // TTS for Home Content
  final FlutterTts _tts = FlutterTts();
  Future<void> _initTTS() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('languageCode') ?? 'fr';
    
    String ttsCode = 'fr-FR';
    if (langCode == 'ar') ttsCode = 'ar-SA';
    if (langCode == 'en') ttsCode = 'en-US';
    
    await _tts.setLanguage(ttsCode);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (!mounted) return;
    final profile = Provider.of<AccessibilityProvider>(context, listen: false).profile;
    // Enable for both blind and low vision if they touch cards
    if (profile.visualNeeds == 'blind' || profile.visualNeeds == 'low_vision') {
      await _tts.stop(); // Interrupt
      await _tts.speak(text);
    }
  }

  Future<void> _toggleRegistration(String eventId, List<dynamic> participants) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final uid = user.uid;
    final isRegistered = participants.contains(uid);
    
    try {
      await FirebaseFirestore.instance.collection('events').doc(eventId).update({
        'participants': isRegistered 
            ? FieldValue.arrayRemove([uid]) 
            : FieldValue.arrayUnion([uid])
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRegistered ? 'Désinscription confirmée' : 'Inscription confirmée!'),
          backgroundColor: isRegistered ? Colors.grey : AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      
      if (!isRegistered) _speak("Vous êtes inscrit à l'événement.");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
          
          // Announce Welcome Message for Blind Users
          final name = _userData?['fullName'] ?? _userData?['name'] ?? 'Membre';
          final group = _getGroupName();
          _speak("Bienvenue sur l'écran d'accueil, $name. Vous êtes dans le groupe $group. Double tapez pour voir votre course d'aujourd'hui.");
          
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Error loading user: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _getGroupName() {
    final groupId = _userData?['groupId'] ?? _userData?['group'] ?? '';
    switch (groupId.toString().toLowerCase()) {
      case 'beginner':
      case 'débutants':
        return 'Débutants';
      case 'intermediate':
      case 'intermédiaires':
        return 'Intermédiaires';
      case 'advanced':
      case 'confirmés':
        return 'Confirmés';
      default:
        return 'Non assigné';
    }
  }

  Color _getGroupColor() {
    final groupId = _userData?['groupId'] ?? _userData?['group'] ?? '';
    switch (groupId.toString().toLowerCase()) {
      case 'beginner':
      case 'débutants':
        return AppColors.beginner;
      case 'intermediate':
      case 'intermédiaires':
        return AppColors.intermediate;
      case 'advanced':
      case 'confirmés':
        return AppColors.advanced;
      default:
        return Colors.grey;
    }
  }

  String _getMemberSince() {
    final timestamp = _userData?['memberSince'] ?? _userData?['createdAt'];
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 
                     'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
      return '${months[date.month - 1]} ${date.year}';
    }
    return 'Récemment';
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    final boldText = profile.boldText;
    
    final bgColor = highContrast ? Colors.black : AppColors.background;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = highContrast ? Colors.white70 : AppColors.textSecondary;
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    
    final userName = _userData?['fullName'] ?? _userData?['name'] ?? 'Membre';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
        foregroundColor: highContrast ? primaryColor : Colors.white,
        elevation: highContrast ? 0 : 2,
        title: InkWell(
          onTap: () => _speak("Running Club Tunis. Appuyez pour écouter."),
          child: Row(
            children: [
              Image.asset(
                'assets/logo.jpg',
                width: 32 * textScale.clamp(1.0, 1.2),
                height: 32 * textScale.clamp(1.0, 1.2),
                errorBuilder: (_, __, ___) => Icon(
                  Icons.directions_run,
                  size: 28 * textScale.clamp(1.0, 1.2),
                ),
              ),
              SizedBox(width: 8 * textScale.clamp(1.0, 1.2)),
              Text(
                'Running Club Tunis',
                style: TextStyle(
                  fontSize: 18 * textScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 26 * textScale.clamp(1.0, 1.2),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                tooltip: 'Notifications',
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4 * textScale.clamp(1.0, 1.2)),
                    decoration: BoxDecoration(
                      color: highContrast ? Colors.yellow : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 18 * textScale.clamp(1.0, 1.2),
                      minHeight: 18 * textScale.clamp(1.0, 1.2),
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: TextStyle(
                        color: highContrast ? Colors.black : Colors.white,
                        fontSize: 10 * textScale,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    _buildWelcomeCard(
                      firstName: firstName,
                      groupName: _getGroupName(),
                      groupColor: _getGroupColor(),
                      memberSince: _getMemberSince(),
                      textScale: textScale,
                      highContrast: highContrast,
                      boldText: boldText,
                      primaryColor: primaryColor,
                    ),
                    
                    SizedBox(height: 24 * textScale.clamp(1.0, 1.2)),

                    StreamBuilder<QuerySnapshot>(
                      stream: _eventsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Erreur: ${snapshot.error}');
                        }
                        
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final events = snapshot.data?.docs ?? [];
                        final now = DateTime.now();
                        final todayStart = DateTime(now.year, now.month, now.day);
                        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
                        
                        // Filter Today vs Upcoming
                        final todayEvents = events.where((doc) {
                          final date = (doc['date'] as Timestamp).toDate();
                          return date.isAfter(todayStart.subtract(const Duration(seconds: 1))) && 
                                 date.isBefore(todayEnd);
                        }).toList();
                        
                        final upcomingEvents = events.where((doc) {
                          final date = (doc['date'] as Timestamp).toDate();
                          return date.isAfter(todayEnd);
                        }).take(3).toList(); // Take next 3
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Today's Run Section
                            _buildSectionHeader(
                              icon: '🏃',
                              title: "Course d'aujourd'hui",
                              textScale: textScale,
                              textColor: textColor,
                              boldText: boldText,
                            ),
                            SizedBox(height: 12 * textScale.clamp(1.0, 1.2)),
                            
                            if (todayEvents.isNotEmpty) ...todayEvents.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final date = (data['date'] as Timestamp).toDate();
                                final timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                                final participants = List<String>.from(data['participants'] ?? []);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: _buildTodayEventCard(
                                    eventId: doc.id,
                                    title: data['title'] ?? 'Entraînement',
                                    time: timeStr,
                                    location: data['location'] ?? 'Stade',
                                    distance: data['distance'] ?? 'Unknown',
                                    participants: participants,
                                    groupName: data['group'] ?? 'Tous',
                                    description: data['description'] ?? '',
                                    textScale: textScale,
                                    highContrast: highContrast,
                                    boldText: boldText,
                                    textColor: textColor,
                                    secondaryTextColor: secondaryTextColor,
                                    primaryColor: primaryColor,
                                    groupColor: _getGroupColor(), // dynamic based on user group or event group? User group for match logic? Let's use User's group logic for coloring
                                    onRegister: () => _toggleRegistration(doc.id, participants),
                                  ),
                                );
                            }).toList()
                            else
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: highContrast ? Colors.white10 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Pas d'événement prévu aujourd'hui. Repos! 😴",
                                  style: TextStyle(
                                    fontSize: 16 * textScale,
                                    color: secondaryTextColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            
                            SizedBox(height: 24 * textScale.clamp(1.0, 1.2)),

                            // Quick Actions (Keep static for now as requested or make dynamic later)
                             _buildSectionHeader(
                              icon: '⚡',
                              title: 'Actions rapides',
                              textScale: textScale,
                              textColor: textColor,
                              boldText: boldText,
                            ),
                            SizedBox(height: 12 * textScale.clamp(1.0, 1.2)),
                            _buildQuickActions(
                              textScale: textScale,
                              highContrast: highContrast,
                              boldText: boldText,
                            ),
                            
                            SizedBox(height: 24 * textScale.clamp(1.0, 1.2)),

                            // Upcoming Events
                            _buildSectionHeader(
                              icon: '📅',
                              title: 'Événements à venir',
                              textScale: textScale,
                              textColor: textColor,
                              boldText: boldText,
                            ),
                            SizedBox(height: 12 * textScale.clamp(1.0, 1.2)),
                            
                            if (upcomingEvents.isNotEmpty) ...upcomingEvents.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final date = (data['date'] as Timestamp).toDate();
                                final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                                final dayStr = "${dayNames[date.weekday - 1]} ${date.day}/${date.month}";
                                final timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildUpcomingEventCard(
                                    title: data['title'] ?? 'Entraînement',
                                    date: dayStr,
                                    time: timeStr,
                                    location: data['location'] ?? 'Stade',
                                    distance: data['distance'] ?? '',
                                    group: data['group'] ?? 'Tous',
                                    groupColor: AppColors.primary,
                                    textScale: textScale,
                                    highContrast: highContrast,
                                    boldText: boldText,
                                    textColor: textColor,
                                    secondaryTextColor: secondaryTextColor,
                                  ),
                                );
                            }).toList()
                             else
                              Text("Rien de prévu cette semaine.", style: TextStyle(color: secondaryTextColor, fontSize: 14 * textScale)),

                          ],
                        );
                      },
                    ),
                    
                    SizedBox(height: 32 * textScale.clamp(1.0, 1.2)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard({
    required String firstName,
    required String groupName,
    required Color groupColor,
    required String memberSince,
    required double textScale,
    required bool highContrast,
    required bool boldText,
    required Color primaryColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * textScale.clamp(1.0, 1.2)),
      decoration: BoxDecoration(
        gradient: highContrast 
            ? null
            : LinearGradient(
                colors: [primaryColor, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: highContrast ? AppColors.highContrastSurface : null,
        borderRadius: BorderRadius.circular(20),
        border: highContrast ? Border.all(color: primaryColor, width: 2) : null,
        boxShadow: highContrast ? null : [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _speak("Bienvenue, $firstName. Vous êtes dans le groupe $groupName. Membre depuis $memberSince."),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Internal padding was removed from Container, moved to here? 
            // Actually, Container has padding. InkWell should be OUTSIDE or INSIDE?
            // If Container has decoration, InkWell must be inside Material inside Container.
            // Let's wrap content in InkWell properly.
             Padding(
               padding: EdgeInsets.all(20 * textScale.clamp(1.0, 1.2)),
               child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50 * textScale.clamp(1.0, 1.2),
                          height: 50 * textScale.clamp(1.0, 1.2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: highContrast ? primaryColor : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: primaryColor,
                            size: 28 * textScale.clamp(1.0, 1.2),
                          ),
                        ),
                        SizedBox(width: 12 * textScale.clamp(1.0, 1.2)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenue! 👋',
                                style: TextStyle(
                                  color: highContrast ? Colors.white70 : Colors.white70,
                                  fontSize: 14 * textScale,
                                  fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text(
                                firstName,
                                style: TextStyle(
                                  color: highContrast ? primaryColor : Colors.white,
                                  fontSize: 22 * textScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16 * textScale.clamp(1.0, 1.2)),
                    Wrap(
                      spacing: 12 * textScale.clamp(1.0, 1.2),
                      runSpacing: 8 * textScale.clamp(1.0, 1.2),
                      children: [
                        // Group Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * textScale.clamp(1.0, 1.2),
                            vertical: 6 * textScale.clamp(1.0, 1.2),
                          ),
                          decoration: BoxDecoration(
                            color: highContrast 
                                ? groupColor.withOpacity(0.3) 
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: highContrast ? groupColor : Colors.white54,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8 * textScale.clamp(1.0, 1.2),
                                height: 8 * textScale.clamp(1.0, 1.2),
                                decoration: BoxDecoration(
                                  color: groupColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6 * textScale.clamp(1.0, 1.2)),
                              Text(
                                groupName,
                                style: TextStyle(
                                  color: highContrast ? Colors.white : Colors.white,
                                  fontSize: 13 * textScale,
                                  fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Member Since
                        Text(
                          'Membre depuis $memberSince',
                          style: TextStyle(
                            color: highContrast ? Colors.white70 : Colors.white70,
                            fontSize: 12 * textScale,
                            fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String icon,
    required String title,
    required double textScale,
    required Color textColor,
    required bool boldText,
  }) {
    return InkWell(
      onTap: () => _speak("$title"),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: 20 * textScale),
            ),
            SizedBox(width: 8 * textScale.clamp(1.0, 1.2)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20 * textScale,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayEventCard({
    required String eventId,
    required String title,
    required String time,
    required String location,
    required String distance,
    required String groupName,
    required String description,
    required List<String> participants,
    required double textScale,
    required bool highContrast,
    required bool boldText,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
    required Color groupColor,
    required VoidCallback onRegister,
  }) {
    final isRegistered = participants.contains(FirebaseAuth.instance.currentUser?.uid);
    final participantCount = participants.length;

    return Container(
      decoration: BoxDecoration(
        color: highContrast ? AppColors.highContrastSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: highContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: highContrast ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
             final speakText = "Course d'aujourd'hui : $title à $time. $location. $distance. $participantCount inscrits.";
             _speak(speakText);
            // TODO: Navigate to event details
          },
          child: Padding(
            padding: EdgeInsets.all(20 * textScale.clamp(1.0, 1.2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Group Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * textScale.clamp(1.0, 1.2),
                        vertical: 6 * textScale.clamp(1.0, 1.2),
                      ),
                      decoration: BoxDecoration(
                        color: groupColor.withOpacity(highContrast ? 0.3 : 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: groupColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8 * textScale.clamp(1.0, 1.2),
                            height: 8 * textScale.clamp(1.0, 1.2),
                            decoration: BoxDecoration(
                              color: groupColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6 * textScale.clamp(1.0, 1.2)),
                          Text(
                            groupName,
                            style: TextStyle(
                              color: groupColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12 * textScale,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Time Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * textScale.clamp(1.0, 1.2),
                        vertical: 6 * textScale.clamp(1.0, 1.2),
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(highContrast ? 0.3 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            size: 14 * textScale.clamp(1.0, 1.2),
                            color: primaryColor,
                          ),
                          SizedBox(width: 4 * textScale.clamp(1.0, 1.2)),
                          Text(
                            time,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13 * textScale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16 * textScale.clamp(1.0, 1.2)),
                
                // Event Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22 * textScale,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                
                SizedBox(height: 12 * textScale.clamp(1.0, 1.2)),
                
                // Details
                _buildEventDetail(
                  icon: Icons.location_on_outlined,
                  text: location,
                  textScale: textScale,
                  color: secondaryTextColor,
                ),
                SizedBox(height: 6 * textScale.clamp(1.0, 1.2)),
                _buildEventDetail(
                  icon: Icons.straighten,
                  text: '$distance  •  $description',
                  textScale: textScale,
                  color: secondaryTextColor,
                ),
                SizedBox(height: 6 * textScale.clamp(1.0, 1.2)),
                _buildEventDetail(
                  icon: Icons.people_outline,
                  text: '$participantCount inscrits',
                  textScale: textScale,
                  color: secondaryTextColor,
                ),
                
                SizedBox(height: 20 * textScale.clamp(1.0, 1.2)),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 52 * textScale.clamp(1.0, 1.2),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(isRegistered ? Icons.cancel : Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8 * textScale.clamp(1.0, 1.2)),
                              Text(
                                isRegistered ? 'Désinscription confirmée' : 'Inscription confirmée!',
                                style: TextStyle(fontSize: 14 * textScale),
                              ),
                            ],
                          ),
                          backgroundColor: isRegistered ? Colors.grey : AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      onRegister();
                    },
                    icon: Icon(
                        isRegistered ? Icons.cancel_outlined : Icons.check_circle_outline, 
                        size: 20 * textScale.clamp(1.0, 1.2)
                    ),
                    label: Text(
                      isRegistered ? "SE DÉSINSCRIRE" : "JE PARTICIPE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15 * textScale,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: highContrast ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: highContrast ? 0 : 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetail({
    required IconData icon,
    required String text,
    required double textScale,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _speak(text),
      child: Row(
        children: [
          Icon(icon, size: 18 * textScale.clamp(1.0, 1.2), color: color),
          SizedBox(width: 8 * textScale.clamp(1.0, 1.2)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14 * textScale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions({
    required double textScale,
    required bool highContrast,
    required bool boldText,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.event,
            label: 'Événements',
            color: highContrast ? AppColors.highContrastPrimary : AppColors.primary,
            textScale: textScale,
            highContrast: highContrast,
            onTap: () {},
          ),
        ),
        SizedBox(width: 12 * textScale.clamp(1.0, 1.2)),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.history,
            label: 'Historique',
            color: highContrast ? Colors.cyan : AppColors.success,
            textScale: textScale,
            highContrast: highContrast,
            onTap: () {},
          ),
        ),
        SizedBox(width: 12 * textScale.clamp(1.0, 1.2)),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.campaign,
            label: 'Annonces',
            color: highContrast ? Colors.yellow : AppColors.warning,
            textScale: textScale,
            highContrast: highContrast,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required double textScale,
    required bool highContrast,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _speak("Action rapide : $label");
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.2)),
            decoration: BoxDecoration(
              color: color.withOpacity(highContrast ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: highContrast ? Border.all(color: color, width: 2) : null,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 28 * textScale.clamp(1.0, 1.2),
                ),
                SizedBox(height: 8 * textScale.clamp(1.0, 1.2)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12 * textScale,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEventCard({
    required String title,
    required String date,
    required String time,
    required String location,
    required String distance,
    required String group,
    required Color groupColor,
    required double textScale,
    required bool highContrast,
    required bool boldText,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: highContrast ? AppColors.highContrastSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highContrast ? Border.all(color: Colors.white54, width: 1) : null,
        boxShadow: highContrast ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
             final speakText = "Événement à venir : $title le $date à $time. $location. $distance. Groupe $group.";
            _speak(speakText);
            // TODO: Navigate to event details
          },
          child: Padding(
            padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.2)),
            child: Row(
              children: [
                // Date Column
                Container(
                  padding: EdgeInsets.all(12 * textScale.clamp(1.0, 1.2)),
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(highContrast ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        date.split(' ').first,
                        style: TextStyle(
                          fontSize: 12 * textScale,
                          fontWeight: FontWeight.w600,
                          color: groupColor,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 14 * textScale,
                          fontWeight: FontWeight.bold,
                          color: groupColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16 * textScale.clamp(1.0, 1.2)),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16 * textScale,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 4 * textScale.clamp(1.0, 1.2)),
                      Text(
                        '$location • $distance',
                        style: TextStyle(
                          fontSize: 13 * textScale,
                          color: secondaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 4 * textScale.clamp(1.0, 1.2)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * textScale.clamp(1.0, 1.2),
                          vertical: 2 * textScale.clamp(1.0, 1.2),
                        ),
                        decoration: BoxDecoration(
                          color: groupColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          group,
                          style: TextStyle(
                            fontSize: 11 * textScale,
                            fontWeight: FontWeight.w500,
                            color: groupColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: secondaryTextColor,
                  size: 24 * textScale.clamp(1.0, 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Events Tab - Full events list
class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : AppColors.background;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Événements',
          style: TextStyle(fontSize: 20 * textScale),
        ),
        backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
        foregroundColor: highContrast ? primaryColor : Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64 * textScale.clamp(1.0, 1.3),
              color: primaryColor.withOpacity(0.5),
            ),
            SizedBox(height: 16 * textScale.clamp(1.0, 1.2)),
            Text(
              '📅 Liste des événements',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18 * textScale,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 8 * textScale.clamp(1.0, 1.2)),
            Text(
              'À implémenter prochainement',
              style: TextStyle(
                fontSize: 14 * textScale,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Club Tab - Club information
class _ClubTab extends StatelessWidget {
  const _ClubTab();

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : AppColors.background;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Le Club',
          style: TextStyle(fontSize: 20 * textScale),
        ),
        backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
        foregroundColor: highContrast ? primaryColor : Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups,
              size: 64 * textScale.clamp(1.0, 1.3),
              color: primaryColor.withOpacity(0.5),
            ),
            SizedBox(height: 16 * textScale.clamp(1.0, 1.2)),
            Text(
              '🏛️ Informations du club',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18 * textScale,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 8 * textScale.clamp(1.0, 1.2)),
            Text(
              'Historique • Groupes • Valeurs',
              style: TextStyle(
                fontSize: 14 * textScale,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile Tab - User profile and settings
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : AppColors.background;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Profil',
          style: TextStyle(fontSize: 20 * textScale),
        ),
        backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
        foregroundColor: highContrast ? primaryColor : Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24 * textScale.clamp(1.0, 1.2)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 64 * textScale.clamp(1.0, 1.3),
                color: primaryColor.withOpacity(0.5),
              ),
              SizedBox(height: 16 * textScale.clamp(1.0, 1.2)),
              Text(
                '👤 Profil utilisateur',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18 * textScale,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 8 * textScale.clamp(1.0, 1.2)),
              Text(
                'Statistiques • Paramètres • Accessibilité',
                style: TextStyle(
                  fontSize: 14 * textScale,
                  color: textColor.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48 * textScale.clamp(1.0, 1.2)),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56 * textScale.clamp(1.0, 1.2),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    
                    // Reset profile to local/wizard (Device Owner) settings
                    if (context.mounted) {
                      await Provider.of<AccessibilityProvider>(context, listen: false).logoutAndRestoreLocalProfile();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    }
                  },
                  icon: Icon(Icons.logout, size: 20 * textScale.clamp(1.0, 1.2)),
                  label: Text(
                    'Déconnexion',
                    style: TextStyle(
                      fontSize: 16 * textScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
}
