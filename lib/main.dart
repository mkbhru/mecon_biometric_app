import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ Detects Web
import 'camera_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AttendancePage(),
    );
  }
}

class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String? imagePath;
  Uint8List? imageBytes;
  String? timestamp;
  double? latitude;
  double? longitude;

  /// Open Camera and retrieve image data
  Future<void> openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraPage()),
    );

    if (result != null) {
      setState(() {
        timestamp = result['timestamp'];
        latitude = result['latitude'];
        longitude = result['longitude'];

        if (kIsWeb) {
          imageBytes = result['imageBytes']; // ✅ Web Fix
        } else {
          imagePath = result['imagePath']; // ✅ Mobile Fix
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance System")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: openCamera,
              child: Text("Capture Selfie"),
            ),

            SizedBox(height: 20),

            // ✅ Show captured image with timestamp & coordinates
            if ((kIsWeb && imageBytes != null) || (!kIsWeb && imagePath != null))
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Captured Image"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          kIsWeb
                              ? Image.memory(imageBytes!, fit: BoxFit.cover) // ✅ Web Fix
                              : Image.file(File(imagePath!), fit: BoxFit.cover), // ✅ Mobile Fix
                          SizedBox(height: 10),
                          Text("📅 Timestamp: $timestamp"),
                          Text("📍 Latitude: $latitude"),
                          Text("📍 Longitude: $longitude"),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                },
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: kIsWeb
                          ? Image.memory(imageBytes!, width: 100, height: 100, fit: BoxFit.cover) // ✅ Web Fix
                          : Image.file(File(imagePath!), width: 100, height: 100, fit: BoxFit.cover), // ✅ Mobile Fix
                    ),
                    SizedBox(height: 5),
                    Text("📅 $timestamp", style: TextStyle(fontSize: 12)),
                    Text("📍 ${latitude?.toStringAsFixed(5)}, ${longitude?.toStringAsFixed(5)}", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
