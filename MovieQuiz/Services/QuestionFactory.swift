//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Danil Klimov on 01.06.2025.
//

import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    private let moviesLoader: MoviesLoading
    private weak var delegate: QuestionFactoryDelegate?
    private var movies: [MostPopularMovie] = []

    var totalQuestionsCount: Int { movies.count }

    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
        self.moviesLoader = moviesLoader
        self.delegate = delegate
    }

    func setup(delegate: QuestionFactoryDelegate) {
        self.delegate = delegate
    }

    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.items
                    self.delegate?.didLoadDataFromServer()
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }

    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self, !self.movies.isEmpty else { return }
            let movie = self.movies.randomElement()!

            var imageData = Data()
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch { }

            let ratingValue = Float(movie.rating) ?? 0
            let thresholds: [Float] = Array(stride(from: 5, through: 9, by: 0.5))
            let threshold = thresholds.randomElement()!
            let askGreater = Bool.random()

            let text: String
            let correctAnswer: Bool
            if askGreater {
                text = "Рейтинг этого фильма больше чем \(threshold)?"
                correctAnswer = ratingValue > threshold
            } else {
                text = "Рейтинг этого фильма меньше чем \(threshold)?"
                correctAnswer = ratingValue < threshold
            }

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

    func reset() {
        movies.removeAll()
    }
}
