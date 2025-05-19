import UIKit

struct QuizStepViewModel {
    let image: UIImage
    let question: String
    let questionNumber: String
}

struct QuizResultsViewModel {
    let title: String
    let text: String
    let buttonText: String
}

struct QuizQuestion {
    let image: String
    let text: String
    let correctAnswer: Bool
}

final class MovieQuizViewController: UIViewController {
    
    private func showNetworkError(_ message: String) {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: message,
            preferredStyle: .alert
        )
        let retry = UIAlertAction(
            title: "Попробовать ещё раз",
            style: .default
        ) { [weak self] _ in
            self?.currentQuestionIndex = 0
            self?.correctAnswers = 0
            self?.showCurrentQuestion()
        }

        alert.addAction(retry)
        present(alert, animated: true)
    }

    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    
    
    private let questions: [QuizQuestion] = [
        QuizQuestion(
            image: "The Godfather",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true
        ),
        QuizQuestion(
            image: "The Dark Knight",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true
        ),
        QuizQuestion(
            image: "Kill Bill",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true
        ),
        QuizQuestion(
            image: "The Avengers",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true
        ),
        QuizQuestion(
            image: "Deadpool",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true
        ),
        QuizQuestion(
            image: "The Green Knight",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true
        ),
        QuizQuestion(
            image: "Old",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false
        ),
        QuizQuestion(
            image: "The Ice Age Adventures of Buck Wild",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false
        ),
        QuizQuestion(
            image: "Tesla",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false
        ),
        QuizQuestion(
            image: "Vivarium",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false
        )
    ]
    
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        
        showCurrentQuestion()
    }
    
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        handleAnswer(true)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        handleAnswer(false)
    }
    
    
    
    private func showCurrentQuestion() {
        let question = questions[currentQuestionIndex]
        let viewModel = convert(model: question)
        show(quiz: viewModel)
    }
    
    private func handleAnswer(_ givenAnswer: Bool) {
        let current = questions[currentQuestionIndex]
        let isCorrect = (givenAnswer == current.correctAnswer)
        if isCorrect {
            correctAnswers += 1
        }
        showAnswerResult(isCorrect: isCorrect)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let image = UIImage(named: model.image) ?? UIImage()
        let questionNumber = "\(currentQuestionIndex + 1)/\(questions.count)"
        return QuizStepViewModel(
            image: image,
            question: model.text,
            questionNumber: questionNumber
        )
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
           imageView.layer.borderColor = UIColor.clear.cgColor

           imageView.image = step.image
           textLabel.text = step.question
           counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect
            ? UIColor.ypGreen.cgColor
            : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questions.count - 1 {
            statisticService.store(correct: correctAnswers,
            total: questions.count)
            
                   let dateFormatter = DateFormatter()
                   dateFormatter.dateStyle = .short
                   dateFormatter.timeStyle = .short
                   
                   let best = statisticService.bestGame
                   let bestDateStr = dateFormatter.string(from: best.date)
                   
                   let message = """
                   Ваш результат: \(correctAnswers)/\(questions.count)
                   Количество сыгранных квизов: \(statisticService.gamesCount)
                   Рекорд: \(best.correct)/\(best.total) (\(bestDateStr))
                   Средняя точность: \(String(format: "%.2f", statisticService.averageAccuracy))%
                   """
                   
                   let resultVM = QuizResultsViewModel(
                       title: "Этот раунд окончен!",
                       text: message,
                       buttonText: "Сыграть ещё раз"
                   )
                   show(quiz: resultVM)
                   
               } else {
                   currentQuestionIndex += 1
                   showCurrentQuestion()
               }
           }
    
    private func show(quiz result: QuizResultsViewModel) {
        let alert = UIAlertController(
            title: result.title,
            message: result.text,
            preferredStyle: .alert
        )
        let action = UIAlertAction(
            title: result.buttonText,
            style: .default
        ) { [weak self] _ in
            guard let self = self else { return }
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            self.showCurrentQuestion()
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
}

struct GameRecord: Codable {
    let correct: Int
    let total: Int
    let date: Date
}

protocol StatisticService {
    func store(correct count: Int, total questions: Int)
    
    var gamesCount: Int { get }
    var bestGame: GameRecord { get }
    var averageAccuracy: Double { get }
}

final class StatisticServiceImplementation: StatisticService {
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let gamesCount      = "stat_gamesCount"
        static let bestGame        = "stat_bestGame"
        static let totalAccuracy   = "stat_totalAccuracy"
    }
    
    func store(correct count: Int, total questions: Int) {
        let newGamesCount = gamesCount + 1
        userDefaults.set(newGamesCount, forKey: Keys.gamesCount)
        
        let thisAccuracy = Double(count) / Double(questions) * 100
        let newTotalAcc = totalAccuracySum + thisAccuracy
        userDefaults.set(newTotalAcc, forKey: Keys.totalAccuracy)
        
        let currentBest = bestGame
        if count > currentBest.correct {
            let newRecord = GameRecord(correct: count,
                                       total: questions,
                                       date: Date())
            if let data = try? JSONEncoder().encode(newRecord) {
                userDefaults.set(data, forKey: Keys.bestGame)
            }
        }
    }
    
    var gamesCount: Int {
        userDefaults.integer(forKey: Keys.gamesCount)
    }
    
    private var totalAccuracySum: Double {
        userDefaults.double(forKey: Keys.totalAccuracy)
    }
    
    var averageAccuracy: Double {
        guard gamesCount > 0 else { return 0 }
        return totalAccuracySum / Double(gamesCount)
    }
    
    var bestGame: GameRecord {
        if let data = userDefaults.data(forKey: Keys.bestGame),
           let record = try? JSONDecoder().decode(GameRecord.self, from: data) {
            return record
        }
        return GameRecord(correct: 0, total: 0, date: Date())
    }
}

private let statisticService: StatisticService = StatisticServiceImplementation()
