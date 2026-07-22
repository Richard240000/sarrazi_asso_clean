import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:sarrazi_asso_clean/pages/forgot_password_page.dart';

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({super.key});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  // Champs VIDE (pas de valeurs par défaut)
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

    if (response.isSuccess) {
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.pop(context, true);
    } else {
      setState(() {
        errorMessage = response.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          color: Colors.blue[800],
          child: Padding(
            //padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom < 100 ? kBottomNavigationBarHeight : MediaQuery.of(context).viewInsets.bottom),
            padding: EdgeInsetsGeometry.only(
              bottom:
                  Platform.isAndroid &&
                      MediaQuery.of(context).viewInsets.bottom < 100
                  ? MediaQuery.paddingOf(context).bottom
                  : MediaQuery.of(context).viewInsets.bottom < 100
                  ? kBottomNavigationBarHeight
                  : MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 16,
                  ),
                  child: Center(
                    child: AutofillGroup(
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),

                            // Champ EMAIL
                            TextFormField(
                              autofillHints: [
                                AutofillHints.newUsername,
                                AutofillHints.username,
                              ],
                              controller: emailController,
                              decoration: InputDecoration(
                                hintText: "Adresse mail",
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.blue[800],
                                ),
                                errorStyle: TextStyle(color: Colors.white),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Champ obligatoire';
                                }
                                final bool emailValid = RegExp(
                                  r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$",
                                ).hasMatch(value);
                                if (!emailValid) {
                                  return 'Format incorrect';
                                }
                                return null;
                              },
                            ),

                            // Champ MOT DE PASSE
                            TextFormField(
                              autofillHints: [AutofillHints.password],
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: "Mot de passe",
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.blue[800],
                                ),
                                errorStyle: TextStyle(color: Colors.white),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Champ obligatoire';
                                }
                                return null;
                              },
                            ),

                            // 🔥🔥🔥 BOUTON "Mot de passe oublié ?"
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Mot de passe oublié ?",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                            // Boutons
                            Row(
                              spacing: 15,
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: ButtonStyle(
                                      padding: WidgetStatePropertyAll(
                                        EdgeInsets.all(15),
                                      ),
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      side: WidgetStateProperty.all(
                                        BorderSide(
                                          color: Colors.white,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "Annuler",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () async => await seConnecter(),
                                    style: ButtonStyle(
                                      padding: WidgetStatePropertyAll(
                                        EdgeInsets.all(15),
                                      ),
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: isLoading
                                        ? SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text("Se connecter"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Message d’erreur
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
        ),
      ],
    );
  }
}
