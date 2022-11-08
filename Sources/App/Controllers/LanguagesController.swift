import Vapor

struct LanguagesController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let languagesRoutes = routes.grouped("api", "languages")
    languagesRoutes.get(use: getAllHandler)
    languagesRoutes.get(":languagesID", use: getHandler)

    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let protected = languagesRoutes.grouped(
      tokenAuthMiddleware,
      guardAuthMiddleware)

    protected.post(use: createHandler)
    protected.put(":languagesID", use: updateHandler)
    protected.delete(":languagesID", use: deleteHandler)
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
}
