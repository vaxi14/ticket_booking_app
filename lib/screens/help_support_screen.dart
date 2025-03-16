import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Help & Support")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("For support, contact:", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("📞 +91 9876543210", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("📧 support@ticketapp.com", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
