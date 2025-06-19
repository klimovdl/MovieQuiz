//
//  MostPopularMovies.swift
//  MovieQuiz
//
//  Created by Danil Klimov on 17.06.2025.
//

import Foundation

struct MostPopularMovies: Codable {
    let errorMessage: String
    let items: [MostPopularMovie]
}

struct MostPopularMovie: Codable {
    let title: String
    let rating: String
    let imageURL: URL

    var resizedImageURL: URL {
        let urlString = imageURL.absoluteString
        let base = urlString.components(separatedBy: "._")[0]
        let modified = base + "._V0_UX600_.jpg"
        return URL(string: modified) ?? imageURL
    }

    private enum CodingKeys: String, CodingKey {
        case title    = "fullTitle"
        case rating   = "imDbRating"
        case imageURL = "image"
    }
}
