import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth_flow/constants/db_contants.dart';
import 'package:firebase_auth_flow/models/note_model.dart';
import 'package:flutter/foundation.dart';

class NoteListState extends Equatable {
  final bool loading;
  final List<Note> notes;

  NoteListState({
    this.loading,
    this.notes,
  });

  NoteListState copyWith({
    bool loading,
    List<Note> notes,
  }) {
    return NoteListState(
      loading: loading ?? this.loading,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [loading, notes];
}

class NoteList extends ChangeNotifier {
  NoteListState state = NoteListState(loading: false, notes: []);
  bool _hasNextDocs = true;

  bool get hasNextDocs => _hasNextDocs;

  void handleError(Exception e) {
    print(e);
    state = state.copyWith(loading: false);
    notifyListeners();
  }

  Future<void> getNotes(String userId, int limit) async {
    state = state.copyWith(loading: true);
    notifyListeners();

    try {
      QuerySnapshot userNotesSnapshot;
      DocumentSnapshot startAfterDoc;

      if (state.notes.isNotEmpty) {
        Note n = state.notes.last;
        startAfterDoc =
            await notesRef.doc(userId).collection('userNotes').doc(n.id).get();
      } else {
        startAfterDoc = null;
      }

      final refNotes = notesRef
          .doc(userId)
          .collection('userNotes')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfterDoc == null) {
        userNotesSnapshot = await refNotes.get();
      } else {
        userNotesSnapshot =
            await refNotes.startAfterDocument(startAfterDoc).get();
      }

      List<Note> notes = userNotesSnapshot.docs.map((noteDoc) {
        return Note.fromDoc(noteDoc);
      }).toList();

      if (userNotesSnapshot.docs.length < limit) {
        _hasNextDocs = false;
      }

      state = state.copyWith(loading: false, notes: [...state.notes, ...notes]);
      notifyListeners();
    } catch (e) {
      handleError(e);
      rethrow;
    }
  }

  Future<void> getAllNotes(String userId) async {
    state = state.copyWith(loading: true);
    notifyListeners();

    try {
      QuerySnapshot userNotesSnapshot = await notesRef
          .doc(userId)
          .collection('userNotes')
          .orderBy('timestamp', descending: true)
          .get();

      List<Note> notes = userNotesSnapshot.docs.map((noteDoc) {
        return Note.fromDoc(noteDoc);
      }).toList();

      state = state.copyWith(loading: false, notes: notes);
      notifyListeners();
    } catch (e) {
      handleError(e);
      rethrow;
    }
  }

  Future<List<QuerySnapshot>> searchNotes(
    String userId,
    String searchTerm,
  ) async {
    try {
      final snapshotOne = notesRef
          .doc(userId)
          .collection('userNotes')
          .where('title', isGreaterThanOrEqualTo: searchTerm)
          .where('title', isLessThanOrEqualTo: searchTerm + 'z');

      final snapshotTwo = notesRef
          .doc(userId)
          .collection('userNotes')
          .where('desc', isGreaterThanOrEqualTo: searchTerm)
          .where('desc', isLessThanOrEqualTo: searchTerm + 'z');

      final userNotesSnapshot =
          await Future.wait([snapshotOne.get(), snapshotTwo.get()]);

      return userNotesSnapshot;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addNote(Note newNote) async {
    state = state.copyWith(loading: true);
    notifyListeners();

    try {
      DocumentReference docRef =
          await notesRef.doc(newNote.noteOwnerId).collection('userNotes').add({
        'title': newNote.title,
        'desc': newNote.desc,
        'noteOwnerId': newNote.noteOwnerId,
        'timestamp': newNote.timestamp,
      });

      final note = Note(
        id: docRef.id,
        title: newNote.title,
        desc: newNote.desc,
        noteOwnerId: newNote.noteOwnerId,
        timestamp: newNote.timestamp,
      );

      state = state.copyWith(loading: false, notes: [
        note,
        ...state.notes,
      ]);
      notifyListeners();
    } catch (e) {
      handleError(e);
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
    state = state.copyWith(loading: true);
    notifyListeners();

    try {
      await notesRef
          .doc(note.noteOwnerId)
          .collection('userNotes')
          .doc(note.id)
          .update({
        'title': note.title,
        'desc': note.desc,
      });

      final notes = state.notes.map((n) {
        return n.id == note.id
            ? Note(
                id: n.id,
                title: note.title,
                desc: note.desc,
                timestamp: note.timestamp,
              )
            : n;
      }).toList();

      state = state.copyWith(loading: false, notes: notes);
      notifyListeners();
    } catch (e) {
      handleError(e);
      rethrow;
    }
  }

  Future<void> removeNote(Note note) async {
    state = state.copyWith(loading: true);
    notifyListeners();

    try {
      await notesRef
          .doc(note.noteOwnerId)
          .collection('userNotes')
          .doc(note.id)
          .delete();

      final notes = state.notes.where((n) => n.id != note.id).toList();
      state = state.copyWith(loading: false, notes: notes);
      notifyListeners();
    } catch (e) {
      handleError(e);
      rethrow;
    }
  }
}
