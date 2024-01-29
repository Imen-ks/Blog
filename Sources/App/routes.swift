import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    // API
    let articlesController = ArticlesController()
    try app.register(collection: articlesController)
    
    let usersController = UsersController()
    try app.register(collection: usersController)
    
    let tagsController = TagsController()
    try app.register(collection: tagsController)
    
    // WEBSITE
    let webAuthController = WebAuthController()
    try app.register(collection: webAuthController)
    
    let webRegisterController = WebRegisterController()
    try app.register(collection: webRegisterController)
    
    let webArticlesController = WebArticlesController()
    try app.register(collection: webArticlesController)
    
    let webTagsController = WebTagsController()
    try app.register(collection: webTagsController)
    
    let webUsersController = WebUsersController()
    try app.register(collection: webUsersController)
}
