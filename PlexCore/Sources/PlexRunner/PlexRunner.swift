import PlexApi
import PlexCore
import PlexShared

@main
enum Main {
  static func main() async throws {
    do {
      let resources = ResourcesService()
      let resourcesResult = try await resources.capabilities(server: .preview1)
      print(resourcesResult)

      let auth = Auth()
      let res = try await auth.pollForPin(
        deviceInfo: DeviceInfo.current,
        pinId: "123",
        requestDelay: 5,
        maxRetries: 100
      )
      print(res)
      let bla = VideosViewModel()
      await bla.reload(silently: false)

    } catch {
      print(error.localizedDescription)
      throw error
    }
  }
}
