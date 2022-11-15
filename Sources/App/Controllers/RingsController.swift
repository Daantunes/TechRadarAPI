import Vapor
import Fluent
import Foundation

struct RingsController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let ringsRoutes = routes.grouped("api", "rings")
    ringsRoutes.get(use: getAllHandler)
    ringsRoutes.get(":ringID", use: getHandler)
    ringsRoutes.get(":ringID", "languages", use: getLanguagesHandler)

    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let protected = ringsRoutes.grouped(
      tokenAuthMiddleware,
      guardAuthMiddleware)

    protected.post(use: createHandler)
    protected.put(":ringID", use: updateHandler)
    protected.delete(":ringID", use: deleteHandler)
    protected.put(":ringID", "languages", use: updateLanguagesHandler)
  }

  func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Ring]> {
    Ring.query(on: req.db).with(\.$languages).all()
  }

  func getHandler(_ req: Request) throws -> EventLoopFuture<Ring> {
    Ring.find(req.parameters.get("ringID"), on: req.db).unwrap(or: Abort(.notFound))
  }

  func createHandler(_ req: Request) throws -> EventLoopFuture<Ring> {
    let data = try req.content.decode(Ring.self)
    let ring = Ring(name: data.name)

    return ring.save(on: req.db).map { ring }
  }

  func updateHandler(_ req: Request) throws -> EventLoopFuture<Ring> {
    let updatedData = try req.content.decode(Ring.self)

    return Ring
      .find(req.parameters.get("ringID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { ring in
        ring.name = updatedData.name

        return ring.save(on: req.db).map { ring }
      }
  }

  func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
    Ring.find(req.parameters.get("ringID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { ring in
        ring.delete(on: req.db).transform(to: .noContent)
      }
  }

  func getLanguagesHandler(_ req: Request) throws -> EventLoopFuture<[Language]> {
    Ring.find(req.parameters.get("ringID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { ring in
        ring.$languages.get(on: req.db)
      }
  }

  func updateLanguagesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
    guard let id = req.parameters.get("ringID", as: UUID.self) else {
      throw Abort(.internalServerError)
    }

    let languages = try req.content.decode([String].self).map {
      Language(name: $0, ringID: id)
    }

    let removeLanguages = Language.query(on: req.db)
      .filter(\Language.$ring.$id == id)
      .delete()

    let createLanguages = Ring
      .find(id, on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { ring in
        ring.$languages.create(languages, on: req.db)
      }

    return removeLanguages.and(createLanguages).transform(to: .noContent)
  }
}
