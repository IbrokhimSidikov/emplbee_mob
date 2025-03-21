import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'whatsNew': 'WHAT\'S NEW',
      'hello': 'Hello',
      'welcome': 'Welcome back!',
      'welcomeTitle': 'What would you like to do today?',
      'profile': 'Profile',
      'attendance': 'Attendance',
      'attendanceList': 'Attendance List',
      'tasks': 'Tasks',
      'notifications': 'Notifications',
      'settings': 'Settings',

      // Profile page
      'totalHours': 'Total Hours',
      'monthlyHours': 'Monthly Hours',
      'availableOffDays': 'Available Off Days',
      'monthlySalary': 'Monthly Salary',
      'quickActions': 'Quick Actions',
      'requestTimeOff': 'Request Time Off',
      'viewAttendanceHistory': 'View Attendance History',
      'downloadPayslip': 'Download Payslip',
      'logout': 'Logout',

      // Onboard page
      'onboardTitle': 'Welcome to Emplbee',
      'onboardSubtitle': 'Your comprehensive employee management solution',
      'onboardButton': 'Get Started',

      // Attendance List
      'attendanceHistory': 'Attendance History',
      'entries': 'Entries',
      'date': 'Date',
      'checkIn': 'Check In',
      'checkOut': 'Check Out',
      'inProgress': 'In Progress',
      'completed': 'Completed',
      'duration': 'Duration',

      // Attendance
      'checkInTitle': 'Check In',
      'checkOutTitle': 'Check Out',
      'faceIddescription': 'Please position your face within the frame',
      'verifying': 'Verifying',
      'loadingAttendance': 'Loading Attendance',

      // Tasks
      'loadingTasks': 'Loading Tasks',
      'subtasks': 'Subtasks',
      'description': 'Description',
      'start': 'Start',
      'end': 'End',
      'status': 'Status',
      'tags': 'Tags',
      'myTasks': 'My Tasks',

      // Notifications
      'markAllAsRead': 'Mark all as read',
    },
    'uz': {
      'whatsNew': 'YANGILIKLAR',
      'hello': 'Salom',
      'welcome': 'Ilovamizga xush kelibsiz',
      'welcomeTitle': 'Bugun nima qilmoqchisiz?',
      'profile': 'Profil',
      'attendance': 'Keldi-ketdi',
      'attendanceList': 'Keldi-ketdi ro\'yxati',
      'tasks': 'Vazifalar',
      'notifications': 'Xabarlar',
      'settings': 'Sozlamalar',

      // Profile page
      'totalHours': 'Jami soat',
      'monthlyHours': 'O\'rtacha soat',
      'availableOffDays': 'Dam olish kunlari',
      'monthlySalary': 'Oylik maosh',
      'quickActions': 'Qo\'shimcha qulayliklar',
      'requestTimeOff': 'Dam olish so\'rovi',
      'viewAttendanceHistory': 'Keldi-ketdi tarihlar',
      'downloadPayslip': 'Oylik maosh yuklab olish',
      'logout': 'Chiqish',

      // Onboard page
      'onboardTitle': 'Emplbee ga xush kelibsiz',
      'onboardSubtitle': 'Xodimlarni boshqarishning eng qulay tizimi',
      'onboardButton': 'Boshlash',

      // Attendance List page
      'attendanceHistory': 'Keldi-ketdi tarixlari',
      'entries': 'Umumiy',
      'date': 'Sana',
      'checkIn': 'Boshladi',
      'checkOut': 'Yakunladi',
      'inProgress': 'Davom etmoqda',
      'completed': 'Tugatilgan',
      'duration': 'Davomiyligi',

      // Attendance
      'checkInTitle': 'Ish boshlash',
      'checkOutTitle': 'Ish yakunlash',
      'faceIddescription': 'Yuzingizni belgilangan hududga moslang',
      'verifying': 'Tasdiqlanmoqda',
      'loadingAttendance': 'Keldi-ketdi yuklanmoqda',

      // Tasks
      'loadingTasks': 'Vazifalar yuklanmoqda',
      'subtasks': 'Qo\'shimcha vazifalar',
      'description': 'Tasvir',
      'start': 'Boshlanish',
      'end': 'Yakunlash',
      'status': 'Status',
      'tags': 'Teglar',
      'myTasks': 'Mening vazifalarim',

      // Notifications
      'markAllAsRead': 'Hammasini o\'qish',
    }
  };
  String get whatsNew => _localizedValues[locale.languageCode]!['whatsNew']!;
  String get hello => _localizedValues[locale.languageCode]!['hello']!;
  String get welcome => _localizedValues[locale.languageCode]!['welcome']!;
  String get welcomeTitle =>
      _localizedValues[locale.languageCode]!['welcomeTitle']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get attendance =>
      _localizedValues[locale.languageCode]!['attendance']!;
  String get attendanceList =>
      _localizedValues[locale.languageCode]!['attendanceList']!;
  String get tasks => _localizedValues[locale.languageCode]!['tasks']!;
  String get notifications =>
      _localizedValues[locale.languageCode]!['notifications']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;

  // Profile page
  String get totalHours =>
      _localizedValues[locale.languageCode]!['totalHours']!;
  String get monthlyHours =>
      _localizedValues[locale.languageCode]!['monthlyHours']!;
  String get availableOffDays =>
      _localizedValues[locale.languageCode]!['availableOffDays']!;
  String get monthlySalary =>
      _localizedValues[locale.languageCode]!['monthlySalary']!;
  String get quickActions =>
      _localizedValues[locale.languageCode]!['quickActions']!;
  String get requestTimeOff =>
      _localizedValues[locale.languageCode]!['requestTimeOff']!;
  String get viewAttendanceHistory =>
      _localizedValues[locale.languageCode]!['viewAttendanceHistory']!;
  String get downloadPayslip =>
      _localizedValues[locale.languageCode]!['downloadPayslip']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;

  // Onboard page
  String get onboardTitle =>
      _localizedValues[locale.languageCode]!['onboardTitle']!;
  String get onboardSubtitle =>
      _localizedValues[locale.languageCode]!['onboardSubtitle']!;
  String get onboardButton =>
      _localizedValues[locale.languageCode]!['onboardButton']!;

  // Attendance List page
  String get attendanceHistory =>
      _localizedValues[locale.languageCode]!['attendanceHistory']!;
  String get entries => _localizedValues[locale.languageCode]!['entries']!;
  String get date => _localizedValues[locale.languageCode]!['date']!;
  String get checkIn => _localizedValues[locale.languageCode]!['checkIn']!;
  String get checkOut => _localizedValues[locale.languageCode]!['checkOut']!;
  String get inProgress =>
      _localizedValues[locale.languageCode]!['inProgress']!;
  String get completed => _localizedValues[locale.languageCode]!['completed']!;
  String get duration => _localizedValues[locale.languageCode]!['duration']!;

  // Attendance page
  String get checkInTitle =>
      _localizedValues[locale.languageCode]!['checkInTitle']!;
  String get checkOutTitle =>
      _localizedValues[locale.languageCode]!['checkOutTitle']!;
  String get faceIddescription =>
      _localizedValues[locale.languageCode]!['faceIddescription']!;
  String get verifying => _localizedValues[locale.languageCode]!['verifying']!;
  String get loadingAttendance =>
      _localizedValues[locale.languageCode]!['loadingAttendance']!;

  // Tasks
  String get loadingTasks =>
      _localizedValues[locale.languageCode]!['loadingTasks']!;
  String get subtasks => _localizedValues[locale.languageCode]!['subtasks']!;
  String get description =>
      _localizedValues[locale.languageCode]!['description']!;
  String get start => _localizedValues[locale.languageCode]!['start']!;
  String get end => _localizedValues[locale.languageCode]!['end']!;
  String get status => _localizedValues[locale.languageCode]!['status']!;
  String get tags => _localizedValues[locale.languageCode]!['tags']!;
  String get myTasks => _localizedValues[locale.languageCode]!['myTasks']!;

  // Notifications
  String get markAllAsRead =>
      _localizedValues[locale.languageCode]!['markAllAsRead']!;
}
