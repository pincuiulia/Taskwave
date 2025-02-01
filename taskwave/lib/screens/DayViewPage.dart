import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DayViewPage extends StatefulWidget {
  final DatabaseService databaseService;

  const DayViewPage({super.key, required this.databaseService});

  @override
  _DayViewPageState createState() => _DayViewPageState();
}

class _DayViewPageState extends State<DayViewPage> {
  late Future<List<Map<String, dynamic>>> _events;

  @override
  void initState() {
    super.initState();
    _loadEventsForDay(DateTime.now());
  }

  void _loadEventsForDay(DateTime date) {
    setState(() {
      _events = widget.databaseService.fetchEventsForDay(date);
    });
  }

void _showAddEventDialog() {
  print("Dialogul de adăugare eveniment este apelat.");
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Add Event",
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter event title",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Event Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: "Start Time",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: "End Time",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    print("Event added!");
                    Navigator.of(context).pop();
                  },
                  child: const Text("Add Event"),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day View'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _events,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

          return ListView.builder(
            itemCount: 24,
            itemBuilder: (context, hour) {
              final hourEvents = events.where((event) {
                final startTime = DateTime.parse(event['start_time']);
                return startTime.hour == hour;
              }).toList();

              return Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Text('${hour.toString().padLeft(2, '0')}:00'),
                    ...hourEvents.map((event) => Container(
                          margin: const EdgeInsets.only(left: 8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(event['title']),
                        )),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
