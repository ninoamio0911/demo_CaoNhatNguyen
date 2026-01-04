import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lịch trình")),
      body: Center(
        child: Text("Chúc mừng!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}