import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_task_manager/core/utils/validators.dart';
import '../controllers/auth_controller.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
 
    final controller = Get.find<AuthController>();

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        
        controller.clearTextFields();
      },
      child: Scaffold(
        appBar: AppBar(
          
          title: const Text("Create Account")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: controller.signupFormKey,  
            child: Column(
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
        
                // Name Field
              
                TextFormField(
                  controller: controller.nameController,
                  decoration:  InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                  ),
                   validator: (value) => Validators().nameValidation(value)
                ),
                const SizedBox(height: 15),
              
                // Email Field
                TextFormField(
                  controller: controller.emailController, 
                  decoration:  InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
                  ),
                   validator: (value) => Validators().emailValidation(value)
                ),
                const SizedBox(height: 15),
              
                // Password Field
                Obx(() => TextFormField(
                  controller: controller.passwordController,
                  obscureText: controller.isPasswordHidden.value,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon:   Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(controller.isPasswordHidden.value ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).colorScheme.primary),
                      onPressed: () => controller.togglePasswordVisibility(),
                    ),
                  ),
                  validator: (value) =>Validators().passwordValidation(value)
                )),
                const SizedBox(height: 15),
              
               
                Obx(() => TextFormField(
                  controller: controller.confirmPasswordController,
                  obscureText: controller.isConfirmPasswordHidden.value,
                  decoration:   InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(controller.isConfirmPasswordHidden.value 
                          ? Icons.visibility_off 
                          : Icons.visibility, color: Theme.of(context).colorScheme.primary),
                      onPressed: () => controller.toggleConfirmPasswordVisibility(),
                    ),
                  ),
                  
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirm Password is required';
                    if (value != controller.passwordController.text) {
                      return 'Passwords do not match';  
                    }
                    return null;
                  },
                )),
                const SizedBox(height: 30),
              
                // Signup Button
                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.signup(),
                  child: controller.isLoading.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("SIGN UP"),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}