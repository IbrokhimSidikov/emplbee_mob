import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/face_recognition_service.dart';
import 'dart:convert';

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
  bool isCheckedIn = false;
  String? activeWorkEntryId;
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _loadAttendanceStatus();
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

  Future<void> _loadAttendanceStatus() async {
    final status = await _storage.read(key: 'attendance_status');
    final entryId = await _storage.read(key: 'active_work_entry');
    setState(() {
      isCheckedIn = status == 'checked_in';
      activeWorkEntryId = entryId;
    });
  }

  Future<void> _saveAttendanceStatus(bool isCheckedIn) async {
    await _storage.write(
      key: 'attendance_status',
      value: isCheckedIn ? 'checked_in' : 'checked_out',
    );
    setState(() {
      this.isCheckedIn = isCheckedIn;
    });
  }

  Future<void> _createWorkEntry() async {
    final now = DateTime.now();
    final newEntry = {
      'id': now.millisecondsSinceEpoch.toString(),
      'checkIn': now.toIso8601String(),
      'checkOut': null,
    };

    // Load existing entries
    final entriesJson = await _storage.read(key: 'work_entries') ?? '[]';
    final List<dynamic> entries = json.decode(entriesJson);
    entries.add(newEntry);

    // Save updated entries
    await _storage.write(key: 'work_entries', value: json.encode(entries));
    await _storage.write(key: 'active_work_entry', value: newEntry['id']);
    activeWorkEntryId = newEntry['id'];
  }

  Future<void> _completeWorkEntry() async {
    if (activeWorkEntryId == null) return;

    // Load existing entries
    final entriesJson = await _storage.read(key: 'work_entries') ?? '[]';
    final List<dynamic> entries = json.decode(entriesJson);

    // Find and update the active entry
    for (var i = 0; i < entries.length; i++) {
      if (entries[i]['id'] == activeWorkEntryId) {
        entries[i]['checkOut'] = DateTime.now().toIso8601String();
        break;
      }
    }

    // Save updated entries
    await _storage.write(key: 'work_entries', value: json.encode(entries));
    await _storage.delete(key: 'active_work_entry');
    activeWorkEntryId = null;
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
          if (!isCheckedIn) {
            // Handling check-in
            await _createWorkEntry();
            await _saveAttendanceStatus(true);
            print("Face recognized. Check-in successful.");
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Check-in successful!")));
          } else {
            // Handling check-out
            await _completeWorkEntry();
            await _saveAttendanceStatus(false);
            print("Face recognized. Check-out successful.");
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Check-out successful!")));
          }
          Navigator.pop(context, true);
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
