/// Algolia configuration constants for the meal catalog search feature.
///
/// Replace [algoliaAppId] and [algoliaSearchApiKey] with your actual
/// Algolia credentials. Store the search-only API key here (never the
/// admin API key).
abstract final class AlgoliaConstants {
  static const String algoliaAppId = String.fromEnvironment('ALGOLIA_APP_ID');
  static const String algoliaSearchApiKey =
      String.fromEnvironment('ALGOLIA_SEARCH_API_KEY');
  static const String mealsIndexName = 'meals';
  static const String mealsPriceAscIndexName = 'meals_price_asc';
  static const String mealsPriceDescIndexName = 'meals_price_desc';
  static const String mealsNewestFirstIndexName = 'meals_newest_first';
}
