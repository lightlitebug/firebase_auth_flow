import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String desc;
  final String noteOwnerId;
  final Timestamp timestamp;

  Note({
    this.id,
    this.title,
    this.desc,
    this.noteOwnerId,
    this.timestamp,
  });

  factory Note.fromDoc(DocumentSnapshot noteDoc) {
    final noteData = noteDoc.data();

    return Note(
      id: noteDoc.id,
      title: noteData['title'],
      desc: noteData['desc'],
      noteOwnerId: noteData['noteOwnerId'],
      timestamp: noteData['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'desc': desc,
      'noteOwnerId': noteOwnerId,
      'timestamp': timestamp,
    };
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [id, title, desc, noteOwnerId, timestamp];
}
