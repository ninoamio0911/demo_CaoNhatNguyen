import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();

  bool _isAdmin = false;
  Map<DateTime, List<dynamic>> _events = {};
  final ApiService _apiService = ApiService();
  final Set<String> _processedAlerts = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
    _checkRole();
    _notificationService.init();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- LOGIC GIỮ NGUYÊN ---
  void _startAutoCheck() {
    _timer = Timer.periodic(Duration(seconds: 20), (timer) async {
      final now = DateTime.now();
      SharedPreferences prefs = await SharedPreferences.getInstance();

      _events.forEach((date, events) {
        for (var event in events) {
          DateTime startTime = DateTime.parse(event['startTime']);
          int eventId = event['eventId'] ?? event['EventId'];

          int remindMinutes = prefs.getInt('remind_$eventId') ?? 15;
          if (remindMinutes == 0) continue;

          final difference = startTime.difference(now).inMinutes;
          String alertKey = '${eventId}_$remindMinutes';

          if (difference == remindMinutes && !_processedAlerts.contains(alertKey)) {
            _notificationService.showNotificationNow(
                eventId,
                "Sự kiện '${event['title']}' sắp diễn ra trong $remindMinutes phút nữa!"
            );
            _processedAlerts.add(alertKey);
          }
        }
      });
    });
  }

  void _loadEvents() async {
    try {
      List<dynamic> data = await _apiService.getEvents();
      Map<DateTime, List<dynamic>> tempEvents = {};
      for (var item in data) {
        DateTime date = DateTime.parse(item['startTime']);
        DateTime dateKey = DateTime(date.year, date.month, date.day);
        if (tempEvents[dateKey] == null) tempEvents[dateKey] = [];
        tempEvents[dateKey]!.add(item);
      }
      setState(() { _events = tempEvents; });
    } catch (e) { print("Lỗi tải lịch: $e"); }
  }

  void _checkRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() { _isAdmin = (prefs.getString('role') == "Admin"); });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  // --- POPUP DIALOG (GIỮ NGUYÊN LOGIC, CHỈ THÊM BO GÓC) ---
  void _showEventDialog({Map<String, dynamic>? eventToEdit}) {
    final bool isEdit = eventToEdit != null;
    final titleCtrl = TextEditingController(text: isEdit ? eventToEdit['title'] : "");
    final descCtrl = TextEditingController(text: isEdit ? eventToEdit['description'] : "");

    DateTime initStart = isEdit ? DateTime.parse(eventToEdit['startTime']) : DateTime.now();
    DateTime initEnd = isEdit ? DateTime.parse(eventToEdit['endTime']) : DateTime.now().add(Duration(hours: 1));

    TimeOfDay startTime = TimeOfDay(hour: initStart.hour, minute: initStart.minute);
    TimeOfDay endTime = TimeOfDay(hour: initEnd.hour, minute: initEnd.minute);

    int remindMinutes = 15;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Bo góc Dialog
            title: Text(isEdit ? "Sửa Sự Kiện" : "Thêm Sự Kiện", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: InputDecoration(labelText: "Tiêu đề", prefixIcon: Icon(Icons.title_rounded))),
                  SizedBox(height: 10),
                  TextField(controller: descCtrl, decoration: InputDecoration(labelText: "Mô tả", prefixIcon: Icon(Icons.description_outlined))),
                  SizedBox(height: 20),
                  Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.access_time, color: Colors.blue),
                    title: Text("Bắt đầu: ${startTime.format(context)}", style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: startTime);
                      if (picked != null) setStateDialog(() => startTime = picked);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.access_time_filled, color: Colors.redAccent),
                    title: Text("Kết thúc: ${endTime.format(context)}", style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: endTime);
                      if (picked != null) setStateDialog(() => endTime = picked);
                    },
                  ),
                  DropdownButtonFormField<int>(
                    value: remindMinutes,
                    decoration: InputDecoration(prefixIcon: Icon(Icons.notifications_active_outlined), labelText: "Nhắc tôi trước", border: InputBorder.none),
                    items: [0, 5, 15, 30, 60].map((m) => DropdownMenuItem(value: m, child: Text(m == 0 ? "Không nhắc" : "$m phút"))).toList(),
                    onChanged: (val) => setStateDialog(() => remindMinutes = val!),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Hủy", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) return;
                  final startDateTime = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, startTime.hour, startTime.minute);
                  final endDateTime = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, endTime.hour, endTime.minute);

                  try {
                    int eventIdToSave = 0;
                    if (isEdit) {
                      int id = eventToEdit['eventId'] ?? eventToEdit['EventId'];
                      await _apiService.updateEvent(id, titleCtrl.text, descCtrl.text, startDateTime, endDateTime);
                      eventIdToSave = id;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã cập nhật!")));
                    } else {
                      int newId = await _apiService.addEvent(titleCtrl.text, descCtrl.text, startDateTime, endDateTime);
                      eventIdToSave = newId;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm mới!")));
                    }

                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('remind_$eventIdToSave', remindMinutes);

                    Navigator.pop(ctx);
                    _loadEvents();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                  }
                },
                child: Text(isEdit ? "Cập nhật" : "Lưu"),
              )
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(int eventId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa công việc này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteEvent(eventId);
                _loadEvents();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa thành công!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
              }
            },
            child: Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDay!);

    return Scaffold(
      // --- APP BAR GRADIENT ---
      appBar: AppBar(
        title: Text("Lịch Trình", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active),
            onPressed: () async {
              await _notificationService.showInstantNotification();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => _showEventDialog(),
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // --- TABLE CALENDAR DESIGN ---
          Container(
            margin: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 5))],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.blueAccent),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.blueAccent),
              ),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                // Ngày hiện tại
                todayDecoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.5), shape: BoxShape.circle),
                // Ngày đang chọn
                selectedDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                // Dấu chấm sự kiện
                markerDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                weekendTextStyle: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),

          // --- TIÊU ĐỀ NGÀY ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(
                  "Công việc ngày ${DateFormat('dd/MM').format(_selectedDay!)}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text("${events.length} việc", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          // --- DANH SÁCH SỰ KIỆN ---
          Expanded(
            child: events.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
                  SizedBox(height: 10),
                  Text("Không có sự kiện nào", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final startTime = DateTime.parse(event['startTime']);
                final endTime = DateTime.parse(event['endTime']);

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: Offset(0, 3))
                      ],
                      border: Border.all(color: Colors.grey.shade100)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cột giờ bên trái
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('HH:mm').format(startTime), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            SizedBox(height: 4),
                            Text(DateFormat('HH:mm').format(endTime), style: TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                        SizedBox(width: 16),

                        // Đường kẻ dọc trang trí
                        Container(
                          height: 40,
                          width: 4,
                          decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)),
                        ),
                        SizedBox(width: 16),

                        // Nội dung chính
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              if (event['description'] != null && event['description'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                      event['description'],
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Nút thao tác
                        Column(
                          children: [
                            InkWell(
                              onTap: () => _showEventDialog(eventToEdit: event),
                              child: Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 20, color: Colors.blue)),
                            ),
                            SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                var id = event['eventId'] ?? event['EventId'];
                                if (id != null) _confirmDelete(id);
                              },
                              child: Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 20, color: Colors.red)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}