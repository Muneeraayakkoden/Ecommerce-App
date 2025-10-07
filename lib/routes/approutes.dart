import 'package:flutter/material.dart';
import '../screens/login/view/login.dart';
import '../screens/dashboard/view/dashboard.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginScreen(),
    '/dashboard': (context) => const DashboardScreen(),
  };
}
