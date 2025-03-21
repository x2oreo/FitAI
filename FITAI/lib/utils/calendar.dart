import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/auth_io.dart';

class CalendarClient {
  // For storing the CalendarApi object
  static CalendarApi? calendar;
  
  // Method to initialize the calendar API
  static Future<void> initialize(AutoRefreshingAuthClient client) async {
    calendar = CalendarApi(client);
  }

  // For creating a new calendar event
  Future<Map<String, String>?> insert({
    required String title,
    required String description,
    required String location,
    required List<EventAttendee> attendeeEmailList,
    required bool shouldNotifyAttendees,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (calendar == null) {
      throw Exception('Calendar API not initialized. Call CalendarClient.initialize() first.');
    }
    
    Map<String, String>? eventData;

    String calendarId = "primary";
    Event event = Event();

    event.summary = title;
    event.description = description;
    event.attendees = attendeeEmailList;
    event.location = location;

    EventDateTime start = EventDateTime();
    start.dateTime = startTime;
    start.timeZone = "GMT+05:30";
    event.start = start;

    EventDateTime end = EventDateTime();
    end.timeZone = "GMT+05:30";
    end.dateTime = endTime;
    event.end = end;

    try {
      Event? response = await calendar?.events.insert(event, calendarId, 
          sendUpdates: shouldNotifyAttendees ? "all" : "none");
      
      if (response != null) {
        eventData = {
          'id': response.id ?? '',
          'link': response.htmlLink ?? '',
          'status': response.status ?? '',
        };
      }
    } catch (e) {
      print('Error creating calendar event: $e');
      rethrow;
    }

    return eventData;
  }
}