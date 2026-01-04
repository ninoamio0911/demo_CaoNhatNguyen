import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = "Người dùng";
  String _role = "Staff";
  bool _isAdmin = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _notificationService.init();
  }

  void _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('fullName') ?? "Người dùng";
      _role = prefs.getString('role') ?? "Staff";
      _isAdmin = (_role == "Admin");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cá Nhân"), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Avatar và Tên
          Center(
            child: Column(
              children: [
                CircleAvatar(radius: 40, child: Text(_fullName[0], style: TextStyle(fontSize: 30))),
                SizedBox(height: 10),
                Text(_fullName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text("Chức vụ: $_role", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          SizedBox(height: 30),

          // Mục Quản trị (Chỉ hiện nếu là Admin)
          if (_isAdmin)
            Card(
              child: ListTile(
                leading: Icon(Icons.admin_panel_settings, color: Colors.red),
                title: Text("Quản Trị Hệ Thống"),
                subtitle: Text("Quản lý nhân viên"),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AdminScreen()));
                },
              ),
            ),

          // Test Thông Báo
          Card(
            child: ListTile(
              leading: Icon(Icons.notifications_active, color: Colors.orange),
              title: Text("Test Thông Báo"),
              onTap: () async {
                await _notificationService.showInstantNotification();
              },
            ),
          ),

          // Đăng Xuất
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.black),
              title: Text("Đăng Xuất"),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}