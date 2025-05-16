import 'dart:convert';

import 'package:location_autocomplete/logger.dart';
import 'package:location_autocomplete/models.dart';
import 'package:http/http.dart' as http;

var log = Logger("Services");
const String baseUrl = "https://places.googleapis.com/v1";

Future<List<AddressSuggestion>> fetchSuggestions(
  http.Client client,
  String apiKey,
  String input, {
  List<PlaceType>? types,
  List? regionCodes,
  String? sessionToken,
  String? languageCode,
}) async {
  if (input.isEmpty || input.length < 3) {
    return [];
  }
  final queryParams = {
    if (languageCode != null) 'languageCode': languageCode,
    if (sessionToken != null) 'sessionToken': sessionToken,
  };
  String request = '$baseUrl/places:autocomplete';
  final headers = {
    'Content-Type': 'application/json',
    "X-Goog-Api-Key": apiKey,
  };
  var body = jsonEncode({
    "input": input,
    if (regionCodes != null) "includedRegionCodes": regionCodes,
  });
  var uri = Uri.parse(request).replace(queryParameters: queryParams);
  final response = await client.post(uri, headers: headers, body: body);
  final Map<String, dynamic> result = jsonDecode(
    utf8.decode(response.bodyBytes),
  );

  if (response.statusCode == 200) {
    if (result['suggestions'] == null) {
      log.i("No suggestions found for input=$input");
      return [];
    }
    List<AddressSuggestion> addressSuggestions =
        result['suggestions'].map<AddressSuggestion>((suggestion) {
          return AddressSuggestion.fromJson(suggestion);
        }).toList();
    return addressSuggestions;
  } else if (response.statusCode == 400 && result["error"] != null) {
    var exception = ApiException.fromJson(result["error"]);
    throw exception;
  } else {
    log.e(
      "Failed fetching for input=$input: Http code ${response.statusCode}, Body: ${response.body}",
    );
    throw Exception('Failed to fetch suggestion for input=$input.');
  }
}

Future<Address?> fetchPlaceDetailFromId(
  http.Client client,
  String apiKey,
  String placeId, {
  String? languageCode,
  String? sessionToken,
}) async {
  final queryParams = {
    if (languageCode != null) 'languageCode': languageCode,
    if (sessionToken != null) 'sessionToken': sessionToken,
  };
  String request = "$baseUrl/places/$placeId";
  var headers = {
    "X-Goog-Api-Key": apiKey,
    "X-Goog-FieldMask":
        "name,displayName,formattedAddress,addressComponents,shortFormattedAddress,location",
  };
  final response = await client.get(
    Uri.parse(request).replace(queryParameters: queryParams),
    headers: headers,
  );
  final result = jsonDecode(
    utf8.decode(response.bodyBytes, allowMalformed: true),
  );

  if (response.statusCode == 200) {
    return Address.fromJson(result);
  } else if (response.statusCode == 400 && result["error"] != null) {
    var exception = ApiException.fromJson(result);
    throw exception;
  } else {
    log.e("Failed fetching place $placeId", result["error"]["details"]);
    throw Exception('Failed to fetch place details for $placeId.');
  }
}
