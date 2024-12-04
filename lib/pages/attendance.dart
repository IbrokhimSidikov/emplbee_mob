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
            await _createWorkEntry();
            await _saveAttendanceStatus(true);
            print("Face recognized. Check-in successful.");
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Check-in successful!")));
          } else {
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
          if (isCameraInitialized)
            Stack(
              children: [
                CameraPreview(controller!),
                CustomPaint(
                  painter: FaceOverlayPainter(),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
              ],
            )
          else
            Center(child: CircularProgressIndicator()),
          if (isLoading) 
            Container(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),
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

class FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw dark overlay for the entire screen
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Calculate face oval dimensions
    final double ovalWidth = size.width * 0.65;
    final double ovalHeight = size.height * 0.45;
    final double centerX = size.width / 2;
    final double centerY = size.height * 0.4;

    // Create oval path for the face outline
    final ovalRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: ovalWidth,
      height: ovalHeight,
    );
    final ovalPath = Path()..addOval(ovalRect);

    // Cut out the oval from the dark overlay
    canvas.drawPath(
      ovalPath,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.clear,
    );

    // Draw the bright outline
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Add glow effect
    outlinePaint.maskFilter = MaskFilter.blur(BlurStyle.outer, 3);
    
    canvas.drawPath(ovalPath, outlinePaint);

    // Add guiding text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Position your face within the outline',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        centerY + ovalHeight / 2 + 20,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
