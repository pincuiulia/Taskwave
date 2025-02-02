import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarList extends StatefulWidget {
  const CalendarList({Key? key}) : super(key: key);

  @override
  _CalendarListState createState() => _CalendarListState();
}

class _CalendarListState extends State<CalendarList> {
  List<String> _calendars = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendars();
    });
  }

  Future<void> _loadCalendars() async {
    final prefs = await SharedPreferences.getInstance();
    final String? calendarsJson = prefs.getString('calendars');
    if (calendarsJson != null) {
      setState(() {
        _calendars = List<String>.from(json.decode(calendarsJson));
      });
    }
  }

  Future<void> _saveCalendars() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calendars', json.encode(_calendars));
  }

  void _addCalendar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String calendarName = '';
        return AlertDialog(
          title: const Text('Add Calendar'),
          content: TextField(
            onChanged: (value) => calendarName = value.trim(),
            decoration: const InputDecoration(hintText: 'Enter calendar name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (calendarName.isNotEmpty && !_calendars.contains(calendarName)) {
                  setState(() {
                    _calendars.add(calendarName);
                  });
                  _saveCalendars();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCalendar(int index) {
    setState(() {
      _calendars.removeAt(index);
    });
    _saveCalendars();
  }

  void _openCalendar(String calendarName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarPage(calendarName: calendarName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Calendars',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: _calendars.isEmpty
          ? const Center(
              child: Text(
                "No calendars found. Create one!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _calendars.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openCalendar(_calendars[index]),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey.shade200,
                        child: const Icon(Icons.calendar_today, color: Colors.white),
                      ),
                      title: Text(
                        _calendars[index],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCalendar(index),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCalendar,
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  final String calendarName;

  const CalendarPage({Key? key, required this.calendarName}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();

  /// Structură: dateString -> listă de evenimente
  ///
  /// {
  ///   "2025-02-01": [
  ///       {
  ///         "title": "Meeting",
  ///         "description": "Discuss project status",
  ///         "startTime": "10:00",
  ///         "endTime": "11:30",
  ///         "color": 4294198070,
  ///         "tasks": [
  ///             {
  ///               "title": "Task X",
  ///               "status": "Pending"
  ///             }
  ///         ]
  ///       }
  ///   ]
  /// }
  Map<String, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsJson = prefs.getString(widget.calendarName);
    if (eventsJson != null) {
      final decoded = json.decode(eventsJson) as Map<String, dynamic>;
      final Map<String, List<Map<String, dynamic>>> loadedEvents =
          decoded.map((date, listOfEvents) {
        final List<Map<String, dynamic>> convertedEvents =
            List<Map<String, dynamic>>.from(
          listOfEvents.map((e) => Map<String, dynamic>.from(e)),
        );
        return MapEntry(date, convertedEvents);
      });
      setState(() {
        _events = loadedEvents;
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.calendarName, json.encode(_events));
  }

  void _addEvent({
    required String title,
    required String description,
    required String startTime,
    required String endTime,
    required int colorValue,
  }) {
    setState(() {
      final key = _selectedDay.toIso8601String().split('T')[0];
      final newEvent = {
        "title": title,
        "description": description,
        "startTime": startTime,
        "endTime": endTime,
        "color": colorValue,
        "tasks": <Map<String, dynamic>>[], // listă goală de task-uri
      };

      if (_events[key] == null) {
        _events[key] = [newEvent];
      } else {
        _events[key]!.add(newEvent);
      }
      _saveEvents();
    });
  }

  Future<void> _showAddEventDialog() async {
    String title = '';
    String description = '';
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    final List<Color> colorOptions = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.grey,
    ];
    Color selectedColor = colorOptions.first;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    TextField(
                      onChanged: (value) => title = value,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    // Description
                    TextField(
                      onChanged: (value) => description = value,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 8),
                    // Start Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Start Time: ${startTime?.format(context) ?? '--:--'}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                startTime = picked;
                              });
                            }
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                    // End Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'End Time: ${endTime?.format(context) ?? '--:--'}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                endTime = picked;
                              });
                            }
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Color Picker (simple dropdown)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Color: '),
                        DropdownButton<Color>(
                          value: selectedColor,
                          items: colorOptions.map((color) {
                            return DropdownMenuItem<Color>(
                              value: color,
                              child: Row(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    color: color,
                                    margin: const EdgeInsets.only(right: 8),
                                  ),
                                  Text(_colorToString(color)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (color) {
                            if (color != null) {
                              setStateDialog(() {
                                selectedColor = color;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (title.isNotEmpty && startTime != null && endTime != null) {
                      final startTimeStr = _timeOfDayToString(startTime!);
                      final endTimeStr = _timeOfDayToString(endTime!);
                      _addEvent(
                        title: title,
                        description: description,
                        startTime: startTimeStr,
                        endTime: endTimeStr,
                        colorValue: selectedColor.value,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Event'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _colorToString(Color color) {
    if (color == Colors.red) return "Red";
    if (color == Colors.blue) return "Blue";
    if (color == Colors.green) return "Green";
    if (color == Colors.orange) return "Orange";
    if (color == Colors.purple) return "Purple";
    if (color == Colors.grey) return "Grey";
    // fallback
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Deschide pagina de detalii a unui eveniment (pt. task-uri)
  void _openEventDetails(String dateKey, int eventIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(
          dateKey: dateKey,
          eventIndex: eventIndex,
          events: _events,
          onUpdate: (updatedEvents) {
            setState(() {
              _events = updatedEvents;
            });
            _saveEvents();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _selectedDay.toIso8601String().split('T')[0];
    final eventsForDay = _events[dateKey] ?? [];

    // Sort the events by startTime before building the list
    eventsForDay.sort((a, b) {
      final startA = a["startTime"] ?? "00:00";
      final startB = b["startTime"] ?? "00:00";
      return startA.compareTo(startB);
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.calendarName)),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
          ),
          // Display events (sorted by startTime)
          Expanded(
            child: ListView.builder(
              itemCount: eventsForDay.length,
              itemBuilder: (context, index) {
                final event = eventsForDay[index];
                final eventColor = Color(event["color"]);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: eventColor.withOpacity(0.1),
                  child: ListTile(
                    onTap: () => _openEventDetails(dateKey, index), // intrăm pe detalii
                    leading: CircleAvatar(
                      backgroundColor: eventColor,
                      child: const Icon(Icons.event, color: Colors.white),
                    ),
                    title: Text(
                      event["title"] ?? "No Title",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${event["description"] ?? ""}\n'
                      'Start: ${event["startTime"]} - End: ${event["endTime"]}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
          // Add Event Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _showAddEventDialog,
              child: const Text('Add Event'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pagina de detalii pentru un eveniment specific.
/// Permite adăugarea și modificarea task-urilor (cu status).
class EventDetailPage extends StatefulWidget {
  final String dateKey;
  final int eventIndex;
  final Map<String, List<Map<String, dynamic>>> events;

  /// Callback pentru a actualiza starea (_events) din CalendarPage
  final Function(Map<String, List<Map<String, dynamic>>>) onUpdate;

  const EventDetailPage({
    Key? key,
    required this.dateKey,
    required this.eventIndex,
    required this.events,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Map<String, dynamic> eventData;

  /// Valori posibile pentru status
  final List<String> _statuses = ["Pending", "Ongoing", "Canceled", "Completed"];

  @override
  void initState() {
    super.initState();
    // Referință spre evenimentul selectat
    eventData = widget.events[widget.dateKey]![widget.eventIndex];
    // Dacă tasks e null, îl transformăm într-o listă goală
    eventData["tasks"] ??= <Map<String, dynamic>>[];
  }

  void _addTask(String taskTitle) {
    setState(() {
      final tasks = eventData["tasks"] as List<dynamic>;
      tasks.add({
        "title": taskTitle,
        "status": "Pending", // status default
      });
    });
    // Trimitem noua structură la părinte
    widget.onUpdate(widget.events);
  }

  void _updateTaskStatus(int index, String newStatus) {
    setState(() {
      final tasks = eventData["tasks"] as List<dynamic>;
      tasks[index]["status"] = newStatus;
    });
    widget.onUpdate(widget.events);
  }

  /// Determină culoarea de fundal a unui task, în funcție de status
  Color _getStatusColor(String status) {
    switch (status) {
      case "Ongoing":
        return Colors.blue.withOpacity(0.2);
      case "Pending":
        return Colors.purple.withOpacity(0.2);
      case "Canceled":
        return Colors.red.withOpacity(0.2);
      case "Completed":
        return Colors.green.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Future<void> _showAddTaskDialog() async {
    String taskTitle = '';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: TextField(
            onChanged: (value) => taskTitle = value,
            decoration: const InputDecoration(
              labelText: 'Task title',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                if (taskTitle.isNotEmpty) {
                  _addTask(taskTitle);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = eventData["tasks"] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(eventData["title"] ?? "Event Details"),
      ),
      body: Column(
        children: [
          // Info eveniment (descriere, oră, etc.)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Description: ${eventData["description"] ?? "No description"}\n'
              'Start: ${eventData["startTime"] ?? "--:--"}\n'
              'End: ${eventData["endTime"] ?? "--:--"}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const Divider(),
          // Listă de task-uri (cu status și design)
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (BuildContext context, int index) {
                final task = tasks[index];
                final String title = task["title"] ?? "";
                final String status = task["status"] ?? "Pending";

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: DropdownButton<String>(
                      value: status,
                      underline: const SizedBox(), // ascunde linia sub dropdown
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _updateTaskStatus(index, newValue);
                        }
                      },
                      items: _statuses.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
