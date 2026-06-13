import 'package:cloud_firestore/cloud_firestore.dart';

class UnionAffair {
  final String id, title, date, fileUrl, fileType;
  final DateTime createdAt;

  const UnionAffair({
    required this.id, required this.title, required this.date,
    required this.fileUrl, required this.fileType, required this.createdAt,
  });

  factory UnionAffair.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UnionAffair(
      id: doc.id,
      title: d['title'] ?? '',
      date: d['date'] ?? '',
      fileUrl: d['fileUrl'] ?? '',
      fileType: d['fileType'] ?? 'pdf',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title, 'date': date, 'fileUrl': fileUrl,
    'fileType': fileType, 'created_at': Timestamp.fromDate(createdAt),
  };
}
