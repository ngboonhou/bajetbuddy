import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'scan_options_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final CameraDescription camera;
  const WelcomeScreen({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade400, Colors.blue.shade600],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                   'assets/icon/icon.jpg',
                   width: 100,
                   height: 100,
                 ),
                const SizedBox(height: 20),
                const Text(
                  'Bajet Buddy',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan, extract, and save receipt data effortlessly.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Start Scanning'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ScanOptionsScreen(camera: camera),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}