import 'package:edu_karama_app/cors/constants.dart';
import 'package:edu_karama_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

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
              const _ResetPasswordForm(),
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
        // Text(
        //   'Réinitialiser le mot de passe',
        //   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        //         fontWeight: FontWeight.bold,
        //         color: Theme.of(context).colorScheme.primary,
        //       ),
        // ),
      ],
    );
  }
}

class _ResetPasswordForm extends StatefulWidget {
  const _ResetPasswordForm();

  @override
  _ResetPasswordFormState createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<_ResetPasswordForm> {
  final _emailController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un email.';
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
      final message = await apiService.resetPassword(
        identifier: _emailController.text.trim(),
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
    _emailController.dispose();
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
              colors: [Colors.blue[900]!,Color.fromARGB(255, 247, 231, 112)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          // margin: const EdgeInsets.symmetric(horizontal: AppDefaults.padding),
          child: Padding(
            padding: const EdgeInsets.all(AppDefaults.padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Réinitialiser le mot de passe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: AppDefaults.margin),
                Text(
                  'Entrez votre email pour recevoir un lien de réinitialisation.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDefaults.margin * 2),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.blue[900]),
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
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Envoyer',
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
          onPressed: () => context.go('/login-eleve'),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Retour à la ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: 'connexion',
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
