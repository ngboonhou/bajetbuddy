import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/receipt_data.dart';
import '../services/database_service.dart';
import '../services/gemini_ocr_service.dart';
import '../widgets/receipt_detail_view.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final String? initialMode;

  const CameraScreen({Key? key, required this.camera, this.initialMode})
      : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  late final GeminiOcrService _geminiService;
  late final SqfliteHistoryService _historyService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Remember to replace 'YOUR_API_KEY' with your actual Gemini API Key
    _geminiService = GeminiOcrService('AIzaSyDY220c_dwbu0_KddVxiCzNxjANtnYWTvc');
    _historyService = SqfliteHistoryService();
    _requestPermissions();
    if (widget.initialMode == 'gallery') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImageFromGallery();
      });
    } else {
      _initializeCamera();
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.storage].request();
  }

  void _initializeCamera() {
    _controller =
        CameraController(widget.camera, ResolutionPreset.high, enableAudio: false);
    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _processImage(XFile imageFile) async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
    });
    try {
      final originalFile = File(imageFile.path);
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
          tempDir.path, "${DateTime.now().millisecondsSinceEpoch}-compressed.jpg");

      final XFile? compressedXFile =
          await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: 88,
        minWidth: 1024,
        minHeight: 1024,
      );
      final fileToProcess =
          compressedXFile != null ? File(compressedXFile.path) : originalFile;
      final ReceiptData result =
          await _geminiService.extractReceiptData(fileToProcess);

      _showResultsBottomSheet(result);
    } catch (e) {
      _showErrorDialog('Error processing image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showResultsBottomSheet(ReceiptData receipt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
          child: Column(
            children: [
              Expanded(
                child: ReceiptDetailView(
                    receipt: receipt,
                    scrollController: scrollController),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                        onPressed: () => _copyToClipboard(receipt),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white),
                        onPressed: () => _saveToHistory(receipt),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(ReceiptData receipt) {
    final buffer = StringBuffer();
    buffer.writeln('Store: ${receipt.storeName ?? 'N/A'}');
    buffer.writeln('Date: ${receipt.transactionDate ?? 'N/A'}');
    buffer.writeln('---');
    for (var item in receipt.lineItems) {
      buffer.writeln(
          '${item.quantity}x ${item.itemName}: \$${item.price.toStringAsFixed(2)}');
    }
    buffer.writeln('---');
    if (receipt.sst != null && receipt.sst! > 0) {
      buffer.writeln('SST: \$${receipt.sst!.toStringAsFixed(2)}');
    }
    if (receipt.serviceTax != null && receipt.serviceTax! > 0) {
      buffer.writeln(
          'Service Tax: \$${receipt.serviceTax!.toStringAsFixed(2)}');
    }
    buffer.writeln('Total: \$${receipt.total?.toStringAsFixed(2) ?? 'N/A'}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt data copied to clipboard!')),
    );
  }

  Future<void> _saveToHistory(ReceiptData receipt) async {
    await _historyService.saveReceipt(receipt);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt saved to history!')),
    );
    if (widget.initialMode == 'gallery' && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    XFile? pickedFile;
    try {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      print("Error picking image from gallery: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open gallery.')),
        );
      }
      return;
    }

    if (pickedFile == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }
    await _processImage(pickedFile);
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _showErrorDialog('Camera is not ready.');
      return;
    }
    try {
      final image = await _controller!.takePicture();
      await _processImage(image);
    } catch (e) {
      _showErrorDialog('Error capturing image: $e');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialMode == 'gallery') {
      return Scaffold(
        appBar: AppBar(title: const Text('Processing Image')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing Receipt...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return _controller != null
                    ? CameraPreview(_controller!)
                    : const Center(
                        child: Text("Could not initialize camera."));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Analyzing Receipt...",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              )),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isProcessing ? null : _captureAndProcess,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: Colors.black,
    );
  }
}