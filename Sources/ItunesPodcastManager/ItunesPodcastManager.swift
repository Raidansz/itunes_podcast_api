//
//  ItunesManager.swift
//  PodcastLibraries
//
//  Created by Raidan on 2024. 11. 13..
//

import Foundation
import SwiftyJSON
import ItunesPodcastManagerLogger

/// Searches for podcasts based on various filters.
///
/// - Parameters:
///   - term: The search term.
///   - country: Country of the iTunes store.
///   - entity: The entity type, default is `.podcastAndEpisode`.
///   - attribute: Specific attribute to filter results.
///   - genreId: Genre to filter results by.
///   - lang: Language of the results.
///   - version: API version, default is 2.
///   - explicit: Explicit content filter.
/// - Returns: A `PodcastResult` containing search results.
/// - Throws: An error if the request or parsing fails.
public func searchPodcasts(term: String? = nil,
                           country: Country? = nil,
                           entity: Entity? = .podcastAndEpisode,
                           attribute: String? = nil,
                           genreId: PodcastGenre? = nil,
                           lang: Language? = nil,
                           version: Int? = 2,
                           explicit: String? = nil) async throws -> PodcastResult {
    let url = "search"
    var queryItems = constructBaseQueryItems(
        term: term,
        country: country,
        entity: entity,
        attribute: attribute,
        genreId: genreId,
        lang: lang,
        version: version,
        explicit: explicit
    )

    queryItems.append(URLQueryItem(name: ItunesManager.Constants.media, value: "podcast"))

    var urlComponents = URLComponents(string: ItunesManager.Constants.apiURL + url)
    urlComponents?.queryItems = queryItems

    return try await ItunesManager.performQuery(urlComponents?.url, entity: entity)
}

/// Fetches trending podcast IDs for a specific country.
///
/// - Parameters:
///   - country: The country to fetch trending podcasts for.
///   - limit: The maximum number of results.
/// - Returns: An array of podcast IDs.
/// - Throws: An error if the request or parsing fails.
public func getTrendingPodcastIDs(country: Country, limit: Int) async throws -> [String] {
    let scheme = "https"
    let mainURL = "rss.applemarketingtools.com"

    var urlComponents = URLComponents()
    urlComponents.scheme = scheme
    urlComponents.host = mainURL
    urlComponents.path = "/api/v2/\(country.rawValue)/podcasts/top/\(limit)/podcasts.json"

    guard let url = urlComponents.url else {
        LogError("Failed to create valid URL for trending podcasts")
        return []
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        LogError("Bad response for trending podcasts: \(response)")
        throw URLError(.badServerResponse)
    }

    guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let feed = jsonObject["feed"] as? [String: Any],
          let results = feed["results"] as? [[String: Any]] else {
        return []
    }

    let ids = results.compactMap { $0["id"] as? String }
    return ids
}

/// Fetches trending podcasts as full `PodcastResult` items.
///
/// - Parameters:
///   - country: The country for which to fetch trending items.
///   - limit: The maximum number of items to return.
/// - Returns: A `PodcastResult` with trending items.
/// - Throws: An error if the request fails.
public func getTrendingPodcastItems(country: Country, limit: Int) async throws -> PodcastResult {
    let ids = try await getTrendingPodcastIDs(country: country, limit: limit)
    return try await lookupPodcasts(ids: ids)
}

/// Looks up podcasts by an array of IDs.
///
/// - Parameter ids: An array of podcast IDs.
/// - Returns: A `PodcastResult` containing the podcast details for each ID.
/// - Throws: An error if the request or parsing fails.
public func lookupPodcasts(ids: [String]) async throws -> PodcastResult {
    let url = "lookup"
    guard !ids.isEmpty else {
        LogError("Empty podcast ID list for lookup")
        throw URLError(.badURL)
    }

    let idString = ids.joined(separator: ",")

    var queryItems = [URLQueryItem]()
    queryItems.append(URLQueryItem(name: "id", value: idString))
    queryItems.append(URLQueryItem(name: ItunesManager.Constants.media, value: "podcast"))

    var urlComponents = URLComponents(string: ItunesManager.Constants.apiURL + url)
    urlComponents?.queryItems = queryItems

    return try await ItunesManager.performQuery(urlComponents?.url, entity: .podcast)
}

/// Fetches a list of podcasts within a category.
///
/// - Parameters:
///   - category: The genre or category of podcasts.
///   - mediaType: The type of media to search for.
///   - limit: The maximum number of results.
/// - Returns: A `PodcastResult` containing the results for the specified category.
/// - Throws: An error if the request fails.
public func getPodcastListOf(category: PodcastGenre, mediaType: Entity, limit: Int) async throws -> PodcastResult {
    let url = "search"
    var queryItems = constructBaseQueryItems(
        term: "podcast",
        country: nil,
        entity: mediaType,
        attribute: nil,
        genreId: category,
        lang: nil,
        version: nil,
        explicit: nil
    )

    queryItems.append(URLQueryItem(name: ItunesManager.Constants.limit, value: "\(limit)"))

    var urlComponents = URLComponents(string: ItunesManager.Constants.apiURL + url)
    urlComponents?.queryItems = queryItems
    return try await ItunesManager.performQuery(urlComponents?.url, entity: mediaType)
}

/// Helper function to construct query items for API requests.
private func constructBaseQueryItems(term: String? = nil,
                                     country: Country? = nil,
                                     entity: Entity? = nil,
                                     attribute: String? = nil,
                                     genreId: PodcastGenre? = nil,
                                     lang: Language? = nil,
                                     version: Int? = nil,
                                     explicit: String? = nil) -> [URLQueryItem] {
    var queryItems = [URLQueryItem]()

    if let safeTerm = term?.replacingOccurrences(of: " ", with: "+") {
        queryItems.append(URLQueryItem(name: "term", value: safeTerm))
    }
    if let country = country {
        queryItems.append(URLQueryItem(name: ItunesManager.Constants.country, value: country.rawValue))
    }
    if let entity = entity {
        queryItems.append(URLQueryItem(name: ItunesManager.Constants.entity, value: entity.rawValue))
    }
    if let attribute = attribute {
        queryItems.append(URLQueryItem(name: ItunesManager.Constants.attribute, value: attribute))
    }
    if let genreId = genreId {
        queryItems.append(URLQueryItem(name: ItunesManager.Constants.genreId, value: genreId.rawValue))
    }
    if let lang = lang {
        queryItems.append(URLQueryItem(name: ItunesManager.Constants.lang, value: lang.rawValue))
    }
    if let version = version {
        queryItems.append(URLQueryItem(name: ItunesManager.Constants.version, value: String(version)))
    }
    if let explicit = explicit {
        queryItems.append(URLQueryItem(name: ItunesManager.Constants.explicit, value: explicit))
    }

    return queryItems
}

/// Manages interactions with the iTunes API for podcast retrieval.
open class ItunesManager: @unchecked Sendable {
    static let shared = ItunesManager()

    /// Constants used in constructing API queries.
    public struct Constants {
        static let term = "term"
        static let country = "country"
        static let media = "media"
        static let entity = "entity"
        static let attribute = "attribute"
        static let genreId = "genreId"
        static let limit = "limit"
        static let lang = "lang"
        static let version = "version"
        static let explicit = "explicit"
        static let apiURL = "https://itunes.apple.com/"
    }

    /// Performs a query to the iTunes API with the given URL.
    ///
    /// - Parameters:
    ///   - url: The URL to query.
    ///   - entity: The media entity type.
    /// - Returns: A `PodcastResult` with the results.
    /// - Throws: An error if the request fails.
    @Sendable
    static func performQuery(_ url: URL?, entity: Entity?) async throws -> PodcastResult {
        guard let url = url else {
            LogError("Invalid URL in performQuery")
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        try Task.checkCancellation()

        let (data, _) = try await URLSession.shared.data(from: url)

        let json = try JSON(data: data)
        let resultCount = json["resultCount"].intValue
        let resultsArray = json["results"].arrayValue
        let searchResults = resultsArray.map { SearchResult(json: $0) }

        return PodcastResult(
            searchResults: SearchResults(resultCount: resultCount, results: searchResults),
            mediaType: entity
        )
    }
}

/// Represents a podcast genre in the iTunes API.
public enum PodcastGenre: String {
        case arts = "1301"
        case business = "1321"
        case comedy = "1303"
        case education = "1304"
        case healthAndFitness = "1512"
        case kidsAndFamily = "1305"
        case music = "1310"
        case news = "1489"
        case religionAndSpirituality = "1314"
        case science = "1533"
        case societyAndCulture = "1324"
        case sports = "1545"
        case technology = "1318"
        case tvAndFilm = "1309"
        case trueCrime = "1488"
}

/// Represents the entity type in the iTunes API.
public enum Entity: String {
    case podcast = "podcast"
    case podcastEpisode = "podcastEpisode"
    case podcastAndEpisode = "podcast,podcastEpisode"
}

/// Represents a country in the iTunes API.
public enum Country: String {
    case afghanistan = "AF"
    case albania = "AL"
    case algeria = "DZ"
    case andorra = "AD"
    case angola = "AO"
    case antiguaAndBarbuda = "AG"
    case argentina = "AR"
    case armenia = "AM"
    case australia = "AU"
    case austria = "AT"
    case azerbaijan = "AZ"
    case bahamas = "BS"
    case bahrain = "BH"
    case bangladesh = "BD"
    case barbados = "BB"
    case belarus = "BY"
    case belgium = "BE"
    case belize = "BZ"
    case benin = "BJ"
    case bhutan = "BT"
    case bolivia = "BO"
    case bosniaAndHerzegovina = "BA"
    case botswana = "BW"
    case brazil = "BR"
    case brunei = "BN"
    case bulgaria = "BG"
    case burkinaFaso = "BF"
    case burundi = "BI"
    case caboVerde = "CV"
    case cambodia = "KH"
    case cameroon = "CM"
    case canada = "CA"
    case centralAfricanRepublic = "CF"
    case chad = "TD"
    case chile = "CL"
    case china = "CN"
    case colombia = "CO"
    case comoros = "KM"
    case congoBrazzaville = "CG"
    case congoKinshasa = "CD"
    case costaRica = "CR"
    case croatia = "HR"
    case cuba = "CU"
    case cyprus = "CY"
    case czechRepublic = "CZ"
    case denmark = "DK"
    case djibouti = "DJ"
    case dominica = "DM"
    case dominicanRepublic = "DO"
    case ecuador = "EC"
    case egypt = "EG"
    case elSalvador = "SV"
    case equatorialGuinea = "GQ"
    case eritrea = "ER"
    case estonia = "EE"
    case eswatini = "SZ"
    case ethiopia = "ET"
    case fiji = "FJ"
    case finland = "FI"
    case france = "FR"
    case gabon = "GA"
    case gambia = "GM"
    case georgia = "GE"
    case germany = "DE"
    case ghana = "GH"
    case greece = "GR"
    case grenada = "GD"
    case guatemala = "GT"
    case guinea = "GN"
    case guineaBissau = "GW"
    case guyana = "GY"
    case haiti = "HT"
    case honduras = "HN"
    case hungary = "HU"
    case iceland = "IS"
    case india = "IN"
    case indonesia = "ID"
    case iran = "IR"
    case iraq = "IQ"
    case ireland = "IE"
    case israel = "IL"
    case italy = "IT"
    case jamaica = "JM"
    case japan = "JP"
    case jordan = "JO"
    case kazakhstan = "KZ"
    case kenya = "KE"
    case kiribati = "KI"
    case koreaNorth = "KP"
    case koreaSouth = "KR"
    case kosovo = "XK"
    case kuwait = "KW"
    case kyrgyzstan = "KG"
    case laos = "LA"
    case latvia = "LV"
    case lebanon = "LB"
    case lesotho = "LS"
    case liberia = "LR"
    case libya = "LY"
    case liechtenstein = "LI"
    case lithuania = "LT"
    case luxembourg = "LU"
    case madagascar = "MG"
    case malawi = "MW"
    case malaysia = "MY"
    case maldives = "MV"
    case mali = "ML"
    case malta = "MT"
    case marshallIslands = "MH"
    case mauritania = "MR"
    case mauritius = "MU"
    case mexico = "MX"
    case micronesia = "FM"
    case moldova = "MD"
    case monaco = "MC"
    case mongolia = "MN"
    case montenegro = "ME"
    case morocco = "MA"
    case mozambique = "MZ"
    case myanmar = "MM"
    case namibia = "NA"
    case nauru = "NR"
    case nepal = "NP"
    case netherlands = "NL"
    case newZealand = "NZ"
    case nicaragua = "NI"
    case niger = "NE"
    case nigeria = "NG"
    case northMacedonia = "MK"
    case norway = "NO"
    case oman = "OM"
    case pakistan = "PK"
    case palau = "PW"
    case panama = "PA"
    case papuaNewGuinea = "PG"
    case paraguay = "PY"
    case peru = "PE"
    case philippines = "PH"
    case poland = "PL"
    case portugal = "PT"
    case qatar = "QA"
    case romania = "RO"
    case russia = "RU"
    case rwanda = "RW"
    case saintKittsAndNevis = "KN"
    case saintLucia = "LC"
    case saintVincentAndTheGrenadines = "VC"
    case samoa = "WS"
    case sanMarino = "SM"
    case saoTomeAndPrincipe = "ST"
    case saudiArabia = "SA"
    case senegal = "SN"
    case serbia = "RS"
    case seychelles = "SC"
    case sierraLeone = "SL"
    case singapore = "SG"
    case slovakia = "SK"
    case slovenia = "SI"
    case solomonIslands = "SB"
    case somalia = "SO"
    case southAfrica = "ZA"
    case southSudan = "SS"
    case spain = "ES"
    case sriLanka = "LK"
    case sudan = "SD"
    case suriname = "SR"
    case sweden = "SE"
    case switzerland = "CH"
    case syria = "SY"
    case taiwan = "TW"
    case tajikistan = "TJ"
    case tanzania = "TZ"
    case thailand = "TH"
    case timorLeste = "TL"
    case togo = "TG"
    case tonga = "TO"
    case trinidadAndTobago = "TT"
    case tunisia = "TN"
    case turkey = "TR"
    case turkmenistan = "TM"
    case tuvalu = "TV"
    case uganda = "UG"
    case ukraine = "UA"
    case unitedArabEmirates = "AE"
    case unitedKingdom = "GB"
    case unitedStates = "US"
    case uruguay = "UY"
    case uzbekistan = "UZ"
    case vanuatu = "VU"
    case venezuela = "VE"
    case vietnam = "VN"
    case yemen = "YE"
    case zambia = "ZM"
    case zimbabwe = "ZW"
    public static func fromCountryCode(_ code: String) -> Country? {
        return Country(rawValue: code.uppercased())
    }
}

/// Represents a language option in the iTunes API.
public enum Language: String {
        case afrikaans = "af"
        case albanian = "sq"
        case amharic = "am"
        case arabic = "ar"
        case armenian = "hy"
        case azerbaijani = "az"
        case basque = "eu"
        case belarusian = "be"
        case bengali = "bn"
        case bosnian = "bs"
        case bulgarian = "bg"
        case catalan = "ca"
        case chinese = "zh"
        case croatian = "hr"
        case czech = "cs"
        case danish = "da"
        case dutch = "nl"
        case english = "en"
        case esperanto = "eo"
        case estonian = "et"
        case finnish = "fi"
        case french = "fr"
        case galician = "gl"
        case georgian = "ka"
        case german = "de"
        case greek = "el"
        case gujarati = "gu"
        case haitianCreole = "ht"
        case hebrew = "he"
        case hindi = "hi"
        case hungarian = "hu"
        case icelandic = "is"
        case indonesian = "id"
        case irish = "ga"
        case italian = "it"
        case japanese = "ja"
        case kannada = "kn"
        case kazakh = "kk"
        case khmer = "km"
        case korean = "ko"
        case kurdish = "ku"
        case kyrgyz = "ky"
        case lao = "lo"
        case latvian = "lv"
        case lithuanian = "lt"
        case macedonian = "mk"
        case malagasy = "mg"
        case malay = "ms"
        case malayalam = "ml"
        case maltese = "mt"
        case maori = "mi"
        case marathi = "mr"
        case mongolian = "mn"
        case myanmar = "my"
        case nepali = "ne"
        case norwegian = "no"
        case pashto = "ps"
        case persian = "fa"
        case polish = "pl"
        case portuguese = "pt"
        case punjabi = "pa"
        case romanian = "ro"
        case russian = "ru"
        case samoan = "sm"
        case serbian = "sr"
        case sindhi = "sd"
        case sinhala = "si"
        case slovak = "sk"
        case slovenian = "sl"
        case somali = "so"
        case spanish = "es"
        case swahili = "sw"
        case swedish = "sv"
        case tajik = "tg"
        case tamil = "ta"
        case telugu = "te"
        case thai = "th"
        case turkish = "tr"
        case ukrainian = "uk"
        case urdu = "ur"
        case uzbek = "uz"
        case vietnamese = "vi"
        case welsh = "cy"
        case xhosa = "xh"
        case yiddish = "yi"
        case yoruba = "yo"
        case zulu = "zu"
}

/// Holds results of a podcast search query.
public final class PodcastResult: Identifiable, Codable, Sendable {
    public let totalCount: Int?
    public let podcastList: [Podcast]?
    init(searchResults: SearchResults, mediaType: Entity? = nil) {
        self.totalCount = searchResults.resultCount
        self.podcastList = searchResults.results.compactMap { item in
            try? Podcast.normalizeResult(result: item, mediaType: mediaType, totalCount: searchResults.resultCount)
        }
    }
}

/// Represents a single podcast.
public final class Podcast: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String?
    public let image: URL?
    public let publicationDate: Date?
    public let author: String?
    public let isPodcast: Bool
    public let feedURL: URL?

    init(item: SearchResult, mediaType: Entity?) {
        self.id = "\(item.id)"
        self.title = item.trackName
        self.image = item.artworkUrl600 ?? item.artworkUrl100 ?? URL(fileURLWithPath: "")
        self.publicationDate = item.releaseDate
        self.author = item.artistName ?? ""
        self.isPodcast = mediaType == .podcast
        self.feedURL = item.feedUrl
    }

    static func normalizeResult(result: SearchResult, mediaType: Entity?, totalCount: Int) throws -> Podcast {
        return Podcast(item: result, mediaType: mediaType)
    }
}

/// Holds an array of `SearchResult` objects.
public class SearchResults: Equatable, Identifiable, Codable {
    var resultCount: Int!
    var results: [SearchResult] = []

    init(resultCount: Int, results: [SearchResult]) {
        self.resultCount = resultCount
        self.results = results
    }

    public static func == (lhs: SearchResults, rhs: SearchResults) -> Bool {
        return lhs.results == rhs.results && lhs.resultCount == rhs.resultCount
    }
}

protocol PartialPodcast {
    var collectionId: Int! { get }
    var feedUrl: URL! { get }
    var artistName: String! { get }
    var collectionName: String! { get }
    var artworkUrl30: URL? { get }
    var artworkUrl60: URL? { get }
    var artworkUrl100: URL? { get }
    var collectionExplicitness: String! { get }
    var primaryGenreName: String! { get }
    var artworkUrl600: URL? { get }
    var genreIds: [String]! { get }
    var genres: [String]! { get }
}

public class SearchResult: Equatable, Identifiable, PartialPodcast, Codable {
    public var wrapperType: String!
    public var kind: String!
    public var collectionId: Int!
    public var trackId: Int?
    public var artistName: String!
    public var collectionName: String!
    public var trackName: String!
    public var collectionCensoredName: String!
    public var trackCensoredName: String!
    public var collectionViewUrl: URL!
    public var feedUrl: URL!
    public var trackViewUrl: URL!
    public var artworkUrl30: URL?
    public var artworkUrl60: URL?
    public var artworkUrl100: URL?
    public var collectionPrice: Double?
    public var trackPrice: Double?
    public var trackRentalPrice: Double?
    public var collectionHdPrice: Double?
    public var trackHdPrice: Double?
    public var trackHdRentalPrice: Double?
    public var releaseDate: Date!
    public var collectionExplicitness: String!
    public var trackExplicitness: String!
    public var trackCount: Int?
    public var country: String!
    public var currency: String!
    public var primaryGenreName: String!
    public var contentAdvisoryRating: String?
    public var artworkUrl600: URL?
    public var genreIds: [String]!
    public var genres: [String]!

    public init(json: JSON) {
        wrapperType = json["wrapperType"].string
        kind = json["kind"].string
        collectionId = json["collectionId"].int
        trackId = json["collectionId"].int
        artistName = json["artistName"].string
        collectionName = json["collectionName"].string
        trackName = json["trackName"].string ?? ""
        collectionCensoredName = json["collectionCensoredName"].string
        trackCensoredName = json["trackCensoredName"].string
        collectionViewUrl = URL(string: json["collectionViewUrl"].string ?? "") ?? URL(string: "")
        feedUrl = URL(string: json["feedUrl"].string ?? "")
        trackViewUrl = URL(string: json["trackViewUrl"].string ?? "") ?? URL(string: "")
        artworkUrl30 = URL(string: json["artworkUrl30"].string ?? "")
        artworkUrl60 = URL(string: json["artworkUrl60"].string ?? "")
        artworkUrl100 = URL(string: json["artworkUrl100"].string ?? "")
        artworkUrl600 = URL(string: json["artworkUrl600"].string ?? "")
        collectionPrice = json["collectionPrice"].double
        trackPrice = json["trackPrice"].double
        trackRentalPrice = json["trackRentalPrice"].double
        collectionHdPrice = json["collectionHdPrice"].double
        trackHdPrice = json["trackHdPrice"].double
        trackHdRentalPrice = json["trackHdRentalPrice"].double
        releaseDate = ISO8601DateFormatter().date(from: json["releaseDate"].string ?? "")
        collectionExplicitness = json["collectionExplicitness"].string
        trackExplicitness = json["trackExplicitness"].string
        trackCount = json["trackCount"].int
        country = json["country"].string
        currency = json["currency"].string
        primaryGenreName = json["primaryGenreName"].string
        contentAdvisoryRating = json["contentAdvisoryRating"].string

        if let genreIdsArray = json["genreIds"].array {
            genreIds = genreIdsArray.compactMap { $0.string }
        } else {
            genreIds = []
        }

        if let genresArray = json["genres"].array {
            genres = genresArray.compactMap { $0.string }
        } else {
            genres = []
        }
    }

    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.collectionId == rhs.collectionId &&
        lhs.trackId == rhs.trackId &&
        lhs.artistName == rhs.artistName &&
        lhs.collectionName == rhs.collectionName &&
        lhs.trackName == rhs.trackName &&
        lhs.feedUrl == rhs.feedUrl &&
        lhs.collectionViewUrl == rhs.collectionViewUrl &&
        lhs.primaryGenreName == rhs.primaryGenreName
    }
}
