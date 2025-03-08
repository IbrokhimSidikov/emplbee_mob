import 'package:camera/camera.dart';
import 'package:emplbee_mob/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/face_recognition_service.dart';
import 'dart:convert';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  CameraController? controller;
  List<CameraDescription>? cameras;
  CameraDescription? selectedCamera;
  bool isCameraInitialized = false;
  final String personId = 'b50d5157-27d6-11ef-86d3-0242ac120002';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
    initializeCamera();
    _loadAttendanceStatus();
  }

  @override
  void dispose() {
    controller?.dispose();
    _animationController.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCheckedIn
                          ? AppLocalizations.of(context).checkOutTitle
                          : AppLocalizations.of(context).checkInTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  AppLocalizations.of(context).faceIddescription,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Camera Preview
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        if (isCameraInitialized)
                          Stack(
                            children: [
                              SizedBox.expand(
                                child: CameraPreview(controller!),
                              ),
                              CustomPaint(
                                painter: FaceOverlayPainter(),
                                size: Size.infinite,
                              ),
                            ],
                          )
                        else
                          Container(
                            color: Colors.blue.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (isLoading)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context).verifying,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (isVerified != null && !isLoading)
                          Container(
                            color: isVerified!
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isVerified!
                                        ? Icons.check_circle_outline
                                        : Icons.error_outline,
                                    color: Colors.white,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    isVerified!
                                        ? 'Face recognized!'
                                        : 'Face not recognized',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Capture Button
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: ElevatedButton(
                  onPressed: isLoading ? null : captureImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckedIn ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isCheckedIn ? Icons.logout : Icons.login),
                      const SizedBox(width: 8),
                      Text(
                        isCheckedIn ? 'Check Out' : 'Check In',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.blue.withOpacity(0.5);

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width * 0.4;

    // Draw outer circle
    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    // Draw corner markers
    final markerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blue;

    final markerLength = radius * 0.2;

    // Top-left markers
    canvas.drawLine(
      Offset(centerX - radius, centerY - radius),
      Offset(centerX - radius + markerLength, centerY - radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(centerX - radius, centerY - radius),
      Offset(centerX - radius, centerY - radius + markerLength),
      markerPaint,
    );

    // Top-right markers
    canvas.drawLine(
      Offset(centerX + radius, centerY - radius),
      Offset(centerX + radius - markerLength, centerY - radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(centerX + radius, centerY - radius),
      Offset(centerX + radius, centerY - radius + markerLength),
      markerPaint,
    );

    // Bottom-left markers
    canvas.drawLine(
      Offset(centerX - radius, centerY + radius),
      Offset(centerX - radius + markerLength, centerY + radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(centerX - radius, centerY + radius),
      Offset(centerX - radius, centerY + radius - markerLength),
      markerPaint,
    );

    // Bottom-right markers
    canvas.drawLine(
      Offset(centerX + radius, centerY + radius),
      Offset(centerX + radius - markerLength, centerY + radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(centerX + radius, centerY + radius),
      Offset(centerX + radius, centerY + radius - markerLength),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
