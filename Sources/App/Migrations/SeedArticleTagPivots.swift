//
//  SeedArticleTagPivots.swift
//
//
//  Created by Imen Ksouri on 26/01/2024.
//

import Foundation
import Fluent

struct SeedArticleTagPivots: AsyncMigration {
    func prepare(on database: Database) async throws {
        let fileManager = FileManager.default
        let path = fileManager.currentDirectoryPath + WorkingDirectory.seedArticleTagPivotsFile
        if let data = fileManager.contents(atPath: path) {
            let articleTagPivots = try JSONDecoder().decode([ArticleTagPivot].self, from: data)
            for articleTagPivot in articleTagPivots {
                try await articleTagPivot.create(on: database)
            }
        } else {
            fatalError("articleTagPivots.json not found. Set scheme's `Working Directory` to the project's folder and try again.")
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema(ArticleTagPivot.schema).delete()
    }
}
