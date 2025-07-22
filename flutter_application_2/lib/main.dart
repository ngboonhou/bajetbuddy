import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(ReceiptScannerApp(camera: cameras.first));
}

class ReceiptScannerApp extends StatelessWidget {
  final CameraDescription camera;
  const ReceiptScannerApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Scanner',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomeScreen(camera: camera),
    );
  }
}