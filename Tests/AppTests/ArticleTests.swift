//
//  ArticleTests.swift
//  
//
//  Created by Imen Ksouri on 02/02/2024.
//

import Foundation
@testable import App
import XCTVapor

final class ArticleTests: XCTestCase {    

    func testLoggedInUserCanCreateArticle() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let title = UUID().uuidString
        let description = UUID().uuidString
        let picture = UUID().uuidString
        let articleData = CreateArticleData(
            title: title,
            description: description,
            picture: picture)
        let uri = "/api/articles/"

        try app.test(.POST, uri, loggedInUser: user, beforeRequest: { req in
            try req.content.encode(articleData)
        }, afterResponse: { res in
            let retrievedArticle = try res.content.decode(Article.self)
            XCTAssertEqual(retrievedArticle.title, title)
            XCTAssertEqual(retrievedArticle.description, description)
            XCTAssertEqual(retrievedArticle.$user.id, user.id)
        })
    }

    func testNotLoggedInUserCannotCreateArticle() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let title = UUID().uuidString
        let description = UUID().uuidString
        let picture = UUID().uuidString
        let articleData = CreateArticleData(
            title: title,
            description: description,
            picture: picture)
        let uri = "/api/articles/"

        try app.test(.POST, uri, beforeRequest: { req in
            try req.content.encode(articleData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testAllArticlesCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let database = await TestDatabase.init(on: app.db)
        let articlesAtStart = database.articles.count
        let randomCount = Int.random(in: 1...100)
        let user = try User.create(on: app.db)
        var articlesCreated: [Article] = []
        for _ in 1...randomCount {
            articlesCreated.append(try Article.create(by: user, on: app.db))
        }
        XCTAssertEqual(randomCount, articlesCreated.count)
        let uri = "/api/articles/"
        try app.test(.GET, uri, afterResponse: { res in
            let retrievedArticles = try res.content.decode([Article].self)
            XCTAssertEqual(retrievedArticles.count, articlesAtStart + articlesCreated.count)
        })
    }

    func testSingleArticleCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(by: user, on: app.db)
        let articleId = article.id!
        let uri = "/api/articles/\(articleId)"
        try app.test(.GET, uri, afterResponse: { res in
            let retrievedArticle = try res.content.decode(Article.self)
            XCTAssertEqual(retrievedArticle.id, articleId)
            XCTAssertEqual(retrievedArticle.title, article.title)
            XCTAssertEqual(retrievedArticle.description, article.description)
        })
    }

    func testAuthorizedUserCanUpdateArticle() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(by: user, on: app.db)
        let articleId = article.id!
        let updatedTitle = UUID().uuidString
        let updatedArticleData = UpdateArticleData(title: updatedTitle)
        let uri = "/api/articles/\(articleId)"

        try app.test(.PUT, uri, loggedInUser: user, beforeRequest: { req in
            try req.content.encode(updatedArticleData)
        }, afterResponse: { res in
            let retrievedArticle = try res.content.decode(Article.self)
            XCTAssertEqual(retrievedArticle.id, article.id)
            XCTAssertEqual(retrievedArticle.title, updatedTitle)
            XCTAssertEqual(retrievedArticle.description, article.description)
            XCTAssertEqual(retrievedArticle.$user.id, user.id)
        })
    }

    func testNotLoggedInUserCannotUpdateArticle() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)


        let user = try User.create(on: app.db)
        let article = try Article.create(by: user, on: app.db)
        let articleId = article.id!
        let updatedTitle = UUID().uuidString
        let updatedArticleData = UpdateArticleData(title: updatedTitle)
        let uri = "/api/articles/\(articleId)"

        try app.test(.PUT, uri, beforeRequest: { req in
            try req.content.encode(updatedArticleData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testUnauthorizedUserCannotUpdateArticle() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(on: app.db)
        let articleId = article.id!
        let updatedTitle = UUID().uuidString
        let updatedArticleData = UpdateArticleData(title: updatedTitle)
        let uri = "/api/articles/\(articleId)"

        try app.test(.PUT, uri, loggedInUser: user, beforeRequest: { req in
            try req.content.encode(updatedArticleData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testAuthorizedUserCanDeleteArticle() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(by: user, on: app.db)
        let articleId = article.id!
        let uri = "/api/articles/\(articleId)"

        try app.test(.DELETE, uri, loggedInUser: user, beforeRequest: { req in
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
    }

    func testNotLoggedInUserCannotDeleteArticle() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(by: user, on: app.db)
        let articleId = article.id!
        let uri = "/api/articles/\(articleId)"

        try app.test(.DELETE, uri, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testUnauthorizedUserCannotDeleteArticle() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(on: app.db)
        let articleId = article.id!
        let uri = "/api/articles/\(articleId)"

        try app.test(.DELETE, uri, loggedInUser: user, beforeRequest: { req in
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testSearchTermReturnsArticlesWithTerm() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let searchedTerm = UUID().uuidString
        let title = "\(UUID().uuidString) \(searchedTerm) \(UUID().uuidString)"
        let description = "\(UUID().uuidString) \(searchedTerm) \(UUID().uuidString)"
        let article1 = try Article.create(title: title, on: app.db)
        let article2 = try Article.create(description: description, on: app.db)

        let uri = "/api/articles/search?term=\(searchedTerm)"
        try app.test(.GET, uri, afterResponse: { res in
            let articles = try res.content.decode([Article].self)
            XCTAssertTrue(articles.contains(where: {
                $0.title.lowercased().contains(searchedTerm.lowercased()) ||
                $0.description.lowercased().contains(searchedTerm.lowercased())
            }))
            XCTAssertTrue(articles.contains(where: { $0.id == article1.id }))
            XCTAssertTrue(articles.contains(where: { $0.id == article2.id }))
        })
    }

    func testArticleAuthorCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(by: user, on: app.db)
        let articleId = article.id!
        let uri = "/api/articles/\(articleId)/user"
        try app.test(.GET, uri, afterResponse: { res in
            let retrievedUser = try res.content.decode(User.Public.self)
            XCTAssertEqual(retrievedUser.id, user.id)
        })
    }

    func testArticleTagsCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let article = try Article.create(on: app.db)
        let articleId = article.id!
        let database = await TestDatabase.init(on: app.db)
        let tagsAtStart = try await database.articles.first { $0.id == articleId }!.$tags.get(on: app.db).count
        let randomCount = Int.random(in: 1...100)
        var tagsCreated: [Tag] = []
        for _ in 1...randomCount {
            try await tagsCreated.append(Tag.add(to: article, on: app.db))
        }
        XCTAssertEqual(randomCount, tagsCreated.count)
        let uri = "/api/articles/\(articleId)/tags"
        try app.test(.GET, uri, afterResponse: { res in
            let retrievedTags = try res.content.decode([Tag].self)
            XCTAssertEqual(retrievedTags.count, tagsAtStart + tagsCreated.count)
        })
    }

    func testAuthorizedUserCanUpdateArticleTags() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(by: user, on: app.db)
        let articleId = article.id!
        let tagsToUpdate = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
        let uri = "/api/articles/\(articleId)/tags"

        try app.test(.POST, uri, loggedInUser: user, beforeRequest: { req in
            try req.content.encode(tagsToUpdate)
        }, afterResponse: { res in
            let retrievedTags = try res.content.decode([Tag].self)
            for tag in tagsToUpdate {
                XCTAssertTrue(retrievedTags.contains(where: { $0.name == tag.lowercased() }))
            }
        })
    }

    func testNotLoggedInUserCannotUpdateArticleTags() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(by: user, on: app.db)
        let articleId = article.id!
        let tagsToUpdate = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
        let uri = "/api/articles/\(articleId)/tags"

        try app.test(.POST, uri, beforeRequest: { req in
            try req.content.encode(tagsToUpdate)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testUnauthorizedUserCanUpdateArticleTags() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(on: app.db)
        let articleId = article.id!
        let tagsToUpdate = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
        let uri = "/api/articles/\(articleId)/tags"

        try app.test(.POST, uri, loggedInUser: user, beforeRequest: { req in
            try req.content.encode(tagsToUpdate)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testArticleCommentsWithAuthorCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(on: app.db)
        let articleId = article.id!
        let database = await TestDatabase.init(on: app.db)
        let commentsAtStart = try await database.articles.first { $0.id == articleId }!.$comments.get(on: app.db).count
        let randomCount = Int.random(in: 1...100)
        var comments: [Comment] = []
        for _ in 1...randomCount {
            comments.append(try Comment.add(by: user, to: article, on: app.db))
        }
        XCTAssertEqual(randomCount, comments.count)
        let uri = "/api/articles/\(articleId)/comments"
        try app.test(.GET, uri, afterResponse: { res in
            let retrievedComments = try res.content.decode([CommentWithAuthor].self)
            XCTAssertEqual(retrievedComments.count, commentsAtStart + comments.count)
        })
    }

    func testLoggedInUserCanPostComment() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(on: app.db)
        let articleId = article.id!
        let comment = UUID().uuidString
        let commentData = CreateCommentData(comment: comment)
        let uri = "/api/articles/\(articleId)/comments"

        try app.test(.POST, uri, loggedInUser: user, beforeRequest: { req in
            try req.content.encode(commentData)
        }, afterResponse: { res in
            let retrievedComment = try res.content.decode(Comment.self)
            XCTAssertEqual(retrievedComment.description, comment)
            XCTAssertEqual(retrievedComment.$author.id, user.id)
            XCTAssertEqual(retrievedComment.$article.id, articleId)
        })
    }

    func testNotLoggedInUserCannotPostComment() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(on: app.db)
        let articleId = article.id!
        let comment = UUID().uuidString
        let commentData = CreateCommentData(comment: comment)
        let uri = "/api/articles/\(articleId)/comments"

        try app.test(.POST, uri, beforeRequest: { req in
            try req.content.encode(commentData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
}
