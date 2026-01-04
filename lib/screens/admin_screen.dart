import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    try {
      final users = await _apiService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải: $e")));
    }
  }

  // --- DIALOG THÊM / SỬA USER (Đã nâng cấp) ---
  void _showUserDialog({Map<String, dynamic>? user}) {
    bool isEdit = user != null;
    final nameCtrl = TextEditingController(text: isEdit ? user['fullName'] : "");
    final emailCtrl = TextEditingController(text: isEdit ? user['email'] : "");
    final passCtrl = TextEditingController();

    // Nếu đang sửa thì lấy quyền cũ, nếu thêm mới thì mặc định Staff
    String selectedRole = isEdit ? user['roleName'] : "Staff";

    // Kiểm tra xem role lấy từ API có nằm trong danh sách cứng không, nếu không thì về Staff để tránh lỗi
    List<String> roles = ["Admin", "Manager", "Staff"];
    if (!roles.contains(selectedRole)) selectedRole = "Staff";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( // Dùng StatefulBuilder để Dropdown cập nhật được UI
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEdit ? "Sửa thông tin" : "Thêm nhân viên mới"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Họ tên")),
                if (!isEdit)
                  TextField(controller: emailCtrl, decoration: InputDecoration(labelText: "Email")),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(labelText: isEdit ? "Mật khẩu mới (Để trống nếu ko đổi)" : "Mật khẩu"),
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Text("Phân quyền: "),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedRole,
                      items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        setStateDialog(() { // Cập nhật lại giá trị chọn trong Dialog
                          selectedRole = val!;
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Hủy")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  if (isEdit) {
                    // Gọi hàm update mới có thêm role
                    await _apiService.updateUserAdmin(user['userId'], nameCtrl.text, passCtrl.text, selectedRole);
                  } else {
                    await _apiService.createUserAdmin(nameCtrl.text, emailCtrl.text, passCtrl.text, selectedRole);
                  }
                  _loadUsers(); // Tải lại danh sách
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Thành công!")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                }
              },
              child: Text(isEdit ? "Cập nhật" : "Thêm mới"),
            )
          ],
        ),
      ),
    );
  }

  // --- XỬ LÝ ẨN / HIỆN ---
  void _toggleHide(int id, bool currentStatus) async {
    try {
      await _apiService.toggleHideUser(id);
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  // --- XỬ LÝ XÓA VĨNH VIỄN ---
  void _deleteHard(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Cảnh báo xóa vĩnh viễn"),
        content: Text("Dữ liệu sẽ bị mất hoàn toàn khỏi Database. Bạn chắc chứ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteUserHard(id);
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa vĩnh viễn!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
              }
            },
            child: Text("Xóa luôn"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản Trị Hệ Thống"), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _showUserDialog(),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isHidden = user['isDeleted'] == true;

          return Card(
            color: isHidden ? Colors.grey[200] : Colors.white, // Xám nếu bị ẩn
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isHidden ? Colors.grey : Colors.blue,
                child: Text(user['fullName'][0].toUpperCase()),
              ),
              title: Text(
                  user['fullName'],
                  style: TextStyle(
                      decoration: isHidden ? TextDecoration.lineThrough : null, // Gạch ngang tên nếu ẩn
                      color: isHidden ? Colors.grey : Colors.black
                  )
              ),
              subtitle: Text("${user['email']} - ${user['roleName']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút Sửa
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showUserDialog(user: user),
                  ),
                  // Nút Ẩn/Hiện
                  IconButton(
                    icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility, color: Colors.orange),
                    onPressed: () => _toggleHide(user['userId'], isHidden),
                    tooltip: isHidden ? "Mở khóa user" : "Ẩn user",
                  ),
                  // Nút Xóa Vĩnh Viễn
                  IconButton(
                    icon: Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _deleteHard(user['userId']),
                    tooltip: "Xóa vĩnh viễn",
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}