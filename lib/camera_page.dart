import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ Detects Web
import 'package:intl/intl.dart'; // ✅ For Timestamp Formatting
import 'package:geolocator/geolocator.dart'; // ✅ For GPS Coordinates

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool isCameraInitialized = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  /// Initializes the default camera
  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras.first, // ✅ Default Camera (Back or Front)
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      setState(() => isCameraInitialized = true);
    } catch (e) {
      print("❌ Camera error: $e");
    }
  }

  /// Fetches the current location of the user
  Future<Position> fetchLocation() async {
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("❌ Location error: $e");

      // ✅ FIX: Provide all required parameters for `Position`
      return Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0, // ✅ Fix: Required parameter added
        headingAccuracy: 0.0,  // ✅ Fix: Required parameter added
      );
    }
  }

  /// Captures a photo and retrieves timestamp & location
  Future<void> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() => isLoading = true);

      final XFile image = await _controller!.takePicture();
      Position position = await fetchLocation();
      String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      if (kIsWeb) {
        Uint8List bytes = await image.readAsBytes(); // ✅ Web Fix
        Navigator.pop(context, {
          'imageBytes': bytes,
          'timestamp': formattedTime,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      } else {
        Navigator.pop(context, {
          'imagePath': image.path,
          'timestamp': formattedTime,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }
    } catch (e) {
      print("❌ Error capturing image: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isCameraInitialized
          ? Stack(
        children: [
          CameraPreview(_controller!),
          Align(
            alignment: Alignment.bottomCenter,
            child: isLoading
                ? CircularProgressIndicator()
                : IconButton(
              icon: Icon(Icons.camera, size: 50, color: Colors.red),
              onPressed: isLoading ? null : capturePhoto,
            ),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
