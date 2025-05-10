import 'package:location_autocomplete/models.dart';
import 'package:location_autocomplete/services.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'services_test.mocks.dart';

const String baseUrl = "https://places.googleapis.com/v1";

@GenerateMocks([http.Client])
void main() {
  group('Services', () {
    late MockClient mockClient;
    String apikey = "ANNUOMFFk";
    setUp(() {
      mockClient = MockClient();
    });

    test(
      'returns place suggestions if the http call completes successfully',
      () async {
        // Arrange
        when(
          mockClient.post(
            Uri.parse("$baseUrl/places:autocomplete?"),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '{"suggestions": [ { "placePrediction": { "place": "places/ChIJd1sVSRCnwokRZkZJ5DqieeA", "placeId": "ChIJd1sVSRCnwokRZkZJ5DqieeA", "text": { "text": "Walter Stewart\'s Market, Elm Street, New Canaan, CT, USA", "matches": [ { "endOffset": 14 } ] }, "structuredFormat": { "mainText": { "text": "Walter Stewart\'s Market", "matches": [ { "endOffset": 14 } ] }, "secondaryText": { "text": "Elm Street, New Canaan, CT, USA" } }, "types": [ "supermarket", "butcher_shop", "food", "store", "point_of_interest", "grocery_store", "restaurant", "deli", "food_store", "market", "sandwich_shop", "establishment" ] } } ]}',
            200,
          ),
        );

        // Act
        final suggestions = await fetchSuggestions(mockClient, apikey, "input");

        // Assert
        expect(suggestions.length, 1);
        expect(suggestions[0].placeId, "ChIJd1sVSRCnwokRZkZJ5DqieeA");
        expect(suggestions[0].mainText, "Walter Stewart's Market");
        expect(suggestions[0].secondaryText, "Elm Street, New Canaan, CT, USA");
        expect(
          suggestions[0].fullText,
          "Walter Stewart's Market, Elm Street, New Canaan, CT, USA",
        );
      },
    );

    test(
      'returns place suggestions if the http call completes successfully',
      () async {
        String placeId = "ChIJ5ejkIL4byUwR6QX2w3htZC4";
        // Arrange
        when(
          mockClient.get(
            Uri.parse("$baseUrl/places/$placeId?"),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '{"name":"places/ChIJ5ejkIL4byUwR6QX2w3htZC4","formattedAddress":"Montreal, QC H2K 1R3, Canada","addressComponents":[{"longText":"Montreal","shortText":"Montreal","types":["locality","political"],"languageCode":"en"},{"longText":"Ville-Marie","shortText":"Ville-Marie","types":["sublocality_level_1","sublocality","political"],"languageCode":"en"},{"longText":"Montréal","shortText":"Montréal","types":["administrative_area_level_3","political"],"languageCode":"fr"},{"longText":"Montreal","shortText":"Montreal","types":["administrative_area_level_2","political"],"languageCode":"en"},{"longText":"Quebec","shortText":"QC","types":["administrative_area_level_1","political"],"languageCode":"en"},{"longText":"Canada","shortText":"CA","types":["country","political"],"languageCode":"en"},{"longText":"H2K 1R3","shortText":"H2K 1R3","types":["postal_code"],"languageCode":"en-US"}],"location":{"latitude":45.5329949,"longitude":-73.5563082},"displayName":{"text":"Walter Stewart Park","languageCode":"en"},"shortFormattedAddress":"Montreal"}',
            200,
          ),
        );

        // Act
        Address? address = await fetchPlaceDetailFromId(
          mockClient,
          apikey,
          placeId,
        );

        // Assert
        expect(address, isNotNull);
        expect(address!.formattedAddress, "Montreal, QC H2K 1R3, Canada");
        expect(address.postalCode, "H2K 1R3");
        expect(address.street, isNull);
        expect(address.streetNumber, isNull);
        expect(address.city, "Montreal");
        expect(address.state, "Quebec");
        expect(address.country, "Canada");
        expect(address.latitude, 45.5329949);
        expect(address.longitude, -73.5563082);
      },
    );
  });
}
