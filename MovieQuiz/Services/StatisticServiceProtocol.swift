// StatisticServiceProtocol.swift
// MovieQuiz

import Foundation

/// Интерфейс для хранения и форматирования статистики
protocol StatisticServiceProtocol {
    /// Сохраняет текущее число правильных ответов и общее количество вопросов
    func store(correct count: Int, total questions: Int)
    /// Возвращает итоговое сообщение с результатами
    func makeResultMessage() -> String
}
