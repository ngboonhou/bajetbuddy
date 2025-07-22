import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'history_screen.dart';

class ScanOptionsScreen extends StatelessWidget {
  final CameraDescription camera;
  const ScanOptionsScreen({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Scan Method')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Use Camera'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CameraScreen(camera: camera))),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Select from Gallery'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CameraScreen(
                            camera: camera, initialMode: 'gallery'))),
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('View History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}