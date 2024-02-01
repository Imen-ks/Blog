# Blog

![featured](https://github.com/Imen-ks/Blog/blob/master/Public/Images/featured.png)

This project uses [Vapor 4 framework for macOS](https://docs.vapor.codes/install/macos) to build a fully-featured web app comprising a web API consumed by a web Client.  
The models are persisted into a PostgreSQL database hosted in a Docker container.  
To be able to run this project, you need to have [Docker](https://www.docker.com/products/docker-desktop) installed in your system.

## Usage and Configuration

### Open the project
Download the project and save it on your system. Using the terminal, navigate to the directory where the project is located and run the following command:
```
open Package.swift
```
This creates an Xcode project from the Swift package, using Xcode’s support for Swift Package Manager. It will automatically begin downloading Swift Package Manager dependencies. This can take some time the first time you open a project.

### Environment variables
| Key                 | Default Value    | Description       |
|---------------------|------------------|-------------------|
| `DATABASE_HOST`     | `localhost`      | Postgres hostname |
| `DATABASE_NAME`     | `vapor_database` | Postgres database |
| `DATABASE_USERNAME` | `vapor_username` | Postgres username |
| `DATABASE_PASSWORD` | `vapor_password` | Postgres password |
| `REDIS_HOSTNAME`    | `localhost`      | Redis hostname    |
| `DATABASE_URL`      | none             | Heroku database   |

### Run the Docker containers
```
docker run --name postgres \
  -e POSTGRES_DB=vapor_database \
  -e POSTGRES_USER=vapor_username \
  -e POSTGRES_PASSWORD=vapor_password \
  -p 5432:5432 -d postgres
docker run --name redis -p 6379:6379 -d redis
```
> [!NOTE]
> If you didn’t set up the environment variables, the default values will be used to run the containers.

### Custom Working Directory

You must tell Vapor where the API is running. To do this, set a custom working directory in Xcode.  
Option-Click the Run button in Xcode to open the scheme editor. On the Options tab, click to enable `Use custom working directory` and select the directory where the `Package.swift` file lives.  
For more guidance, check [Vapor’s documentation](https://docs.vapor.codes/getting-started/xcode/#custom-working-directory).

### Run the project
Make sure you have the deployment target set to `My Mac` on Xcode, then build and run the application.  
After the database migrations are completed, you should see a notice indicating : Server starting on http://127.0.0.1:8080. This is the root url of the web Client. 
The root url for the web API is http://127.0.0.1:8080/api.

## Seed Data
This project's database is already populated with an initial set of data. The json files containing this data are located under the folder `/Resources/SeedData`.
This is the data used in the section `API Documentation` below to provide example of CURL requests.

You can also test the consumption of the API through the web Client.  
Here are two users already created which you can use to authenticate :
| Username | Password |
|----------|----------|
| janedoe  | password |
| johndoe  | password |

## Models
The database stores the following models:
* User
* Token
* Tag
* Article
* Comment
  
Each model has an `id` property which is a unique identifier for the entries in the database.  
A `createdAt` property is defined for the User, Article & Comment models to store the creation date.  
In addition, an `updatedAt` property is defined for the Article model to trace the latest updated date of article entries following their edition.
`createdAt` and `updatedAt` are equivalent if no update is made to the model.  
Based on these models, the API provides the below response Models to the Client.

### User.Public
A public version of the API User model which does not include the password is returned to the Client when requested.  
The `profilePicture` property of the model is optional and stores the **file name** of the user profile picture.  
`{`  
&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`"firstName"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;`"lastName"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;`"username"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;`"email"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;`"profilePicture"` : `String`   
&nbsp;&nbsp;&nbsp;&nbsp;`"createdAt"` : `Date`  
`}`

### Token
A token is generated following each user login request. The token `value` is to be added to the bearer authentication for CRUD requests. 
The Token model also stores a `user` property providing the unique identifier of the authenticated user.   
`{`  
&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`"value"` : `String`   
&nbsp;&nbsp;&nbsp;&nbsp;`"user"` : `{`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`}`  
`}`

### Tag
A tag can be associated with one or many articles. An article can have one or many tags.  
`{`  
&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`"name"` : `String`  
`}`

### Article
The `picture` property of the model is optional and stores the **file name** of the article picture. 
The Article model also stores a `user` property providing the unique identifier of the the article’s author.  
`{`  
&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`"title"`: `String`  
&nbsp;&nbsp;&nbsp;&nbsp;`"description"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;`"picture"`: `String`  
&nbsp;&nbsp;&nbsp;&nbsp;`"user"` : `{`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`}`,  
&nbsp;&nbsp;&nbsp;&nbsp;`"createdAt"` : `Date`  
&nbsp;&nbsp;&nbsp;&nbsp;`"updatedAt"` : `Date`  
`}`

### Comment
Along with the `description` property relating to the comment description itself, the Comment model also stores an `article` property providing the unique identifier of the commented article as well as an `author` property providing the unique identifier of the comment’s author.  
`{`  
&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`"description"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;`"createdAt"` : `Date`  
&nbsp;&nbsp;&nbsp;&nbsp;`"article"` : `{`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`}`,  
&nbsp;&nbsp;&nbsp;&nbsp;`"author"` : `{`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`}`  
`}`  

### CommentWithArticle
In addition to the comment `description` property this model also provides full information about the commented article.    
`{`  
&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`"description"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;`"createdAt"` : `Date`  
&nbsp;&nbsp;&nbsp;&nbsp;`"article"` : `{`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"title"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"description"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"picture"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"user"` : `{`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`}`,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"createdAt"` : `Date`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"updatedAt"` : `Date`  
&nbsp;&nbsp;&nbsp;&nbsp;`}`  
`}`

### CommentWithArticle
In addition to the comment `description` property this model also provides full information about the comment’s author.  
`{`  
&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;`"description"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;`"createdAt"` : `Date`  
&nbsp;&nbsp;&nbsp;&nbsp;`"author"` : `{`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"id"` : `UUID`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"firstName"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"lastName"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"username"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"email"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"profilePicture"` : `String`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`"createdAt"` : `Date`  
&nbsp;&nbsp;&nbsp;&nbsp;`}`  
`}`

## Routes and Headers

Here is a recap of the different API routes and their related attributes.  
For further details and specific examples, see `API Documentation` section below.

| Method | Route                          | Authorization  | Content-Type         | Body         | Response Content |
|:------:|--------------------------------|----------------|----------------------|--------------|------------------|
| GET    | /api/users                     |                |                      |              | [User.Public]    |
| GET    | /api/users/{userId}            |                |                      |              | User.Public      |
| GET    | /api/articles/{articleId}/user |                |                      |              | User.Public      |
| POST   | /api/users                     |                | application/<br>json | `firstName`<br>`lastName`<br>`username`<br>`password`<br>`email`<br>`profilePicture` | User.Public      |
| POST   | /api/users/login               | Basic          |                      |              | Token            |
| PUT    | /api/users/{userId}            | Bearer         | application/<br>json | `firstName`<br>`lastName`<br>`username`<br>`password`<br>`email`<br>`profilePicture` | User.Public      |
| GET    | /api/tags                      |                |                      |              | [Tag]            |
| GET    | /api/tags/{tagId}              |                |                      |              | Tag              |
| GET    | /api/articles/{articleId}/tags |                |                      |              | [Tag]            |
| POST   | /api/articles/{articleId}/tags | Bearer         | application/<br>x-www-form-<br>urlencoded | List of tag names | [Tag]            |
| GET    | /api/articles                  |                |                      |              | [Article]        |
| GET    | /api/articles/{articleId}      |                |                      |              | Article          |
| GET    | /api/users/{userId}/articles   |                |                      |              | [Article]        |
| GET    | /api/tags/{tagId}/articles     |                |                      |              | [Article]        |
| GET    | /api/articles/search?term=     |                |                      |              | [Article]        |
| POST   | /api/users/{userId}/articles   | Bearer         | application/<br>json | `title`<br>`description`<br>`picture` | Article          |
| PUT    | /api/articles/{articleId}      | Bearer         | application/<br>json | `title`<br>`description`<br>`picture` | Article          |
| DELETE | /api/articles/{articleId}      | Bearer         |                      |              |                  |
| GET    | /api/users/{userId}/comments   |                |                      |              | [Comment<br>WithArticle] |
| GET    | /api/articles/{articleId}/comments |                |                      |              | [Comment<br>WithAuthor] |
| POST   | /api/users/{userId}/<br>articles/{articleId}/comments | Bearer         | application/<br>json | `comment`    | [Comment]        |

## API Documentation

#### GET `/api/users`
This route returns the list of all users.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | [User.Public]    |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/users | jq
```

#### GET `/api/users/{userId}`
This route returns a specified user.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | User.Public      |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/users/1C36BF09-2E46-47BB-A98C-E29B44FA124D | jq
```

#### GET `/api/articles/{articleId}/user`
This route provides the author of a specified article.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | User.Public      |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/articles/31B9718F-B385-4107-A262-C66FB5DD0F66/user | jq
```

#### POST `/api/users`
This routes allows to create a new user. When successfully completed, the created user is returned.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | application/json     | `firstName`: `String`&nbsp;&nbsp;(required)<br>`lastName` : `String`&nbsp;&nbsp;(required)<br>`username` : `String`&nbsp;&nbsp;(required)<br>`password` : `String`&nbsp;&nbsp;(required)<br>`email` : `String`&nbsp;&nbsp;(required)<br>`profilePicture` : `String`&nbsp;&nbsp;(optional) | User.Public      |

CURL Example :
```
curl -H "Content-Type: application/json" \
-d '{"firstName":"foo","lastName":"bar","username":"foobar","password":"password","email":"foo@bar.com"}' \
-X POST \
http://localhost:8080/api/users | jq
```

#### POST `/api/users/login`
This route allows the user to authenticate himself. When successfully completed, the user is authenticated and a token is returned.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| Basic          | Not applicable       | Not applicable           | Token            |

CURL Example :
```
curl -u janedoe:password  \
-X POST \
http://localhost:8080/api/users/login | jq
```

#### PUT `/api/users/{userId}`
This route allows to update a specified user. It requires the user to be authenticated and to be the same user as the one specified. When successfully completed, the updated user is returned.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| Bearer         | application/json     | `firstName`: `String`&nbsp;&nbsp;(optional)<br>`lastName` : `String`&nbsp;&nbsp;(optional)<br>`username` : `String`&nbsp;&nbsp;(optional)<br>`password` : `String`&nbsp;&nbsp;(optional)<br>`email` : `String`&nbsp;&nbsp;(optional)<br>`profilePicture` : `String`&nbsp;&nbsp;(optional) | User.Public      |

CURL Example :
```
curl -H "Content-Type: application/json" \
-H "Authorization: Bearer vxd2uFskmIT5OwfdLbqU+Q==" \
-d '{"email":"jane@doe.com"}' \
-X PUT \
http://localhost:8080/api/users/1C36BF09-2E46-47BB-A98C-E29B44FA124D | jq
```

#### GET `/api/tags`
This route returns the list of all tags.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | [Tag]            |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/tags | jq
```

#### GET `/api/tags/{tagId}`
This route returns a specified tag.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | Tag              |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/tags/F39FF292-C38B-40D2-B221-A5E58716E68A | jq
```

#### GET `/api/articles/{articleId}/tags`
This route provides the tags attached to a specified article.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | [Tag]            |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/articles/31B9718F-B385-4107-A262-C66FB5DD0F66/tags | jq
```

#### POST `/api/articles/{articleId}/tags`
This route allows to attach new tags to a specified article or to update existing ones. It requires the user to be authenticated and to be the author of the article. When successfully completed, the updated tags list is returned.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| Bearer         | application/x-www-form-urlencoded | List of Tags : `[String]`| [Tag]            |

CURL Example :
```
curl -H "Content-Type: application/x-www-form-urlencoded" \
-H "Authorization: Bearer vxd2uFskmIT5OwfdLbqU+Q==" \
-d "vapor,web,frontend" \
-X POST \
http://localhost:8080/api/articles/98F8DF40-D111-4E41-A946-33FB6663F59C/tags | jq
```

#### GET `/api/articles`
This route returns the list of all articles.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | [Article]        |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/articles | jq
```

#### GET `/api/articles/{articleId}`
This route returns a specified article.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | Article          |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/articles/31B9718F-B385-4107-A262-C66FB5DD0F66 | jq
```

#### GET `/api/users/{userId}/articles`
This route provides the list of articles written by a specified user.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | [Article]        |


CURL Example :
```
curl -X GET \
http://localhost:8080/api/users/1C36BF09-2E46-47BB-A98C-E29B44FA124D/articles | jq
```

#### GET `/api/tags/{tagId}/articles`
This route provides the list of articles associated with a specified tag.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | [Article]        |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/tags/F39FF292-C38B-40D2-B221-A5E58716E68A/articles | jq
```

#### GET `/api/articles/search?term=`
This route provides the list of articles whose title or description contains the specified term.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | [Article]        |


CURL Example :
```
curl -X GET \
http://localhost:8080/api/articles/search?term=leaf | jq
```

#### POST `/api/users/{userId}/articles`
This route allows a specified user to create a new article. It requires the user to be authenticated. When successfully completed, the created article is returned.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| Bearer         | application/json     | `title`: `String`&nbsp;&nbsp;(required)<br>`description` : `String`&nbsp;&nbsp;(required)<br>`picture` : `String`&nbsp;&nbsp;(optional) |  Article         |

CURL Example :
```
curl -H "Content-Type: application/json" \
-H "Authorization: Bearer vxd2uFskmIT5OwfdLbqU+Q==" \
-d '{"title":"This is a title.", "description":"This is a description."}' \
-X POST \
http://localhost:8080/api/users/1C36BF09-2E46-47BB-A98C-E29B44FA124D/articles | jq
```

#### PUT `/api/articles/{articleId}`
This route allows to update an article. It requires the user to be authenticated and to be the author of the article. When successfully completed, the updated article is returned.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| Bearer         | application/json     | `title`: `String`&nbsp;&nbsp;(optional)<br>`description` : `String`&nbsp;&nbsp;(optional)<br>`picture` : `String`&nbsp;&nbsp;(optional) |  Article         |


CURL Example :
```
curl -H "Content-Type: application/json" \
-H "Authorization: Bearer vxd2uFskmIT5OwfdLbqU+Q==" \
-d '{"title":"Build backend applications for iOS apps, frontend websites and stand-alone server applications with Vapor"}' \
-X PUT \
http://localhost:8080/api/articles/31B9718F-B385-4107-A262-C66FB5DD0F66 | jq
```

#### DELETE `/api/articles/{articleId}`
This route allows to delete an article. It requires the user to be authenticated and to be the author of the article. When successfully completed, the http status code `204 (No Content)` is returned.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| Bearer         | Not applicable       | Not applicable           | Http status code |

CURL Example :
```
curl -X DELETE \
-o /dev/null -s -w "%{http_code}\n" \
http://localhost:8080/api/articles/F50C1005-4825-495C-B1DE-78A717D87080 \
-H "Authorization: Bearer vxd2uFskmIT5OwfdLbqU+Q==" | jq
```

#### GET `/api/users/{userId}/comments`
This route provides the list of comments written by a specified user. It also returns the articles associated with these comments.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | [CommentWithArticle] |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/users/1BC36B40-2199-4300-A38D-6BCDF1FF7E64/comments | jq
```

#### GET `/api/articles/{articleId}/comments`
This route provides the list of comments related to a specified article. It also returns the authors of these comments.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| None           | Not applicable       | Not applicable           | [CommentWithAuthor] |

CURL Example :
```
curl -X GET \
http://localhost:8080/api/articles/31B9718F-B385-4107-A262-C66FB5DD0F66/comments | jq
```

#### POST `/api/users/{userId}/articles/{articleId}/comments`
This route allows a specified user to post a new comment about a specified article. It requires the user to be authenticated. When successfully completed, the created comment is returned.
| Authorization  | Content-Type         | Body                     | Response Content |
|:--------------:|:--------------------:|--------------------------|:----------------:|
| Bearer         | application/json     | `comment`: `String`&nbsp;&nbsp;(required) |  Comment         |


CURL Example :
```
curl -H "Content-Type: application/json" \
-H "Authorization: Bearer vxd2uFskmIT5OwfdLbqU+Q==" \
-d '{"comment":"This is a comment."}' \
-X POST \
http://localhost:8080/api/users/1C36BF09-2E46-47BB-A98C-E29B44FA124D/articles/0CC0F31E-C79A-4ADC-8EB7-9C8191148339/comments | jq
```

## Remove the Docker containers
```
docker rm -f postgres
docker rm -f redis
```
> [!NOTE]
> You can remove the containers and rerun them to restart with the initial database contained in the project.
