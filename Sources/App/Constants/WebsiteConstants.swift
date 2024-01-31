//
//  WebsiteConstants.swift
//
//
//  Created by Imen Ksouri on 08/01/2024.
//

import Foundation
import Vapor

struct WebsiteHostUrl {
    static let root = "http://localhost:8080/"
}

enum WebsiteEndpoint: String {
    case register, login, logout, users, articles, tags, search, profile
    
    var url: String {
        switch self {
        case.register:
            return WebsiteHostUrl.root + WebsiteEndpoint.register.rawValue
        case.login:
            return WebsiteHostUrl.root + WebsiteEndpoint.login.rawValue
        case.logout:
            return WebsiteHostUrl.root + WebsiteEndpoint.logout.rawValue
        case .users:
            return WebsiteHostUrl.root + WebsiteEndpoint.users.rawValue
        case .articles:
            return WebsiteHostUrl.root + WebsiteEndpoint.articles.rawValue
        case .tags:
            return WebsiteHostUrl.root + WebsiteEndpoint.tags.rawValue
        case .search:
            return WebsiteHostUrl.root + WebsiteEndpoint.search.rawValue
        case .profile:
            return WebsiteHostUrl.root + WebsiteEndpoint.profile.rawValue
        }
    }
}

enum WebsitePath: String {
    // WebRegisterController
    case register

    // WebAuthController
    case login
    case logout
    
    // WebUsersController
    case users
    case userId
    case profile
    case addProfilePicture
    case changePassword

    // WebArticlesController
    case articles
    case articleId
    case create
    case addArticlePicture
    case delete
    case search
    case comments

    // WebTagsController
    case tags
    case tagId

    // WebArticlesController & WebUsersController
    case edit
    
    var component: PathComponent {
        switch self {
        case .register:
            return PathComponent(stringLiteral: Self.register.rawValue)
        case .login:
            return PathComponent(stringLiteral: Self.login.rawValue)
        case .logout:
            return PathComponent(stringLiteral: Self.logout.rawValue)
        case .users:
            return PathComponent(stringLiteral: Self.users.rawValue)
        case .userId:
            return PathComponent(stringLiteral: ":\(Self.userId.rawValue)")
        case .profile:
            return PathComponent(stringLiteral: Self.profile.rawValue)
        case .addProfilePicture:
            return PathComponent(stringLiteral: Self.addProfilePicture.rawValue)
        case .changePassword:
            return PathComponent(stringLiteral: Self.changePassword.rawValue)
        case .articles:
            return PathComponent(stringLiteral: Self.articles.rawValue)
        case .articleId:
            return PathComponent(stringLiteral: ":\(Self.articleId.rawValue)")
        case .create:
            return PathComponent(stringLiteral: Self.create.rawValue)
        case .addArticlePicture:
            return PathComponent(stringLiteral: Self.addArticlePicture.rawValue)
        case .delete:
            return PathComponent(stringLiteral: Self.delete.rawValue)
        case .search:
            return PathComponent(stringLiteral: Self.search.rawValue)
        case .comments:
            return PathComponent(stringLiteral: Self.comments.rawValue)
        case .tags:
            return PathComponent(stringLiteral: Self.tags.rawValue)
        case .tagId:
            return PathComponent(stringLiteral: ":\(Self.tagId.rawValue)")
        case .edit:
            return PathComponent(stringLiteral: Self.edit.rawValue)
        }
    }
}

struct WebsiteView {
    static let register = (leafRenderer: "register", title: "Sign Up")
    static let login = (leafRenderer: "login", title: "Sign In")
    static let allUsers = (leafRenderer: "allUsers", title: "Authors")
    static let profile = (leafRenderer: "profile", title: "My Profile")
    static let addProfilePicture = (leafRenderer: "addPicture", title: "Update Profile Picture")
    static let editProfile = (leafRenderer: "editProfile", title: "Edit Profile")
    static let userArticles = (leafRenderer: "userArticles", title: "")
    static let userComments = (leafRenderer: "userComments", title: "My Comments")
    static let index = (leafRenderer: "index", title: "Home page")
    static let article = (leafRenderer: "article", title: "")
    static let createArticle = (leafRenderer: "createArticle", title: "Write An Article")
    static let addArticlePicture = (leafRenderer: "addPicture", title: "Update Article Picture")
    static let editArticle = (leafRenderer: "createArticle", title: "Edit Article")
    static let searchArticle = (leafRenderer: "search", title: "Search")
    static let allTags = (leafRenderer: "allTags", title: "Tags")
    static let tag = (leafRenderer: "tag", title: "")
}
