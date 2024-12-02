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
  final String personId = 'b50d5157-27d6-11ef-86d3-0242ac120002';

  final FaceRecognitionService faceRecognitionService =
      FaceRecognitionService('719876f955a84032a0e25193c4f103e2');

  bool isLoading = false;
  bool? isVerified;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
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
    setState(() {
      isLoading = true;
      isVerified = null;
    });

    try {
      if (controller != null && controller!.value.isInitialized) {
        print("Camera is initialized. Capturing image...");
        final image = await controller!.takePicture();
        print("Image captured at path: ${image.path}");

        bool verificationResult = await faceRecognitionService
            .checkInWithFaceRecognition(image.path, personId);
        setState(() {
          isVerified = verificationResult;
        });

        if (verificationResult) {
          print("Face recognized. Check-in successful.");
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Check-in successful!")));
          Navigator.pop(context, true); // Return true to parent page
        } else {
          print("Face not recognized.");
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Face not recognized.")));
        }
      } else {
        print("Camera is not initialized.");
      }
    } catch (e) {
      print("Error capturing image: $e");
      setState(() {
        isVerified = false;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
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
      appBar: AppBar(
        title: Text("Attendance"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          isCameraInitialized
              ? CameraPreview(controller!)
              : Center(child: CircularProgressIndicator()),
          if (isLoading) Center(child: CircularProgressIndicator()),
          if (isVerified != null && !isLoading)
            Center(
              child: Icon(
                isVerified! ? Icons.check_circle : Icons.error,
                color: isVerified! ? Colors.green : Colors.red,
                size: 100,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: captureImage,
        child: Icon(Icons.camera),
      ),
    );
  }
}
