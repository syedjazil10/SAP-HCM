import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Loginpage.dart';
import 'landing_page.dart';

Future<void> main() async {
   WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  await SharedPreferences.getInstance();
  var status = await Permission.location.request();

  // Initialize GetX bindings and controller
UserController userController = UserController();
  Get.put<UserController>(UserController());
  
  runApp(SmartHCMApp());
}

class SmartHCMApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart IIL HCM App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color.fromARGB(255, 1, 45, 56),
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
