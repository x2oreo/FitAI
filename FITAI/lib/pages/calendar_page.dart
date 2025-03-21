import 'package:flutter/material.dart';
import 'package:hk11/utils/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarClient calendarClient = CalendarClient();
  
  @override
  Widget build(BuildContext context) {
    // Add a button to create an event
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Create an event
            await calendarClient.insert(
              title: 'Meeting',
              description: 'Discuss the project',
              location: 'Office',
              attendeeEmailList: [],
              shouldNotifyAttendees: true,
              startTime: DateTime.now().add(const Duration(days: 1)),
              endTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
            );
          },
          child: const Text('Create Event'),
        ),
      ),
    );
  }
}