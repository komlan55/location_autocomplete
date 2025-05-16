import 'package:flutter/material.dart';

enum VirtualLocationValue { externalLink, other }

abstract class Location {
  String get label;
  String get displayText;
}

class VirtualLocation extends Location {
  VirtualLocation({this.externalLink});
  String? externalLink;
  bool get isOther => externalLink == null;

  @override
  String get label => "Virtual Location";

  @override
  String get displayText =>
      isOther ? "Virtual: Other" : "Virtual: ${externalLink!}";

  @override
  String toString() {
    return "VirtualLocation($displayText)";
  }
}

class Address extends Location {
  // The formatted address of the place details of the Google Places API.
  // This is a human-readable address that may not be the same as the
  // address components.
  final String formattedAddress;
  String? mainText;
  String? secondaryText;
  final int? streetNumber;
  final String? street;
  final String city;
  final String postalCode;
  final String country;
  final String state;

  final double longitude;
  final double latitude;

  Address({
    required this.formattedAddress,
    required this.city,
    this.streetNumber,
    this.street,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.longitude,
    required this.latitude,
    this.mainText,
    this.secondaryText,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    // Creates an instance of the class from a JSON map.
    //
    // Takes a [Map<String, dynamic>] and returns a new instance
    // with fields populated from the JSON data.
    String formattedAddress = json['formattedAddress'];
    final addressComponents = json['addressComponents'];
    double longitude = json['location']['longitude'];
    double latitude = json['location']['latitude'];
    String state = "";
    String postalCode = "";
    int? streetNumber;
    String? street;
    String country = "";
    String city = "";
    for (var c in addressComponents) {
      final List type = c['types'];
      if (type.contains('street_number')) {
        streetNumber = int.parse(c['longText']);
      }
      if (type.contains('route')) {
        street = c['longText'];
      }
      if (type.contains('locality')) {
        city = c['longText'];
      }
      if (type.contains('postal_code')) {
        postalCode = c['longText'];
      }
      if (type.contains('country')) {
        country = c['longText'];
      }
      if (type.contains('administrative_area_level_1')) {
        state = c['longText'];
      }
    }

    return Address(
      formattedAddress: formattedAddress,
      streetNumber: streetNumber,
      street: street,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      longitude: longitude,
      latitude: latitude,
    );
  }

  @override
  String toString() {
    return "Address{formattedAddress: $formattedAddress, streetNumber: $streetNumber, street: $street, city: $city, state: $state, postalCode: $postalCode, country: $country, longitude: $longitude, latitude: $latitude}";
  }

  @override
  String get label => "Physical Address";
  @override
  String get displayText => formattedAddress;
}

class AddressSuggestion {
  // The formated place prediction based on the Google Places API.
  // This is a human-readable address that may not be the same as the
  // place prediction.
  final String placeId;
  final String mainText;
  final String fullText;
  final String secondaryText;
  bool isSelected;
  AddressSuggestion({
    required this.mainText,
    required this.placeId,
    required this.fullText,
    required this.secondaryText,
    this.isSelected = false,
  });
  @override
  String toString() {
    return "AddressSuggestion{placeId: $placeId, fullText: $fullText, mainText: $mainText, secondaryText: $secondaryText}";
  }

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    // Creates an instance of the class from a JSON map.
    //
    // Takes a [Map<String, dynamic>] and returns a new instance
    var prediction = json['placePrediction'] as Map<String, dynamic>;
    String placeID = prediction['placeId'] as String;

    String fullText = prediction['text']["text"] as String;
    String mainText =
        prediction["structuredFormat"]["mainText"]["text"] as String;
    String secondaryText =
        prediction["structuredFormat"]["secondaryText"]["text"] as String;
    return AddressSuggestion(
      placeId: placeID,
      mainText: mainText,
      secondaryText: secondaryText,
      fullText: fullText,
    );
  }
  static void sortSuggestions(List<AddressSuggestion> suggestions) {
    // Sorts the suggestions based on the isSelected property.
    // The selected suggestions will be at the top of the list.
    suggestions.sort((a, b) {
      if (a.isSelected == true && b.isSelected != true) {
        return -1;
      } else if (a.isSelected != true && b.isSelected == true) {
        return 1;
      }
      return 0;
    });
  }
}

class PlaceType {
  // The type of place based on the Google Places API.
  final String type;
  final IconData icon;
  final String displayText;

  PlaceType({
    required this.type,
    required this.icon,
    required this.displayText,
  });
  static PlaceType park = PlaceType(
    type: "park",
    icon: Icons.park,
    displayText: "Park",
  );
  static PlaceType metro = PlaceType(
    type: "subway",
    icon: Icons.park,
    displayText: "Metro",
  );
}

class ApiException implements Exception {
  // The exception class for the Google Places API.
  final String message;
  final int code;
  final String status;
  ApiException(this.message, this.code, this.status);

  ApiException.fromJson(Map<String, dynamic> json)
    : message = json['message'],
      code = json['code'],
      status = json['status'];
  @override
  String toString() {
    return "ApiException($code): $message - $status";
  }
}
