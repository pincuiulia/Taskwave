import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DayViewPage extends StatefulWidget {
  final DatabaseService databaseService;

  const DayViewPage({Key? key, required this.databaseService}) : super(key: key);

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

  void _addEvent() async {
    final now = DateTime.now();
    await widget.databaseService.addEvent(
      title: 'New Event',
      description: 'Description for new event',
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
    );
    _loadEventsForDay(DateTime.now());
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('${hour.toString().padLeft(2, '0')}:00'),
                    ),
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
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
