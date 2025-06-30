// MoviesLoaderStub.swift
// MovieQuiz
//
// Created by Danil Klimov on 30.06.2025.

import Foundation

/// Заглушка для UI‐тестов: формирует JSON с 10 одинаковыми фильмами
/// и декодирует его в вашу модель через JSONDecoder.
/// Так не важно, с какими параметрами у вас синтезированный init.
final class MoviesLoaderStub: MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        // 1) Описываем один «заглушечный» фильм в словаре:
        let item: [String: Any] = [
            "id": 0,
            "title": "Stub Movie",
            "year": "2020",
            "rating": "8.0",
            "poster": "https://example.com/poster.png",
            "imageURL": "https://example.com/resized.png"
        ]
        
        // 2) Дублируем его 10 раз и упаковываем в корневой словарь
        let dict: [String: Any] = [
            "errorMessage": "",      // если в модели MostPopularMovies есть это поле
            "items": Array(repeating: item, count: 10)
        ]
        
        do {
            // 3) Собираем Data из JSON
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            // 4) Декодируем в вашу модель
            let decoded = try JSONDecoder().decode(MostPopularMovies.self, from: data)
            handler(.success(decoded))
        } catch {
            handler(.failure(error))
        }
    }
}
