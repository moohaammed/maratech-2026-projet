import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// TODO: replace with your generated firebase options if using flutterfire configure
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
      );
  runApp(const RctApp());
}

class RctApp extends StatelessWidget {
  const RctApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RCT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;

        // Not logged in => VISITOR UI
        if (user == null) return const VisitorShell();

        // Logged in => fetch role from Firestore users/{uid}
        return RoleGate(uid: user.uid);
      },
    );
  }
}

class RoleGate extends StatelessWidget {
  final String uid;
  const RoleGate({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snap.data!.data();

        if (data == null) {
          // user exists in Auth but no Firestore profile
          return const MissingProfileScreen();
        }

        final role = (data['role'] ?? 'MEMBER') as String;
        final isActive = (data['isActive'] ?? true) as bool;

        if (!isActive) {
          return const DisabledAccountScreen();
        }

        switch (role) {
          case 'ADMIN_MAIN':
          case 'ADMIN_COACH':
          case 'ADMIN_GROUP':
            return AdminShell(role: role);
          case 'MEMBER':
          default:
            return const MemberShell();
        }
      },
    );
  }
}

class MissingProfileScreen extends StatelessWidget {
  const MissingProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil manquant')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Ton compte existe dans Authentication mais il manque le document Firestore users/{uid}.\n"
          "Crée-le dans Firestore avec role/isActive/groupIds.",
        ),
      ),
    );
  }
}

class DisabledAccountScreen extends StatelessWidget {
  const DisabledAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compte désactivé')),
      body: const Center(child: Text("Ton compte est désactivé. Contacte l'admin.")),
    );
  }
}

/* ===========================
   VISITOR UI
=========================== */

class VisitorShell extends StatefulWidget {
  const VisitorShell({super.key});

  @override
  State<VisitorShell> createState() => _VisitorShellState();
}

class _VisitorShellState extends State<VisitorShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const VisitorHomeScreen(),
      const PublicPostsScreen(),
      const LoginScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Running Club Tunis')),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.article), label: 'News'),
          NavigationDestination(icon: Icon(Icons.login), label: 'Login'),
        ],
      ),
    );
  }
}

class VisitorHomeScreen extends StatelessWidget {
  const VisitorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bienvenue 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Accède aux news & à l’historique du club. Connecte-toi pour voir les événements de ton groupe.'),
          SizedBox(height: 16),
          Text('À faire plus tard:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('• Page historique RCT\n• Valeurs / charte\n• Présentation groupes'),
        ],
      ),
    );
  }
}

/* ===========================
   MEMBER UI
=========================== */

class MemberShell extends StatefulWidget {
  const MemberShell({super.key});

  @override
  State<MemberShell> createState() => _MemberShellState();
}

class _MemberShellState extends State<MemberShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MemberEventsScreen(),
      const MemberProgramsScreen(),
      const MemberProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('RCT - Adhérent'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event), label: 'Événements'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Programme'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class MemberEventsScreen extends StatelessWidget {
  const MemberEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Load my groupIds from users/{uid}, then query events for those groups
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
        final u = userSnap.data!.data() ?? {};
        final List<dynamic> groupIdsDyn = (u['groupIds'] ?? []) as List<dynamic>;
        final groupIds = groupIdsDyn.map((e) => e.toString()).toList();

        if (groupIds.isEmpty) {
          return const Center(child: Text("Aucun groupe assigné. Contacte l’admin."));
        }

        final query = FirebaseFirestore.instance
            .collection('events')
            .where('groupId', whereIn: groupIds)
            .orderBy('dateTimeStart', descending: false)
            .limit(30);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("Aucun événement pour le moment."));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data();
                final title = (data['title'] ?? 'Event') as String;
                final type = (data['type'] ?? 'DAILY') as String;
                final groupId = (data['groupId'] ?? '-') as String;

                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text('$type • Groupe: $groupId'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: d.id)),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('events').doc(eventId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snap.data!.data();
        if (data == null) return const Scaffold(body: Center(child: Text("Event introuvable")));

        final title = (data['title'] ?? '') as String;
        final desc = (data['description'] ?? '') as String;
        final type = (data['type'] ?? '') as String;
        final groupId = (data['groupId'] ?? '-') as String;
        final loc = (data['location'] ?? {}) as Map<String, dynamic>;
        final locName = (loc['name'] ?? '-') as String;

        return Scaffold(
          appBar: AppBar(title: const Text('Détails')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('$type • Groupe: $groupId'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(locName)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(desc),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MemberProgramsScreen extends StatelessWidget {
  const MemberProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
        final u = userSnap.data!.data() ?? {};
        final List<dynamic> groupIdsDyn = (u['groupIds'] ?? []) as List<dynamic>;
        final groupIds = groupIdsDyn.map((e) => e.toString()).toList();

        if (groupIds.isEmpty) return const Center(child: Text("Aucun groupe assigné."));

        // Simple: fetch latest program for first group
        final q = FirebaseFirestore.instance
            .collection('programs')
            .where('groupId', isEqualTo: groupIds.first)
            .orderBy('weekStart', descending: true)
            .limit(5);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: q.snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Center(child: Text("Aucun programme publié."));

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final data = docs[i].data();
                final weekStart = (data['weekStart'] ?? '-') as String;
                final content = (data['content'] ?? {}) as Map<String, dynamic>;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Semaine: $weekStart',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        for (final entry in content.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text('• ${entry.key}: ${entry.value}'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final data = snap.data!.data() ?? {};
        final fullName = (data['fullName'] ?? '-') as String;
        final role = (data['role'] ?? '-') as String;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: ListTile(
              title: Text(fullName),
              subtitle: Text('Role: $role\nUID: $uid'),
            ),
          ),
        );
      },
    );
  }
}

/* ===========================
   ADMIN UI (MAIN/COACH/GROUP)
=========================== */

class AdminShell extends StatefulWidget {
  final String role; // ADMIN_MAIN / ADMIN_COACH / ADMIN_GROUP
  const AdminShell({super.key, required this.role});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const AdminEventsScreen(),
      const AdminProgramsScreen(),
      if (widget.role == 'ADMIN_MAIN') const AdminUsersScreen(),
      const MemberProfileScreen(), // reuse profile view
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
      const NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Programs'),
      if (widget.role == 'ADMIN_MAIN') const NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
      const NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('RCT - Admin (${widget.role})'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: pages[index],
      floatingActionButton: (index == 0)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Créer event'),
            )
          : (index == 1)
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateProgramScreen()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer programme'),
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: destinations,
      ),
    );
  }
}

class AdminEventsScreen extends StatelessWidget {
  const AdminEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('events')
        .orderBy('dateTimeStart', descending: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return Card(
              child: ListTile(
                title: Text((d['title'] ?? 'Event') as String),
                subtitle: Text('type: ${d['type']} • groupId: ${d['groupId']}'),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminProgramsScreen extends StatelessWidget {
  const AdminProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('programs')
        .orderBy('weekStart', descending: true)
        .limit(30);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return Card(
              child: ListTile(
                title: Text('Week: ${d['weekStart']}'),
                subtitle: Text('groupId: ${d['groupId']} • status: ${d['status']}'),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection('users').limit(50);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final u = docs[i].data();
            return Card(
              child: ListTile(
                title: Text((u['fullName'] ?? '-') as String),
                subtitle: Text('role: ${u['role']} • active: ${u['isActive']}'),
              ),
            );
          },
        );
      },
    );
  }
}

/* ===========================
   CREATE FORMS (Admin)
=========================== */

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final groupCtrl = TextEditingController(text: 'g1');
  String type = 'DAILY';
  DateTime selected = DateTime.now().add(const Duration(hours: 2));

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    groupCtrl.dispose();
    super.dispose();
  }

  Future<void> create() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('events').add({
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'type': type,
      'groupId': groupCtrl.text.trim(),
      'dateTimeStart': Timestamp.fromDate(selected),
      'location': {'name': 'À définir', 'lat': 0, 'lng': 0},
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isPublic': false,
      'status': 'PUBLISHED',
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un événement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: type,
            items: const [
              DropdownMenuItem(value: 'DAILY', child: Text('DAILY')),
              DropdownMenuItem(value: 'WEEKLY', child: Text('WEEKLY')),
              DropdownMenuItem(value: 'SPECIAL', child: Text('SPECIAL')),
            ],
            onChanged: (v) => setState(() => type = v ?? 'DAILY'),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 12),
          TextField(controller: groupCtrl, decoration: const InputDecoration(labelText: 'groupId (ex: g1)')),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text('Date/Heure: ${selected.toString()}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: selected,
              );
              if (date == null) return;

              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(selected),
              );
              if (time == null) return;

              setState(() => selected = DateTime(date.year, date.month, date.day, time.hour, time.minute));
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: create,
            child: const Text('Créer'),
          )
        ],
      ),
    );
  }
}

class CreateProgramScreen extends StatefulWidget {
  const CreateProgramScreen({super.key});

  @override
  State<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  final groupCtrl = TextEditingController(text: 'g1');
  final weekCtrl = TextEditingController(text: '2026-02-03');

  final mondayCtrl = TextEditingController(text: '6km easy + éducatifs');
  final wedCtrl = TextEditingController(text: '8x400m fractionné');
  final friCtrl = TextEditingController(text: '10km progressif');
  final sunCtrl = TextEditingController(text: 'Sortie longue 16km');

  @override
  void dispose() {
    groupCtrl.dispose();
    weekCtrl.dispose();
    mondayCtrl.dispose();
    wedCtrl.dispose();
    friCtrl.dispose();
    sunCtrl.dispose();
    super.dispose();
  }

  Future<void> create() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('programs').add({
      'coachId': uid,
      'groupId': groupCtrl.text.trim(),
      'weekStart': weekCtrl.text.trim(),
      'content': {
        'monday': mondayCtrl.text.trim(),
        'wednesday': wedCtrl.text.trim(),
        'friday': friCtrl.text.trim(),
        'sunday': sunCtrl.text.trim(),
      },
      'status': 'PUBLISHED',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer programme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: groupCtrl, decoration: const InputDecoration(labelText: 'groupId (ex: g1)')),
          const SizedBox(height: 12),
          TextField(controller: weekCtrl, decoration: const InputDecoration(labelText: 'weekStart (YYYY-MM-DD)')),
          const SizedBox(height: 12),
          TextField(controller: mondayCtrl, decoration: const InputDecoration(labelText: 'monday')),
          const SizedBox(height: 12),
          TextField(controller: wedCtrl, decoration: const InputDecoration(labelText: 'wednesday')),
          const SizedBox(height: 12),
          TextField(controller: friCtrl, decoration: const InputDecoration(labelText: 'friday')),
          const SizedBox(height: 12),
          TextField(controller: sunCtrl, decoration: const InputDecoration(labelText: 'sunday')),
          const SizedBox(height: 16),
          FilledButton(onPressed: create, child: const Text('Publier')),
        ],
      ),
    );
  }
}

/* ===========================
   POSTS (Public)
=========================== */

class PublicPostsScreen extends StatelessWidget {
  const PublicPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('posts')
        .where('isPublic', isEqualTo: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Aucune news pour le moment."));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return Card(
              child: ListTile(
                title: Text((d['title'] ?? '-') as String),
                subtitle: Text((d['type'] ?? '-') as String),
              ),
            );
          },
        );
      },
    );
  }
}

/* ===========================
   AUTH UI (simple)
=========================== */

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 16),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: loading ? null : login,
            child: loading ? const CircularProgressIndicator() : const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}
