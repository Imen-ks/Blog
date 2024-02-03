//
//  TagTests.swift
//  
//
//  Created by Imen Ksouri on 03/02/2024.
//

import Foundation
@testable import App
import XCTVapor

final class TagTests: XCTestCase {

    func testAllTagsCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let database = await TestDatabase.init(on: app.db)
        let tagsAtStart = database.tags.count
        let randomCount = Int.random(in: 1...100)
        var tagsCreated: [Tag] = []
        for _ in 1...randomCount {
            tagsCreated.append(try Tag.create(on: app.db))
        }
        XCTAssertEqual(randomCount, tagsCreated.count)
        let uri = "/api/tags/"
        try app.test(.GET, uri, afterResponse: { res in
            let retrievedTags = try res.content.decode([Tag].self)
            XCTAssertEqual(retrievedTags.count, tagsAtStart + tagsCreated.count)
        })
    }

    func testSingleTagCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let tag = try Tag.create(on: app.db)
        let tagId = tag.id!
        let uri = "/api/tags/\(tagId)"
        try app.test(.GET, uri, afterResponse: { res in
            let retrievedTag = try res.content.decode(Tag.self)
            XCTAssertEqual(retrievedTag.id, tagId)
            XCTAssertEqual(retrievedTag.name, tag.name)
        })
    }

    func testTagArticlesCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let tag = try Tag.create(on: app.db)
        let tagId = tag.id!
        let database = await TestDatabase.init(on: app.db)
        let articlesAtStart = try await database.tags.first { $0.id == tagId }!.$articles.get(on: app.db).count
        let randomCount = Int.random(in: 1...100)
        var articlesCreated: [Article] = []
        for _ in 1...randomCount {
            articlesCreated.append(try Article.add(tag, on: app.db))
        }
        XCTAssertEqual(randomCount, articlesCreated.compactMap { $0 }.count)
        let uri = "/api/tags/\(tagId)/articles"
        try app.test(.GET, uri, afterResponse: { res in
            let retrievedArticles = try res.content.decode([Article].self)
            XCTAssertEqual(retrievedArticles.count, articlesAtStart + articlesCreated.count)
        })
    }
}
