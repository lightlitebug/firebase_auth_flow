import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:firebase_auth_flow/models/note_model.dart';
import 'package:firebase_auth_flow/pages/add_edit_note_page.dart';
import 'package:firebase_auth_flow/providers/note_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  Future<List<QuerySnapshot>> _notes;
  String userId, searchTerm;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<firebaseAuth.User>();
      userId = user.uid;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _notes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          style: TextStyle(color: Colors.white),
          controller: _searchController,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
            filled: true,
            border: InputBorder.none,
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.white),
            prefixIcon: Icon(
              Icons.search,
              size: 30.0,
              color: Colors.white,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.clear,
                size: 30.0,
                color: Colors.white,
              ),
              onPressed: _clearSearch,
            ),
          ),
          onSubmitted: (val) {
            searchTerm = val;
            if (searchTerm.isNotEmpty) {
              setState(() {
                _notes =
                    context.read<NoteList>().searchNotes(userId, searchTerm);
              });
            }
          },
        ),
      ),
      body: _notes == null
          ? Center(
              child: Text(
                'Search for Notes',
                style: TextStyle(fontSize: 18.0),
              ),
            )
          : FutureBuilder(
              future: _notes,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                print(snapshot.data.length);

                List<Note> foundNotes = [];

                for (int i = 0; i < snapshot.data.length; i++) {
                  for (int j = 0; j < snapshot.data[i].docs.length; j++) {
                    foundNotes.add(Note.fromDoc(snapshot.data[i].docs[j]));
                  }
                }

                foundNotes = [
                  ...{...foundNotes}
                ];

                if (foundNotes.length == 0) {
                  return Center(
                    child: Text(
                      'No note found, please try again',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: foundNotes.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Note note = foundNotes[index];

                    return Card(
                      child: ListTile(
                        onTap: () async {
                          final modified = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return AddEditNotePage(note: note);
                              },
                            ),
                          );
                          if (modified == true) {
                            setState(() {
                              _notes = context
                                  .read<NoteList>()
                                  .searchNotes(userId, searchTerm);
                            });
                          }
                        },
                        title: Text(
                          note.title,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd, hh:mm:ss')
                              .format(note.timestamp.toDate()),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
