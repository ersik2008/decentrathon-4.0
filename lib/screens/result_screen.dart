// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/result_card.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../models/history_item.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Мок-генератор результатов (для всех фото один раз)
  Map<String, dynamic> _generateMockResults() {
    final random = math.Random();

    final cleanlinessOptions = [
      {'label': 'Чистый', 'confidence': 85 + random.nextInt(15)},
      {'label': 'Слегка грязный', 'confidence': 75 + random.nextInt(20)},
      {'label': 'Сильно грязный', 'confidence': 80 + random.nextInt(20)},
    ];

    final integrityOptions = [
      {'label': 'Целый', 'confidence': 90 + random.nextInt(10)},
      {'label': 'Повреждённый', 'confidence': 85 + random.nextInt(15)},
    ];

    return {
      'cleanliness': cleanlinessOptions[random.nextInt(cleanlinessOptions.length)],
      'integrity': integrityOptions[random.nextInt(integrityOptions.length)],
    };
  }

  late Map<String, File?> photos;
  late Map<String, dynamic> results;
  bool _saved = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, File?>) {
      photos = args;
      results = _generateMockResults();
    } else {
      photos = {'front': null, 'left': null, 'right': null, 'back': null};
      results = _generateMockResults();
    }
  }

  Future<void> _saveResult() async {
    if (_saving || _saved) return;
    setState(() => _saving = true);

    final provider = Provider.of<HistoryProvider>(context, listen: false);

    final item = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      cleanliness: results['cleanliness']['label'] as String,
      cleanlinessConfidence: results['cleanliness']['confidence'] as int,
      integrity: results['integrity']['label'] as String,
      integrityConfidence: results['integrity']['confidence'] as int,
      imagePath: photos['front']?.path, // сохраняем путь front (можно расширить)
    );

    await provider.addItem(item);

    setState(() {
      _saved = true;
      _saving = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Результат сохранён в истории'),
        backgroundColor: Color(0xFF32D583),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат проверки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...photos.entries.map((entry) {
                final side = entry.key;
                final file = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _getSideName(side),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (file != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
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
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                        child: const Center(child: Text("Фото не сделано")),
                      ),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),

              Text(
                'Результаты анализа',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ResultCard(
                title: 'Чистота',
                result: results['cleanliness']['label'],
                confidence: results['cleanliness']['confidence'],
                icon: Icons.cleaning_services,
                color: _getCleanlinessColor(results['cleanliness']['label']),
              ),
              const SizedBox(height: 12),
              ResultCard(
                title: 'Целостность',
                result: results['integrity']['label'],
                confidence: results['integrity']['confidence'],
                icon: Icons.build_circle,
                color: _getIntegrityColor(results['integrity']['label']),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('Проверить другое фото'),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: _saved ? null : _saveResult,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF32D583),
                  side: const BorderSide(color: Color(0xFF32D583)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_saved ? 'Сохранено' : 'Сохранить результат'),
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
    switch (result) {
      case 'Чистый':
        return Colors.green;
      case 'Слегка грязный':
        return Colors.orange;
      case 'Сильно грязный':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getIntegrityColor(String result) {
    switch (result) {
      case 'Целый':
        return Colors.green;
      case 'Повреждённый':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
