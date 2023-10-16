import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'leave_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_bar.dart';
import 'positioned_button.dart';
import 'user_drawer.dart';
import 'right_drawer.dart';
import 'footer.dart';
import 'square_button.dart';
import 'checkin_popup.dart'; // Import the checkin_popup.dart file
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';


class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
 String checkInTimestamp = '';
String checkOutTimestamp = '';
String formattedCheckInTime = '';
String formattedCheckOutTime = '';

   String username = 'John Doe'; // Default username
  String userId = '12345'; // Default userId
    String comId = 'Candyland'; // Default userId


  @override
  void initState() {
    super.initState();
    // Retrieve username and userId from SharedPreferences
    retrieveUserData();
       retrieveCheckInTime();
  retrieveCheckoutTime();
  // Set up a timer to clear the stored times at midnight (12 AM)
    AndroidAlarmManager.periodic(const Duration(days: 1), 0, clearStoredTimes);

}

  Future<void> retrieveCheckInTime() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    checkInTimestamp = prefs.getString('checkinTime') ?? '';
  });
   
}

Future<void> retrieveCheckoutTime() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    checkOutTimestamp = prefs.getString('checkoutTime') ?? '';
  });
   
}
  Future<void> retrieveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('userName') ?? 'John Doe';
      userId = prefs.getString('userId') ?? '12345';
            userId = prefs.getString('ComID') ?? 'Candyland';

    });
  }

void clearStoredTimes() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.remove('checkinTime');
  prefs.remove('checkoutTime');
  setState(() {
    checkInTimestamp = '';
    checkOutTimestamp = '';
  });
}

 Future<void> checkIn() async {
  print("CheckIn button tapped.");

  // Retrieve the userID from shared preferences
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId') ?? '';

  // Get the current date and time
  final DateTime now = DateTime.now();
  final String checkInDate = now.toLocal().toString().split(' ')[0];
  final String checkInTime = DateFormat('h:mm a').format(now); 

  // Retrieve user data from SharedPreferences as a JSON string
  final userDataListJson = prefs.getStringList('userDataList') ?? [];
  final userDataList = userDataListJson.map((userDataJson) => json.decode(userDataJson)).toList();

  // Request location permission
  PermissionStatus permission = await Permission.location.request();

  if (permission.isGranted) {
    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Iterate through user data and check proximity
      for (final userData in userDataList) {
        final double? latitude = double.tryParse(userData['Latitude'] ?? '');
        final double? longitude = double.tryParse(userData['Longitude'] ?? '');

        if (latitude != null && longitude != null) {
          // Calculate the distance between current location and user data location
          final double distanceInMeters = await Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            latitude,
            longitude,
          );

        // Check if the distance is less than 300 meters
        if (distanceInMeters < 300) {
          // If the user is within 300 meters, make the API call
          final Map<String, String> requestData = {
            "UserID": userId,
            "CheckInDate": checkInDate,
            "CheckInTime": checkInTime,
            "CheckOutDate": '',
            "CheckOutTime": '',
            "CheckInLatLong": "${currentPosition.latitude},${currentPosition.longitude}",
            "CheckOutLatLong": '',
          };

          final String apiUrl = "http://202.61.46.140:80/UserValidate/User_Login.asmx/InsertUserAttendance";

          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
            },
            body: requestData,
          );

          if (response.statusCode == 200) {
             final xmlResponse = xml.XmlDocument.parse(response.body);

  // Extract the content of the <string> element
  final responseContent = xmlResponse.findAllElements('string').first.text;

  // Check if the response content contains "Done"
  if (responseContent == 'Done') {
            // Handle the successful API response as needed
            print("Check-in successful");
            setState(() {
        checkInTimestamp = "$checkInDate $checkInTime";
      });
final prefs = await SharedPreferences.getInstance();
    prefs.setString('checkinTime', checkInTimestamp);
            print("API Response: ${response.body}");
            Fluttertoast.showToast(
              msg: "CheckIn Done.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
            );

            // You can show a success message or navigate to a different page.
            return;
         } 
         } else {
            // Handle the API error
             Get.snackbar(
          "Error",
          "API response failed.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );

            print("Failed to check-in. Status code: ${response.statusCode}");
            // You can show an error message to the user.
            return;
          }
        }
      }
    }

    // If the loop finishes and no suitable location is found, show a message.
    Fluttertoast.showToast(
      msg: "No valid location found for check-in.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
    );
  } else {
    print("Location permission denied.");
    // You can show a dialog or toast indicating that location permission is required.
    Fluttertoast.showToast(
      msg: "Location permission is required to perform CheckIn.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
    );
  }
}

 Future<void> checkOut() async {
  print("CheckOut button tapped.");

  // Retrieve the userID from shared preferences
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId') ?? '';

  // Get the current date and time
  final DateTime now = DateTime.now();
  final String checkOutDate = now.toLocal().toString().split(' ')[0];
  final String checkOutTime = DateFormat('h:mm a').format(now); // Format in 12-hour format

  // Retrieve user data from SharedPreferences as a JSON string
  final userDataListJson = prefs.getStringList('userDataList') ?? [];
  final userDataList = userDataListJson.map((userDataJson) => json.decode(userDataJson)).toList();

  // Request location permission
  PermissionStatus permission = await Permission.location.request();

  if (permission.isGranted) {
    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Iterate through user data and check proximity
    for (final userData in userDataList) {
      final double? latitude = double.tryParse(userData['Latitude'] ?? '');
      final double? longitude = double.tryParse(userData['Longitude'] ?? '');

      if (latitude != null && longitude != null) {
        // Calculate the distance between current location and user data location
        final double distanceInMeters = await Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          latitude,
          longitude,
        );

        // Check if the distance is less than 300 meters
        if (distanceInMeters < 300) {
          // If the user is within 300 meters, make the API call
          final Map<String, String> requestData = {
            "UserID": userId,
            "CheckInDate": '',
            "CheckInTime": '',
            "CheckOutDate": checkOutDate,
            "CheckOutTime": checkOutTime,
            "CheckInLatLong": '',
            "CheckOutLatLong": "${currentPosition.latitude},${currentPosition.longitude}",
          };

          final String apiUrl = "http://202.61.46.140:80/UserValidate/User_Login.asmx/InsertUserAttendance";

          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
            },
            body: requestData,
          );

          if (response.statusCode == 200) {
            // Handle the successful API response as needed
            print("CheckOut successful");
            setState(() {
      checkOutTimestamp = "$checkOutTime";
    });

    // Save the checkout time to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('checkoutTime', checkOutTimestamp);
            print("API Response: ${response.body}");
            Fluttertoast.showToast(
              msg: "CheckOut Done.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
            );

            // You can show a success message or navigate to a different page.
            return;
          } else {
            Get.snackbar(
          "Error",
          "API response failed.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
            // Handle the API error
            print("Failed to check-out. Status code: ${response.statusCode}");
            // You can show an error message to the user.
            return;
          }
        }
      }
    }

    // If the loop finishes and no suitable location is found, show a message.
    Fluttertoast.showToast(
      msg: "No valid location found for check-out.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
    );
  } else {
    print("Location permission denied.");
    // You can show a dialog or toast indicating that location permission is required.
    Fluttertoast.showToast(
      msg: "Location permission is required to perform CheckOut.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
    );
  }
}

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 21, 111, 184),
        centerTitle: true,
        title: Text(
          "IIL HCM",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Handle logout logic here
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                username,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                "$comId", // Replace with user's designation
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 60.0,
                ),
              ),
            ),
            ListTile(
              title: Text('Item 1'),
              onTap: () {
                // Handle item 1 tap
              },
            ),
            ListTile(
              title: Text('Item 2'),
              onTap: () {
                // Handle item 2 tap
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.greenAccent],
          ),
        ),
        child: Column(
          children: [
            // User Information
            SizedBox(height: 20),
            Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(80),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Color.fromARGB(0, 185, 15, 15),
                    child: Icon(
                      Icons.person,
                      color: Color.fromARGB(255, 72, 221, 3),
                      size: 40.0,
                    ),
                  ),
                ),
                SizedBox(width: 8,),
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Welcome,",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "User ID: $userId",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 170),
            // CheckIn and CheckOut buttons
            Container(
              padding: EdgeInsets.all(5.0),
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Handle CheckIn button tap
                          checkIn();
                        },
                        child: Text("Check In"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        
                      ),
                        SizedBox(height: 10), // Add some spacing
      Text(
        "Check In Time: $checkInTimestamp", // Display the check-in timestamp
        style: TextStyle(
          fontSize: 10,
          color: Colors.white,
        ),
      ),
                    ],
                  ),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Handle CheckOut button tap
                          checkOut();
                        },
                        child: Text("Check Out"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                      ),
                       SizedBox(height: 10), // Add some spacing
      Text(
        "Check Out Time: $checkOutTimestamp", // Display the checkout timestamp
        style: TextStyle(
          fontSize: 10,
          color: Colors.white,
        ),
      ),
                    ],
                  ),
                ],
              ),
            ),
            // Four square buttons
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  margin: EdgeInsets.only(top: 100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSquareButton("Salary", Icons.attach_money),
                      SizedBox(width: 3,),
                      _buildSquareButton("Attendance", Icons.access_time),
                      SizedBox(width: 3,),
                      _buildSquareButton("Leaves", Icons.calendar_today),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareButton(String label, IconData icon) {
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 25,
            color: Colors.white,
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}