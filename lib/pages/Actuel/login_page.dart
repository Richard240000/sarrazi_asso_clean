import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'accueil.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> seConnecter() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://www.association-sarrazi.fr/verifier_login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('[DEBUG] Status code : ${response.statusCode}');
      print('[DEBUG] Corps réponse : ${response.body}');

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', data['email']);
        await prefs.setString('nom', data['nom']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AccueilPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Erreur de connexion')),
        );
      }
    } catch (e) {
      print('[DEBUG] Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connexion")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Adresse mail"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Mot de passe"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : seConnecter,
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text("Se connecter"),
            ),
          ],
        ),
      ),
    );
  }
}
