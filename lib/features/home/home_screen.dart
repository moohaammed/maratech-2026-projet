import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../accessibility/providers/accessibility_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/ai_coach_widget.dart';

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
    // Unrestricted speech for manual interactions
    await _tts.setVolume(1.0);
    await _tts.stop();
    await _tts.speak(text);
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
    
    // Navbar styling variables
    final navBarColor = highContrast ? AppColors.highContrastSurface : Colors.white;
    final indicatorColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary.withOpacity(0.15);
    final selectedIconColor = highContrast ? Colors.black : AppColors.primary;
    final unselectedIconColor = highContrast ? Colors.white : AppColors.textSecondary;
    final labelStyle = TextStyle(
      fontSize: 12 * textScale, 
      fontWeight: FontWeight.w600,
      color: highContrast ? Colors.white : AppColors.textPrimary
    );

    return Scaffold(

      // extendBody: false, // Standard layout, navbar pushes content up
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _HomeTab(),
          const _EventsTab(),
          _ClubTab(onSpeak: _speak),
          const _ProfileTab(),
        ],
      ),
      floatingActionButton: const AICoachButton(),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: (80 * textScale).clamp(80.0, 120.0),
          backgroundColor: navBarColor,
          indicatorColor: indicatorColor,
          labelTextStyle: WidgetStateProperty.all(labelStyle),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(
                size: 26 * textScale.clamp(1.0, 1.3),
                color: selectedIconColor,
              );
            }
            return IconThemeData(
              size: 24 * textScale.clamp(1.0, 1.3),
              color: unselectedIconColor,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            final labels = ['Accueil', 'Événements', 'Le Club', 'Profil'];
            _speak("Onglet ${labels[index]} sélectionné");
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: highContrast ? 0 : 3,
          shadowColor: Colors.black26, 
          // SurfaceTintColor applied by theme usually, helpful to ensure explicit color
          surfaceTintColor: navBarColor, 
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
              tooltip: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today_rounded),
              label: 'Événements',
              tooltip: 'Événements',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Le Club',
              tooltip: 'Le Club',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
              tooltip: 'Profil',
            ),
          ],
        ),
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
    // Unrestricted speech for user interactions
    await _tts.setVolume(1.0);
    await _tts.stop();
    await _tts.speak(text);
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
          onTap: () => _speak("RCT. Appuyez pour écouter."),
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
                'RCT',
                style: TextStyle(
                  fontSize: 18 * textScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('date', isGreaterThanOrEqualTo: Timestamp.now())
                .orderBy('date')
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              int count = 0;
              if (snapshot.hasData) {
                final now = DateTime.now();
                // Count future events
                count = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  return date.isAfter(now);
                }).length;
              }

              return Stack(
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
                  if (count > 0)
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
                          count > 9 ? '9+' : '$count',
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
              );
            }
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
    return Semantics(
      label: "Carte de bienvenue. Bienvenue $firstName. Groupe $groupName. Membre depuis $memberSince.",
      container: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: highContrast 
              ? Border.all(color: primaryColor, width: 2) 
              : Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: highContrast ? null : [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          image: highContrast ? null : const DecorationImage(
            image: AssetImage('assets/image1.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          color: highContrast ? AppColors.highContrastSurface : primaryColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Gradient Overlay for readability
              if (!highContrast)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryColor.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.9],
                      ),
                    ),
                  ),
                ),
                
              Padding(
                padding: EdgeInsets.all(24 * textScale.clamp(1.0, 1.2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 8)
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 28 * textScale.clamp(1.0, 1.2),
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: const AssetImage('assets/logo.jpg'), // Use logo or user image
                            onBackgroundImageError: (_, __) {},
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                        SizedBox(width: 16 * textScale.clamp(1.0, 1.2)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bonjour,',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16 * textScale,
                                  fontWeight: FontWeight.w500,
                                  shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                                ),
                              ),
                              Text(
                                firstName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28 * textScale,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24 * textScale.clamp(1.0, 1.2)),
                    
                    // Stats / Info Row
                    Wrap(
                      spacing: 12 * textScale.clamp(1.0, 1.2),
                      runSpacing: 8 * textScale.clamp(1.0, 1.2),
                      children: [
                        _buildGlassBadge(
                          icon: Icons.groups, 
                          text: groupName, 
                          color: highContrast ? groupColor : Colors.white,
                          bgColor: highContrast ? groupColor.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                          textScale: textScale,
                          borderColor: highContrast ? groupColor : Colors.white30,
                        ),
                        _buildGlassBadge(
                          icon: Icons.calendar_month, 
                          text: memberSince.split(' ').last, // Just Year
                          color: Colors.white,
                          bgColor: Colors.white.withOpacity(0.1),
                          textScale: textScale,
                          borderColor: Colors.white12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Decorative Shine
              if (!highContrast)
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 50, spreadRadius: 10)
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBadge({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
    required double textScale,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * textScale, vertical: 8 * textScale),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           Icon(icon, size: 16 * textScale, color: color),
           SizedBox(width: 6 * textScale),
           Flexible(
             child: Text(
               text,
               style: TextStyle(
                 color: color,
                 fontWeight: FontWeight.w600,
                 fontSize: 13 * textScale,
               ),
               overflow: TextOverflow.ellipsis,
             ),
           )
        ],
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
                    Flexible(
                      child: Container(
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
                            Flexible(
                              child: Text(
                                groupName,
                                style: TextStyle(
                                  color: groupColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12 * textScale,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8), 
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
class _EventsTab extends StatefulWidget {
  const _EventsTab();

  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('languageCode');
    
    String ttsCode = 'fr-FR';
    if (langCode == 'ar') ttsCode = 'ar-SA';
    if (langCode == 'en') ttsCode = 'en-US';
    
    await _tts.setLanguage(ttsCode);
  }

  Future<void> _speak(String text) async {
    // Unrestricted speech
    await _tts.setVolume(1.0);
    await _tts.stop();
    await _tts.speak(text);
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRegistered ? 'Désinscription confirmée' : 'Inscription confirmée!'),
            backgroundColor: isRegistered ? Colors.grey : AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      if (!isRegistered) _speak("Vous êtes inscrit.");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
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
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : AppColors.background;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Tous les événements',
          style: TextStyle(fontSize: 20 * textScale, fontWeight: FontWeight.bold),
        ),
        backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
        foregroundColor: highContrast ? primaryColor : Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('date', isGreaterThanOrEqualTo: Timestamp.now())
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}', style: TextStyle(color: textColor)));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          
          final events = snapshot.data?.docs ?? [];
          
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64 * textScale, color: Colors.grey),
                  SizedBox(height: 16 * textScale),
                  Text(
                    'Aucun événement à venir',
                    style: TextStyle(
                      fontSize: 18 * textScale,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.2)),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final doc = events[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              final participants = List<String>.from(data['participants'] ?? []);
              final String eventId = doc.id;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildEventCard(
                  eventId: eventId,
                  data: data,
                  date: date,
                  participants: participants,
                  textScale: textScale,
                  highContrast: highContrast,
                  primaryColor: primaryColor,
                  textColor: textColor,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventCard({
    required String eventId,
    required Map<String, dynamic> data,
    required DateTime date,
    required List<String> participants,
    required double textScale,
    required bool highContrast,
    required Color primaryColor,
    required Color textColor,
  }) {
    final title = data['title'] ?? 'Événement';
    final location = data['location'] ?? 'Lieu inconnu';
    final timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    final dayNames = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final dateStr = "${dayNames[date.weekday - 1]} ${date.day}/${date.month}";
    
    final isRegistered = participants.contains(FirebaseAuth.instance.currentUser?.uid);
    final secondaryTextColor = highContrast ? Colors.white70 : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: highContrast ? AppColors.highContrastSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highContrast ? Border.all(color: Colors.white, width: 1) : null,
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
             Navigator.pushNamed(
               context, 
               '/event-details',
               arguments: eventId,
             );
          },
          child: Padding(
            padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Box
                    Container(
                      padding: EdgeInsets.all(12 * textScale.clamp(1.0, 1.2)),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "${date.day}",
                            style: TextStyle(
                              fontSize: 20 * textScale,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            _getMonthName(date.month),
                            style: TextStyle(
                              fontSize: 12 * textScale,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16 * textScale.clamp(1.0, 1.2)),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18 * textScale,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 4 * textScale.clamp(1.0, 1.2)),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14 * textScale, color: secondaryTextColor),
                              SizedBox(width: 4 * textScale.clamp(1.0, 1.2)),
                              Text(timeStr, style: TextStyle(color: secondaryTextColor, fontSize: 13 * textScale)),
                              SizedBox(width: 12 * textScale.clamp(1.0, 1.2)),
                              Icon(Icons.location_on_outlined, size: 14 * textScale, color: secondaryTextColor),
                              SizedBox(width: 4 * textScale.clamp(1.0, 1.2)),
                              Expanded(
                                child: Text(location, 
                                  style: TextStyle(color: secondaryTextColor, fontSize: 13 * textScale),
                                  overflow: TextOverflow.ellipsis
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16 * textScale.clamp(1.0, 1.2)),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _toggleRegistration(eventId, participants),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRegistered ? Colors.grey.shade300 : primaryColor,
                      foregroundColor: isRegistered ? Colors.black87 : (highContrast ? Colors.black : Colors.white),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isRegistered ? "Inscrit (Appuyez pour annuler)" : "S'inscrire",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14 * textScale
                      ),
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

  String _getMonthName(int month) {
    const months = ['JAN', 'FEV', 'MAR', 'AVR', 'MAI', 'JUIN', 'JUIL', 'AOUT', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}

/// Club Tab - Club information
class _ClubTab extends StatelessWidget {
  final Future<void> Function(String)? onSpeak;
  const _ClubTab({this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : AppColors.background;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = highContrast ? Colors.white70 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Le Club',
          style: TextStyle(fontSize: 20 * textScale, fontWeight: FontWeight.bold),
        ),
        backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
        foregroundColor: highContrast ? primaryColor : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Club Info Header
            Center(
              child: Column(
                children: [
                   InkWell(
                    onTap: () => onSpeak?.call("Running Club Tunis. Depuis 2015."),
                    child: Container(
                      width: 100 * textScale.clamp(1.0, 1.3),
                      height: 100 * textScale.clamp(1.0, 1.3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                        image: const DecorationImage(
                          image: AssetImage('assets/logo.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * textScale.clamp(1.0, 1.2)),
                  InkWell(
                    onTap: () => onSpeak?.call("Running Club Tunis"),
                    child: Text(
                      "Running Club Tunis",
                      style: TextStyle(
                        fontSize: 24 * textScale,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8 * textScale.clamp(1.0, 1.2)),
                  InkWell(
                    onTap: () => onSpeak?.call("Depuis 2015"),
                    child: Text(
                      "Depuis 2015",
                      style: TextStyle(
                        fontSize: 16 * textScale,
                        color: secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32 * textScale.clamp(1.0, 1.2)),

            // History Section
            _buildSectionHeader(
              icon: Icons.history_edu,
              title: "Notre Histoire",
              textScale: textScale,
              textColor: primaryColor,
            ),
            SizedBox(height: 12 * textScale.clamp(1.0, 1.2)),
            InkWell(
              onTap: () => onSpeak?.call("Fondé en 2015 par un groupe de passionnés de course à pied, le Running Club Tunis a commencé avec seulement 10 membres. Aujourd'hui, nous sommes fiers de compter plus de 500 coureurs actifs de tous niveaux. Notre mission est de promouvoir la santé, le bien-être et l'esprit de communauté à travers la course à pied."),
              child: Text(
                "Fondé en 2015 par un groupe de passionnés de course à pied, le Running Club Tunis a commencé avec seulement 10 membres. Aujourd'hui, nous sommes fiers de compter plus de 500 coureurs actifs de tous niveaux.\n\n"
                "Notre mission est de promouvoir la santé, le bien-être et l'esprit de communauté à travers la course à pied. Nous organisons des sorties hebdomadaires, des participations aux marathons internationaux et des événements caritatifs.",
                style: TextStyle(
                  fontSize: 14 * textScale,
                  height: 1.5,
                  color: textColor,
                ),
              ),
            ),

            SizedBox(height: 24 * textScale.clamp(1.0, 1.2)),

            // Values Section
            _buildSectionHeader(
              icon: Icons.star_rate_rounded,
              title: "Nos Valeurs",
              textScale: textScale,
              textColor: primaryColor,
            ),
            SizedBox(height: 12 * textScale.clamp(1.0, 1.2)),
            _buildValueItem("Inclusion", "Ouvert à tous, quel que soit le niveau ou l'âge.", Icons.diversity_3, textScale, textColor, primaryColor),
            _buildValueItem("Dépassement", "Nous encourageons chacun à atteindre ses objectifs personnels.", Icons.trending_up, textScale, textColor, primaryColor),
            _buildValueItem("Solidarité", "On ne laisse personne derrière. On court ensemble.", Icons.volunteer_activism, textScale, textColor, primaryColor),

            SizedBox(height: 24 * textScale.clamp(1.0, 1.2)),

            // Contact Section
            _buildSectionHeader(
              icon: Icons.contact_support,
              title: "Contactez-nous",
              textScale: textScale,
              textColor: primaryColor,
            ),
            SizedBox(height: 12 * textScale.clamp(1.0, 1.2)),
            _buildContactRow(Icons.email, "contact@runningclubtunis.com", textScale, textColor),
            _buildContactRow(Icons.phone, "+216 71 123 456", textScale, textColor),
            _buildContactRow(Icons.location_on, "Parc du Belvédère, Tunis", textScale, textColor),
            
            SizedBox(height: 32 * textScale.clamp(1.0, 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required double textScale,
    required Color textColor,
  }) {
    return InkWell(
      onTap: () => onSpeak?.call(title),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Icon(icon, size: 24 * textScale, color: textColor),
            SizedBox(width: 8 * textScale.clamp(1.0, 1.2)),
            Text(
              title,
              style: TextStyle(
                fontSize: 20 * textScale,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueItem(String title, String description, IconData icon, double textScale, Color textColor, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => onSpeak?.call("$title. $description"),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20 * textScale, color: iconColor),
            SizedBox(width: 12 * textScale),
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
                  SizedBox(height: 4 * textScale),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14 * textScale,
                      color: textColor.withOpacity(0.8),
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

  Widget _buildContactRow(IconData icon, String text, double textScale, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => onSpeak?.call(text),
        child: Row(
          children: [
            Icon(icon, size: 20 * textScale, color: textColor.withOpacity(0.7)),
            SizedBox(width: 12 * textScale),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14 * textScale,
                  color: textColor,
                ),
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
          'Profil & Paramètres',
          style: TextStyle(fontSize: 20 * textScale, fontWeight: FontWeight.bold),
        ),
        backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
        foregroundColor: highContrast ? primaryColor : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.2)),
        children: [
          // User Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40 * textScale.clamp(1.0, 1.3),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, size: 48 * textScale.clamp(1.0, 1.3), color: primaryColor),
                ),
                SizedBox(height: 16 * textScale.clamp(1.0, 1.2)),
                Text(
                  'Membre du Club',
                  style: TextStyle(
                    fontSize: 20 * textScale,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: profile.dyslexicMode ? 'Verdana' : null,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 32 * textScale.clamp(1.0, 1.2)),
          
          // Accessibility Settings
          _buildSectionHeader("Accessibilité Visuelle", textScale, textColor),
          _buildSwitchTile(
            context,
            title: "Mode Dyslexie",
            subtitle: "Police et espacements adaptés",
            value: profile.dyslexicMode,
            onChanged: (val) => accessibility.updateProfile(profile.copyWith(dyslexicMode: val)),
            textScale: textScale,
            textColor: textColor,
            activeColor: primaryColor,
          ),
          _buildSwitchTile(
            context,
            title: "Contraste Élevé",
            subtitle: "Couleurs distinctes (Noir/Blanc/Jaune)",
            value: profile.highContrast,
            onChanged: (val) => accessibility.updateProfile(profile.copyWith(highContrast: val)),
            textScale: textScale,
            textColor: textColor,
            activeColor: primaryColor,
          ),
          
          SizedBox(height: 16 * textScale.clamp(1.0, 1.2)),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Taille du texte: ${(profile.textSize * 100).toInt()}%",
                  style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.w600, color: textColor),
                ),
                Slider(
                  value: profile.textSize,
                  min: 1.0,
                  max: 2.0,
                  divisions: 5,
                  label: "${(profile.textSize * 100).toInt()}%",
                  activeColor: primaryColor,
                  onChanged: (val) => accessibility.updateProfile(profile.copyWith(textSize: val)),
                ),
              ],
            ),
          ),

          SizedBox(height: 24 * textScale.clamp(1.0, 1.2)),
          
          _buildSectionHeader("Audio & Assistance", textScale, textColor),
          _buildSwitchTile(
             context,
             title: "Vibrations",
             subtitle: "Retour haptique au toucher",
             value: profile.vibrationEnabled,
             onChanged: (val) => accessibility.updateProfile(profile.copyWith(vibrationEnabled: val)),
             textScale: textScale,
             textColor: textColor,
             activeColor: primaryColor,
          ),

           SizedBox(height: 32 * textScale.clamp(1.0, 1.2)),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 56 * textScale.clamp(1.0, 1.2),
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
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
          SizedBox(height: 32 * textScale),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, double textScale, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18 * textScale,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required double textScale,
    required Color textColor,
    required Color activeColor,
  }) {
    return Card(
      elevation: 0,
       color: textColor == Colors.white ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(
          title, 
          style: TextStyle(
            fontSize: 16 * textScale, 
            fontWeight: FontWeight.w600,
            color: textColor
          )
        ),
        subtitle: Text(
          subtitle, 
          style: TextStyle(
            fontSize: 13 * textScale, 
            color: textColor.withOpacity(0.7)
          )
        ),
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
