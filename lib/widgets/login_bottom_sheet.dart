import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sarrazi_asso_clean/main.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({super.key});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future seConnecter() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      errorMessage = '';
      isLoading = true;
    });
    var response = await HttpService.verifieAuthentification(email, password);
    setState(() => isLoading = false);
    if (response?.isSuccess ?? false) {
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() {
        errorMessage = response?.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Wrap(
          children: [
            Container(
              color: Colors.blue[800],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Center(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 20,
                          children: [
                            Text(
                              "Espace sécurisé",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                hintText: "Adresse mail",
                                prefixIcon: Icon(Icons.email, color: Colors.blue[800]),
                                errorStyle: TextStyle(color: Colors.white),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Champ obligatoire';
                                }
                                final bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
                                if (!emailValid) {
                                  return 'Format incorrect';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: "Mot de passe",
                                prefixIcon: Icon(Icons.lock, color: Colors.blue[800]),
                                errorStyle: TextStyle(color: Colors.white),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Champ obligatoire';
                                }
                                return null;
                              },
                            ),
                            // Padding(
                            //   padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            //   child: Text(
                            //     "Mot de passe oublié ?",
                            //     textAlign: TextAlign.start,
                            //     style: TextStyle(
                            //       color: Colors.transparent,
                            //       fontStyle: FontStyle.italic,
                            //       decoration: TextDecoration.underline,
                            //       decorationColor: Colors.white,
                            //       decorationThickness: 2,
                            //       shadows: [Shadow(color: Colors.white, offset: Offset(0, -5))],
                            //     ),
                            //   ),
                            // ),
                            Row(
                              spacing: 15,
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: ButtonStyle(
                                      padding: WidgetStatePropertyAll(EdgeInsets.all(15)),
                                      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                      side: WidgetStateProperty.all(BorderSide(color: Colors.white, width: 1.0, style: BorderStyle.solid)),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text("Annuler", style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : () async => await seConnecter(),
                                    style: ButtonStyle(
                                      padding: WidgetStatePropertyAll(EdgeInsets.all(15)),
                                      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    ),
                                    child: isLoading ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : Text("Se connecter"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  errorMessage?.isNotEmpty ?? false
                      ? Container(
                          color: Colors.red,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              errorMessage ?? '',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
