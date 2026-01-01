import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/routes.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller Inject
    final controller = Get.put(AuthController());

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: controller.loginFormKey, 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: const AssetImage('assets/logo.jpg'),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Email Field
                TextFormField(
                  controller: controller.emailController,
                  decoration:  InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
                  ),
                  validator: (value) => Validators().emailValidation(value)
                ),
                const SizedBox(height: 20),

                // Password Field (Reactive Eye Icon)
                Obx(() => TextFormField(
                  controller: controller.passwordController,
                  obscureText: controller.isPasswordHidden.value, 
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon:  Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordHidden.value 
                          ? Icons.visibility_off 
                          : Icons.visibility, color: Theme.of(context).colorScheme.primary
                      ),
                      onPressed: () => controller.togglePasswordVisibility(),
                    ),
                  ),
                  validator: (value) =>Validators().passwordValidation(value)
                )),
                const SizedBox(height: 30),

                // Login Button (Reactive Loading)
                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.login(),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text("LOGIN"),
                )),

                const SizedBox(height: 15),
                TextButton(
                  onPressed: () { 
               controller.clearTextFields();
                    Get.toNamed(AppRoutes.signup);},
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}