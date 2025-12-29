from models.quiz import QuizTopic, QuizQuestion, QuizSubmission, QuizResult


class QuizService:

    def __init__(self):
        # Example static dataset for now
        self.topics = [
            QuizTopic(id=1, name="Force & Motion", description="Basics of Newton's laws"),
            QuizTopic(id=2, name="Algebra", description="Linear equations & simplification"),
        ]

        self.questions = [
            QuizQuestion(
                id=101,
                topic_id=1,
                question="A 10 kg object accelerates at 2 m/s². What is the force?",
                options=["5 N", "10 N", "15 N", "20 N"],
                correct_index=3
            ),
            QuizQuestion(
                id=102,
                topic_id=1,
                question="Which law states that every action has an equal and opposite reaction?",
                options=[
                    "Newton’s 1st Law",
                    "Newton’s 2nd Law",
                    "Newton’s 3rd Law",
                    "Law of gravitation"
                ],
                correct_index=2
            ),
            QuizQuestion(
                id=201,
                topic_id=2,
                question="Solve: 3x + 5 = 20",
                options=["3", "5", "10", "7"],
                correct_index=1
            ),
        ]

    def get_topics(self):
        return self.topics

    def get_questions(self, topic_id: int, limit: int = 10):
        filtered = [q for q in self.questions if q.topic_id == topic_id]
        return filtered[:limit]

    def evaluate(self, submission: QuizSubmission):
        score = 0
        correct_ids = []

        question_map = {q.id: q for q in self.questions}

        for ans in submission.answers:
            question = question_map.get(ans.question_id)
            if question and question.correct_index == ans.selected_index:
                score += 1
                correct_ids.append(ans.question_id)

        return QuizResult(
            score=score,
            total=len(submission.answers),
            correct_questions=correct_ids
        )
