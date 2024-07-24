import 'package:flutter/material.dart';
import 'geomap_overlay.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GeoMapOverlay(), // Menampilkan overlay GeoMap
    );
  }
}
