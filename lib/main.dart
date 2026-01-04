import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart'; // <--- Nhớ import MainScreen
import 'services/notification_service.dart'; // Để khởi tạo timezone ngay từ đầu

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo dịch vụ thông báo sớm
  final NotificationService notificationService = NotificationService();
  await notificationService.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lịch Cá Nhân',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CheckAuth(), // Gọi widget kiểm tra đăng nhập
    );
  }
}

class CheckAuth extends StatefulWidget {
  @override
  _CheckAuthState createState() => _CheckAuthState();
}

class _CheckAuthState extends State<CheckAuth> {
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    setState(() {
      _isLoggedIn = token != null; // Có token nghĩa là đã đăng nhập
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- QUAN TRỌNG: NẾU ĐÃ ĐĂNG NHẬP THÌ VÀO MAINSCREEN ---
    return _isLoggedIn ? MainScreen() : LoginScreen();
  }
}