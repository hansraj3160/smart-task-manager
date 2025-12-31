
import 'package:get/get.dart';
import 'package:smart_task_manager/features/dashboard/presentation/pages/dashboard_screen.dart';
import '../features/splash/presentation/pages/splash_screen.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/auth/presentation/pages/signup_screen.dart';

class AppRoutes {
  static const baseUrl ='/'; 
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';

  static const dashboard = '/dashboard';


  static final pages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: signup, page: () => const SignupScreen()),
    // Add this Page
GetPage(name: dashboard, page: () => const DashboardScreen()),


  ];
}