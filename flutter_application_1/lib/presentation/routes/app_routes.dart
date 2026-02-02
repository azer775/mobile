import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/contribuables_page.dart';

/// ============================================================================
/// APPLICATION ROUTES CONFIGURATION
/// ============================================================================
///
/// This file centralizes all route definitions for the app.
/// Benefits:
/// - Single source of truth for routes
/// - Easy to maintain and modify
/// - Type-safe route names via constants
///
/// HOW ROUTING WORKS IN FLUTTER:
/// 1. Define routes in MaterialApp (routes, onGenerateRoute, onUnknownRoute)
/// 2. Navigate using Navigator.pushNamed(context, '/route-name')
/// 3. Or use Navigator.push(context, MaterialPageRoute(...))

class AppRoutes {
  // Route name constants - prevents typos!
  static const String login = '/login';
  static const String home = '/';
  static const String contribuables = '/contribuables';

  /// Simple routes map - for screens without parameters
  /// Used by MaterialApp's `routes` property
  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginPage(),
      home: (context) => const HomePage(),
      contribuables: (context) => const ContribuablesPage(),
    };
  }

  /// Dynamic route generator - for screens WITH parameters
  /// Used by MaterialApp's `onGenerateRoute` property
  ///
  /// Example usage:
  /// Navigator.pushNamed(context, '/user-detail', arguments: 123);
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // settings.name = the route path (e.g., '/user-detail')
    // settings.arguments = data passed to the route

    // Example: Handle route with arguments
    // if (settings.name == '/user-detail') {
    //   final userId = settings.arguments as int;
    //   return MaterialPageRoute(
    //     builder: (context) => UserDetailPage(userId: userId),
    //   );
    // }

    // Example: Handle dynamic path segments like '/users/123'
    // final uri = Uri.parse(settings.name ?? '');
    // if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'users') {
    //   final userId = int.tryParse(uri.pathSegments[1]);
    //   if (userId != null) {
    //     return MaterialPageRoute(
    //       builder: (context) => UserDetailPage(userId: userId),
    //     );
    //   }
    // }

    return null; // Return null to fall back to routes map or onUnknownRoute
  }

  /// Fallback for unknown routes - shows 404 page
  /// Used by MaterialApp's `onUnknownRoute` property
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
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
                onPressed: () {
                  // Clear stack and go home
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    home,
                    (route) => false,
                  );
                },
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
