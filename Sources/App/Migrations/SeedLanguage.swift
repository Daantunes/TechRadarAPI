import Fluent
import Foundation

struct SeedLanguage: AsyncMigration {
  func prepare(on database: Database) async throws {
    let fileManager = FileManager.default
    let path = fileManager.currentDirectoryPath + "/Resources/languages.json"
    if let data = fileManager.contents(atPath: path) {
      let languages = try JSONDecoder().decode([Language].self, from: data)
      for language in languages {
        try await language.create(on: database)
      }
    } else {
      fatalError("rings.json not found. Set scheme's `Working Directory` to the project's folder and try again.")
    }
  }

  func revert(on database: Database) async throws {
    try await database
      .schema(Language.schema)
      .delete()
  }
}
