import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient client;

  DatabaseService(this.client);

  /// Preia toate evenimentele pentru o anumită zi
  Future<List<Map<String, dynamic>>> fetchEventsForDay(DateTime date) async {
    // Se extrage doar componenta de dată (ex: "2025-02-01")
    final dayString = date.toIso8601String().split('T').first;

    final response = await client
        .from('events')
        .select('*')
        .eq('starttime', dayString) // compară doar ziua
        .execute();

    if (response.status != 200) {
      throw Exception('Failed to fetch events: ${response.status}');
    }

    return List<Map<String, dynamic>>.from(response.data as List);
  }

  /// Adaugă un eveniment nou în baza de date
  Future<void> addEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Se obține ziua din startTime
    final dayString = startTime.toIso8601String().split('T').first;

    final response = await client
        .from('events')
        .insert({
          'title': title,
          'description': description,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'date': dayString,
        })
        .execute();

    if (response.status != 201) {
      throw Exception('Failed to add event: ${response.status}');
    }
  }

  /// Șterge un eveniment din baza de date
  Future<void> deleteEvent(int eventId) async {
    final response = await client
        .from('events')
        .delete()
        .eq('id', eventId)
        .execute();

    if (response.status != 200) {
      throw Exception('Failed to delete event: ${response.status}');
    }
  }

  /// Actualizează un eveniment existent în baza de date
  Future<void> updateEvent({
    required int eventId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (startTime != null) updates['start_time'] = startTime.toIso8601String();
    if (endTime != null) updates['end_time'] = endTime.toIso8601String();

    final response = await client
        .from('events')
        .update(updates)
        .eq('id', eventId)
        .execute();

    if (response.status != 200) {
      throw Exception('Failed to update event: ${response.status}');
    }
  }
}
