import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_colors.dart';
import '../../coach/screens/events/event_list_screen.dart';
import '../../accessibility/providers/accessibility_provider.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    // Voice welcome for blind users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
      _setupLanguage(accessibility.profile.languageCode);
      if (accessibility.profile.visualNeeds == 'blind') {
        _speakWelcome();
      }
    });
  }

  Future<void> _setupLanguage(String langCode) async {
    String ttsCode = 'fr-FR';
    if (langCode == 'ar') ttsCode = 'ar-SA';
    if (langCode == 'en') ttsCode = 'en-US';
    await _tts.setLanguage(ttsCode);
  }

  int _lastIndex = 0;
  void _onTabChanged() {
    if (_tabController.index != _lastIndex) {
      _lastIndex = _tabController.index;
      final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
      if (accessibility.profile.visualNeeds == 'blind') {
        _readCurrentTab();
      }
    }
  }

  void _readCurrentTab() async {
    await _tts.stop();
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    final lang = accessibility.profile.languageCode;
    
    switch (_tabController.index) {
      case 0:
        if (lang == 'ar') {
          await _tts.speak("علامة تبويب النادي. تاريخنا: ولد نادي الجري بتونس من شغف مشترك بالجري. مساراتنا: من التدريبات اليومية إلى سباقات الماراثون الدولية.");
        } else if (lang == 'en') {
          await _tts.speak("Club tab. Our history: The Running Club Tunis was born from a common passion for running. Our routes: From daily training to international marathons.");
        } else {
          await _tts.speak("Onglet Club. Notre histoire : Le Running Club Tunis est né d'une passion commune pour la course à pied. Parcours : Des entraînements quotidiens aux marathons internationaux.");
        }
        break;
      case 1:
        if (lang == 'ar') {
          await _tts.speak("علامة تبويب القيم. قيمنا: الشمولية، التميز، التضامن. ميثاق النادي: الاحترام، الانضباط، التعاون.");
        } else if (lang == 'en') {
          await _tts.speak("Values tab. Our values: Inclusivity, Excellence, Solidarity. Club charter: Respect, Punctuality, Mutual aid.");
        } else {
          await _tts.speak("Onglet Valeurs. Nos valeurs : Inclusivité, Dépassement, Solidarité. Charte du club : Respect, Ponctualité, Entraide.");
        }
        break;
      case 2:
        if (lang == 'ar') {
          await _tts.speak("علامة تبويب الفعاليات. إليكم قائمة الفعاليات القادمة.");
        } else if (lang == 'en') {
          await _tts.speak("Events tab. Here is the list of upcoming events.");
        } else {
          await _tts.speak("Onglet Événements. Voici la liste des événements à venir.");
        }
        break;
    }
  }

  Future<void> _speakWelcome() async {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    final lang = accessibility.profile.languageCode;
    
    String welcome = "Bienvenue dans le mode invité. Vous êtes sur l'onglet Club. Voici notre histoire.";
    if (lang == 'ar') welcome = "مرحبًا بكم في وضع الضيف. أنتم الآن في علامة تبويب النادي. إليكم تاريخنا.";
    if (lang == 'en') welcome = "Welcome to guest mode. You are on the Club tab. Here is our history.";
    
    await _tts.speak(welcome);
    await Future.delayed(const Duration(milliseconds: 1500));
    _readCurrentTab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tts.stop();
    super.dispose();
  }

  String _T(String fr, String en, String ar) {
    final lang = Provider.of<AccessibilityProvider>(context, listen: false).languageCode;
    switch (lang) {
      case 'ar': return ar;
      case 'en': return en;
      default: return fr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_T('RCT - Invité', 'RCT - Guest', 'نادي RCT - ضيف'), 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Semantics(
                label: _T('Onglet Histoire du Club', 'Club History Tab', 'علامة تبويب تاريخ النادي'),
                child: Text(_T('Club', 'Club', 'النادي')),
              ),
              icon: const Icon(Icons.history),
            ),
            Tab(
              child: Semantics(
                label: _T('Onglet Valeurs et Charte', 'Values and Charter Tab', 'علامة تبويب القيم والميثاق'),
                child: Text(_T('Valeurs', 'Values', 'القيم')),
              ),
              icon: const Icon(Icons.info_outline),
            ),
            Tab(
              child: Semantics(
                label: _T('Onglet Liste des Événements', 'Events List Tab', 'علامة تبويب قائمة الفعاليات'),
                child: Text(_T('Événements', 'Events', 'الفعاليات')),
              ),
              icon: const Icon(Icons.event),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            tooltip: _T('Se connecter', 'Login', 'تسجيل الدخول'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildValuesTab(),
          _buildEventsTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(_T('Notre Histoire', 'Our History', 'تاريخنا')),
          const SizedBox(height: 16),
          _buildTextCard(
            _T(
              'Le Running Club Tunis est né d\'une passion commune pour la course à pied et le dépassement de soi. Depuis sa création, le club a rassemblé des centaines de coureurs de tous niveaux, créant une communauté soudée et dynamique dans la capitale.',
              'The Running Club Tunis was born from a common passion for running and self-improvement. Since its creation, the club has gathered hundreds of runners of all levels, creating a tight-knit and dynamic community in the capital.',
              'ولد نادي الجري بتونس من شغف مشترك بالجري وتجاوز الذات. منذ تأسيسه، جمع النادي مئات العدائين من جميع المستويات، مما خلق مجتمعًا متماسكًا وحيويًا في العاصمة.'
            ),
            Icons.history_edu,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(_T('Parcours', 'Routes', 'المسارات')),
          const SizedBox(height: 16),
          _buildTextCard(
            _T(
              'Des entraînements quotidiens aux marathons internationaux, nos membres portent fièrement les couleurs du club. Nous organisons régulièrement des sorties collectives vers Carthage, Sidi Bou Saïd et le centre-ville.',
              'From daily training to international marathons, our members proudly wear the club colors. We regularly organize collective runs to Carthage, Sidi Bou Saïd, and the city center.',
              'من التدريبات اليومية إلى الماراثونات الدولية، يرتدي أعضاؤنا ألوان النادي بكل فخر. ننظم بانتظام خرجات جماعية إلى قرطاج وسيدي بوسعيد ووسط المدينة.'
            ),
            Icons.map,
          ),
        ],
      ),
    );
  }

  Widget _buildValuesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(_T('Valeurs et Objectifs', 'Values and Goals', 'القيم والأهداف')),
          const SizedBox(height: 16),
          _buildValueItem(
            _T('Inclusivité', 'Inclusivity', 'الشمولية'),
            _T('Accueillir tous les coureurs, du débutant à l\'athlète confirmé.', 'Welcome all runners, from beginners to experienced athletes.', 'الترحيب بجميع العدائين، من المبتدئين إلى الرياضيين المتمرسين.'),
            Icons.people
          ),
          _buildValueItem(
            _T('Dépassement', 'Excellence', 'التميز'),
            _T('Encourager chacun à atteindre ses objectifs personnels.', 'Encourage everyone to reach their personal goals.', 'تشجيع الجميع على تحقيق أهدافهم الشخصية.'),
            Icons.trending_up
          ),
          _buildValueItem(
            _T('Solidarité', 'Solidarity', 'التضامن'),
            _T('Courir ensemble, s\'entraider et ne laisser personne derrière.', 'Running together, helping each other and leaving no one behind.', 'الجري معًا، ومساعدة بعضنا البعض وعدم ترك أي شخص خلفنا.'),
            Icons.favorite
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(_T('Charte du Club', 'Club Charter', 'ميثاق النادي')),
          const SizedBox(height: 16),
          _buildTextCard(
            _T(
              '1. Respect des autres coureurs et des piétons.\n'
              '2. Ponctualité aux entraînements collectifs.\n'
              '3. Port des couleurs du club lors des compétitions officielles.\n'
              '4. Entraide technique et morale entre les membres.',
              '1. Respect for other runners and pedestrians.\n'
              '2. Punctuality at collective training sessions.\n'
              '3. Wearing club colors during official competitions.\n'
              '4. Technical and moral mutual aid between members.',
              '1. احترام العدائين الآخرين والمشاة.\n'
              '2. الانضباط في المواعيد في التدريبات الجماعية.\n'
              '3. ارتداء ألوان النادي خلال المسابقات الرسمية.\n'
              '4. التعاون التقني والمعنوي بين الأعضاء.'
            ),
            Icons.verified_user,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(_T('Organisation des Groupes', 'Group Organization', 'تنظيم المجموعات')),
          const SizedBox(height: 16),
          _buildTextCard(
            _T(
              'L\'organisation s\'appuie sur des responsables de groupe (Group Admins) qui encadrent les séances selon les niveaux :\n\n'
              '• Groupe 1-2 : Débutants et reprise progressive\n'
              '• Groupe 3 : Intermédiaire (Endurance fondamentale)\n'
              '• Groupe 4-5 : Avancé (Performance et fractionné)',
              'The organization relies on group managers (Group Admins) who supervise sessions according to levels:\n\n'
              '• Group 1-2: Beginners and progressive recovery\n'
              '• Group 3: Intermediate (Fundamental endurance)\n'
              '• Group 4-5: Advanced (Performance and interval training)',
              'يعتمد التنظيم على مسؤولي المجموعات (Group Admins) الذين يشرفون على الحصص حسب المستويات:\n\n'
              '• المجموعة 2-1: المبتدئون والاستئناف التدريجي\n'
              '• المجموعة 3: المتوسط (التحمل الأساسي)\n'
              '• المجموعة 4-5: المتقدم (الأداء والتدريب المتقطع)'
            ),
            Icons.format_list_bulleted,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return const EventListScreen(canCreate: false, hideAppBar: true);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextCard(String text, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueItem(String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(desc, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
