//
//  ApiConstants.swift
//
//
//  Created by Imen Ksouri on 07/01/2024.
//

import Foundation
import Vapor

struct ApiHostUrl {
    static let root = "http://localhost:8080/"
}

struct ApiRoot {
    enum Api: String {
        case root = "api/"
    }
    static var url: String {
        return ApiHostUrl.root + Api.root.rawValue
    }
}

enum ApiEndpoint: String {
    case users, articles, tags, comments
    
    var url: String {
        switch self {
        case .users:
            return ApiRoot.url + ApiEndpoint.users.rawValue
        case .articles:
            return ApiRoot.url + ApiEndpoint.articles.rawValue
        case .tags:
            return ApiRoot.url + ApiEndpoint.tags.rawValue
        case .comments:
            return ApiRoot.url + ApiEndpoint.comments.rawValue
        }
    }
}

enum ApiPath: String {
    // Root
    case api
    
    // UsersController
    case users
    case login
    case userId
    case user

    // ArticlesController
    case articles
    case articleId
    case search

    // TagsController
    case tags
    case tagId
    case tagName

    // CommentsController
    case comments
    
    var component: PathComponent {
        switch self {
        case .api:
            return PathComponent(stringLiteral: Self.api.rawValue)
        case .users:
            return PathComponent(stringLiteral: Self.users.rawValue)
        case .login:
            return PathComponent(stringLiteral: Self.login.rawValue)
        case .userId:
            return PathComponent(stringLiteral: ":\(Self.userId.rawValue)")
        case .user:
            return PathComponent(stringLiteral: Self.user.rawValue)
        case .articles:
            return PathComponent(stringLiteral: Self.articles.rawValue)
        case .articleId:
            return PathComponent(stringLiteral: ":\(Self.articleId.rawValue)")
        case .search:
            return PathComponent(stringLiteral: Self.search.rawValue)
        case .tags:
            return PathComponent(stringLiteral: Self.tags.rawValue)
        case .tagId:
            return PathComponent(stringLiteral: ":\(Self.tagId.rawValue)")
        case .tagName:
            return PathComponent(stringLiteral: ":\(Self.tagName.rawValue)")
        case .comments:
            return PathComponent(stringLiteral: Self.comments.rawValue)
        }
    }
}
