import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Anh có thể đổi lại email/pass mặc định này thành rỗng khi muốn release app
  final TextEditingController _emailController = TextEditingController(text: "@gmail.com");
  final TextEditingController _passController = TextEditingController(text: "");
  final ApiService _apiService = ApiService();

  // Biến để ẩn/hiện mật khẩu (Thêm vào cho xịn)
  bool _isObscure = true;

  void _handleLogin() async {
    try {
      // 1. Gọi API Login
      final result = await _apiService.login(_emailController.text, _passController.text);

      int userId = result['userId'];

      // 2. Thông báo đã gửi mail
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã gửi OTP qua Email. Vui lòng kiểm tra hộp thư!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // Thông báo nổi lên trên đẹp hơn
          )
      );

      // 3. Chuyển sang màn hình nhập OTP
      Navigator.push(context, MaterialPageRoute(builder: (context) => OtpScreen(userId: userId)));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView( // Giúp cuộn được khi bàn phím hiện lên
        child: Container(
          height: size.height,
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- PHẦN LOGO & TIÊU ĐỀ ---
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.rectangle,
                  ),
                  child: Icon(Icons.calendar_month_rounded, size: 60, color: Colors.deepOrange),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "CALENDAR!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Quản lý lịch trình của bạn thật dễ dàng",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 40),

              // --- FORM NHẬP LIỆU ---
              // Ô Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              SizedBox(height: 16),

              // Ô Mật khẩu
              TextField(
                controller: _passController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              // Quên mật khẩu (Optional - Để giao diện cân đối hơn)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Xử lý quên mật khẩu sau này
                  },
                  child: Text("Quên mật khẩu?", style: TextStyle(color: Colors.blueAccent)),
                ),
              ),

              SizedBox(height: 20),

              // --- NÚT ĐĂNG NHẬP ---
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5, // Tạo bóng đổ nhẹ
                ),
                child: Text(
                  "Đăng Nhập",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 20),

              // --- CHUYỂN QUA ĐĂNG KÝ ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Chưa có tài khoản? ", style: TextStyle(color: Colors.grey[700])),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen())
                      );
                    },
                    child: Text(
                      "Đăng ký ngay",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}