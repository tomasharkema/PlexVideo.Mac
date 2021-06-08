import Foundation
import XMLCoder

let json = """
<?xml version="1.0" encoding="UTF-8"?>
<MediaContainer size="3" allowSync="0" identifier="com.plexapp.plugins.library" mediaTagPrefix="/system/bundle/media/flags/" mediaTagVersion="1622101051" title1="Plex Library">
<Directory allowSync="1" art="/:/resources/movie-fanart.jpg" composite="/library/sections/1/composite/1622167392" filters="1" refreshing="0" thumb="/:/resources/movie.png" key="1" type="movie" title="Films" agent="tv.plex.agents.movie" scanner="Plex Movie" language="nl-NL" uuid="777509a2-e034-437d-aec1-c6f76c98400a" updatedAt="1622167447" createdAt="1610278829" scannedAt="1622167392" content="1" directory="1" contentChangedAt="659281" hidden="0">
<Location id="7" path="/media/film" />
</Directory>
<Directory allowSync="1" art="/:/resources/show-fanart.jpg" composite="/library/sections/3/composite/1622167434" filters="1" refreshing="0" thumb="/:/resources/show.png" key="3" type="show" title="TV Series" agent="tv.plex.agents.series" scanner="Plex TV Series" language="nl-NL" uuid="c76b150f-cf70-41ec-b4d5-523313b64afc" updatedAt="1622179326" createdAt="1610287572" scannedAt="1622167434" content="1" directory="1" contentChangedAt="662803" hidden="0">
<Location id="3" path="/media/tv" />
</Directory>
<Directory allowSync="1" art="/:/resources/artist-fanart.jpg" composite="/library/sections/4/composite/1622167420" filters="1" refreshing="0" thumb="/:/resources/artist.png" key="4" type="artist" title="Muziek" agent="tv.plex.agents.music" scanner="Plex Music" language="en" uuid="23f36440-3f75-4258-b4a9-aadee974f8e3" updatedAt="1622167475" createdAt="1611235737" scannedAt="1622167420" content="1" directory="1" contentChangedAt="657163" hidden="0">
<Location id="9" path="/cocoariver" />
<Location id="6" path="/media/music" />
</Directory>
</MediaContainer>
""".data(using: .utf8)!

struct MediaContainer: Codable {
  let Directory: [Directory]
}

struct Directory: Codable, Identifiable, DynamicNodeEncoding {
  static func nodeEncoding(for _: CodingKey) -> XMLEncoder.NodeEncoding {
    return .attribute
  }

  let composite: String
  let title: String
  let uuid: String

  var id: String {
    return uuid
  }

  enum CodingKeys: String, CodingKey {
    case composite
    case title
    case uuid
  }
}

struct Video: Codable, Identifiable {
  let id: String
}

let decoded = try! XMLDecoder().decode(MediaContainer.self, from: json)

print(decoded)
