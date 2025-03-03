import 'dart:io'; // For File Handling (Only for Mobile)
import 'dart:typed_data'; // For Image Bytes (For Web & Mobile)
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:intl/intl.dart'; // ✅ For Timestamp Formatting
import 'package:geolocator/geolocator.dart'; // ✅ For Geolocation
import 'location_service.dart'; // ✅ Import Location Service
import 'package:audioplayers/audioplayers.dart'; // ✅ Audio for Shutter Sound

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool isCameraInitialized = false;
  bool isError = false;
  bool isLoading = false; // ✅ Added Loading Flag
  Uint8List? _imageBytes; // ✅ Used for Web & Mobile
  String? timestamp; // ✅ Store Timestamp
  Position? position; // ✅ Store Location
  final AudioPlayer _audioPlayer = AudioPlayer(); // ✅ Audio Player for Shutter Sound

  @override
  void initState() {
    super.initState();
    initializeCamera();
    fetchLocation(); // ✅ Fetch Location Automatically
  }

  /// ✅ Initializes the front camera
  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() => isError = true);
        return;
      }

      // ✅ Select Front Camera
      _controller = CameraController(
        cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front),
        ResolutionPreset.medium,
        enableAudio: false, // ✅ Disable audio for better performance
      );

      await _controller!.initialize();
      setState(() => isCameraInitialized = true);
    } catch (e) {
      print("❌ Camera error: $e");
      setState(() => isError = true);
    }
  }

  /// ✅ Fetch location automatically
  Future<void> fetchLocation() async {
    try {
      position = await LocationService.getUserLocation();
      setState(() {}); // ✅ Update UI after fetching location
    } catch (e) {
      print("❌ Location error: $e");
    }
  }

  /// ✅ Captures a selfie and saves timestamp & location
  Future<void> captureSelfie() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print("⚠️ Camera not initialized!");
      return;
    }

    try {
      setState(() => isLoading = true); // ✅ Start Loading

      // ✅ Play shutter sound
      await _audioPlayer.play(AssetSource("sounds/shutter.mp3"));

      // ✅ Capture the image
      final XFile image = await _controller!.takePicture();

      // ✅ Get Current Timestamp
      String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // ✅ Fetch user location
      Position currentPosition = await LocationService.getUserLocation();

      Uint8List bytes;
      if (kIsWeb) {
        // ✅ Convert image to bytes for Web
        bytes = await image.readAsBytes();
      } else {
        // 🔹 Load the image properly to avoid OpenGL issues (For Mobile)
        bytes = await File(image.path).readAsBytes();
      }

      setState(() {
        _imageBytes = bytes; // ✅ Store Image Bytes
        timestamp = formattedTime;
        position = currentPosition;
        isLoading = false; // ✅ Stop Loading
      });

      print("📸 Image Captured: ${image.path}");
      print("⏳ Timestamp: $formattedTime");
      print("📍 Location: ${currentPosition.latitude}, ${currentPosition.longitude}");

      // ✅ Return captured image with metadata
      Navigator.pop(context, {
        'imagePath': image.path,
        'timestamp': formattedTime,
        'latitude': currentPosition.latitude,
        'longitude': currentPosition.longitude,
      });

    } catch (e) {
      print("❌ Error capturing selfie: $e");
    } finally {
      setState(() => isLoading = false); // ✅ Ensure loading stops
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isError
          ? Center(child: Text("❌ Error initializing camera"))
          : isCameraInitialized
          ? Stack(
        children: [
          CameraPreview(_controller!),
          Align(
            alignment: Alignment.bottomCenter,
            child: isLoading
                ? CircularProgressIndicator() // ✅ Show Loading Indicator
                : IconButton(
              icon: Icon(Icons.camera, size: 50, color: Colors.red),
              onPressed: isLoading ? null : captureSelfie, // ✅ Prevent Multiple Clicks
            ),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
      floatingActionButton: _imageBytes != null
          ? FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("📸 Captured Image"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _imageBytes != null
                      ? Image.memory(
                    _imageBytes!,
                    gaplessPlayback: true, // 🔹 Prevents Flickering
                    fit: BoxFit.cover, // 🔹 Proper Scaling
                  )
                      : Text("No Image Captured"), // 🔹 Prevents Empty UI Crash
                  SizedBox(height: 10),
                  Text("📅 Timestamp: $timestamp"),
                  if (position != null)
                    Text("📍 Latitude: ${position!.latitude}, Longitude: ${position!.longitude}"),
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
    _audioPlayer.dispose();
    super.dispose();
  }
}
