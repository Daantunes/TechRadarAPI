import Vapor

struct UsersController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let usersRoutes = routes.grouped("api", "users")
    usersRoutes.get(use: getAllHandler)
    usersRoutes.get(":userID", use: getHandler)

    let basicAuthMiddleware = User.authenticator()
    let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
    basicAuthGroup.post("login", use: loginHandler)

    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let protected = usersRoutes.grouped(
      tokenAuthMiddleware,
      guardAuthMiddleware)

    protected.post(use: createHandler)
  }

  func getAllHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
    return User.query(on: req.db).all().convertToPublic()
  }

  func getHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
    return User.find(req.parameters.get("userID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .convertToPublic()
  }

  func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
    let user = try req.content.decode(User.self)
    user.password = try Bcrypt.hash(user.password)
    return user.save(on: req.db).map { user.convertToPublic() }
  }

  func loginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
    let user = try req.auth.require(User.self)
    let token = try Token.generate(for: user)

    return token.save(on: req.db).map { token }
  }


}
