import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ticket_booking_app/theme/theme_provider.dart';
import 'package:ticket_booking_app/screens/user_detail_screen.dart';
import 'package:ticket_booking_app/screens/help_support_screen.dart';
import 'package:ticket_booking_app/services/auth_service.dart';
import 'package:ticket_booking_app/services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    Map<String, dynamic>? data = await _firestoreService.getUserData();
    setState(() {
      userData = data ?? {"name": "No Name", "email": "No Email", "phone": "No Phone"};
    });
  }

  void _logout() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Profile"),backgroundColor: Colors.grey[300],),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text("User Details",style: TextStyle(color: Colors.white)),
                    subtitle: const Text("Edit your profile details",style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserDetailsScreen(userData: userData!),
                        ),
                      ).then((_) => _loadUserData());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text("Favorite Events",style: TextStyle(color: Colors.white)),
                    subtitle: const Text("View your saved events",style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Favorite Events Screen (to be implemented)
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text("Help & Support",style: TextStyle(color: Colors.white),),
                    subtitle: const Text("Get assistance",style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpSupportScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text("Logout", style: TextStyle(color: Colors.red)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
    );
  }
}
