import 'package:edu_karama_app/cors/constants.dart';
import 'package:edu_karama_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupPageEleve extends StatelessWidget {
  const SignupPageEleve({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AppDefaults.padding * 2),
              const _AppLogoAndHeadline(),
              const SizedBox(height: AppDefaults.margin),
              const _SignupForm(),
              const SizedBox(height: AppDefaults.margin),
              const _Footer(),
              const SizedBox(height: AppDefaults.padding),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppLogoAndHeadline extends StatelessWidget {
  const _AppLogoAndHeadline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: Image.asset(
              AppImages.logo,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported,
                size: 100,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDefaults.padding),
        Text(
          'Inscription Élève',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}

class _SignupForm extends StatefulWidget {
  const _SignupForm();

  @override
  _SignupFormState createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _numInscriptController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Validate inputs
    if (_nomController.text.trim().isEmpty ||
        _prenomController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _numInscriptController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Tous les champs sont obligatoires.';
        _isLoading = false;
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Les mots de passe ne correspondent pas.';
        _isLoading = false;
      });
      return;
    }

    if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      setState(() {
        _errorMessage = 'Veuillez entrer un email valide.';
        _isLoading = false;
      });
      return;
    }

    try {
      final apiService = ApiService();
      final message = await apiService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: 'eleve',
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        numInscript: _numInscriptController.text.trim(),
        // Note: niveau is omitted for now; add later if needed
      );

      if (mounted) {
        setState(() {
          _successMessage = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _numInscriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDefaults.padding),
      child: Column(
        children: [
          TextField(
            controller: _nomController,
            decoration: InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppDefaults.margin),
          TextField(
            controller: _prenomController,
            decoration: InputDecoration(
              labelText: 'Prénom',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppDefaults.margin),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppDefaults.margin),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: AppDefaults.margin),
          TextField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: AppDefaults.margin),
          TextField(
            controller: _numInscriptController,
            decoration: InputDecoration(
              labelText: 'Numéro d\'inscription',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppDefaults.margin),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: AppDefaults.margin),
            Text(
              _successMessage!,
              style: const TextStyle(color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppDefaults.margin),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Inscription'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => context.go('/login-eleve'),
          child: const Text(
            'Vous avez déjà un compte ? Connectez-vous',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
