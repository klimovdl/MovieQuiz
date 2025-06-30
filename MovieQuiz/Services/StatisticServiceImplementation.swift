// StatisticServiceImplementation.swift
// MovieQuiz

import Foundation

final class StatisticServiceImplementation: StatisticServiceProtocol {
    private enum Keys {
        static let gamesCount      = "gamesCount"
        static let bestGame        = "bestGame"
        static let correctAnswers  = "correctAnswers"
        static let totalAnswers    = "totalAnswers"
    }

    private let defaults = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    var gamesCount: Int {
        defaults.integer(forKey: Keys.gamesCount)
    }

    var bestGame: GameRecord {
        if let data = defaults.data(forKey: Keys.bestGame),
           let record = try? decoder.decode(GameRecord.self, from: data) {
            return record
        }
        return GameRecord(correct: 0, total: 0, date: Date())
    }

    var totalAccuracy: Double {
        let total = defaults.integer(forKey: Keys.totalAnswers)
        guard total > 0 else { return 0 }
        let correct = defaults.double(forKey: Keys.correctAnswers)
        return correct / Double(total) * 100
    }

    func store(correct: Int, total: Int) {
        // обновляем общий счёт
        let prevCorrect = defaults.double(forKey: Keys.correctAnswers)
        let prevTotal   = defaults.integer(forKey: Keys.totalAnswers)
        defaults.set(prevCorrect + Double(correct), forKey: Keys.correctAnswers)
        defaults.set(prevTotal + total, forKey: Keys.totalAnswers)

        // обновляем количество игр
        let newGamesCount = defaults.integer(forKey: Keys.gamesCount) + 1
        defaults.set(newGamesCount, forKey: Keys.gamesCount)

        // обновляем лучший рекорд
        let currentRecord = GameRecord(correct: correct, total: total, date: Date())
        if currentRecord > bestGame {
            if let data = try? encoder.encode(currentRecord) {
                defaults.set(data, forKey: Keys.bestGame)
            }
        }
    }
}
