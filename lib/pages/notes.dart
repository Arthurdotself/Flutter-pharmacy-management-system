import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> notes = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showAddNoteDialog({int? index, Note? initialNote}) async {
    final TextEditingController textController = TextEditingController(text: initialNote?.text);
    bool enableNotification = false;
    DateTime? selectedDateTime;

    if (initialNote != null && initialNote.notificationDateTime != null) {
      selectedDateTime = initialNote.notificationDateTime;
      enableNotification = true;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(index != null ? 'Edit Note' : 'Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                onChanged: (value) {
                  textController.text = value;
                },
                decoration: InputDecoration(hintText: 'Enter your note here'),
              ),
              CheckboxListTile(
                title: Text('Enable Notification'),
                value: enableNotification,
                onChanged: (value) {
                  setState(() {
                    enableNotification = value!;
                  });
                },
              ),
              if (enableNotification) ...[
                TextButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      final TimeOfDay? timePicked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (timePicked != null) {
                        setState(() {
                          selectedDateTime = DateTime(picked.year, picked.month, picked.day, timePicked.hour, timePicked.minute);
                        });
                      }
                    }
                  },
                  child: Text(selectedDateTime != null ? 'Change Notification Time' : 'Set Notification Time'),
                ),
                if (selectedDateTime != null) Text('Notification Time: ${selectedDateTime.toString()}'),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                final trimmedText = textController.text.trim();
                if (trimmedText.isNotEmpty) {
                  setState(() {
                    if (index != null) {
                      notes[index].text = trimmedText;
                      notes[index].notificationDateTime = selectedDateTime;
                    } else {
                      notes.add(Note(
                        text: trimmedText,
                        notificationDateTime: selectedDateTime,
                      ));
                    }
                  });
                  if (enableNotification && selectedDateTime != null) {
                    _scheduleNotification(index ?? notes.length - 1, textController.text, selectedDateTime!);
                  }
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Note cannot be empty or contain only spaces!'),
                    ),
                  );
                }
              },
              child: Text(index != null ? 'Save' : 'Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scheduleNotification(int id, String text, DateTime dateTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails('your channel id', 'your channel name', 'your channel description');
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Note Notification',
      text,
      tz.TZDateTime.from(dateTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: notes.length * 2 + 1, // Corrected item count
        itemBuilder: (BuildContext context, int index) {
          if (index.isOdd) {
            // Separator
            return Divider();
          }
          final noteIndex = index ~/ 2;
          if (noteIndex >= notes.length) {
            // Handle out-of-range index
            return SizedBox.shrink(); // Return an empty widget
          }
          return ListTile(
            title: Text(notes[noteIndex].text),
            onTap: () {
              _showAddNoteDialog(index: noteIndex, initialNote: notes[noteIndex]);
            },
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _deleteNote(noteIndex);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddNoteDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Note {
  String text;
  DateTime? notificationDateTime;

  Note({
    required this.text,
    this.notificationDateTime,
  });
}

void main() {
  runApp(MaterialApp(
    home: NotesPage(),
  ));
}
