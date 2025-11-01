import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaService {
  static const String _baseUrl = 'https://en.wikipedia.org/api/rest_v1';
  
  /// Get artist summary from Wikipedia
  static Future<Map<String, dynamic>?> getArtistInfo(String artistName) async {
    try {
      // Search for the artist page
      final searchUrl = 'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$artistName&format=json&origin=*';
      
      final searchResponse = await http.get(Uri.parse(searchUrl));
      if (searchResponse.statusCode != 200) return null;
      
      final searchData = json.decode(searchResponse.body);
      final searchResults = searchData['query']?['search'] as List?;
      
      if (searchResults == null || searchResults.isEmpty) return null;
      
      // Get the first result's title
      final pageTitle = searchResults[0]['title'] as String;
      
      // Get page summary
      final summaryUrl = '$_baseUrl/page/summary/${Uri.encodeComponent(pageTitle)}';
      final summaryResponse = await http.get(Uri.parse(summaryUrl));
      
      if (summaryResponse.statusCode != 200) return null;
      
      final summaryData = json.decode(summaryResponse.body);
      
      // Extract relevant information
      return {
        'title': summaryData['title'] as String?,
        'extract': summaryData['extract'] as String?,
        'description': summaryData['description'] as String?,
        'thumbnail': summaryData['thumbnail']?['source'] as String?,
        'pageUrl': summaryData['content_urls']?['desktop']?['page'] as String?,
      };
    } catch (e) {
      print('Wikipedia API Error: $e');
      return null;
    }
  }
  
  /// Get detailed artist biography
  static Future<String?> getArtistBiography(String artistName) async {
    try {
      final info = await getArtistInfo(artistName);
      return info?['extract'] as String?;
    } catch (e) {
      print('Error getting biography: $e');
      return null;
    }
  }
}
