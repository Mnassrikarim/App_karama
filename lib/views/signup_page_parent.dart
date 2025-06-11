import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_karama_app/cors/constants.dart';
import 'package:edu_karama_app/services/api_service.dart';

class SignupPageParent extends StatelessWidget {
  const SignupPageParent({super.key});

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
          width: MediaQuery.of(context).size.width * 0.44,
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
  final _numTellController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    if (_nomController.text.trim().isEmpty ||
        _prenomController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _numTellController.text.trim().isEmpty) {
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
        role: 'parent',
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        numTell: _numTellController.text.trim(),
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
    _numTellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Color.fromARGB(255, 247, 231, 112)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDefaults.padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Inscription Parent',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: AppDefaults.margin),
                Text(
                  'Rejoignez l’aventure !',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: AppDefaults.margin * 2),
                TextField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    hintText: 'Nom',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: AppDefaults.margin),
                TextField(
                  controller: _prenomController,
                  decoration: InputDecoration(
                    hintText: 'Prénom',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: AppDefaults.margin),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppDefaults.margin),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Mot de passe',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: AppDefaults.margin),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    hintText: 'Confirmer le mot de passe',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: AppDefaults.margin),
                TextField(
                  controller: _numTellController,
                  decoration: InputDecoration(
                    hintText: 'Numéro de téléphone',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                  ),
                  keyboardType: TextInputType.phone,
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
                      backgroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Inscription',
                            style: TextStyle(color: Colors.white),
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
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => context.go('/login-parent'),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Vous avez déjà un compte ? ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: 'Connectez-vous',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
