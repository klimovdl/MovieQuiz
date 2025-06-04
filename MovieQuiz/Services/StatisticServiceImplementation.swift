// StatisticServiceImplementation.swift
// MovieQuiz

import Foundation

struct GameRecord: Codable {
    let correct: Int
    let total: Int
    let date: Date
}

final class StatisticServiceImplementation: StatisticServiceProtocol {

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
        let newTotalAccuracy = totalAccuracySum + thisAccuracy
        userDefaults.set(newTotalAccuracy, forKey: Keys.totalAccuracy)

        let currentBest = bestGame
        if count > currentBest.correct {
            let newBest = GameRecord(correct: count, total: questions, date: Date())
            if let data = try? JSONEncoder().encode(newBest) {
                userDefaults.set(data, forKey: Keys.bestGame)
            }
        }
    }

    var gamesCount: Int {
        return userDefaults.integer(forKey: Keys.gamesCount)
    }

    private var totalAccuracySum: Double {
        return userDefaults.double(forKey: Keys.totalAccuracy)
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
