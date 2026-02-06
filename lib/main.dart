import 'firebase_options.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for the login logic

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ImpacAPP());
}

class ImpacAPP extends StatelessWidget {
  const ImpacAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Impact AP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ACCESSIBILITY: High Contrast Blue & White theme
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          labelStyle: TextStyle(fontSize: 18, color: Colors.black87),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _cinController = TextEditingController(); 
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      // LOGIC: Name + 3 Digits -> Email + Password
      // Example: "Fares" + "438" -> fares@rct.tn / 438rct2026
      final cleanName = _nameController.text.trim().replaceAll(' ', '').toLowerCase();
      final email = "$cleanName@rct.tn"; 
      final password = "${_cinController.text.trim()}rct2026"; 

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Success! For now, just print it.
      print("User Logged In: $email");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bienvenue au Running Club Tunis!")),
      );
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        // ACCESSIBILITY: Readable error messages
        if (e.code == 'user-not-found') {
          _errorMessage = "Utilisateur non trouvé. Vérifiez le nom.";
        } else if (e.code == 'wrong-password') {
          _errorMessage = "Code CIN incorrect.";
        } else {
          _errorMessage = "Erreur de connexion.";
        }
      });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion RCT")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo placeholder
              const Icon(Icons.directions_run, size: 80, color: Colors.blue),
              const SizedBox(height: 30),
              
              Semantics(
                label: "Champ de texte pour le nom",
                hint: "Entrez votre nom complet",
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nom (ex: Fares)",
                    prefixIcon: Icon(Icons.person),
                  ),
                  style: const TextStyle(fontSize: 18), // Large text
                ),
              ),
              const SizedBox(height: 20),
              
              Semantics(
                label: "Champ de texte pour le CIN",
                hint: "Entrez les 3 derniers chiffres",
                child: TextField(
                  controller: _cinController,
                  decoration: const InputDecoration(
                    labelText: "3 derniers chiffres CIN (ex: 438)",
                    prefixIcon: Icon(Icons.lock),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                height: 55, // Large button for easy tapping
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SE CONNECTER", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Semantics(
                    liveRegion: true, // Screen reader announces this automatically when it appears
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
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