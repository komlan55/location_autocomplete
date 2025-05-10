# LocationAutocomplete 

## Features
Widget allowing you to search and select address using [Google Place API](https://developers.google.com/maps/documentation/places/web-service/op-overview)

- Address autocommplete
- Location autocomplete (in person/virtual) Similar Facebook Location Autocomplete

![Preview](assets/images/widget-preview.gif)
## Getting started

## Usage


For a simple address autocomplete use **SimpleAddressSearchField**

```dart
SimpleAddressSearchField(
                inputDecoration: InputDecoration(
                  labelText: "Search address",
                  hintText: "Search address",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                googleApiKey: "<Google API KEY>",
                onSelected:
                    (address) =>
                        address != null
                            ? ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Address selected: ${address.formattedAddress}',
                                ),
                              ),
                            )
                            : null,
              )
```
For a for a more complex location search similar to the Facebook event location autocomplete use
**LocationSearchField**
```dart
LocationSearchField(
    hintText: "Location Search address",
    labelText: "Location: in person or virtual",
    googleApiKey: "<Google API KEY>",
    onSelected:
        (address) =>
            address != null
                ? ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                    content: Text(
                        'Location selected: ${address.displayText}',
                      ),
                    ),
                )
                : null,
),
```


## Todo
- [ ] Add package to pub.dev