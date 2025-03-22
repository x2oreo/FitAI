import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';

class CalendarClient {
  static CalendarApi? calendar;

  ///to insert/ add google meet and added event in your calender
  Future<Map<String, String>?> insert({
    required String title,
    required String description,
    required String location,
    required List<String> attendeeEmailList,
    required bool shouldNotifyAttendees,
    required bool hasConferenceSupport,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    Map<String, String>? eventData;

    List<EventAttendee> attendeeList = [];

    String calendarId = "primary";
    Event event = Event();

    for (var element in attendeeEmailList) {
      EventAttendee eventAttendee = EventAttendee();
      eventAttendee.email = element;
      attendeeList.add(eventAttendee);
    }

    event.summary = title;
    event.description = description;
    event.attendees = attendeeList;
    event.location = location;

    if (hasConferenceSupport) {
      ConferenceData conferenceData = ConferenceData();
      CreateConferenceRequest conferenceRequest = CreateConferenceRequest();
      conferenceRequest.requestId =
          "${startTime.millisecondsSinceEpoch}-${endTime.millisecondsSinceEpoch}";
      // conferenceData.conferenceId
      conferenceData.createRequest = conferenceRequest;
      event.conferenceData = conferenceData;
    }

    EventDateTime start = EventDateTime();
    start.dateTime = startTime;
    start.timeZone = "GMT+05:30";
    event.start = start;

    EventDateTime end = EventDateTime();
    end.timeZone = "GMT+05:30";
    end.dateTime = endTime;
    event.end = end;

    try {
      await calendar?.events
          .insert(event, calendarId,
              conferenceDataVersion: hasConferenceSupport ? 1 : 0,
              sendUpdates: shouldNotifyAttendees ? "all" : "none")
          .then((value) {
        debugPrint("Event Status: ${value.status}");
        debugPrint("conferenceId: ${value.conferenceData?.conferenceId}");
        if (value.status == "confirmed") {
          String? joiningLink;
          String? eventId;

          eventId = value.id;

          if (hasConferenceSupport) {
            joiningLink =
                "https://meet.google.com/${value.conferenceData?.conferenceId}";
          }

          eventData = {'id': eventId ?? "", 'link': '$joiningLink'};

          debugPrint('Event added to Google Calendar $joiningLink');
        } else {
          debugPrint("Unable to add event to Google Calendar");
        }
      });
    } catch (e) {
      debugPrint('Error creating event $e');
    }

    return eventData;
  }

  ///to modify/update google meet and added event in your calender
  Future<Map<String, String>?> modify({
    required String id,
    required String title,
    required String description,
    required String location,
    required List<String> attendeeEmailList,
    required bool shouldNotifyAttendees,
    required bool hasConferenceSupport,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    Map<String, String>? eventData;

    String calendarId = "primary";
    Event event = Event();

    List<EventAttendee> attendeeList = [];

    for (var element in attendeeEmailList) {
      EventAttendee eventAttendee = EventAttendee();
      eventAttendee.email = element;
      attendeeList.add(eventAttendee);
    }

    event.summary = title;
    event.description = description;
    event.attendees = attendeeList;
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
      await calendar?.events
          .patch(event, calendarId, id,
              conferenceDataVersion: hasConferenceSupport ? 1 : 0,
              sendUpdates: shouldNotifyAttendees ? "all" : "none")
          .then((value) {
        debugPrint("Event Status: ${value.status}");
        if (value.status == "confirmed") {
          String? joiningLink;
          String eventId;

          eventId = value.id ?? '';

          if (hasConferenceSupport) {
            joiningLink =
                "https://meet.google.com/${value.conferenceData?.conferenceId}";
          }

          eventData = {'id': eventId, 'link': '$joiningLink'};

          debugPrint('Event added to Google Calendar $joiningLink');
        } else {
          debugPrint("Unable to update event in google calendar");
        }
      });
    } catch (e) {
      debugPrint('Error updating event $e');
    }

    return eventData;
  }

  ///to delete/remove google meet and added event in your calender
  Future<void> delete(String eventId, bool shouldNotify) async {
    String calendarId = "primary";

    try {
      await calendar?.events
          .delete(calendarId, eventId,
              sendUpdates: shouldNotify ? "all" : "none")
          .then((value) {
        debugPrint('Event deleted from Google Calendar');
      });
    } catch (e) {
      debugPrint('Error deleting event: $e');
    }
  }
}
