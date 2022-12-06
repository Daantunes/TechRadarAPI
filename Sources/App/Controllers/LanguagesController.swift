import Vapor
import Fluent

struct LanguagesController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let languagesRoutes = routes.grouped("api", "languages")
    languagesRoutes.get(use: getAllHandler)
    languagesRoutes.get(":languageID", use: getHandler)
    languagesRoutes.get("search", use: searchHandler)
    languagesRoutes.get(":languageID", "ring", use: getRingHandler)

    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let protected = languagesRoutes.grouped(
      tokenAuthMiddleware,
      guardAuthMiddleware)

    protected.post(use: createHandler)
    protected.put(":languageID", use: updateHandler)
    protected.delete(":languageID", use: deleteHandler)
  }

  func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Language]> {
    Language.query(on: req.db).all()
  }

  func getHandler(_ req: Request) throws -> EventLoopFuture<Language> {
    Language.find(req.parameters.get("languageID"), on: req.db).unwrap(or: Abort(.notFound))
  }

  func createHandler(_ req: Request) throws -> EventLoopFuture<Language> {
    let data = try req.content.decode(LanguageDTO.self)
    let language = Language(name: data.name, ringID: data.ringID)

    return language.save(on: req.db).map { language }
  }

  func updateHandler(_ req: Request) throws -> EventLoopFuture<Language> {
    let updatedData = try req.content.decode(LanguageDTO.self)

    return Language
      .find(req.parameters.get("languageID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { language in
        language.name = updatedData.name
        language.$ring.id = updatedData.ringID

        return language.save(on: req.db).map { language }
      }
  }

  func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
    Language.find(req.parameters.get("languageID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { language in
        language.delete(on: req.db).transform(to: .noContent)
      }
  }

  func searchHandler(_ req: Request) throws -> EventLoopFuture<[Language]> {
    guard let searchTerm = req.query[String.self, at: "term"] else {
      throw Abort(.badRequest)
    }
    return Language.query(on: req.db)
      .filter(\.$name, .custom("~*"), searchTerm)
      .all()
  }

  func getRingHandler(_ req: Request) throws -> EventLoopFuture<Ring> {
    Language.find(req.parameters.get("languageID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { language in
        language.$ring.get(on: req.db)
      }
  }
}
