import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final ApiService _apiService = ApiService();

  void _handleRegister() async {
    try {
      await _apiService.register(
          _nameController.text,
          _emailController.text,
          _passController.text
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đăng ký thành công!")));
      Navigator.pop(context); // Quay về màn hình đăng nhập
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đăng Ký Tài Khoản")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Họ và tên")),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: _passController, decoration: InputDecoration(labelText: "Mật khẩu"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _handleRegister, child: Text("Đăng Ký Ngay")),
          ],
        ),
      ),
    );
  }
}