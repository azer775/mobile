import 'package:flutter/material.dart';

/// ============================================================================
/// FLUTTER ROUTING GUIDE - Navigation Between Screens
/// ============================================================================
///
/// Flutter offers several ways to handle navigation:
/// 1. Navigator.push/pop - Basic imperative navigation
/// 2. Named Routes - Define routes in one place, navigate by name
/// 3. onGenerateRoute - Dynamic route generation
/// 4. go_router (package) - Declarative routing with URL support

// =============================================================================
// METHOD 1: BASIC NAVIGATION (Navigator.push/pop)
// =============================================================================

class BasicNavigationExample extends StatelessWidget {
  const BasicNavigationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Navigate to a new screen
            ElevatedButton(
              onPressed: () {
                // Push a new route onto the navigation stack
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetailScreen(itemId: 123),
                  ),
                );
              },
              child: const Text('Go to Details'),
            ),

            const SizedBox(height: 16),

            // Navigate and REPLACE current screen (can't go back)
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnotherScreen(),
                  ),
                );
              },
              child: const Text('Replace with Another'),
            ),

            const SizedBox(height: 16),

            // Navigate and get result back
            ElevatedButton(
              onPressed: () async {
                // Wait for result from the next screen
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectionScreen(),
                  ),
                );

                // Use the result
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected: $result')),
                  );
                }
              },
              child: const Text('Select and Return'),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final int itemId; // Receive data via constructor

  const DetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail #$itemId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Showing item $itemId'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Go back to previous screen
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select an Option')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Option A'),
            onTap: () {
              // Return result to previous screen
              Navigator.pop(context, 'Option A');
            },
          ),
          ListTile(
            title: const Text('Option B'),
            onTap: () => Navigator.pop(context, 'Option B'),
          ),
          ListTile(
            title: const Text('Option C'),
            onTap: () => Navigator.pop(context, 'Option C'),
          ),
        ],
      ),
    );
  }
}

class AnotherScreen extends StatelessWidget {
  const AnotherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Another Screen')),
      body: const Center(child: Text('This replaced the previous screen')),
    );
  }
}

// =============================================================================
// METHOD 2: NAMED ROUTES (Defined in MaterialApp)
// =============================================================================

/// In your main.dart, define routes like this:
/// 
/// ```dart
/// MaterialApp(
///   initialRoute: '/',
///   routes: {
///     '/': (context) => const HomeScreen(),
///     '/details': (context) => const DetailsScreen(),
///     '/profile': (context) => const ProfileScreen(),
///   },
/// )
/// ```
///
/// Then navigate using:
/// ```dart
/// Navigator.pushNamed(context, '/details');
/// ```

class NamedRoutesExample extends StatelessWidget {
  const NamedRoutesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Named Routes')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple named navigation
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/users');
              },
              child: const Text('Go to Users'),
            ),

            const SizedBox(height: 16),

            // Named navigation with arguments
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/user-detail',
                  arguments: {'userId': 42, 'userName': 'John'},
                );
              },
              child: const Text('Go to User Detail'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// METHOD 3: onGenerateRoute (Dynamic Route Generation)
// =============================================================================

/// This is the RECOMMENDED approach for complex apps.
/// Define this in your MaterialApp:
///
/// ```dart
/// MaterialApp(
///   onGenerateRoute: AppRouter.onGenerateRoute,
///   onUnknownRoute: AppRouter.onUnknownRoute,
/// )
/// ```

class AppRouter {
  // Define route names as constants
  static const String home = '/';
  static const String users = '/users';
  static const String userDetail = '/users/:id'; // With parameter
  static const String settings = '/settings';

  /// Main route generator
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Parse the route name and arguments
    final uri = Uri.parse(settings.name ?? '');
    // ignore: unused_local_variable
    final args = settings.arguments; // Available for routes that need arguments

    // Match routes and return appropriate MaterialPageRoute
    switch (uri.path) {
      case '/':
        return _buildRoute(
          settings,
          const HomeScreen(),
        );

      case '/users':
        return _buildRoute(
          settings,
          const UsersListScreen(),
        );

      case '/settings':
        return _buildRoute(
          settings,
          const SettingsScreen(),
        );

      default:
        // Handle dynamic routes like '/users/123'
        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'users') {
          final userId = int.tryParse(uri.pathSegments[1]);
          if (userId != null) {
            return _buildRoute(
              settings,
              UserDetailScreen(userId: userId),
            );
          }
        }
        return null; // Return null for unknown routes
    }
  }

  /// Fallback for unknown routes
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Route "${settings.name}" not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                ),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build routes with consistent settings
  static MaterialPageRoute<T> _buildRoute<T>(
    RouteSettings settings,
    Widget page, {
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (context) => page,
      fullscreenDialog: fullscreenDialog,
    );
  }
}

// Sample screens for routing examples
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home Screen')),
    );
  }
}

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ListTile(
          title: Text('User ${index + 1}'),
          onTap: () {
            // Navigate to user detail with ID in URL
            Navigator.pushNamed(context, '/users/${index + 1}');
          },
        ),
      ),
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User $userId')),
      body: Center(child: Text('Details for user $userId')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Screen')),
    );
  }
}

// =============================================================================
// NAVIGATION PATTERNS CHEAT SHEET
// =============================================================================

/// COMMON NAVIGATION METHODS:
///
/// // Push new screen (adds to stack)
/// Navigator.push(context, MaterialPageRoute(builder: (_) => Screen()));
/// Navigator.pushNamed(context, '/route');
///
/// // Pop current screen (go back)
/// Navigator.pop(context);
/// Navigator.pop(context, resultValue); // Return data
///
/// // Replace current screen
/// Navigator.pushReplacement(context, route);
/// Navigator.pushReplacementNamed(context, '/route');
///
/// // Clear stack and push
/// Navigator.pushAndRemoveUntil(context, route, (r) => false);
/// Navigator.pushNamedAndRemoveUntil(context, '/route', (r) => false);
///
/// // Pop until specific route
/// Navigator.popUntil(context, ModalRoute.withName('/home'));
///
/// // Check if can pop
/// Navigator.canPop(context);
///
/// // Maybe pop (pops if possible)
/// Navigator.maybePop(context);

// =============================================================================
// PAGE TRANSITIONS
// =============================================================================

/// Custom page transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from right
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Fade page transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Usage:
/// Navigator.push(context, SlidePageRoute(page: MyScreen()));
/// Navigator.push(context, FadePageRoute(page: MyScreen()));
