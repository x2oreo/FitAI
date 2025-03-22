import 'package:flutter/material.dart';
import 'package:hk11/utils/calendar.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
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
              attendeeEmailList: [''],
              shouldNotifyAttendees: true,
              hasConferenceSupport: true,
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