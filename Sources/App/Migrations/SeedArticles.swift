//
//  SeedArticles.swift
//
//
//  Created by Imen Ksouri on 26/01/2024.
//

import Foundation
import Fluent

struct SeedArticles: AsyncMigration {
    func prepare(on database: Database) async throws {
        let fileManager = FileManager.default
        let path = fileManager.currentDirectoryPath + WorkingDirectory.seedArticlesFile
        if let data = fileManager.contents(atPath: path) {
            let articles = try JSONDecoder().decode([Article].self, from: data)
            for article in articles {
                try await article.create(on: database)
            }
        } else {
            fatalError("articles.json not found. Set scheme's `Working Directory` to the project's folder and try again.")
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema(Article.schema).delete()
    }
}
