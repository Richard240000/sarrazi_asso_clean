import 'package:flutter/material.dart';

class PopupService {
  static void showErrorMessage(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Une erreur est survenue.', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        showCloseIcon: true,
        closeIconColor: Colors.white,
      ),
    );
  }
}
