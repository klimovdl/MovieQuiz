// StatisticServiceProtocol.swift
// MovieQuiz

import Foundation

struct GameRecord: Codable, Comparable {
    let correct: Int
    let total: Int
    let date: Date

    static func < (lhs: GameRecord, rhs: GameRecord) -> Bool {
        Double(lhs.correct)/Double(lhs.total) < Double(rhs.correct)/Double(rhs.total)
    }
}

protocol StatisticServiceProtocol {
    var gamesCount: Int { get }
    var bestGame: GameRecord { get }
    var totalAccuracy: Double { get }
    func store(correct: Int, total: Int)
}
