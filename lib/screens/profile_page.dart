import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cashtrack/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cashtrack/main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  File? _profileImage;

  final TextEditingController _nameController =
  TextEditingController(text: 'Username');
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _logout() async {
    //await GoogleSignIn().signOut();
    /////////////////////////////////////////////////////////////////////////
    final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    /////////////////////////////////////////////////////////////////////////
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String fullUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Safely extract last 6 characters (or entire UID if shorter)
    final String shortUid = (fullUid.length >= 6)
        ? fullUid.substring(fullUid.length - 6)
        : fullUid;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.transparent,
        backgroundColor: const Color(0xFF00CCE7),
        leadingWidth: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 2.0),
          child: Image.asset(
            'assets/logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        title: Transform.translate(
          offset: const Offset(-25, -5),
          child: const Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 30,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Transform.translate(
              offset: const Offset(0, -5),
              child: GestureDetector(
                onTap: () {
                  // Check if we're already on ProfilePage
                  if (widget.runtimeType != ProfilePage) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  }
                },
                child: const Icon(
                  Icons.account_circle,
                  size: 50,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: isEditing ? _pickImage : null,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage('assets/chippy.png')
                    as ImageProvider,
                    child: isEditing
                        ? const Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 15,
                        child:
                        Icon(Icons.edit, size: 18, color: Colors.black),
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // User Name
                Text(
                  _nameController.text,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),

                // Display only last 6 chars of UID
                Text(
                  'User ID: $shortUid',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: const TextStyle(color: Colors.blue),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  enabled: isEditing,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Colors.blue),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  enabled: isEditing,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Email ID',
                    labelStyle: const TextStyle(color: Colors.blue),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  enabled: isEditing,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _collegeController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'College Name',
                    labelStyle: const TextStyle(color: Colors.blue),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  enabled: isEditing,
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = !isEditing;
                    });
                  },
                  child: Text(isEditing ? 'Save' : 'Edit'),
                ),
                const SizedBox(height: 15),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black54, size: 30),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
