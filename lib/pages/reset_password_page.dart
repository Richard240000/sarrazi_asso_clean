import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordPage extends StatefulWidget {
  /// Token éventuellement fourni par le code (ex: deep link ou navigation interne).
  /// S'il est null ou vide, l'utilisateur devra saisir le code reçu par email.
  final String? token;

  const ResetPasswordPage({super.key, this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  /// Nouveau mot de passe
  final TextEditingController passwordController = TextEditingController();

  /// Confirmation du mot de passe
  final TextEditingController confirmController = TextEditingController();

  /// Code / token reçu par email (utilisé seulement si widget.token est null ou vide)
  final TextEditingController tokenController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  String? serverMessage;

  // ⚠️ À ADAPTER : URL de ton API
  static const String resetApiUrl =
      'https://www.association-sarrazi.fr/reset_api.php';

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    // Déterminer le token à envoyer :
    // - si widget.token est fourni et non vide, on l'utilise
    // - sinon on prend le contenu du champ "code"
    final String effectiveToken;
    if (widget.token != null && widget.token!.trim().isNotEmpty) {
      effectiveToken = widget.token!.trim();
    } else {
      effectiveToken = tokenController.text.trim();
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Les deux mots de passe ne correspondent pas.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (effectiveToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Le code de réinitialisation est obligatoire.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      serverMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(resetApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': effectiveToken, 'password': password}),
      );

      debugPrint('[DEBUG] Status reset: ${response.statusCode}');
      debugPrint('[DEBUG] Body reset: ${response.body}');

      if (response.statusCode != 200) {
        setState(() {
          serverMessage = 'Erreur serveur (${response.statusCode}).';
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Erreur serveur (${response.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException catch (e) {
        debugPrint('[DEBUG] Erreur de parsing JSON reset: $e');
        setState(() {
          serverMessage = 'Réponse invalide du serveur.';
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Réponse invalide du serveur.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = data['success'] == true;
      final message = (data['message'] ?? 'Une réponse a été reçue.')
          .toString();

      setState(() {
        serverMessage = message;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
          backgroundColor: success ? Colors.green[700] : Colors.red[700],
        ),
      );

      if (success) {
        // On ferme la page "Nouveau mot de passe"
        Navigator.pop(context); // ResetPasswordPage

        // Puis on ferme la page "Mot de passe oublié"
        Navigator.pop(
          context,
        ); // ForgotPasswordPage -> retour à la bottom sheet de login
      }
    } catch (e) {
      debugPrint('[DEBUG] Erreur réseau reset: $e');

      setState(() {
        serverMessage = 'Erreur réseau. Veuillez réessayer.';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Erreur réseau. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool doitSaisirCode =
        widget.token == null || widget.token!.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doitSaisirCode
                      ? "Saisissez le code reçu par email puis choisissez un nouveau mot de passe."
                      : "Veuillez choisir un nouveau mot de passe.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Champ "Code reçu par email" uniquement si aucun token n'est fourni
                if (doitSaisirCode) ...[
                  TextFormField(
                    controller: tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Code de réinitialisation',
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Code obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Champ obligatoire';
                    }
                    if (value.trim().length < 8) {
                      return 'Au moins 8 caractères.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Champ obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _resetPassword,
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Valider le nouveau mot de passe'),
                  ),
                ),
                if (serverMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    serverMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
