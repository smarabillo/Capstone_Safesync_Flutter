import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'package:safesync/config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    String userId = _usernameController.text;
    String password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse(Config.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"user_id": userId, "password": password}),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        await prefs.setString('name', data['name'] ?? "");
        await prefs.setString('position', data['position'] ?? "");
        await prefs.setString('number', data['number'].toString());
        await prefs.setString('profile_image', data['profile-image'] ?? "");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SafeSyncDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'].toString())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set the status bar text color to dark for visibility
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Optional: Set background color
      statusBarIconBrightness: Brightness.dark, // Dark text color
    ));

    const double inputWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: Image.asset(
                      'assets/images/logo-safesyncwnamelndscp.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Username Field
                  SizedBox(
                    width: inputWidth,
                    child: TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Officer ID',
                        hintStyle: const TextStyle(
                          fontSize: 18.0,
                          fontFamily: 'Poppins',
                          color: Colors.black54,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black26),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black26),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.blueAccent),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Password Field
                  SizedBox(
                    width: inputWidth,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                          fontSize: 18.0,
                          fontFamily: 'Poppins',
                          color: Colors.black54,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black26),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.blueAccent),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),

                  // Login Button
                  SizedBox(
                    width: inputWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: TextButton(
                        onPressed: _isLoading ? null : _login,
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors
                                    .blue.shade900; // Darker color when pressed
                              }
                              return Colors.blueAccent; // Default color
                            },
                          ),
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 14.0),
                          ),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Sign in now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: 30.0), // Named argument for padding
                    child: Text(
                      '© 2024 Safesync, All rights reserved.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black45,
                        fontFamily: 'Poppins', // Poppins font for the text
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
