import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class OtpScreen extends StatefulWidget {
  final int userId;
  OtpScreen({required this.userId});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final ApiService _apiService = ApiService();

  void _verifyOtp() async {
    try {
      await _apiService.verifyOtp(widget.userId, _otpController.text);

      // Nếu thành công -> Vào trang chủ (MainScreen)
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (route) => false
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP Sai: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Xác thực OTP qua email")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Vui lòng nhập mã OTP đã gửi về Email "),
            TextField(controller: _otpController, decoration: InputDecoration(labelText: "Vui lòng nhập mã 6 số")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _verifyOtp, child: Text("Xác Nhận"))
          ],
        ),
      ),
    );
  }
}
