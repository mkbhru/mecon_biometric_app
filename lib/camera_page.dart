// import 'dart:io'; // For File
// import 'dart:typed_data'; // For Uint8List
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart'; // For kIsWeb
//
// class CameraPage extends StatefulWidget {
//   @override
//   _CameraPageState createState() => _CameraPageState();
// }
//
// class _CameraPageState extends State<CameraPage> {
//   CameraController? _controller;
//   late List<CameraDescription> cameras;
//   bool isCameraInitialized = false;
//   bool isError = false;
//   Uint8List? _imageBytes; // ✅ Used for Web & Mobile
//
//   @override
//   void initState() {
//     super.initState();
//     initializeCamera();
//   }
//
//   Future<void> initializeCamera() async {
//     try {
//       cameras = await availableCameras();
//
//       if (cameras.isEmpty) {
//         setState(() {
//           isError = true;
//         });
//         return;
//       }
//
//       _controller = CameraController(cameras.first, ResolutionPreset.medium);
//       await _controller!.initialize();
//
//       setState(() {
//         isCameraInitialized = true;
//       });
//     } catch (e) {
//       print("Camera error: $e");
//       setState(() {
//         isError = true;
//       });
//     }
//   }
//
//   Future<void> captureSelfie() async {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return;
//     }
//
//     try {
//       final XFile image = await _controller!.takePicture();
//
//       if (kIsWeb) {
//         // ✅ Convert image to bytes for Web
//         Uint8List bytes = await image.readAsBytes();
//         setState(() {
//           _imageBytes = bytes;
//         });
//       } else {
//         // ✅ Send image path for Mobile
//         Navigator.pop(context, image.path);
//       }
//     } catch (e) {
//       print("Error capturing selfie: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: isError
//           ? Center(child: Text("Error initializing camera"))
//           : isCameraInitialized
//           ? Stack(
//         children: [
//           CameraPreview(_controller!),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: IconButton(
//               icon: Icon(Icons.camera, size: 50, color: Colors.white),
//               onPressed: captureSelfie,
//             ),
//           ),
//         ],
//       )
//           : Center(child: CircularProgressIndicator()),
//       floatingActionButton: _imageBytes != null
//           ? FloatingActionButton(
//         onPressed: () {
//           showDialog(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: Text("Captured Image"),
//               content: Image.memory(_imageBytes!), // ✅ Works for Web & Mobile
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text("OK"),
//                 ),
//               ],
//             ),
//           );
//         },
//         child: Icon(Icons.image),
//       )
//           : null,
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }
// }


import 'dart:io'; // For File
import 'dart:typed_data'; // For Uint8List
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:intl/intl.dart'; // ✅ For Timestamp Formatting
import 'package:geolocator/geolocator.dart'; // ✅ For Geolocation
import 'location_service.dart'; // ✅ Import Location Service

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool isCameraInitialized = false;
  bool isError = false;
  Uint8List? _imageBytes; // ✅ Used for Web & Mobile
  String? timestamp; // ✅ Store Timestamp
  Position? position; // ✅ Store Location

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          isError = true;
        });
        return;
      }

      _controller = CameraController(cameras.first, ResolutionPreset.medium);
      await _controller!.initialize();

      setState(() {
        isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera error: $e");
      setState(() {
        isError = true;
      });
    }
  }

  Future<void> captureSelfie() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      // ✅ Take a Picture
      final XFile image = await _controller!.takePicture();

      // ✅ Get Current Timestamp
      String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // ✅ Get Current Location
      Position currentPosition = await LocationService.getUserLocation();

      setState(() {
        timestamp = formattedTime;
        position = currentPosition;
      });

      if (kIsWeb) {
        // ✅ Convert image to bytes for Web
        Uint8List bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        // ✅ Send image path for Mobile along with timestamp & location
        Navigator.pop(context, {
          'imagePath': image.path,
          'timestamp': formattedTime,
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
        });
      }

      print("📸 Image Path: ${image.path}");
      print("⏳ Timestamp: $formattedTime");
      print("📍 Location: ${currentPosition.latitude}, ${currentPosition.longitude}");

    } catch (e) {
      print("Error capturing selfie: $e");
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
            child: IconButton(
              icon: Icon(Icons.camera, size: 50, color: Colors.white),
              onPressed: captureSelfie,
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
              title: Text("Captured Image"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.memory(_imageBytes!), // ✅ Works for Web & Mobile
                  SizedBox(height: 10),
                  Text("📅 Timestamp: $timestamp"),
                  Text("📍 Location: ${position?.latitude}, ${position?.longitude}"),
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
