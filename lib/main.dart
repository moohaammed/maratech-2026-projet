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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); 
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print("=== LOGIN ATTEMPT ===");
      print("Time: ${DateTime.now()}");
      print("Email: $email");
      print("Attempting Firebase signIn...");

      // Add timeout to prevent infinite waiting
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception("Timeout: La connexion a pris trop de temps. Vérifiez votre connexion internet.");
            },
          );
      
      // Success! Navigate to home screen
      print("=== LOGIN SUCCESS ===");
      print("User: ${userCredential.user?.email}");
      print("UID: ${userCredential.user?.uid}");
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
      
    } on FirebaseAuthException catch (e) {
      print("=== FIREBASE AUTH ERROR ===");
      print("Code: ${e.code}");
      print("Message: ${e.message}");
      print("Full error: $e");
      setState(() {
        // ACCESSIBILITY: Readable error messages
        if (e.code == 'user-not-found') {
          _errorMessage = "Utilisateur non trouvé. Vérifiez l'email.";
        } else if (e.code == 'wrong-password') {
          _errorMessage = "Mot de passe incorrect.";
        } else if (e.code == 'invalid-email') {
          _errorMessage = "Format d'email invalide.";
        } else if (e.code == 'invalid-credential') {
          _errorMessage = "Email ou mot de passe incorrect.";
        } else {
          _errorMessage = "Erreur Firebase: ${e.code} - ${e.message}";
        }
      });
    } catch (e, stackTrace) {
      print("=== GENERAL ERROR ===");
      print("Error: $e");
      print("Type: ${e.runtimeType}");
      print("StackTrace: $stackTrace");
      setState(() {
        _errorMessage = "Erreur: $e";
      });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion")),
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
                label: "Champ de texte pour l'email",
                hint: "Entrez votre adresse email",
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 18), // Large text
                ),
              ),
              const SizedBox(height: 20),
              
              Semantics(
                label: "Champ de texte pour le mot de passe",
                hint: "Entrez votre mot de passe",
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Mot de passe",
                    prefixIcon: Icon(Icons.lock),
                  ),
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

// Home Screen - shown after successful login
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accueil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 30),
              const Text(
                "Connexion réussie!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                "Bienvenue",
                style: TextStyle(fontSize: 20, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Text(
                user?.email ?? "Utilisateur",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.blue),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text("Se déconnecter", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}