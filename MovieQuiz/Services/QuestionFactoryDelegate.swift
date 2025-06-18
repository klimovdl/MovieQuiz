//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Danil Klimov on 02.06.2025.
//

import Foundation

import Foundation

protocol QuestionFactoryDelegate: AnyObject {
    func didReceiveNextQuestion(question: QuizQuestion?)
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
}

protocol QuestionFactoryProtocol: AnyObject {
    var totalQuestionsCount: Int { get }
    func requestNextQuestion()
    func reset()
    func setup(delegate: QuestionFactoryDelegate)
    func loadData()
}

