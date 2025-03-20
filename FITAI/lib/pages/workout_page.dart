import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _selectedDay = 0; // 0 means no day selected
  
  // Workout information for each day
  final List<String> _workoutInfo = [
    'Select a day to view workout details',
    'Day 1: Push workout - Chest, Shoulders, Triceps',
    'Day 2: Pull workout - Back, Biceps',
    'Day 3: Legs workout - Quads, Hamstrings, Calves',
    'Day 4: Upper body focus',
    'Day 5: Lower body focus',
    'Day 6: Full body workout',
    'Day 7: Rest and recovery day'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Workout Plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day buttons in a row
            Container(
              height: 50,
              width: double.infinity,
              child: Row(
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDay == day;
                  
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 6 ? 8.0 : 0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDay = day;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? theme.hintColor 
                                : theme.colorScheme.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.hintColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'D$day',
                            style: TextStyle(
                              color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Display selected workout information below buttons
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.hintColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _workoutInfo[_selectedDay],
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}