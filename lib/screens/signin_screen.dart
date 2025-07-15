import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cashtrack/screens/home_screen.dart';
import 'package:cashtrack/models/uid_extraction.dart';


import '../main.dart'; // for openUserBox()
import '../services/database_service.dart';
import '../services/hive_utils.dart'; // Import the DatabaseService
 User? global_user=null;
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  final DatabaseService _databaseService = DatabaseService();
  //


  ////////////////////////////
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;
  //
  //

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: '150056506896-t9pp4l1guro7g7bjhodf5gd882tolk4r.apps.googleusercontent.com', // Your Web Client ID

      );
      setState(() {
        _isGoogleSignInInitialized = true;
      });
      print("✅ Google Sign-In initialized.");
    } catch (e) {
      print("❌ Failed to initialize Google Sign-In: $e");
      setState(() {
        _errorMessage = "Failed to initialize Google Sign-In.";
        _isGoogleSignInInitialized = false;
      });
    }
  }
  //////////////////////////////
  Future<void> _onGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Trigger Google Sign-In flow

      //////////////////////////////////////

        if (!_isGoogleSignInInitialized) {
          await _initializeGoogleSignIn();
        }
        final stringy = "150056506896-t9pp4l1guro7g7bjhodf5gd882tolk4r.apps.googleusercontent.com";
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate(

          scopeHint: ['email'],
        );
      //////////////////////////////////////
      //final GoogleSignInAccount? googleUser = await GoogleSignIn().SignIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get Google authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
////////////////////////////////////////
        final authClient = _googleSignIn.authorizationClient;
        final authorization = await authClient.authorizationForScopes(['email']);
////////////////////////////////////////////
        // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;


      if (user == null) {
        throw Exception('Authentication failed - no user returned');
      }
      else{
        global_user = user;
        print(global_user?.photoURL);
      }

      final String fullUid = user.uid;
      final String last6Digits = UidExtraction.extractLast6Digits(fullUid);
      final String userFriendlyId = UidExtraction.createUserFriendlyId(fullUid);

      final Map<String, dynamic> uidInfo = UidExtraction.getUidInfo(fullUid);
      print('🔍 UID Info: $uidInfo');

      // Check if this is a new user
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Save user data to Firestore using DatabaseService
      await _databaseService.createUserDocument(user, isNewUser: isNewUser);

      // Persist user email in SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', user.email ?? '');
      await prefs.setString('uid_last6', last6Digits);
      await prefs.setString('user_friendly_id', userFriendlyId);

      if (isNewUser) {
        // For new users, you can store the extracted UID info
        await _databaseService.updateUserData(user.uid, {
          'extractedId': last6Digits,
          'userFriendlyId': userFriendlyId,
          'fullUidLength': fullUid.length,
        });
      }

      // Open user-specific Hive box
      await openUserBox(user.email ?? '');

      print('✅ Google Sign-In successful for: ${user.email}');
      print('✅ User document ${isNewUser ? 'created' : 'updated'} in Firestore');

      // Navigation will be handled automatically by AuthGate's StreamBuilder

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials. Please try again.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found for this account.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        default:
          errorMessage = 'An error occurred during sign-in: ${e.message}';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');

    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
      print('❌ Unexpected Sign-In Error: $e');

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Colors.grey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Title
                  const Text(
                    'Smarter\nTracking with',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Text(
                    'CashTrack',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // App Logo
                  Image.asset(
                    'assets/chippy.png',
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),

                  const SizedBox(height: 30),

                  // Google Sign-In Button
                  SizedBox(
                    height: 60,
                    width: 300,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/google.png',
                              height: 30,
                              width: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Text(
                            'Sign in with Google',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error Message Display
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Divider
                  Container(height: 1, width: 350, color: Colors.black12),

                  const SizedBox(height: 20),

                  // Terms and Privacy
                  const Text(
                    'Terms & Conditions  |  Privacy Policy',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// AuthGate remains the same as before


