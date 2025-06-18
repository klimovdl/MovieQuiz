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

    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    private func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true

        textLabel.font = UIFont(name: "YSDisplay-Bold", size: 23)
        counterLabel.font = UIFont(name: "YSDisplay-Medium", size: 20)
        yesButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
        noButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)

        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        showLoadingIndicator()
        questionFactory.loadData()

        print("📂 App Sandbox Path: \(NSHomeDirectory())")
    }

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
        noButton.isEnabled = false

        guard let question = currentQuestion else { return }
        let isCorrect = (givenAnswer == question.correctAnswer)
        if isCorrect { correctAnswers += 1 }

        showAnswerResult(isCorrect: isCorrect)
    }

    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let image = UIImage(data: model.image) ?? UIImage()
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
            self.imageView.layer.borderWidth = 0
            self.imageView.layer.borderColor = UIColor.clear.cgColor

            self.currentQuestionNumber = 0
            self.correctAnswers = 0

            self.questionFactory.reset()
            self.showCurrentQuestion()
        }
        alertPresenter.show(model: alertModel)
    }

    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        let alertModel = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз"
        ) { [weak self] in
            guard let self = self else { return }
            self.imageView.layer.borderWidth = 0
            self.imageView.layer.borderColor = UIColor.clear.cgColor

            self.currentQuestionNumber = 0
            self.correctAnswers = 0

            self.questionFactory.reset()
            self.showCurrentQuestion()
            self.showLoadingIndicator()
            self.questionFactory.loadData()
        }
        alertPresenter.show(model: alertModel)
    }
}

extension MovieQuizViewController: QuestionFactoryDelegate {
    func didReceiveNextQuestion(question: QuizQuestion?) {
        hideLoadingIndicator()
        guard let question = question else {
            let total = questionFactory.totalQuestionsCount
            statisticService.store(correct: correctAnswers, total: total)

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short

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

    func didLoadDataFromServer() {
        hideLoadingIndicator()
        showCurrentQuestion()
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
}
