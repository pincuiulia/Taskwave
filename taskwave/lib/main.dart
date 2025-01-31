import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'start/welcome.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://gbiburylobkjngssxyga.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiaWJ1cnlsb2Jram5nc3N4eWdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgyNjIzODIsImV4cCI6MjA1MzgzODM4Mn0.43u36Ks08rcxhV854JzeExG8ijWF3qxPgx0M2b4iDrE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}
