# iTunes Podcast Manager

iTunes Podcast Manager is a Swift package that simplifies the process of searching, retrieving, and managing podcast data using the iTunes API. It includes functions to search for podcasts, fetch trending podcasts by country, look up podcasts by ID, and filter podcasts based on categories or explicit content.

## Features

- **Search Podcasts:** Perform custom podcast searches using various filters, including term, country, genre, language, and explicit content.
- **Fetch Trending Podcasts:** Retrieve trending podcast IDs or full podcast details for a specific country, with a customizable result limit.
- **Lookup by ID:** Obtain detailed podcast information for specific podcast IDs.
- **Category Filtering:** Fetch podcasts within specific genres, including Business, Comedy, Science, and more.
- **Multi-language Support:** Supports searches across different languages and iTunes store regions.
- **Async API Calls:** All functions are `async` for seamless integration with Swift's asynchronous programming model.

## Usage

Import the package and use the various methods to access podcast data. For example:

```swift
import ItunesPodcastManager

// Example: Search for podcasts about "technology" in the US
let results = try await searchPodcasts(term: "technology", country: .unitedStates)

// Example: Get trending podcasts in the UK, limit 10 results
let trendingPodcasts = try await getTrendingPodcastItems(country: .unitedKingdom, limit: 10)
```


## License

This package is available under the MIT License.
