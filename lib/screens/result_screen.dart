// lib/screens/result_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/result_card.dart';
import '../models/history_item.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _loading = true;
  Map<String, dynamic>? _apiResult;
  HistoryItem? _args;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _args = ModalRoute.of(context)!.settings.arguments as HistoryItem?;
      _sendPhotos();
      _initialized = true;
    }
  }

  Future<void> _sendPhotos() async {
    if (_args == null) return;
    final api = ApiService();

    try {
      final result = await api.sendCarPhotos(
        frontImage: File(_args!.frontImage!),
        leftImage: File(_args!.leftImage!),
        rightImage: File(_args!.rightImage!),
        rearImage: File(_args!.backImage!),
      );
      setState(() {
        _apiResult = result;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Ошибка API: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;

    if (args == null) {
      return const Scaffold(
        body: Center(child: Text("Нет данных")),
      );
    }

    final Map<String, String?> photos = {
      'front': args.frontImage,
      'left': args.leftImage,
      'right': args.rightImage,
      'back': args.backImage,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат проверки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Фото автомобиля ---
                    ...photos.entries.map((entry) {
                      final side = entry.key;
                      final path = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _getSideName(side),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          if (path != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(path),
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey, width: 1),
                              ),
                              child:
                                  const Center(child: Text("Фото не сделано")),
                            ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }).toList(),

                    // --- Агрегированные результаты ---
                    Text(
                      'Общий результат',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    if (_apiResult != null &&
                        _apiResult!['overall'] != null) ...[
                      ResultCard(
                        title: 'Чистота',
                        result: _apiResult!['overall']['cleanliness'] ??
                            "Неизвестно",
                        confidence: (_apiResult!['overall']
                                    ['cleanliness_probability'] ??
                                0)
                            .toInt(),
                        icon: Icons.cleaning_services,
                        color: _getCleanlinessColor(
                            _apiResult!['overall']['cleanliness'] ?? ""),
                      ),
                      const SizedBox(height: 12),
                      ResultCard(
                        title: 'Целостность',
                        result:
                            _apiResult!['overall']['integrity'] ?? "Неизвестно",
                        confidence: (_apiResult!['overall']
                                    ['integrity_probability'] ??
                                0)
                            .toInt(),
                        icon: Icons.build_circle,
                        color: _getIntegrityColor(
                            _apiResult!['overall']['integrity'] ?? ""),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- Детали по каждой стороне ---
                    if (_apiResult != null && _apiResult!['details'] != null)
                      ...(_apiResult!['details'] as List).map((detail) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Детали: ${_getSideName(detail['side'] ?? "")}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            ResultCard(
                              title: 'Чистота',
                              result: detail['cleanliness'] ?? "Неизвестно",
                              confidence:
                                  (detail['cleanliness_probability'] ?? 0)
                                      .toInt(),
                              icon: Icons.cleaning_services,
                              color: _getCleanlinessColor(
                                  detail['cleanliness'] ?? ""),
                            ),
                            const SizedBox(height: 8),
                            ResultCard(
                              title: 'Целостность',
                              result: detail['integrity'] ?? "Неизвестно",
                              confidence: (detail['integrity_probability'] ?? 0)
                                  .toInt(),
                              icon: Icons.build_circle,
                              color:
                                  _getIntegrityColor(detail['integrity'] ?? ""),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }).toList(),

                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/'),
                      child: const Text('Сфотографировать заново'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getSideName(String side) {
    switch (side) {
      case 'front':
        return 'Передняя часть';
      case 'back':
        return 'Задняя часть';
      case 'left':
        return 'Левая сторона';
      case 'right':
        return 'Правая сторона';
      default:
        return side;
    }
  }

  Color _getCleanlinessColor(String result) {
    switch (result.toLowerCase()) {
      case 'clean':
      case 'чистый':
        return Colors.green;
      case 'slightly dirty':
      case 'слегка грязный':
        return Colors.orange;
      case 'dirty':
      case 'сильно грязный':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getIntegrityColor(String result) {
    switch (result.toLowerCase()) {
      case 'intact':
      case 'целый':
        return Colors.green;
      case 'damaged':
      case 'повреждённый':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
