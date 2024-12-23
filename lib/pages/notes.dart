import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../backend/functions.dart';

void main() {
  runApp(NotesPage());
}

class NotesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: NotesHomePage(),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  @override
  _NotesHomePageState createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    final notesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('notes')
        .get();

    final List<Note> loadedNotes = [];
    notesSnapshot.docs.forEach((doc) {
      final data = doc.data();
      loadedNotes.add(Note(
        id: doc.id,
        title: data['title'],
        content: data['content'],
        category: data['category'],
      ));
    });

    setState(() {
      _notes = loadedNotes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslations()['notes']!),
      ),
      body: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetailPage(note: _notes[index]),
                ),
              );
            },
            child: AnimatedNoteCard(
              note: _notes[index],
              index: index,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newNote = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditNotePage(),
            ),
          );
          if (newNote != null) {
            setState(() {
              _notes.add(newNote);
            });
          }
        },
        label: Text(getTranslations()['add_note']!),
        icon: Icon(Icons.note_add),
        backgroundColor: Colors.blue.shade50,
      ),
    );
  }
}


class Note {
  final String id;
  final String title;
  final String content;
  final String category;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
  });
}

class AnimatedNoteCard extends StatefulWidget {
  final Note note;
  final int index;

  const AnimatedNoteCard({Key? key, required this.note, required this.index}) : super(key: key);

  @override
  _AnimatedNoteCardState createState() => _AnimatedNoteCardState();
}

class _AnimatedNoteCardState extends State<AnimatedNoteCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _offsetAnimation = Tween<Offset>(begin: Offset(0.0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: NoteCard(note: widget.note),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final Note note;

  const NoteCard({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(
          note.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _trimContent(note.content),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        trailing: Text(note.category),
      ),
    );
  }

  String _trimContent(String content) {
    if (content.length > 50) {
      return content.substring(0, 50) + '...'; // Trim content to 50 characters
    } else {
      return content;
    }
  }
}

class NoteDetailPage extends StatelessWidget {
  final Note note;

  const NoteDetailPage({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditNotePage(
                    note: note,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              // Implement delete functionality
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(getTranslations()['delete_note']!),
                    content: Text(getTranslations()['Are_you_sure_you_want_to_delete_this_note']!),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(getTranslations()['cancel']!),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context, note.id);
                        },
                        child: Text(getTranslations()['delete']!),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${getTranslations()['category']}: ${note.category}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),
              Text(note.content),
            ],
          ),
        ),
      ),
    );
  }
}

class AddEditNotePage extends StatefulWidget {
  final Note? note;

  const AddEditNotePage({Key? key, this.note}) : super(key: key);

  @override
  _AddEditNotePageState createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _categoryController.text = widget.note!.category;
    } else {
      _titleController.text =  getTranslations()['new_note']!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? getTranslations()['add_note']! : getTranslations()['add_note']!),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: getTranslations()['title']!,
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: getTranslations()['content']!,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: getTranslations()['category']!,
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final title = _titleController.text.trim();
                final content = _contentController.text.trim();
                if (title.isNotEmpty && content.isNotEmpty) {
                  final newNote = Note(
                    id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    content: content,
                    category: _categoryController.text,
                  );

                  try {
                    await FirebaseFirestore.instance.collection('users').
                    doc(userEmail).
                    collection('notes').
                    doc(newNote.id).set({
                      'title': newNote.title,
                      'content': newNote.content,
                      'category': newNote.category,
                      // Add other fields if necessary
                    });

                    Navigator.pop(context, newNote);
                  } catch (e) {
                    print('Error saving note: $e');
                    // Handle error
                  }
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(getTranslations()['error']!),
                        content: Text(getTranslations()['Title_and_content_cannot_be_empty']!),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(getTranslations()['error']!),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text(getTranslations()['save']!),
            ),

          ],
        ),
      ),
    );
  }
}
