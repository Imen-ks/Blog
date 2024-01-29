//
//  SeedComments.swift
//
//
//  Created by Imen Ksouri on 26/01/2024.
//

import Foundation
import Fluent

struct SeedComments: AsyncMigration {
    func prepare(on database: Database) async throws {
        let fileManager = FileManager.default
        let path = fileManager.currentDirectoryPath + WorkingDirectory.seedCommentsFile
        if let data = fileManager.contents(atPath: path) {
            let comments = try JSONDecoder().decode([Comment].self, from: data)
            for comment in comments {
                try await comment.create(on: database)
            }
        } else {
            fatalError("comments.json not found. Set scheme's `Working Directory` to the project's folder and try again.")
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema(Comment.schema).delete()
    }
}
