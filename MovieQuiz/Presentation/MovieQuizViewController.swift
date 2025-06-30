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
        showLoadingIndicator()
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory.loadData()
    }

    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        handleAnswer(isYes: true)
    }

    @IBAction private func noButtonClicked(_ sender: UIButton) {
        handleAnswer(isYes: false)
    }

    private func handleAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else { return }
        let isCorrect = (currentQuestion.correctAnswer == isYes)
        showAnswerResult(isCorrectAnswer: isCorrect)
        if isCorrect { correctAnswers += 1 }
    }

    private func showAnswerResult(isCorrectAnswer: Bool) {
        yesButton.isEnabled = false
        noButton.isEnabled  = false

        let title   = isCorrectAnswer ? "Правильно!" : "Неправильно!"
        let message = isCorrectAnswer
            ? "Вы ответили верно"
            : "Правильный ответ: \(currentQuestion?.correctAnswer.description ?? "—")"

        let alertModel = AlertModel(
            title: title,
            message: message,
            buttonText: "Далее"
        ) { [weak self] in
            self?.showNextQuestionOrResults()
        }

        alertPresenter.show(model: alertModel)
    }

    private func showNextQuestionOrResults() {
        currentQuestionNumber += 1
        if currentQuestionNumber == questionFactory.totalQuestionsCount {
            showQuizResult()
        } else {
            showLoadingIndicator()
            questionFactory.requestNextQuestion()
        }
    }

    private func showQuizResult() {
        let gamesCount    = statisticService.gamesCount
        let bestGame      = statisticService.bestGame
        let totalAccuracy = statisticService.totalAccuracy

        let title   = "Этот раунд окончен!"
        let message = """
                      Ваш результат: \(correctAnswers)/\(questionFactory.totalQuestionsCount)
                      Сыграно квизов: \(gamesCount)
                      Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date))
                      Средняя точность: \(String(format: "%.2f", totalAccuracy))%
                      """

        // Создаём алерт-модель сразу
        let alertModel = AlertModel(
            title: title,
            message: message,
            buttonText: "Сыграть ещё раз"
        ) { [weak self] in
            self?.resetGame()
        }

        alertPresenter.show(model: alertModel)
        statisticService.store(correct: correctAnswers,
                               total: questionFactory.totalQuestionsCount)
    }

    private func resetGame() {
        currentQuestionNumber = 0
        correctAnswers        = 0
        questionFactory.reset()
        showLoadingIndicator()
        questionFactory.loadData()
    }

    private func show(question: QuizStepViewModel) {
        activityIndicator.stopAnimating()
        imageView.image      = question.image
        textLabel.text       = question.question
        counterLabel.text    = question.questionNumber
        yesButton.isEnabled  = true
        noButton.isEnabled   = true
    }

    private func showLoadingIndicator() {
        activityIndicator.startAnimating()
        textLabel.text       = ""
        counterLabel.text    = ""
        yesButton.isEnabled  = false
        noButton.isEnabled   = false
    }

    private func showNetworkError(message: String) {
        let alertModel = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз"
        ) { [weak self] in
            self?.resetGame()
        }
        alertPresenter.show(model: alertModel)
    }
}

extension MovieQuizViewController: QuestionFactoryDelegate {
    func didLoadDataFromServer() {
        showLoadingIndicator()
        questionFactory.requestNextQuestion()
    }

    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let quiz = question else { return }
        currentQuestion = quiz
        let viewModel = QuizStepViewModel(
            image: UIImage(data: quiz.image) ?? UIImage(),
            question: quiz.text,
            questionNumber: "\(currentQuestionNumber + 1)/\(questionFactory.totalQuestionsCount)"
        )
        show(question: viewModel)
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
}
