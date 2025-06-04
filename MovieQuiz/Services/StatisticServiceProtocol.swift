// StatisticServiceProtocol.swift
// MovieQuiz

import Foundation

protocol StatisticServiceProtocol {
    func store(correct count: Int, total questions: Int)

    var gamesCount: Int { get }

    var bestGame: GameRecord { get }

    var averageAccuracy: Double { get }
}

