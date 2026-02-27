import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/refs_sync_service.dart';

/// ============================================================================
/// HOME PAGE - The main entry point of the application
/// ============================================================================
///
/// This is a STATELESS WIDGET because:
/// - It doesn't have any internal state that changes
/// - It just displays static content and navigation buttons
/// - Any data it needs could be passed via constructor

class HomePage extends StatelessWidget {
  // 'const' constructor - allows Flutter to optimize rebuilds
  // 'super.key' - passes the key to the parent StatelessWidget
  const HomePage({super.key});

  void _handleLogout(BuildContext context) async {
    await AuthService.instance.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _handleSyncReferences(BuildContext context) async {
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Synchronisation des références...')),
          ],
        ),
      ),
    );

    final result = await RefsSyncService.instance.synchronize();

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) return;

    final counts = result.counts;
    final details = counts == null
        ? ''
        : ' (zones: ${counts['zoneTypes']}, avenues: ${counts['avenues']}, '
            'quartiers: ${counts['quartiers']}, communes: ${counts['communes']}, '
            'activités: ${counts['typeActivites']})';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.message}$details'),
        backgroundColor: result.success ? Colors.green : Colors.orange,
      ),
    );
  }

  // build() is called when Flutter needs to render this widget
  // 'context' provides access to theme, navigation, screen size, etc.
  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;
    
    return Scaffold(
      // Scaffold provides the basic visual structure:
      // - AppBar at top
      // - Body in the middle
      // - FloatingActionButton, BottomNavigationBar, Drawer, etc.
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (authService.isLoggedIn)
            PopupMenuButton<String>(
              icon: const CircleAvatar(
                child: Icon(Icons.person, size: 20),
              ),
              onSelected: (value) {
                if (value == 'sync_refs') {
                  _handleSyncReferences(context);
                }
                if (value == 'logout') {
                  _handleLogout(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authService.currentUser ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        authService.currentUserEmail ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'sync_refs',
                  child: Row(
                    children: [
                      Icon(Icons.sync),
                      SizedBox(width: 8),
                      Text('Synchroniser les références'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Déconnexion', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Center(
        // Center widget centers its child both horizontally and vertically
        child: Column(
          // Column arranges children vertically
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            // 'const' before widgets that never change = better performance
            const Icon(
              Icons.home,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16), // SizedBox for spacing

            if (authService.isLoggedIn) ...[
              Text(
                'Bonjour, ${authService.currentUser}!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ] else ...[
              const Text(
                'Welcome to Flutter App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 32),

            // Button to access the Contribuables
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/contribuables');
              },
              icon: const Icon(Icons.account_balance),
              label: const Text('Contribuables'),
            ),
            const SizedBox(height: 16),

            // Button to access the Immobilier module
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/immobilier');
              },
              icon: const Icon(Icons.landscape),
              label: const Text('Immobilier'),
            ),
          ],
        ),
      ),
    );
  }
}
