import 'package:flutter/material.dart';
import 'package:objectdetectioncat/widget/graph.dart';

class GraphPage extends StatefulWidget {
  GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  @override
    Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
         Expanded(child: GraphWidget()),
        ],
      ),  // เรียกใช้ GraphWidget ที่จัดการการเลื่อนแล้ว
    );
  }
}
