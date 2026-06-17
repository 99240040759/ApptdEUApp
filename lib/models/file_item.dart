import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified model for both Circulars and Union Affairs — identical structure.
class FileItem {
  final String id, title, date, fileUrl, fileType;
  final DateTime createdAt;
  const FileItem({
    required this.id, required this.title, required this.date,
    required this.fileUrl, required this.fileType, required this.createdAt,
  });
  factory FileItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FileItem(
      id: doc.id, title: d['title'] ?? '', date: d['date'] ?? '',
      fileUrl: d['fileUrl'] ?? '', fileType: d['fileType'] ?? 'pdf',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() => {
    'title': title, 'date': date, 'fileUrl': fileUrl,
    'fileType': fileType, 'created_at': Timestamp.fromDate(createdAt),
  };
}
