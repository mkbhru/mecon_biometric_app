import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}


class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool isCameraInitialized = false;
  bool isError = false;

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
      final XFile image = await _controller!.takePicture();
      Navigator.pop(context, image.path);
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
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
