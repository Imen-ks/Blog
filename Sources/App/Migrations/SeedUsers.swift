//
//  SeedUsers.swift
//
//
//  Created by Imen Ksouri on 26/01/2024.
//

import Foundation
import Fluent

struct SeedUsers: AsyncMigration {
    func prepare(on database: Database) async throws {
        let fileManager = FileManager.default
        let path = fileManager.currentDirectoryPath + WorkingDirectory.seedUsersFile
        if let data = fileManager.contents(atPath: path) {
            let users = try JSONDecoder().decode([User].self, from: data)
            for user in users {
                try await user.create(on: database)
            }
        } else {
            fatalError("users.json not found. Set scheme's `Working Directory` to the project's folder and try again.")
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
