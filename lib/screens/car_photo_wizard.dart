import 'dart:io';
import 'package:flutter/material.dart';
import 'camera_overlay.dart';

class CarPhotoWizard extends StatefulWidget {
  const CarPhotoWizard({super.key});

  @override
  State<CarPhotoWizard> createState() => _CarPhotoWizardState();
}

class _CarPhotoWizardState extends State<CarPhotoWizard> {
  int _currentStep = 0;
  final Map<String, File?> _photos = {
    "front": null,
    "left": null,
    "right": null,
    "back": null,
  };

  final List<Map<String, String>> _steps = [
    {
      "title": "Фото спереди",
      "overlay": "assets/overlays/car_front.png",
      "key": "front",
    },
    {
      "title": "Фото слева",
      "overlay": "assets/overlays/car_left.png",
      "key": "left",
    },
    {
      "title": "Фото справа",
      "overlay": "assets/overlays/car_right.png",
      "key": "right",
    },
    {
      "title": "Фото сзади",
      "overlay": "assets/overlays/car_back.png",
      "key": "back",
    },
  ];

  Future<void> _openCamera(String title, String overlay, String key) async {
    final File? photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CameraOverlayScreen(title: title, overlayAsset: overlay),
      ),
    );
    if (photo != null) {
      setState(() {
        _photos[key] = photo;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      // Все фото готовы → отправляем на ResultScreen
      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: _photos,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final progress = (_currentStep + 1) / _steps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Фотосъёмка автомобиля"),
        backgroundColor: const Color(0xFF32D583),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: const Color(0xFF32D583),
            minHeight: 6,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              step["title"]!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: _photos[step["key"]] == null
                  ? Container(
                      width: 220,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text("Нет фото")),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _photos[step["key"]]!,
                        width: 220,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF32D583),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () => _openCamera(
                    step["title"]!,
                    step["overlay"]!,
                    step["key"]!,
                  ),
                  child: const Text(
                    "Открыть камеру",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _photos[step["key"]] != null ? _nextStep : null,
                  child: Text(
                    _currentStep == _steps.length - 1 ? "Завершить" : "Далее",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
