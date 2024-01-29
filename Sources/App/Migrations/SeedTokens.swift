//
//  SeedTokens.swift
//
//
//  Created by Imen Ksouri on 26/01/2024.
//

import Foundation
import Fluent

struct SeedTokens: AsyncMigration {
    func prepare(on database: Database) async throws {
        let fileManager = FileManager.default
        let path = fileManager.currentDirectoryPath + WorkingDirectory.seedTokensFile
        if let data = fileManager.contents(atPath: path) {
            let tokens = try JSONDecoder().decode([Token].self, from: data)
            for token in tokens {
                try await token.create(on: database)
            }
        } else {
            fatalError("tokens.json not found. Set scheme's `Working Directory` to the project's folder and try again.")
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema(Token.schema).delete()
    }
}
