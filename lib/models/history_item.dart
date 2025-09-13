// lib/models/history_item.dart
import 'package:hive/hive.dart';

/// Модель истории (POJO)
class HistoryItem {
  final String id;
  final DateTime date;
  final String cleanliness;
  final int cleanlinessConfidence;
  final String integrity;
  final int integrityConfidence;
  final String? imagePath; // путь к сохранённому фото (в internal storage)

  HistoryItem({
    required this.id,
    required this.date,
    required this.cleanliness,
    required this.cleanlinessConfidence,
    required this.integrity,
    required this.integrityConfidence,
    this.imagePath,
  });
}

/// Ручной TypeAdapter для Hive — не требует build_runner
class HistoryItemAdapter extends TypeAdapter<HistoryItem> {
  @override
  final int typeId = 1;

  @override
  HistoryItem read(BinaryReader reader) {
    final id = reader.readString();
    final dateMillis = reader.readInt();
    final cleanliness = reader.readString();
    final cleanlinessConfidence = reader.readInt();
    final integrity = reader.readString();
    final integrityConfidence = reader.readInt();
    final hasImage = reader.readBool();
    final imagePath = hasImage ? reader.readString() : null;

    return HistoryItem(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      cleanliness: cleanliness,
      cleanlinessConfidence: cleanlinessConfidence,
      integrity: integrity,
      integrityConfidence: integrityConfidence,
      imagePath: imagePath,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryItem obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.cleanliness);
    writer.writeInt(obj.cleanlinessConfidence);
    writer.writeString(obj.integrity);
    writer.writeInt(obj.integrityConfidence);
    writer.writeBool(obj.imagePath != null);
    if (obj.imagePath != null) {
      writer.writeString(obj.imagePath!);
    }
  }
}
