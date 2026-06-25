import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailControleur = TextEditingController();
  final _motDePasseControleur = TextEditingController();
  bool _estConnexion = true;
  bool _chargement = false;
  bool _motDePasseVisible = false;
  String? _erreur;

  Future<void> _soumettre() async {
    final email = _emailControleur.text.trim();
    final mdp = _motDePasseControleur.text.trim();

    if (email.isEmpty || mdp.isEmpty) {
      setState(() => _erreur = 'Remplis tous les champs.');
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      if (_estConnexion) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: mdp,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: mdp,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _erreur = 'Aucun compte trouvé avec cet email.';
            break;
          case 'wrong-password':
            _erreur = 'Mot de passe incorrect.';
            break;
          case 'email-already-in-use':
            _erreur = 'Cet email est déjà utilisé.';
            break;
          case 'weak-password':
            _erreur = 'Mot de passe trop faible (6 caractères minimum).';
            break;
          case 'invalid-email':
            _erreur = 'Adresse email invalide.';
            break;
          default:
            _erreur = 'Erreur : ${e.message}';
        }
      });
    } finally {
      setState(() => _chargement = false);
    }
  }

  Future<void> _motDePasseOublie() async {
    final email = _emailControleur.text.trim();

    if (email.isEmpty) {
      setState(() => _erreur = 'Entre ton email d\'abord.');
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email envoyé'),
            content: Text(
              'Un lien de réinitialisation a été envoyé à $email.\nVérifie ta boîte mail.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _erreur = 'Aucun compte trouvé avec cet email.';
            break;
          case 'invalid-email':
            _erreur = 'Adresse email invalide.';
            break;
          default:
            _erreur = 'Erreur : ${e.message}';
        }
      });
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  void dispose() {
    _emailControleur.dispose();
    _motDePasseControleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.home_outlined, size: 72, color: Color(0xFF1565C0)),
              const SizedBox(height: 16),
              const Text(
                'SmartHome Connect',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 8),
              Text(
                _estConnexion ? 'Connecte-toi à ton compte' : 'Crée ton compte',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailControleur,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _motDePasseControleur,
                obscureText: !_motDePasseVisible,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_motDePasseVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(
                        () => _motDePasseVisible = !_motDePasseVisible),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Bouton mot de passe oublié (visible uniquement en mode connexion)
              if (_estConnexion)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _chargement ? null : _motDePasseOublie,
                    child: const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

              if (_erreur != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _erreur!,
                    style:
                        TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _chargement ? null : _soumettre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _chargement
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _estConnexion ? 'Se connecter' : "S'inscrire",
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {
                  _estConnexion = !_estConnexion;
                  _erreur = null;
                }),
                child: Text(
                  _estConnexion
                      ? "Pas encore de compte ? S'inscrire"
                      : 'Déjà un compte ? Se connecter',
                  style: const TextStyle(color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}