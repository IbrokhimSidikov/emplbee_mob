import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/face_recognition_service.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  CameraDescription? selectedCamera;
  bool isCameraInitialized = false;
  final String personId = 'b50d5157-27d6-11ef-86d3-0242ac120002'; // Use your existing UUID

  final FaceRecognitionService faceRecognitionService =
      FaceRecognitionService('719876f955a84032a0e25193c4f103e2');

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      // Select the front camera if available
      selectedCamera = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras!.first,
      );

      controller = CameraController(selectedCamera!, ResolutionPreset.high);
      await controller!.initialize();
      setState(() {
        isCameraInitialized = true;
      });
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> captureImage() async {
    try {
      if (controller != null && controller!.value.isInitialized) {
        print("Camera is initialized. Capturing image...");
        final image = await controller!.takePicture();
        print("Image captured at path: ${image.path}");

        bool isVerified = await faceRecognitionService
            .checkInWithFaceRecognition(image.path, personId);
        if (isVerified) {
          print("Face recognized. Check-in successful.");
          // Handle successful check-in, e.g., show a success message or update the UI
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Check-in successful!")));
        } else {
          print("Face not recognized.");
          // Handle face not recognized, e.g., show an error message
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Face not recognized.")));
        }
      } else {
        print("Camera is not initialized.");
      }
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance")),
      body: isCameraInitialized
          ? CameraPreview(controller!)
          : Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: captureImage,
        child: Icon(Icons.camera),
      ),
    );
  }
}
