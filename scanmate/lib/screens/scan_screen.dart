import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:scanmate/screens/crop_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  FlashMode _currentFlashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(_controller!.description);
    }
  }

  Future<void> _initializeCamera([CameraDescription? cameraDescription]) async {
    if (_cameras == null || _cameras!.isEmpty) {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available.')),
          );
        }
        return;
      }
    }

    final CameraController cameraController = CameraController(
      cameraDescription ?? _cameras![0], // Use the first camera by default
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    try {
      await cameraController.initialize();
      await cameraController.setFlashMode(FlashMode.off); // Default flash off
      _currentFlashMode = FlashMode.off;
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: ${e.description}')),
        );
      }
      // Handle error, e.g., show a message to the user
      print('Error initializing camera: $e');
    }
  }

  Future<void> _onTakePicturePressed() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not initialized.')),
      );
      return;
    }
    if (_controller!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return;
    }

    try {
      final XFile imageFile = await _controller!.takePicture();
      if (mounted) {
        // Navigate to CropScreen, passing the image path
        // For now, just show a snackbar with the path
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Picture saved to ${imageFile.path}')),
        // );
        Navigator.push<String>( // Expect a String (path) back
          context,
          MaterialPageRoute(
            builder: (context) => CropScreen(imagePath: imageFile.path),
          ),
        ).then((croppedImagePath) {
          if (croppedImagePath != null) {
            // TODO: Handle the cropped image path (e.g., add to a list for PDF generation)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cropped image ready: $croppedImagePath. Add to document list.')),
            );
            // Potentially pop ScanScreen or allow more scans
            // Navigator.pop(context); // Example: Pop back after one scan & crop
          } else {
            // Cropping was cancelled or failed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cropping cancelled or failed.')),
            );
          }
        });
      }
    } on CameraException catch (e) {
      print('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: ${e.description}')),
        );
      }
    }
  }

  void _onFlashButtonPressed() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_currentFlashMode == FlashMode.off) {
        _currentFlashMode = FlashMode.auto;
      } else if (_currentFlashMode == FlashMode.auto) {
        _currentFlashMode = FlashMode.torch;
      } else {
        _currentFlashMode = FlashMode.off;
      }
      _controller!.setFlashMode(_currentFlashMode);
    });
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
        return Icons.flash_on;
      default: // Also covers always (not used here)
        return Icons.flash_off;
    }
  }


  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        appBar: null, // No AppBar while camera is initializing
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true, // Make body extend behind AppBar
      appBar: AppBar(
        title: const Text('Scan Document'),
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0, // No shadow
        actions: [
          IconButton(
            icon: Icon(_getFlashIcon()),
            onPressed: _onFlashButtonPressed,
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          // TODO: Add edge detection overlay here if possible with the camera plugin directly
          // or guide lines.
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _onTakePicturePressed,
        tooltip: 'Take Picture',
        child: const Icon(Icons.camera),
      ),
    );
  }
}
