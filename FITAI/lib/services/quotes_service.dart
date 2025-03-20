import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class QuotesService {
  final CollectionReference quotesCollection = 
      FirebaseFirestore.instance.collection('quotes');
  
  // Initialize quotes if collection is empty
  Future<void> initializeQuotes() async {
    // Check if collection is empty
    final snapshot = await quotesCollection.limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      // Add initial motivational fitness quotes
      final List<String> initialQuotes = [
        "The only bad workout is the one that didn't happen.",
        "Fitness is not about being better than someone else, it's about being better than you used to be.",
        "Take care of your body. It's the only place you have to live.",
        "The hardest lift of all is lifting your butt off the couch.",
        "Your body can stand almost anything. It's your mind that you have to convince.",
        "Exercise is king. Nutrition is queen. Put them together and you've got a kingdom.",
        "Strive for progress, not perfection.",
        "Your health is an investment, not an expense.",
        "The difference between try and triumph is just a little umph!",
        "The pain you feel today will be the strength you feel tomorrow."
      ];
      
      // Add each quote as a document
      for (String quote in initialQuotes) {
        await quotesCollection.add({'text': quote});
      }
    }
  }
  
  // Get a random quote
  Future<String> getRandomQuote() async {
    try {
      // Get all quotes
      final snapshot = await quotesCollection.get();
      
      if (snapshot.docs.isEmpty) {
        // If no quotes found, initialize and try again
        await initializeQuotes();
        return getRandomQuote();
      }
      
      // Get random quote from the list
      final random = Random();
      final randomIndex = random.nextInt(snapshot.docs.length);
      
      // Return quote text
      return snapshot.docs[randomIndex]['text'];
    } catch (e) {
      print('Error getting random quote: $e');
      return "Your body can stand almost anything. It's your mind that you have to convince.";
    }
  }
}