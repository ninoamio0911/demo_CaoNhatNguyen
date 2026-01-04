import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // <--- Thêm thư viện này để check nền tảng

class ApiService {
  // Tự động đổi IP tùy theo anh chạy trên Web hay Android

  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5161/api"; // Nếu chạy Web
    } else {
      return "http://10.0.2.2:5161/api"; // Nếu chạy Android Emulator
    }
  }

  // 1. Hàm Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Sửa chỗ này để dùng biến baseUrl động phía trên
    final url = Uri.parse('$baseUrl/Auth/login');

    try {
      print("Đang gọi API tới: $url"); // In ra để debug xem đúng link chưa
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*", // Thêm dòng này cho Web đỡ bị chặn
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Lỗi Server: ${response.body}");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }

  // 2. Hàm Xác thực OTP
  Future<Map<String, dynamic>> verifyOtp(int userId, String otpCode) async {
    final url = Uri.parse('$baseUrl/Auth/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "otpCode": otpCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Lưu Token vào bộ nhớ máy để dùng sau này
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('fullName', data['fullName']);
        return data;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception("Lỗi OTP: $e");
    }
  }
  // 3. Lấy danh sách sự kiện
  Future<List<dynamic>> getEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token'); // Lấy token đã lưu lúc đăng nhập

    final url = Uri.parse('$baseUrl/Events');

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // Gửi kèm Token để chứng minh đã đăng nhập
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Không tải được lịch: ${response.body}");
    }
  }

  // 4. Thêm sự kiện mới (Nâng cấp)
  Future<int> addEvent(String title, String description, DateTime startTime, DateTime endTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/Events');

    final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "description": description, // Thêm mô tả
          "startTime": startTime.toIso8601String(),
          "endTime": endTime.toIso8601String(),
          "location": "Việt Nam",
          "categoryId": 1
        })
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Trả về ID của sự kiện vừa tạo để dùng làm ID cho thông báo
      final data = jsonDecode(response.body);
      return data['id'] ?? 0;
    } else {
      throw Exception("Lỗi thêm: ${response.body}");
    }
  }

  // 5. Admin: Lấy danh sách User
  Future<List<dynamic>> getAllUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/Admin/users');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Không thể tải danh sách User (Bạn có phải Admin không?)");
    }
  }

  // 6. Admin: Xóa User
  Future<void> deleteUser(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/Admin/users/$userId');
    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Lỗi khi xóa user");
    }
  }
  // 7. Đăng ký tài khoản
  Future<void> register(String fullName, String email, String password) async {
    final url = Uri.parse('$baseUrl/Auth/register');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": fullName,
        "email": email,
        "password": password
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }
  // 8. Xóa sự kiện (Thêm hàm này vào)
  Future<void> deleteEvent(int eventId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/Events/$eventId');

    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Lỗi khi xóa: ${response.body}");
    }
  }
  // 9. Thêm User mới (Admin)
  Future<void> createUserAdmin(String name, String email, String pass, String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/Admin/users'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "fullName": name, "email": email, "password": pass, "roleName": role
      }),
    );
    if (response.statusCode != 200) throw Exception(response.body);
  }

  // 10. Sửa User (Admin) - Cập nhật thêm Role
  Future<void> updateUserAdmin(int id, String name, String pass, String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/Admin/users/$id'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      // Gửi thêm roleName lên server
      body: jsonEncode({
        "fullName": name,
        "password": pass,
        "roleName": role
      }),
    );
    if (response.statusCode != 200) throw Exception(response.body);
  }

  // 11. Ẩn/Hiện User
  Future<void> toggleHideUser(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/Admin/users/$id/toggle-hide'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) throw Exception(response.body);
  }

  // 12. Xóa vĩnh viễn (Cập nhật lại hàm deleteUser cũ)
  Future<void> deleteUserHard(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/Admin/users/$id'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) throw Exception(response.body);
  }
  // 13. Sửa sự kiện
  Future<void> updateEvent(int id, String title, String description, DateTime startTime, DateTime endTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/Events/$id');

    final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "description": description,
          "startTime": startTime.toIso8601String(),
          "endTime": endTime.toIso8601String(),
          "location": "Việt Nam",
          "categoryId": 1
        })
    );

    if (response.statusCode != 200) {
      throw Exception("Lỗi cập nhật: ${response.body}");
    }
  }
}
