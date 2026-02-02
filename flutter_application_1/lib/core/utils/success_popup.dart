import 'package:flutter/material.dart';

/// Utility class for showing success popup dialogs
class SuccessPopup {
  /// Show a success popup dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.check_circle,
    Color iconColor = Colors.green,
    String buttonText = 'OK',
    VoidCallback? onDismiss,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDismiss?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show login success popup
  static Future<void> showLoginSuccess(BuildContext context, {VoidCallback? onDismiss}) {
    return show(
      context: context,
      title: 'Connexion Réussie',
      message: 'Bienvenue! Vous êtes maintenant connecté.',
      icon: Icons.login,
      iconColor: Colors.green,
      onDismiss: onDismiss,
    );
  }

  /// Show add success popup
  static Future<void> showAddSuccess(BuildContext context, {String itemName = 'Contribuable', VoidCallback? onDismiss}) {
    return show(
      context: context,
      title: 'Ajout Réussi',
      message: '$itemName a été ajouté avec succès.',
      icon: Icons.person_add,
      iconColor: Colors.green,
      onDismiss: onDismiss,
    );
  }

  /// Show update success popup
  static Future<void> showUpdateSuccess(BuildContext context, {String itemName = 'Contribuable', VoidCallback? onDismiss}) {
    return show(
      context: context,
      title: 'Mise à Jour Réussie',
      message: '$itemName a été mis à jour avec succès.',
      icon: Icons.edit,
      iconColor: Colors.blue,
      onDismiss: onDismiss,
    );
  }

  /// Show delete success popup
  static Future<void> showDeleteSuccess(BuildContext context, {String itemName = 'Contribuable', VoidCallback? onDismiss}) {
    return show(
      context: context,
      title: 'Suppression Réussie',
      message: '$itemName a été supprimé avec succès.',
      icon: Icons.delete,
      iconColor: Colors.orange,
      onDismiss: onDismiss,
    );
  }
}
