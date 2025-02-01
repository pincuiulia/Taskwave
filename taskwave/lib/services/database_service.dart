import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient client;

  DatabaseService(this.client);

  /// Fetch all events for a specific day
  Future<List<Map<String, dynamic>>> fetchEventsForDay(DateTime date) async {
  final formattedDate = date.toIso8601String().split('T').first;
  final response = await client
      .from('events')
      .select('*')
      .filter('start_time', 'gte', '$formattedDate 00:00:00')
      .filter('start_time', 'lt', '$formattedDate 23:59:59')
      .execute();

  if (response.status != 200) {
    throw Exception('Failed to fetch events: ${response.status}');
  }

  return List<Map<String, dynamic>>.from(response.data as List);
}


  /// Add a new event to the database
  Future<void> addEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await client
        .from('events')
        .insert({
          'title': title,
          'description': description,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'date': startTime.toIso8601String().split('T').first,
        })
        .execute();

    if (response.status != 201) {
      throw Exception('Failed to add event: ${response.status}');
    }
  }

  /// Delete an event from the database
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

  /// Update an existing event in the database
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
