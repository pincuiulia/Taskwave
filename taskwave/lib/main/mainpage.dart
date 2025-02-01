import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/DayViewPage.dart'; // Asigură-te că acest import este corect
import '../services/database_service.dart'; // Asigură-te că acest import este corect

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Creează instanța DatabaseService
    final databaseService = DatabaseService(Supabase.instance.client);

    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DayViewPage(databaseService: databaseService),
  ),
);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlanWise'),
        backgroundColor: const Color(0xFF1F41BB),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navighează către DayViewPage și transmite databaseService
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DayViewPage(databaseService: databaseService),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F41BB),
            minimumSize: const Size(200, 50),
          ),
          child: const Text(
            'Go to Day View',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
