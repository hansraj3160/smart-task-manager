import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/routes.dart';  
import 'injector_container.dart' as di;  
import 'config/theme.dart';
void main() async {
 
  WidgetsFlutterBinding.ensureInitialized();
 
  await di.init();


  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Task Manager',
      
      // Theme Settings
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
themeMode: ThemeMode.system,
      // Routing Setup
      initialRoute: AppRoutes.splash,  
      getPages: AppRoutes.pages,      
      
      // Default transition for better UX
      defaultTransition: Transition.cupertino, 
    );
  }
}