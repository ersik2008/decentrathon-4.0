import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/result_card.dart';
import '../models/history_item.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! HistoryItem) {
      return Scaffold(
        body: Center(
          child: Text("Нет данных для отображения"),
        ),
      );
    }

    final HistoryItem item = args;

    // Если нужно показать все стороны — расширяем HistoryItem или передаем Map<String,String?>
    final Map<String, String?> photos = {
      'front': item.imagePath,
      // 'left': ..., 'right': ..., 'back': ...
    };

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
                final path = entry.value;
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
                result: item.cleanliness,
                confidence: item.cleanlinessConfidence,
                icon: Icons.cleaning_services,
                color: _getCleanlinessColor(item.cleanliness),
              ),
              const SizedBox(height: 12),
              ResultCard(
                title: 'Целостность',
                result: item.integrity,
                confidence: item.integrityConfidence,
                icon: Icons.build_circle,
                color: _getIntegrityColor(item.integrity),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
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
