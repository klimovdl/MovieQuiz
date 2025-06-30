import UIKit

final class MovieQuizViewController: UIViewController {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    private lazy var alertPresenter = AlertPresenter(viewController: self)
    private let statisticService: StatisticServiceProtocol = StatisticServiceImplementation()
    private var currentQuestionNumber = 0
    private var correctAnswers = 0
    private var questionFactory: QuestionFactoryProtocol!
    private var currentQuestion: QuizQuestion?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Стилизация
        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true
        textLabel.font       = UIFont(name: "YSDisplay-Bold", size: 23)
        counterLabel.font    = UIFont(name: "YSDisplay-Medium", size: 20)
        yesButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
        noButton.titleLabel?.font  = UIFont(name: "YSDisplay-Medium", size: 20)

        // Accessibility для UI-тестов
        imageView.accessibilityIdentifier   = "Poster"
        counterLabel.accessibilityIdentifier = "Index"
        yesButton.accessibilityIdentifier    = "Yes"
        noButton.accessibilityIdentifier     = "No"

        // Если запущено из UI-тестов (см. далее), ставим заглушку
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            let stub = StubQuestionFactory()
            stub.setup(delegate: self)
            questionFactory = stub
        } else {
            questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        }

        showLoadingIndicator()
        questionFactory.loadData()
    }

    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        handleAnswer(isYes: true)
    }
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        handleAnswer(isYes: false)
    }

    private func handleAnswer(isYes: Bool) {
        guard let q = currentQuestion else { return }
        let correct = (q.correctAnswer == isYes)
        if correct { correctAnswers += 1 }
        statisticService.store(correct: correctAnswers, total: currentQuestionNumber + 1)
        showAnswerResult(isCorrectAnswer: correct)
    }

    private func showAnswerResult(isCorrectAnswer: Bool) {
        yesButton.isEnabled = false
        noButton.isEnabled  = false
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = (isCorrectAnswer ? UIColor.systemGreen : .systemRed).cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.imageView.layer.borderWidth = 0
            self.yesButton.isEnabled = true
            self.noButton.isEnabled  = true
            self.didReceiveNextQuestion()
        }
    }

    private func didReceiveNextQuestion() {
        currentQuestionNumber += 1

        if currentQuestionNumber < questionFactory.totalQuestionsCount {
            showLoadingIndicator()
            questionFactory.requestNextQuestion()
        } else {
            // финальный алерт
            let msg = statisticService.makeResultMessage()
            let model = AlertModel(
                title: "Этот раунд окончен!",
                message: msg,
                buttonText: "Попробовать ещё раз"
            ) { [weak self] in self?.resetGame() }
            alertPresenter.show(model: model)
        }
    }

    private func resetGame() {
        currentQuestionNumber = 0
        correctAnswers = 0
        counterLabel.text = "1/\(questionFactory.totalQuestionsCount)"
        showLoadingIndicator()
        questionFactory.reset()
        questionFactory.requestNextQuestion()
    }

    private func show(question: QuizStepViewModel) {
        activityIndicator.stopAnimating()
        imageView.image   = question.image
        textLabel.text    = question.question
        counterLabel.text = question.questionNumber
        currentQuestion   = nil
    }

    private func showLoadingIndicator() {
        activityIndicator.startAnimating()
        textLabel.text    = ""
        counterLabel.text = ""
        yesButton.isEnabled = false
        noButton.isEnabled  = false
    }

    private func showNetworkError(message: String) {
        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз"
        ) { [weak self] in self?.resetGame() }
        alertPresenter.show(model: model)
    }
}

// MARK: - QuestionFactoryDelegate

extension MovieQuizViewController: QuestionFactoryDelegate {
    func didLoadDataFromServer() {
        questionFactory.requestNextQuestion()
    }

    func didReceiveNextQuestion(question: QuizQuestion?) {
        currentQuestion = question
        if let q = question {
            show(question: convert(model: q))
        } else {
            didReceiveNextQuestion() // покажет финальный алерт
        }
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }

    func convert(model: QuizQuestion) -> QuizStepViewModel {
        let image = UIImage(data: model.image) ?? UIImage()
        return QuizStepViewModel(
            image: image,
            question: model.text,
            questionNumber: "\(currentQuestionNumber + 1)/\(questionFactory.totalQuestionsCount)"
        )
    }
}

// MARK: - StubQuestionFactory

final class StubQuestionFactory: QuestionFactoryProtocol {
    private weak var delegate: QuestionFactoryDelegate?
    private let questions: [QuizQuestion]
    private var index = 0

    var totalQuestionsCount: Int { questions.count }

    init() {
        // Названия картинок в Assets
        let names = ["Tesla","Deadpool","Vivarium","The Dark Knight",
                     "The Green Knight","Kill Bill","The Avengers",
                     "The Ice Age Adventures of Buck Wild","Old","The Godfather"]
        questions = names.map { name in
            let img = UIImage(named: name) ?? UIImage()
            return QuizQuestion(
                image: img.pngData() ?? Data(),
                text:  "Тестовый вопрос",
                correctAnswer: false
            )
        }
    }

    func setup(delegate: QuestionFactoryDelegate) {
        self.delegate = delegate
    }

    func loadData() {
        delegate?.didLoadDataFromServer()
    }

    func requestNextQuestion() {
        if index < questions.count {
            delegate?.didReceiveNextQuestion(question: questions[index])
            index += 1
        } else {
            delegate?.didReceiveNextQuestion(question: nil)
            index = 0
        }
    }

    func reset() {
        index = 0
    }
}
