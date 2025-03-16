import 'package:flutter/material.dart';
import 'package:ticket_booking_app/services/firestore_service.dart';

class UserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  UserDetailsScreen({required this.userData});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  
  TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset(0, 0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    _phoneController.text = widget.userData["phone"] ?? "";
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveDetails() async {
    if (_phoneController.text.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Phone number must be exactly 10 digits.")),
      );
      return;
    }

    await _firestoreService.updateUserData({
      "email": widget.userData['email'], // Read-only
      "name": widget.userData["name"], // Read-only
      "phone": _phoneController.text, 
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile Details", style: TextStyle(fontWeight: FontWeight.bold))),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      SizedBox(height: 20),

                      // Name (Read-Only)
                      ListTile(
                        leading: Icon(Icons.person, color: Colors.blue),
                        title: Text("Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(widget.userData["name"], style: TextStyle(fontSize: 18, color: Colors.black87)),
                        tileColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      SizedBox(height: 10),

                      // Email (Read-Only)
                      ListTile(
                        leading: Icon(Icons.email, color: Colors.blue),
                        title: Text("Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(widget.userData["email"], style: TextStyle(fontSize: 18, color: Colors.black87)),
                        tileColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      SizedBox(height: 10),

                      // Phone Number (Editable)
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: "Phone",
                          prefixIcon: Icon(Icons.phone, color: Colors.blue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                      SizedBox(height: 20),

                      // Save Button
                      ElevatedButton(
                        onPressed: _saveDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
