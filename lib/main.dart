import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:objectdetectioncat/widget/navdar.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home:BottomNavbar())
    );
}
