import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Plugin global pentru notificări
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Punctul de intrare în aplicație.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();
  }
  tz.initializeTimeZones();

  // Setăm manual fusul orar la UTC+2
  tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));

  // Inițializare flutter_local_notifications
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      // Aici poți trata ce se întâmplă când user-ul apasă notificarea
    },
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(), // Start direct cu MainPage
    ),
  );
}

//
//                    MAIN PAGE
// ------------------------------------------------------------
//  Afișează task-urile pentru ziua curentă (status, orar),
//  și statistici (Completed, Pending, Canceled, Ongoing).
//  + Încarcă 'darkMode' din JSON și setează backgroundColor.
//

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1;

  // Lista cu task-urile de azi
  List<Map<String, dynamic>> _todayTasks = [];

  // Flag care spune dacă e Dark Mode
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModeFromJson();
    _loadTodayTasks();
  }

  /// Încarcă `darkMode` din JSON-ul salvat în SharedPreferences (cheia "app_settings").
  Future<void> _loadDarkModeFromJson() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString('app_settings') ?? '{}';
    final Map<String, dynamic> settingsMap = jsonDecode(settingsString);

    setState(() {
      _isDarkMode = (settingsMap['darkMode'] as bool?) ?? false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Încarcă toate calendarele și evenimentele cu data de azi.
  Future<void> _loadTodayTasks() async {
    final prefs = await SharedPreferences.getInstance();

    // Data curentă sub formă "YYYY-MM-DD"
    final now = DateTime.now();
    final dateKey = now.toIso8601String().split('T')[0];

    // Lista de calendare
    final String? calendarsJson = prefs.getString('calendars');
    if (calendarsJson == null) return; // nu există calendare
    final List<dynamic> calendars = json.decode(calendarsJson);

    List<Map<String, dynamic>> loadedTasks = [];

    for (var c in calendars) {
      final String calendarName = c;
      final String? eventsJson = prefs.getString(calendarName);
      if (eventsJson == null) continue;

      final Map<String, dynamic> eventsMap = json.decode(eventsJson);

      // Dacă există evenimente pentru ziua curentă (dateKey)
      if (eventsMap.containsKey(dateKey)) {
        List<dynamic> eventsForToday = eventsMap[dateKey];
        for (var e in eventsForToday) {
          final Map<String, dynamic> eventData = e;
          final String start = eventData["startTime"] ?? "--:--";
          final String end   = eventData["endTime"]   ?? "--:--";

          if (eventData.containsKey("tasks")) {
            final List<dynamic> tasks = eventData["tasks"];
            for (var t in tasks) {
              final Map<String, dynamic> taskData = t;
              final String taskTitle = taskData["title"]  ?? "(No title)";
              final String status    = taskData["status"] ?? "Pending";

              loadedTasks.add({
                "taskTitle": taskTitle,
                "startTime": start,
                "endTime": end,
                "status": status,
              });
            }
          }
        }
      }
    }

    setState(() {
      _todayTasks = loadedTasks;
    });
  }

  /// Număr de task-uri pe un anumit status
  int _countTasksByStatus(String status) {
    return _todayTasks.where((t) => t["status"] == status).length;
  }

  /// Culoarea de fundal pentru un task, în funcție de status
  Color _getStatusColor(String status) {
    switch (status) {
      case "Ongoing":
        return Colors.blue.withOpacity(0.2);
      case "Canceled":
        return Colors.red.withOpacity(0.2);
      case "Completed":
        return Colors.green.withOpacity(0.2);
      case "Pending":
        return Colors.purple.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculăm câte task-uri sunt Completed, Pending, Canceled, Ongoing
    final int completedCount = _countTasksByStatus("Completed");
    final int pendingCount   = _countTasksByStatus("Pending");
    final int canceledCount  = _countTasksByStatus("Canceled");
    final int ongoingCount   = _countTasksByStatus("Ongoing");

    // Culori de background, text etc. dacă e Dark Mode
    final backgroundColor = _isDarkMode ? Colors.black : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = _isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: DefaultTextStyle(
            style: TextStyle(color: textColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salut & avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hi, Iulia',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor:
                          _isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: Icon(Icons.person, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Let's make this day productive",
                  style: TextStyle(fontSize: 16, color: secondaryTextColor),
                ),
                const SizedBox(height: 30),

                // 2 carduri: Completed, Pending
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTaskCard("Completed", completedCount, Colors.green),
                    _buildTaskCard("Pending", pendingCount, Colors.purple),
                  ],
                ),
                const SizedBox(height: 16),

                // 2 carduri: Canceled, On Going
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTaskCard("Canceled", canceledCount, Colors.red),
                    _buildTaskCard("On Going", ongoingCount, Colors.blue),
                  ],
                ),
                const SizedBox(height: 30),

                const Text(
                  'Today Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                _todayTasks.isEmpty
                    ? Text(
                        "No tasks for today.",
                        style: TextStyle(fontSize: 16, color: secondaryTextColor),
                      )
                    : Column(
                        children: List.generate(
                          _todayTasks.length,
                          (index) {
                            final task = _todayTasks[index];
                            return _buildTodayTask(
                              task["taskTitle"] ?? "No title",
                              '${task["startTime"]} - ${task["endTime"]}',
                              task["status"] ?? "Pending",
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Buton 1
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.home,
                    color: _isDarkMode ? Colors.blue[300] : Colors.blue,
                    size: 30),
              ),
              // Buton 2: CalendarList
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CalendarList()),
                  ).then((_) {
                    _loadTodayTasks();
                  });
                },
                icon: Icon(Icons.calendar_today,
                    color: _isDarkMode ? Colors.blue[300] : Colors.blue,
                    size: 30),
              ),
              // Buton mare Add
              CircleAvatar(
                radius: 30,
                backgroundColor: _isDarkMode ? Colors.blue[300] : Colors.blue,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
              // Buton 4
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.trending_up,
                    color: _isDarkMode ? Colors.blue[300] : Colors.blue,
                    size: 30),
              ),
              // Buton 5: Setări
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  ).then((_) {
                    _loadDarkModeFromJson();
                  });
                },
                icon: Icon(Icons.settings,
                    color: _isDarkMode ? Colors.blue[300] : Colors.blue,
                    size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construiește un card cu status + count (ex: "Completed", 5)
  Widget _buildTaskCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width / 2 - 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$count Task',
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Construiește widget-ul pentru un task de azi, incluzând status.
  Widget _buildTodayTask(String taskName, String time, String status) {
    final backgroundColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Info task: nume + orar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                taskName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],
          ),
          // Badge cu statusul
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

//
//               CALENDAR LIST
// ------------------------------------------------------------
class CalendarList extends StatefulWidget {
  const CalendarList({super.key});

  @override
  State<CalendarList> createState() => _CalendarListState();
}

class _CalendarListState extends State<CalendarList> {
  List<String> _calendars = [];
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDarkModeFromJson();
      _loadCalendars();
    });
  }

  Future<void> _loadDarkModeFromJson() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString('app_settings') ?? '{}';
    final Map<String, dynamic> settingsMap = jsonDecode(settingsString);

    setState(() {
      _isDarkMode = (settingsMap['darkMode'] as bool?) ?? false;
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
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text('Add Calendar',
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: TextField(
            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
            onChanged: (value) => calendarName = value.trim(),
            decoration: InputDecoration(
              hintText: 'Enter calendar name',
              hintStyle: TextStyle(color: _isDarkMode ? Colors.grey : Colors.grey[700]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: _isDarkMode ? Colors.blue[300] : Colors.blue)),
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
    ).then((_) {
      _loadDarkModeFromJson();
      _loadCalendars();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? Colors.black : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('My Calendars', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: DefaultTextStyle(
        style: TextStyle(color: textColor),
        child: _calendars.isEmpty
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
                      color: _isDarkMode ? Colors.grey[800] : Colors.white,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCalendar,
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

//
//              CALENDAR PAGE
// ------------------------------------------------------------
// Folosim zonedSchedule pentru a programa notificări la data/ora setată
// (plus minus 5 minute), folosind fus orar local.
//
class CalendarPage extends StatefulWidget {
  final String calendarName;
  const CalendarPage({super.key, required this.calendarName});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  Map<String, List<Map<String, dynamic>>> _events = {};

  bool _isDarkMode = false;
  bool _notificationsOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettingsFromJson();
      _loadEvents();
    });
  }

  Future<void> _loadSettingsFromJson() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString('app_settings') ?? '{}';
    final Map<String, dynamic> settingsMap = jsonDecode(settingsString);

    setState(() {
      _isDarkMode = (settingsMap['darkMode'] as bool?) ?? false;
      _notificationsOn = (settingsMap['notificationsOn'] as bool?) ?? true;
    });
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsJson = prefs.getString(widget.calendarName);
    if (eventsJson != null) {
      final decoded = json.decode(eventsJson) as Map<String, dynamic>;
      final Map<String, List<Map<String, dynamic>>> loadedEvents =
          decoded.map((date, listOfEvents) {
        final List<Map<String, dynamic>> converted = List<Map<String, dynamic>>.from(
          listOfEvents.map((e) => Map<String, dynamic>.from(e)),
        );
        return MapEntry(date, converted);
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

  // Programăm notificări cu 5 min înainte, dar folosim `zonedSchedule` și `TZDateTime`.
  Future<void> _zonedScheduleNotificationIfNeeded({
    required String title,
    required DateTime dateTime,
  }) async {
    if (!_notificationsOn) return;

    // Calculăm momentul (dateTime - 5 minute)
    final scheduledTime = dateTime.subtract(const Duration(seconds: 60));
    if (scheduledTime.isBefore(DateTime.now())) return;

    // Convertim la TZDateTime
    final tz.TZDateTime tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final androidDetails = const AndroidNotificationDetails(
      'task_channel_id',
      'Task Notifications',
      channelDescription: 'Notificări pentru evenimente',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationId = dateTime.millisecondsSinceEpoch % 100000;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'TaskWave Reminder',
      'Event "$title" starts in 5 minutes!',
      tzDateTime,
      NotificationDetails(android: androidDetails),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  void _addEvent({
    required String title,
    required String description,
    required String startTime,
    required String endTime,
    required int colorValue,
  }) {
    final dateKey = _selectedDay.toIso8601String().split('T')[0];
    setState(() {
      final newEvent = {
        "title": title,
        "description": description,
        "startTime": startTime,
        "endTime": endTime,
        "color": colorValue,
        "tasks": <Map<String, dynamic>>[],
      };

      if (_events[dateKey] == null) {
        _events[dateKey] = [newEvent];
      } else {
        _events[dateKey]!.add(newEvent);
      }
    });

    _saveEvents();

    _tryZonedScheduleReminderForEvent(title, startTime);
  }

  void _tryZonedScheduleReminderForEvent(String title, String startTimeString) {
    try {
      final parts = startTimeString.split(':'); // "HH:mm"
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final eventDateTime = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        hour,
        minute,
      );
      _zonedScheduleNotificationIfNeeded(title: title, dateTime: eventDateTime);
    } catch (e) {
      // nu se poate parse
    }
  }

  final List<Color> _colorOptions = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.purple,
  ];

  Future<void> _showAddEventDialog() async {
    String title = '';
    String description = '';
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    Color selectedColor = _colorOptions.first;

    await showDialog(
      context: context,
      builder: (context) {
        final bgColor = _isDarkMode ? Colors.grey[900] : Colors.white;
        final textColor = _isDarkMode ? Colors.white : Colors.black;
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              backgroundColor: bgColor,
              title: Text('Add Event', style: TextStyle(color: textColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    TextField(
                      style: TextStyle(color: textColor),
                      onChanged: (value) => title = value,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: textColor),
                      ),
                    ),
                    // Description
                    TextField(
                      style: TextStyle(color: textColor),
                      onChanged: (value) => description = value,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: textColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Start Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Start Time: ${startTime?.format(context) ?? '--:--'}',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() => startTime = picked);
                            }
                          },
                          child: Text('Select',
                              style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                    // End Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'End Time: ${endTime?.format(context) ?? '--:--'}',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() => endTime = picked);
                            }
                          },
                          child: Text('Select',
                              style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Color Picker (4 opțiuni)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Color: ', style: TextStyle(color: textColor)),
                        DropdownButton<Color>(
                          dropdownColor: bgColor,
                          value: selectedColor,
                          items: _colorOptions.map((color) {
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
                                  Text(_colorName(color),
                                      style: TextStyle(color: textColor)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (color) {
                            if (color != null) {
                              setStateDialog(() => selectedColor = color);
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
                  child: Text('Cancel',
                      style: TextStyle(color: Colors.blueAccent)),
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

  String _colorName(Color c) {
    if (c == Colors.red) return "Red";
    if (c == Colors.blue) return "Blue";
    if (c == Colors.green) return "Green";
    if (c == Colors.purple) return "Purple";
    return "Unknown";
  }

  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

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
    ).then((_) => _loadSettingsFromJson());
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _selectedDay.toIso8601String().split('T')[0];
    final eventsForDay = _events[dateKey] ?? [];

    // Sortăm evenimentele după startTime
    eventsForDay.sort((a, b) {
      final startA = a["startTime"] ?? "00:00";
      final startB = b["startTime"] ?? "00:00";
      return startA.compareTo(startB);
    });

    final bgColor = _isDarkMode ? Colors.black : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text(widget.calendarName)),
      body: DefaultTextStyle(
        style: TextStyle(color: textColor),
        child: Column(
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
            Expanded(
              child: ListView.builder(
                itemCount: eventsForDay.length,
                itemBuilder: (context, index) {
                  final event = eventsForDay[index];
                  final eventColor = Color(event["color"]);
                  return Card(
                    color: _isDarkMode
                        ? eventColor.withOpacity(0.2)
                        : eventColor.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      onTap: () => _openEventDetails(dateKey, index),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _showAddEventDialog,
                child: const Text('Add Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
//            EVENT DETAIL PAGE
// ------------------------------------------------------------
class EventDetailPage extends StatefulWidget {
  final String dateKey;
  final int eventIndex;
  final Map<String, List<Map<String, dynamic>>> events;
  final Function(Map<String, List<Map<String, dynamic>>>) onUpdate;

  const EventDetailPage({
    super.key,
    required this.dateKey,
    required this.eventIndex,
    required this.events,
    required this.onUpdate,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Map<String, dynamic> eventData;
  final List<String> _statuses = ["Pending", "Ongoing", "Canceled", "Completed"];

  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    eventData = widget.events[widget.dateKey]![widget.eventIndex];
    eventData["tasks"] ??= <Map<String, dynamic>>[];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDarkModeFromJson();
    });
  }

  Future<void> _loadDarkModeFromJson() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString('app_settings') ?? '{}';
    final Map<String, dynamic> settingsMap = jsonDecode(settingsString);

    setState(() {
      _isDarkMode = (settingsMap['darkMode'] as bool?) ?? false;
    });
  }

  void _addTask(String taskTitle) {
    setState(() {
      final tasks = eventData["tasks"] as List<dynamic>;
      tasks.add({
        "title": taskTitle,
        "status": "Pending",
      });
    });
    widget.onUpdate(widget.events);
  }

  void _updateTaskStatus(int index, String newStatus) {
    setState(() {
      final tasks = eventData["tasks"] as List<dynamic>;
      tasks[index]["status"] = newStatus;
    });
    widget.onUpdate(widget.events);
  }

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
      builder: (context) {
        final bgColor = _isDarkMode ? Colors.grey[900] : Colors.white;
        final textColor = _isDarkMode ? Colors.white : Colors.black;
        return AlertDialog(
          backgroundColor: bgColor,
          title: Text('Add Task', style: TextStyle(color: textColor)),
          content: TextField(
            style: TextStyle(color: textColor),
            onChanged: (value) => taskTitle = value,
            decoration: InputDecoration(
              labelText: 'Task title',
              labelStyle: TextStyle(color: textColor),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.blueAccent)),
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
    final bgColor = _isDarkMode ? Colors.black : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(eventData["title"] ?? "Event Detail"),
      ),
      body: DefaultTextStyle(
        style: TextStyle(color: textColor),
        child: Column(
          children: [
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
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final t = tasks[index];
                  final String title = t["title"] ?? "";
                  final String status = t["status"] ?? "Pending";

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
                        underline: const SizedBox(),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

//
//       SETTINGS PAGE (Dark Mode & Notifications)
// ------------------------------------------------------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _notificationsOn = false;

  @override
  void initState() {
    super.initState();
    _loadSettingsFromJson();
  }

  /// Încarcă setările din JSON-ul "app_settings" din SharedPreferences
  Future<void> _loadSettingsFromJson() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString('app_settings') ?? '{}';
    final Map<String, dynamic> settingsMap = jsonDecode(settingsString);

    setState(() {
      _isDarkMode = (settingsMap['darkMode'] as bool?) ?? false;
      _notificationsOn = (settingsMap['notificationsOn'] as bool?) ?? true;
    });
  }

  /// Salvează noile setări în JSON-ul "app_settings"
  Future<void> _saveSettingsToJson() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString('app_settings') ?? '{}';
    final Map<String, dynamic> settingsMap = jsonDecode(settingsString);

    settingsMap['darkMode'] = _isDarkMode;
    settingsMap['notificationsOn'] = _notificationsOn;

    await prefs.setString('app_settings', jsonEncode(settingsMap));
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _saveSettingsToJson();
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsOn = value;
    });
    _saveSettingsToJson();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? Colors.black : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Setări'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Dark Mode', style: TextStyle(color: textColor)),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
            secondary: Icon(Icons.dark_mode, color: textColor),
          ),
          SwitchListTile(
            title: Text('Notificări', style: TextStyle(color: textColor)),
            value: _notificationsOn,
            onChanged: _toggleNotifications,
            secondary: Icon(Icons.notifications, color: textColor),
          ),
        ],
      ),
    );
  }
}
