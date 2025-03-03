import 'dart:io'; // For File Handling
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For Timestamp Formatting
import 'package:geolocator/geolocator.dart'; // For Geolocation
import 'location_service.dart'; // Import Location Service

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
  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool isCameraInitialized = false;
  bool isError = false;
  bool isLoading = false;
  String? imagePath;
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    fetchLocation(); // Fetch location on startup
  }

  /// Initializes the front camera
  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          isError = true;
        });
        return;
      }

      _controller = CameraController(
        cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front),
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      setState(() {
        isCameraInitialized = true;
      });
    } catch (e) {
      print("❌ Camera error: $e");
      setState(() {
        isError = true;
      });
    }
  }

  /// Fetches the current location of the user
  Future<void> fetchLocation() async {
    try {
      Position position = await LocationService.getUserLocation();
      setState(() {
        userPosition = position;
      });
    } catch (e) {
      print("❌ Location error: $e");
    }
  }

  /// Captures a selfie and retrieves the timestamp & location
  Future<void> captureSelfie() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print("⚠️ Camera not initialized!");
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final XFile image = await _controller!.takePicture();

      // Fetch user location before capturing
      Position currentPosition = await LocationService.getUserLocation();
      String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      setState(() {
        imagePath = image.path;
        userPosition = currentPosition;
        isLoading = false;
      });

      print("📸 Image Captured: ${image.path}");
      print("⏳ Timestamp: $formattedTime");
      print("📍 Location: ${currentPosition.latitude}, ${currentPosition.longitude}");

      // Return the captured image with data
      Navigator.pop(context, {
        'imagePath': image.path,
        'timestamp': formattedTime,
        'latitude': currentPosition.latitude,
        'longitude': currentPosition.longitude,
      });

    } catch (e) {
      print("❌ Error capturing selfie: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isError
          ? Center(child: Text("Error initializing camera"))
          : isCameraInitialized
          ? Stack(
        children: [
          CameraPreview(_controller!),
          Align(
            alignment: Alignment.bottomCenter,
            child: isLoading
                ? CircularProgressIndicator()
                : IconButton(
              icon: Icon(Icons.camera, size: 50, color: Colors.white),
              onPressed: isLoading ? null : captureSelfie, // Prevent multiple clicks
            ),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
      floatingActionButton: imagePath != null
          ? FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Captured Image"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  imagePath != null
                      ? Image.file(File(imagePath!), height: 250, fit: BoxFit.cover)
                      : Text("No Image Captured"),
                  SizedBox(height: 10),
                  if (userPosition != null)
                    Text("📍 Latitude: ${userPosition!.latitude}, Longitude: ${userPosition!.longitude}"),
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
        child: Icon(Icons.image),
      )
          : null,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
