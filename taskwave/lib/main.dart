import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'start/welcome.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://utmpkosaolbifuzxgimc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV0bXBrb3Nhb2xiaWZ1enhnaW1jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgxODMwMDYsImV4cCI6MjA1Mzc1OTAwNn0.BjPQm7qPR4RFXZUF517KDjDEea5s9kJs1GQNCUmLLBE',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}
