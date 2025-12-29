import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  final Map<String, dynamic> quizData;
  final Map<int, int> answers;

  const QuizResultScreen({
    super.key,
    required this.quizData,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    // Null safety
    final questions = quizData["questions"] as List<dynamic>?;
    
    if (questions == null || questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz Results")),
        body: const Center(
          child: Text("No results to display"),
        ),
      );
    }

    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i] as Map<String, dynamic>?;
      if (q == null) continue;
      final correctIndex = q["correct_index"];
      if (answers[i] == correctIndex) {
        score++;
      }
    }

    final percentage = (score / questions.length * 100).round();
    final Color scoreColor = percentage >= 80 
        ? Colors.green 
        : percentage >= 50 
            ? Colors.orange 
            : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Results"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scoreColor.withOpacity(0.8), scoreColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "$score / ${questions.length}",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$percentage% Score",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getScoreMessage(percentage),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Detailed breakdown
              const Text(
                "📝 Answer Review",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              ...List.generate(
                questions.length,
                (i) {
                  final q = questions[i] as Map<String, dynamic>?;
                  if (q == null) return const SizedBox.shrink();
                  
                  final questionText = q["question"]?.toString() ?? "Question unavailable";
                  final options = (q["options"] as List<dynamic>?) ?? [];
                  final correct = (q["correct_index"] as int?) ?? 0;
                  final selected = answers[i];
                  final explanation = q["explanation"]?.toString() ?? "No explanation provided.";
                  final takeaway = q["takeaway"]?.toString() ?? "";
                  final isCorrect = selected == correct;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Header
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isCorrect 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.red.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.green : Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Q${i + 1}. $questionText",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Answer Details
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Your Answer
                              Row(
                                children: [
                                  Text(
                                    "Your Answer: ",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      selected != null && selected < options.length
                                          ? options[selected]?.toString() ?? "N/A"
                                          : "Not answered",
                                      style: TextStyle(
                                        color: isCorrect ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              
                              // Correct Answer
                              Row(
                                children: [
                                  Text(
                                    "Correct Answer: ",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      correct < options.length 
                                          ? options[correct]?.toString() ?? "N/A"
                                          : "N/A",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 14),

                              // Explanation
                              const Text(
                                "💡 Explanation",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                explanation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                              
                              // Takeaway (if available)
                              if (takeaway.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("🎯 ", style: TextStyle(fontSize: 14)),
                                      Expanded(
                                        child: Text(
                                          takeaway,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // Return the score and total to the previous screen
                    Navigator.pop(context, {
                      "score": score,
                      "total": questions.length,
                      "percentage": percentage,
                      "timestamp": DateTime.now().toIso8601String(),
                      "quizData": quizData,
                      "answers": answers,
                    });
                  },
                  child: const Text(
                    "Done",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getScoreMessage(int percentage) {
    if (percentage >= 90) return "🏆 Excellent! You've mastered this topic!";
    if (percentage >= 70) return "👏 Great job! Keep practicing!";
    if (percentage >= 50) return "💪 Good effort! Review the explanations.";
    return "📚 Keep learning! Focus on the concepts below.";
  }
}
