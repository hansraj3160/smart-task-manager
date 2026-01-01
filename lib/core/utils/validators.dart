import 'package:get/get_utils/src/get_utils/get_utils.dart';

class Validators {
  
  String? nameValidation(String? value){
     if (value == null || value.isEmpty) return 'Name is required g';
   
    return null;
  }

  String? passwordValidation(String? value) {
    if (value == null || value.isEmpty) return 'Password is required g';
    if (value.length < 6) return 'Min 6 characters required';
    return null;
  }

  String? emailValidation(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(value)) return 'Enter a valid email';
    return null;
  }

}
