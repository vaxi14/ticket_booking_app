import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadImageScreen extends StatefulWidget {
  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? selectedImage;
  Uint8List? selectedImageBytes;
  String? imageUrl;
  bool isUploading = false;

  String imgbbApiKey = "YOUR_IMGBB_API_KEY"; // Replace with your ImgBB API key

  /// Pick image from local storage
  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // Supports web (returns bytes)
    );

    if (result != null) {
      setState(() {
        selectedImage = File(result.files.single.path ?? "");
        selectedImageBytes = result.files.single.bytes; // For web
      });
    }
  }

  /// Upload image to ImgBB
  Future<void> uploadImageToImgBB() async {
    if (selectedImageBytes == null && selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an image first.")),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.imgbb.com/1/upload?key=$imgbbApiKey"),
      );

      if (selectedImage != null) {
        // Mobile file upload
        request.files.add(await http.MultipartFile.fromPath('image', selectedImage!.path));
      } else if (selectedImageBytes != null) {
        // Web file upload
        request.files.add(http.MultipartFile.fromBytes('image', selectedImageBytes!,
            filename: "upload.png"));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (jsonResponse["success"]) {
        String uploadedImageUrl = jsonResponse["data"]["url"];

        // Store the URL in Firebase Firestore
        await FirebaseFirestore.instance.collection('events').add({
          'imageUrl': uploadedImageUrl,
          'name': 'Sample Event',
          'location': 'Sample Location',
          'date': '2025-03-10',
          'price': 100,
          'priority': 1
        });

        setState(() {
          imageUrl = uploadedImageUrl;
          isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image Uploaded Successfully!")),
        );
      } else {
        throw Exception("Failed to upload image.");
      }
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Event Image")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            selectedImage != null || selectedImageBytes != null
                ? selectedImageBytes != null
                    ? Image.memory(selectedImageBytes!, width: 150, height: 150, fit: BoxFit.cover)
                    : Image.file(selectedImage!, width: 150, height: 150, fit: BoxFit.cover)
                : Icon(Icons.image, size: 100, color: Colors.grey),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickImage,
              child: Text("Pick Image"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: isUploading ? null : uploadImageToImgBB,
              child: isUploading ? CircularProgressIndicator() : Text("Upload to ImgBB"),
            ),

            SizedBox(height: 20),

            imageUrl != null
                ? SelectableText("Uploaded Image URL:\n$imageUrl", textAlign: TextAlign.center)
                : Container(),
          ],
        ),
      ),
    );
  }
}
