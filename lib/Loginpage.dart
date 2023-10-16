import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'landing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  // Define an observable list to store user data
  final RxList<Map<String, String>> userDataList = <Map<String, String>>[].obs;

  // Method to set the user data list
  void setUserDataList(List<Map<String, String>> data) {
    userDataList.assignAll(data);
  }
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController hostlinkController = TextEditingController();

Future<void> validateUser() async {
  // Define the API endpoint URL
  final apiUrl = 'http://202.61.46.140:80/UserValidate/User_Login.asmx/ValidateUser';
  final String userName = userNameController.text;
  final String password = passwordController.text;
  final prefs = await SharedPreferences.getInstance();

  // Create the request body
  final requestBody = {
    'userName': userName,
    'password': password,
  };

  // Make the POST request
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: requestBody,
  );

  // Check if the request was successful (HTTP status code 200)
  if (response.statusCode == 200) {
    // Parse the XML response
    final xmlResponse = xml.XmlDocument.parse(response.body);

    // Extract data from the XML response
    final resultNodes = xmlResponse.findAllElements('result_name');

    if (resultNodes.isNotEmpty) {
      final userDataList = <Map<String, String>>[];

      for (final resultNode in resultNodes) {
        final userId = resultNode.findElements('UserID').first.text;
        final userName = resultNode.findElements('UserName').first.text;
        final imeiNo = resultNode.findElements('IMEINo').first.text;
        final comId = resultNode.findElements('ComID').first.text;
        final unitId = resultNode.findElements('UnitID').first.text;
        final locationId = resultNode.findElements('LocationID').first.text;
        final latitude = resultNode.findElements('Latitude').first.text;
        final longitude = resultNode.findElements('Longitude').first.text;

        // Create a map for the current user data
        final userDataMap = <String, String>{
          'UserID': userId,
          'UserName': userName,
          'IMEINo': imeiNo,
          'ComID': comId,
          'UnitID': unitId,
          'LocationID': locationId,
          'Latitude': latitude,
          'Longitude': longitude,
        };

        // Add the current user data map to the list
        userDataList.add(userDataMap);

        // Do something with the extracted data for each user
        print('UserID: $userId');
        print('UserName: $userName');
        print('IMEINo: $imeiNo');
        print('ComID: $comId');
        print('UnitID: $unitId');
        print('LocationID: $locationId');
        print('Latitude: $latitude');
        print('Longitude: $longitude');
        await prefs.setString('userId', userId); 
        await prefs.setString('userName', userName);
                await prefs.setString('ComID', comId);


      }

      // Store the entire list of user data maps in SharedPreferences
      await prefs.setStringList(
        'userDataList',
        userDataList.map((userData) => jsonEncode(userData)).toList(),
      );

      final userController = Get.find<UserController>();
      userController.setUserDataList(userDataList);
      print(await prefs.getStringList('userDataList'));

      Get.off(() => LandingPage()); // Navigate to the LandingPage
    } else {
      // Handle the case where no user data was found in the response
      print('No valid data found in the response.');
      Get.snackbar(
        "No Data Found",
        "No user data found in the response.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
  } else {
    // Handle the case where the API request failed
    print('API Request failed with status code ${response.statusCode}');
    Get.snackbar(
      "API Request Failed",
      "API request failed with status code ${response.statusCode}.",
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );
  }
}


   @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 238, 129, 5)!,
                Color.fromARGB(255, 184, 82, 167)!,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(top: 100, bottom: 30),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/ii.png',
                      width: 450,
                      height: 200,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Ismail Industries HCM",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded( // Wrap the Column with Expanded
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      InputField(icon: Icons.person, hintText: "UserName", controller: userNameController),
                      SizedBox(height: 10),
                      InputField(icon: Icons.lock, hintText: "Password", isPassword: true, controller: passwordController),
                      SizedBox(height: 10),
                     // InputField(icon: Icons.link, hintText: "Host Link", controller: hostlinkController),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                           if (userNameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                            validateUser();
      } else {
        // Show an error message for empty fields
        Get.snackbar(
          "Error",
          "Username and password cannot be empty",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      }
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green[600],
                          onPrimary: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          elevation: 5,
                        ),
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final bool isPassword;
  final TextEditingController controller;

  InputField({required this.icon, required this.hintText, this.isPassword = false, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[600]),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              obscureText: isPassword,
              controller: controller,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.black),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


