import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:indrive_car_condition/widgets/exit.dart';

class CarPhotoWizard extends StatefulWidget {
  const CarPhotoWizard({super.key});

  @override
  State<CarPhotoWizard> createState() => _CarPhotoWizardState();
}

class _CarPhotoWizardState extends State<CarPhotoWizard> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _currentStep = 0;
  final Map<String, File?> _photos = {
    "front": null,
    "left": null,
    "right": null,
    "back": null,
  };

  bool _flashOn = false;
  File? _previewPhoto;

  final List<Map<String, String>> _steps = [
    {
      "title": "Фото спереди",
      "overlay": "assets/overlays/car_front.png",
      "key": "front"
    },
    {
      "title": "Фото слева",
      "overlay": "assets/overlays/car_left.png",
      "key": "left"
    },
    {
      "title": "Фото справа",
      "overlay": "assets/overlays/car_right.png",
      "key": "right"
    },
    {
      "title": "Фото сзади",
      "overlay": "assets/overlays/car_back.png",
      "key": "back"
    },
  ];

  @override
  void initState() {
    super.initState();
    _lockLandscape();
    _initCamera();
  }

  Future<void> _lockLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final picture = await _controller!.takePicture();
    setState(() {
      _previewPhoto = File(picture.path);
    });
  }

  Future<void> _confirmPhoto() async {
    final stepKey = _steps[_currentStep]["key"]!;
    setState(() {
      _photos[stepKey] = _previewPhoto;
      _previewPhoto = null;
    });

    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      Navigator.pushReplacementNamed(context, "/result", arguments: _photos);
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    _flashOn = !_flashOn;
    await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showExitConfirmationDialog(context);
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller == null || !_controller!.value.isInitialized
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (_previewPhoto == null) ...[
                    CameraPreview(_controller!),

                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.7,
                        child: Image.asset(
                          step["overlay"]!,
                          fit: BoxFit.contain,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Text(
                        step["title"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ),

                    // 🔄 Заменено: вертикальная панель справа
                    Positioned(
                      right: 20,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        children: [
                        const Spacer(flex: 2),
                          Transform.rotate(
                            angle: 2 * pi,
                            child: GestureDetector(
                              onTap: _takePhoto,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 4,
                                  ),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 32, color: Colors.black),
                              ),
                            ),
                          ),
                        const Spacer(flex: 1),
                          Transform.rotate(
                            angle: 2 * pi,
                            child: IconButton(
                              icon: Icon(
                                _flashOn ? Icons.flash_on : Icons.flash_off,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: _toggleFlash,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Positioned.fill(
                      child: Image.file(
                        _previewPhoto!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 30,
                      right: 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () =>
                                setState(() => _previewPhoto = null),
                            icon: const Icon(Icons.close),
                            label: const Text("Переснять"),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: _confirmPhoto,
                            icon: const Icon(Icons.check),
                            label: const Text("Подтвердить"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }
}
