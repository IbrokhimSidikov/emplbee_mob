import 'package:emplbee_mob/api/firebase_api.dart';
import 'package:emplbee_mob/firebase_options.dart';
import 'package:emplbee_mob/pages/home_page.dart';
import 'package:emplbee_mob/pages/onboard_page.dart';
import 'package:emplbee_mob/pages/profile_page.dart';
import 'package:emplbee_mob/pages/attendance_list_page.dart';
import 'package:emplbee_mob/pages/tasks.dart';
import 'package:emplbee_mob/services/notification_service.dart';
import 'package:emplbee_mob/widget/camera_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:emplbee_mob/pages/signin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications using NotificationService
  await NotificationService().initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => OnBoardPage(),
        '/homepage': (context) => HomePage(),
        '/profilepage': (context) => ProfilePage(),
        '/attendancepage': (context) => AttendanceScreen(),
        '/attendancelistpage': (context) => AttendanceListPage(),
        '/taskspage': (context) => TasksPage(),
        '/signinpage': (context) => SignIn(),
      },
    );
  }
}
