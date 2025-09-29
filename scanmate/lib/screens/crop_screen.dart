import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:scanmate/services/image_enhancement_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class CropScreen extends StatefulWidget {
  final String imagePath; // Initial path from camera

  const CropScreen({super.key, required this.imagePath});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  late String _currentImagePath; // Path to the image currently being worked on (original, then cropped)
  Uint8List? _displayedImageBytes; // Bytes of the image shown in UI (can be original, cropped, or enhanced)
  String? _finalImagePathToReturn; // Path of the final image (cropped, possibly enhanced) to be returned

  EnhancementType _currentEnhancement = EnhancementType.none;
  bool _isProcessing = false; // For any async operation like cropping or filtering

  final ImageEnhancementService _enhancementService = ImageEnhancementService();

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
    _finalImagePathToReturn = widget.imagePath; // Initially, it's the uncropped image
    _loadImageBytesForDisplay(_currentImagePath);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _triggerInitialCrop();
      }
    });
  }

  Future<void> _loadImageBytesForDisplay(String path) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    try {
      final file = File(path);
      if (await file.exists()) {
        _displayedImageBytes = await file.readAsBytes();
      } else {
        debugPrint('Error: Image file not found at $path');
        if (!mounted) return; // Guard BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Image file not found.')),
        );
        _displayedImageBytes = null; // Clear display if file not found
      }
    } catch (e) {
      debugPrint('Error loading image bytes: $e');
      if (!mounted) return; // Guard BuildContext
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading image: $e')),
      );
      _displayedImageBytes = null;
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _triggerInitialCrop() async {
    await _cropImage(_currentImagePath);
  }

  Future<void> _cropImage(String sourcePath) async {
    if (_isProcessing) return;
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95, // High quality for further processing
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Document',
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              showCropGrid: true,
              hideBottomControls: false),
          IOSUiSettings(
            title: 'Crop Document',
            minimumAspectRatio: 0.1,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            showActivitySheetOnDone: false,
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        _currentImagePath = croppedFile.path; // This is our new base for filters
        _finalImagePathToReturn = _currentImagePath; // Update path to return
        _currentEnhancement = EnhancementType.none; // Reset filter on new crop
        await _loadImageBytesForDisplay(_currentImagePath);
      } else {
         // If cropping was cancelled, _croppedFile is null.
         // We might want to keep displaying the previous image or the original.
         // For now, if initial crop is cancelled, we might pop or show original.
         // If re-crop is cancelled, we just go back to the last state.
         if (mounted) {
            // If it was the initial crop and it was cancelled, user might want to go back.
            // For re-crop, just ensure _isProcessing is false.
            if (_displayedImageBytes == null && widget.imagePath == sourcePath) {
                // Initial crop cancelled, maybe pop? Or let user confirm current (uncropped)
                // For now, we'll just allow confirming the original if they cancel initial crop.
                await _loadImageBytesForDisplay(widget.imagePath); // Show original again
            }
         }
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) { // Guard for setState is fine, need separate for ScaffoldMessenger
        if (!mounted) return; // Guard BuildContext for ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during crop: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _applyFilter(EnhancementType type) async {
    if (_isProcessing) return;
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _currentEnhancement = type;
    });

    Uint8List? imageToProcessBytes;
    // Always apply filter to the last successfully cropped image
    if (File(_currentImagePath).existsSync()) {
        imageToProcessBytes = await File(_currentImagePath).readAsBytes();
    }

    if (imageToProcessBytes == null) {
        if (!mounted) return; // Guard BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Cropped image data not available for filtering.')));
        if (mounted) { // Guard for setState
          setState(() => _isProcessing = false);
        }
        return;
    }

    Uint8List? enhancedBytes = await _enhancementService.applyEnhancementToBytes(imageToProcessBytes, type);

    if (enhancedBytes != null) { // mounted check will be done before setState
      if (type == EnhancementType.none) {
        // If "Original" (None) is selected, revert to the cropped image without filter
        _finalImagePathToReturn = _currentImagePath;
        _displayedImageBytes = await File(_currentImagePath).readAsBytes();
      } else {
        // Save the enhanced image to a new temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFileName = 'enhanced_${type.name}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final tempFilePath = join(tempDir.path, tempFileName);
        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(enhancedBytes);
        _finalImagePathToReturn = tempFilePath; // This is now the image to be saved/passed back
        _displayedImageBytes = enhancedBytes;
      }
    } else {
      if (!mounted) return; // Guard BuildContext
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to apply filter.')),
      );
      // Revert to last known good state if filter fails
      if(mounted) { // Guard for setState
      _currentEnhancement = EnhancementType.none; // Or previous enhancement
      _finalImagePathToReturn = _currentImagePath;
      _displayedImageBytes = await File(_currentImagePath).readAsBytes();
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Scan'),
        actions: [
          if (_finalImagePathToReturn != null && !_isProcessing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _finalImagePathToReturn);
              },
              tooltip: 'Confirm',
            ),
          IconButton(
            icon: const Icon(Icons.crop_rotate),
            onPressed: _isProcessing ? null : () => _cropImage(_currentImagePath), // Re-crop current base image
            tooltip: 'Re-crop',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isProcessing && _displayedImageBytes == null // Show loader only if nothing to display
                  ? const CircularProgressIndicator()
                  : _displayedImageBytes != null
                      ? Image.memory(_displayedImageBytes!, fit: BoxFit.contain)
                      : const Text('Loading image...'),
            ),
          ),
          if (!_isProcessing) _buildFilterToolbar(),
          if (_isProcessing) const Padding(padding: EdgeInsets.all(16.0), child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar() {
    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _filterButton(context, EnhancementType.none, 'Original', Icons.image_outlined),
            _filterButton(context, EnhancementType.grayscale, 'Grayscale', Icons.filter_b_and_w_outlined),
            _filterButton(context, EnhancementType.blackAndWhite, 'B & W', Icons.contrast_outlined),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(BuildContext context, EnhancementType type, String label, IconData icon) {
    final bool isActive = _currentEnhancement == type;
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color inactiveColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color activeBgColor = Theme.of(context).colorScheme.primaryContainer;
    final Color inactiveBgColor = Theme.of(context).colorScheme.surface;


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: isActive ? activeColor : inactiveColor),
        label: Text(label, style: TextStyle(color: isActive ? activeColor : inactiveColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? activeBgColor : inactiveBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isActive ? activeColor : Theme.of(context).colorScheme.outline.withOpacity(0.5),
              width: isActive ? 2 : 1
            ),
          ),
          elevation: isActive ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onPressed: () => _applyFilter(type),
      ),
    );
  }
}
