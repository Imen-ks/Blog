//
//  SeedTags.swift
//  
//
//  Created by Imen Ksouri on 26/01/2024.
//

import Foundation
import Fluent

struct SeedTags: AsyncMigration {
    func prepare(on database: Database) async throws {
        let fileManager = FileManager.default
        let path = fileManager.currentDirectoryPath + WorkingDirectory.seedTagsFile
        if let data = fileManager.contents(atPath: path) {
            let tags = try JSONDecoder().decode([Tag].self, from: data)
            for tag in tags {
                try await tag.create(on: database)
            }
        } else {
            fatalError("tags.json not found. Set scheme's `Working Directory` to the project's folder and try again.")
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema(Tag.schema).delete()
    }
}
