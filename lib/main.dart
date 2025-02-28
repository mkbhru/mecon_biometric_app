import 'dart:io';
import 'package:flutter/material.dart';
import 'camera_page.dart';
import 'location_service.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MaterialApp(home: AttendancePage(), debugShowCheckedModeBanner: false));
}

class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String? imagePath;
  Position? userPosition;
  bool isLoading = false;

  Future<void> takeAttendance() async {
    setState(() => isLoading = true);

    // Open camera to capture selfie
    final path = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraPage()),
    );

    if (path != null) {
      setState(() => imagePath = path);

      // Fetch user location
      try {
        userPosition = await LocationService.getUserLocation();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location error: $e")));
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance System"), centerTitle: true),
      body: Center(
        child: isLoading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Processing, please wait..."),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            imagePath != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(File(imagePath!), height: 250, fit: BoxFit.cover),
            )
                : Icon(Icons.person, size: 150, color: Colors.grey),
            SizedBox(height: 20),
            if (userPosition != null)
              Text(
                "Latitude: ${userPosition!.latitude}, Longitude: ${userPosition!.longitude}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: takeAttendance,
              icon: Icon(Icons.camera_alt),
              label: Text("Take Selfie"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

