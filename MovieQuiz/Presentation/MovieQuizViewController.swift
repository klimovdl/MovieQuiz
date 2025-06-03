import UIKit

final class MovieQuizViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!

    // MARK: - Свойства

    private lazy var alertPresenter = AlertPresenter(viewController: self)

    private var currentQuestionNumber = 0
    private var correctAnswers = 0

    private var questionFactory: QuestionFactoryProtocol!
    private var currentQuestion: QuizQuestion?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Настройка UI
        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true

        textLabel.font      = UIFont(name: "YSDisplay-Bold",   size: 23)
        counterLabel.font   = UIFont(name: "YSDisplay-Medium", size: 20)
        yesButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
        noButton.titleLabel?.font  = UIFont(name: "YSDisplay-Medium", size: 20)

        let factory = QuestionFactory()
        factory.setup(delegate: self)
        questionFactory = factory

        showCurrentQuestion()
        
        // 4) Выводим путь к песочнице в консоль
         print("📂 App Sandbox Path: \(NSHomeDirectory())")
        
        UserDefaults.standard.set(true, forKey: "viewDidLoad") 

    }

    // MARK: - Actions

    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        handleAnswer(true)
    }

    @IBAction private func noButtonClicked(_ sender: UIButton) {
        handleAnswer(false)
    }


    private func showCurrentQuestion() {
        currentQuestionNumber += 1
        questionFactory.requestNextQuestion()
    }

    private func handleAnswer(_ givenAnswer: Bool) {
        yesButton.isEnabled = false
        noButton.isEnabled  = false

        guard let question = currentQuestion else { return }
        let isCorrect = (givenAnswer == question.correctAnswer)
        if isCorrect {
            correctAnswers += 1
        }

        showAnswerResult(isCorrect: isCorrect)
    }

    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let image = UIImage(named: model.image) ?? UIImage()
        let total = questionFactory.totalQuestionsCount
        let questionNumberText = "\(currentQuestionNumber)/\(total)"
        return QuizStepViewModel(
            image: image,
            question: model.text,
            questionNumber: questionNumberText
        )
    }

    private func show(question viewModel: QuizStepViewModel) {
        imageView.image = viewModel.image
        textLabel.text = viewModel.question
        counterLabel.text = viewModel.questionNumber

        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = UIColor.clear.cgColor
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }

    private func showAnswerResult(isCorrect: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect
            ? UIColor.ypGreenIos.cgColor
            : UIColor.ypRedIos.cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.showCurrentQuestion()
        }
    }

    private func show(result viewModel: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: viewModel.title,
            message: viewModel.text,
            buttonText: viewModel.buttonText
        ) { [weak self] in
            guard let self = self else { return }
            // Сброс рамки
            self.imageView.layer.borderWidth = 0
            self.imageView.layer.borderColor = UIColor.clear.cgColor

            self.currentQuestionNumber = 0
            self.correctAnswers = 0

            self.questionFactory.reset()

            self.showCurrentQuestion()
        }
        alertPresenter.show(model: alertModel)
    }

    private func showNetworkError(_ message: String) {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: message,
            preferredStyle: .alert
        )
        let retry = UIAlertAction(title: "Попробовать ещё раз", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.imageView.layer.borderWidth = 0
            self.imageView.layer.borderColor = UIColor.clear.cgColor

            self.currentQuestionNumber = 0
            self.correctAnswers = 0

            self.questionFactory.reset()

            self.showCurrentQuestion()
        }
        alert.addAction(retry)
        present(alert, animated: true)
    }
}



extension MovieQuizViewController: QuestionFactoryDelegate {
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            let total = questionFactory.totalQuestionsCount
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short

            statisticService.store(correct: correctAnswers, total: total)
            let best = statisticService.bestGame
            let bestDateStr = dateFormatter.string(from: best.date)
            let message = """
            Ваш результат: \(correctAnswers)/\(total)
            Количество сыгранных квизов: \(statisticService.gamesCount)
            Рекорд: \(best.correct)/\(best.total) (\(bestDateStr))
            Средняя точность: \(String(format: "%.2f", statisticService.averageAccuracy))%
            """
            let resultViewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: message,
                buttonText: "Сыграть ещё раз"
            )
            DispatchQueue.main.async { [weak self] in
                self?.show(result: resultViewModel)
            }
            return
        }

        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(question: viewModel)
        }
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
            let newRecord = GameRecord(
                correct: count,
                total: questions,
                date: Date()
            )
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

