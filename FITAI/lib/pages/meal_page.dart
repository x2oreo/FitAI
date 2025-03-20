import 'package:flutter/material.dart';

class MealPage extends StatefulWidget {
  const MealPage({Key? key}) : super(key: key);

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  int _selectedDay = 0; // 0 means no day selected
  
  // Meal information for each day
  final List<String> _mealInfo = [
    'Select a day to view meal plan details',
    'Day 1: High Protein Day\n• Breakfast: Protein Oatmeal\n• Lunch: Chicken Salad\n• Dinner: Salmon with Vegetables',
    'Day 2: Low Carb Day\n• Breakfast: Greek Yogurt with Berries\n• Lunch: Tuna Salad\n• Dinner: Steak with Asparagus',
    'Day 3: Balanced Day\n• Breakfast: Whole Grain Toast with Avocado\n• Lunch: Quinoa Bowl\n• Dinner: Turkey and Sweet Potato',
    'Day 4: Recovery Day\n• Breakfast: Smoothie Bowl\n• Lunch: Lentil Soup\n• Dinner: Grilled Chicken with Rice',
    'Day 5: High Energy Day\n• Breakfast: Banana Pancakes\n• Lunch: Pasta with Lean Beef\n• Dinner: Baked Fish with Quinoa',
    'Day 6: Vegetarian Day\n• Breakfast: Tofu Scramble\n• Lunch: Bean Burrito\n• Dinner: Vegetable Curry with Rice',
    'Day 7: Flexible Day\n• Breakfast: Your Choice\n• Lunch: Moderate Portion\n• Dinner: Light and Balanced'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Plan'),
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
            
            // Display selected meal information
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
                    _mealInfo[_selectedDay],
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