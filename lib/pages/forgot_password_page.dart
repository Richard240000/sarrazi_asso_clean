import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sarrazi_asso_clean/pages/reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  String? serverMessage;

  // ⚠️ URL de ton API
  static const String forgotApiUrl =
      'https://www.association-sarrazi.fr/forgot_api.php';

  Future<void> _envoyerLienReset() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();

    setState(() {
      isLoading = true;
      serverMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(forgotApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('[DEBUG] Status: ${response.statusCode}');
      print('[DEBUG] Body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      final success = data['success'] == true;
      final message = (data['message'] ?? 'Réponse reçue').toString();

      setState(() {
        serverMessage = message;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green[700] : Colors.red[700],
        ),
      );

      // 🔥 SI SUCCÈS → on enchaîne vers la page de saisie du code + nouveau mot de passe
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ResetPasswordPage(), // sans token → champ code affiché
          ),
        );
      }
    } catch (e) {
      print('[DEBUG] Erreur réseau : $e');

      setState(() {
        serverMessage = "Erreur réseau. Veuillez réessayer.";
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur réseau. Veuillez réessayer."),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Saisissez l'adresse mail associée à votre compte.\n"
                      "Si elle est reconnue, un code de réinitialisation vous sera envoyé par email.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse mail',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Champ obligatoire';
                    }
                    final emailRegExp = RegExp(
                      r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$",
                    );
                    if (!emailRegExp.hasMatch(value.trim())) {
                      return 'Format d’email incorrect';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _envoyerLienReset,
                    child: isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Envoyer le code de réinitialisation'),
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
