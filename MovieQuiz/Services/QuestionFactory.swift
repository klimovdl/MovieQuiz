// QuestionFactory.swift
// MovieQuiz
//
// Created by Danil Klimov on 30.06.2025.
//

import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    private let moviesLoader: MoviesLoading
    private weak var delegate: QuestionFactoryDelegate?
    private var movies: [MostPopularMovie] = []

    // Количество вопросов берётся из длины массива
    var totalQuestionsCount: Int { movies.count }

    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate) {
        self.moviesLoader = moviesLoader
        self.delegate     = delegate
    }

    // Загружаем данные и сразу обрезаем до 10 фильмов
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopular):
                    self.movies = Array(mostPopular.items.prefix(10))
                    self.delegate?.didLoadDataFromServer()
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }

    // Формируем следующий вопрос на фоне, возвращаем его в главный поток
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self, !self.movies.isEmpty else { return }
            let movie = self.movies.randomElement()!

            let imageData: Data
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                imageData = Data()
            }

            let rating = Float(movie.rating) ?? 0
            let thresholds: [Float] = [5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0]
            let threshold = thresholds.randomElement()!
            let askGreater = Bool.random()
            let text = askGreater
                ? "Рейтинг этого фильма больше чем \(threshold)?"
                : "Рейтинг этого фильма меньше чем \(threshold)?"
            let correctAnswer = askGreater ? rating > threshold : rating < threshold

            let question = QuizQuestion(
                image: imageData,
                text: text,
                correctAnswer: correctAnswer
            )

            DispatchQueue.main.async {
                self.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }

    // Сбросить внутрений массив вопросов
    func reset() {
        movies.removeAll()
    }
}
