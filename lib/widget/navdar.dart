import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:objectdetectioncat/page/camera.dart';
import 'package:objectdetectioncat/page/homescreen.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _selectedIndex = 0; 

  final List<Widget> screens = [
    Homescreen(),   
    Cameras(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 232, 221, 191),
      bottomNavigationBar: CurvedNavigationBar(
        items: const [
          Icon(Icons.home, size: 30),
          Icon(Icons.camera_alt_outlined, size: 30),
        ],
        index: _selectedIndex, 
        onTap: (index) {
          setState(() {
            _selectedIndex = index; 
          });
        },
        backgroundColor: Colors.black26,
        color: const Color.fromARGB(255, 235, 229, 194),
      ),
      body: screens[_selectedIndex], 
    );
  }
}
