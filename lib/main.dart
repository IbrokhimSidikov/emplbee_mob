import 'package:Emplbee/api/firebase_api.dart';
import 'package:Emplbee/firebase_options.dart';
import 'package:Emplbee/pages/home_page.dart';
import 'package:Emplbee/pages/notification_test_page.dart';
import 'package:Emplbee/pages/onboard_page.dart';
import 'package:Emplbee/pages/profile_page.dart';
import 'package:Emplbee/pages/tasks.dart';
import 'package:Emplbee/pages/attendance_list_page.dart';
import 'package:Emplbee/pages/attendance.dart';
import 'package:Emplbee/pages/notifications_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:Emplbee/pages/signin_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations_delegate.dart';
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await FirebaseApi().initNotifications();

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Emplbee',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('uz')],
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const OnBoardPage(),
        '/login': (context) => const SignIn(),
        '/homepage': (context) => const HomePage(),
        '/profilepage': (context) => const ProfilePage(),
        '/attendancelistpage': (context) => const AttendanceListPage(),
        '/attendancepage': (context) => AttendanceScreen(),
        '/taskspage': (context) => const TasksPage(),
        '/notificationspage': (context) => const NotificationsPage(),
        '/notificationtestpage': (context) => const NotificationTestPage(),
      },
    );
  }
}
