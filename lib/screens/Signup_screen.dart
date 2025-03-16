import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticket_booking_app/screens/login_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> signUp() async {
    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup Successful! Please Login")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Create an Account",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black))
                  .animate()
                  .fade(duration: 500.ms)
                  .slideY(begin: -0.5, end: 0, curve: Curves.easeOut),
              SizedBox(height: 10),
              Text("Sign up to get started", style: TextStyle(fontSize: 16, color: Colors.grey[600]))
                  .animate()
                  .fade(duration: 500.ms)
                  .slideY(begin: -0.3, end: 0, curve: Curves.easeOut),
              SizedBox(height: 30),

              // Name Input Field
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ).animate().fade(duration: 500.ms).slideX(begin: -0.5, end: 0),
              SizedBox(height: 20),

              // Email Input Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ).animate().fade(duration: 500.ms).slideX(begin: -0.5, end: 0),
              SizedBox(height: 20),

              // Password Input Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ).animate().fade(duration: 500.ms).slideX(begin: -0.5, end: 0),
              SizedBox(height: 30),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Sign Up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: 0.5, end: 0),
              SizedBox(height: 20),

              // OR Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[500])),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[500]))
                ],
              ).animate().fade(duration: 500.ms).slideY(begin: 0.3, end: 0),

              SizedBox(height: 20),

              // Login Redirect
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  "Already have an account? Login",
                  style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: 0.3, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
