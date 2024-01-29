//
//  CreateTag.swift
//
//
//  Created by Imen Ksouri on 10/12/2023.
//

import Foundation
import Fluent

struct CreateTag: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Tag.schema)
            .id()
            .field(Tag.name, .string, .required)
            .unique(on: Tag.name)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Tag.schema).delete()
    }
}
