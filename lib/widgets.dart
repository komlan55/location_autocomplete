import 'package:location_autocomplete/logger.dart';
import 'package:location_autocomplete/models.dart';
import 'package:location_autocomplete/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

final log = Logger("AddressAutocomplete");
const String baseUrl = "https://places.googleapis.com/v1";

class SimpleAddressSearchField extends StatefulWidget {
  /// A simple address search field that uses Google Places API to fetch address suggestions.
  /// The [googleApiKey] is required to use the Google Places API.
  /// The [onSelected] callback is called when an address is selected.
  /// The [minInputLength] specifies the minimum number of characters required to start searching.
  /// The [languageCode] specifies the language for the address suggestions.
  /// The [regionCodes] specifies the region codes to restrict the search to.
  /// The [textEditingController] can be used to control the text field.
  /// The [inputDecoration] can be used to customize the appearance of the text field.
  /// The [validator] can be used to validate the input.
  /// The [labelText] is the label for the text field.
  /// The [hintText] is the hint text for the text field.
  const SimpleAddressSearchField({
    super.key,
    this.hintText = "Search address",
    this.labelText,
    this.languageCode = "en",
    this.regionCodes,
    this.textEditingController,
    this.inputDecoration,
    this.validator,
    this.minInputLength = 3,
    required this.onSelected,
    required this.googleApiKey,
  });
  final String? labelText;
  final String? hintText;
  final String languageCode;
  final List? regionCodes;
  final TextEditingController? textEditingController;
  final int minInputLength;
  final ValueChanged<Address?> onSelected;
  final String? Function(dynamic value)? validator;
  final InputDecoration? inputDecoration;
  final String googleApiKey;
  @override
  State<SimpleAddressSearchField> createState() =>
      _SimpleAddressSearchFieldState();
}

class _SimpleAddressSearchFieldState extends State<SimpleAddressSearchField> {
  List<AddressSuggestion> _addressSuggestions = [];
  final GlobalKey fieldKey = GlobalKey();
  final http.Client client = http.Client();
  final String sessionToken = Uuid().v4();
  TextEditingController? textEditingController;
  String? country;
  @override
  void initState() {
    super.initState();
    textEditingController =
        widget.textEditingController ?? TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RawAutocomplete<AddressSuggestion>(
        displayStringForOption: (option) => option.fullText,
        optionsViewBuilder: (context, optionOnSelected, options) {
          // Get the size of the TextField
          final RenderBox renderBox =
              fieldKey.currentContext?.findRenderObject() as RenderBox;
          final double textFieldWidth = renderBox.size.width;

          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: Container(
                color: Colors.grey[200],
                constraints: BoxConstraints(
                  maxHeight: 400,
                  maxWidth: textFieldWidth,
                ), // Optional: Limit height

                padding: EdgeInsets.all(10),
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return SuggestionListItem(
                      suggestion: option,
                      onSelected: (value) {
                        optionOnSelected(option);
                      },
                      onDelete: () {},
                    );
                  },
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (
          context,
          textEditingController,
          focusNode,
          onFieldSubmitted,
        ) {
          return TextFormField(
            key: fieldKey,
            controller: textEditingController,
            focusNode: focusNode,
            decoration:
                widget.inputDecoration ??
                InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
          );
        },
        optionsBuilder: (TextEditingValue textEditingValue) async {
          String? searchingWithQuery = textEditingValue.text;

          List<AddressSuggestion> suggestions = [];
          if (searchingWithQuery.isEmpty ||
              searchingWithQuery.length < widget.minInputLength) {
            return [];
          }
          try {
            suggestions = await fetchSuggestions(
              client,
              widget.googleApiKey,
              searchingWithQuery,
              regionCodes: widget.regionCodes,
              sessionToken: sessionToken,
              languageCode: widget.languageCode,
            );
          } catch (e) {
            log.e("Failed fetched address suggestions: Error $e");
          }

          if (searchingWithQuery != textEditingValue.text) {
            return _addressSuggestions;
          }
          _addressSuggestions = suggestions;
          return suggestions;
        },
        onSelected: (option) async {
          try {
            Address? address = await fetchPlaceDetailFromId(
              client,
              widget.googleApiKey,
              option.placeId,
              languageCode: widget.languageCode,
              sessionToken: sessionToken,
            );

            widget.onSelected(address);
          } catch (e) {
            log.e("Failed to fetch address details: $e");
          }
        },
      ),
    );
  }
}

class SuggestionListItem extends StatelessWidget {
  /// A list item that displays an address suggestion.
  /// The [suggestion] is the address suggestion to display.
  /// The [onSelected] callback is called when the suggestion is selected.
  /// The [onDelete] callback is called when the delete button is pressed.
  /// The [icon] is the icon to display in the leading position.

  const SuggestionListItem({
    super.key,
    required this.suggestion,
    required this.onSelected,
    this.onDelete,
    this.icon = Icons.location_on,
  });
  final ValueChanged<AddressSuggestion?> onSelected;
  final Function? onDelete;
  final AddressSuggestion suggestion;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Icon(icon),
          ),
          title: Text(
            suggestion.mainText,
            softWrap: true,
            maxLines: 2,
            selectionColor: Colors.white,
          ),
          subtitle: Text(suggestion.secondaryText),
          onTap: () {
            onSelected(suggestion);
          },
          trailing:
              suggestion.isSelected == true && onDelete != null
                  ? IconButton(
                    onPressed: () {
                      onDelete!();
                    },
                    icon: Icon(Icons.cancel),
                  )
                  : null,
        ),
      ],
    );
  }
}

class AdvancedAddressSearchView extends StatefulWidget {
  /// An advanced address search view that allows users to select an address
  /// from a list of suggestions.
  /// The [googleApiKey] is required to use the Google Places API.
  /// The [initialAddressSuggestion] is the initial address suggestion to display.
  /// The [onSelected] callback is called when an address is selected.
  /// The [textEditingController] can be used to control the text field.
  /// The [onDelete] callback is called when the delete button is pressed.

  const AdvancedAddressSearchView({
    super.key,
    required this.googleApiKey,
    required this.onSelected,
    required this.onDelete,
    this.textEditingController,
    this.initialAddressSuggestion,
  });
  final String googleApiKey;
  final void Function(Address?, AddressSuggestion?) onSelected;
  final TextEditingController? textEditingController;
  final AddressSuggestion? initialAddressSuggestion;
  final void Function(AddressSuggestion?) onDelete;

  @override
  State<AdvancedAddressSearchView> createState() =>
      _AdvancedAddressSearchViewState();
}

class _AdvancedAddressSearchViewState extends State<AdvancedAddressSearchView> {
  AddressSuggestion? _currentSuggestion;
  List<AddressSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _displayDivider = true;
  final http.Client client = http.Client();
  final String _sessionToken = Uuid().v4();
  TextEditingController? _textEditingController;

  @override
  void initState() {
    super.initState();
    _currentSuggestion = widget.initialAddressSuggestion;
    _currentSuggestion?.isSelected = true;
    _suggestions =
        _currentSuggestion != null
            ? [_currentSuggestion!]
            : []; // Initialize suggestions with the current suggestion
    _textEditingController =
        widget.textEditingController ?? TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _suggestions.clear();
  }

  void _onTextChanged(String input) async {
    setState(() {
      _displayDivider = input.isEmpty;
    });
    if (input.isEmpty || input.length < 3) {
      setState(() {
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    String? errorMessage;
    try {
      final suggestions = await fetchSuggestions(
        client,
        widget.googleApiKey,
        input,
        sessionToken: _sessionToken,
      );
      if (_currentSuggestion != null) {
        if (suggestions.any(
          (suggestion) => suggestion.placeId == _currentSuggestion!.placeId,
        )) {
          for (var suggestion in suggestions) {
            if (suggestion.placeId == _currentSuggestion!.placeId) {
              setState(() {
                suggestion.isSelected = true;
              });
            }
          }
        } else {
          suggestions.add(_currentSuggestion!);
        }
      }
      AddressSuggestion.sortSuggestions(suggestions);

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } on http.ClientException catch (e) {
      log.e("Error fetching suggestions: $e");
      errorMessage =
          "Please ensure that your device is connected to the internet and try again. ";
    } catch (e) {
      log.e("Error fetching suggestions: $e");
      errorMessage = "An error occurred while fetching suggestions";
    } finally {
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textEditingController,
                  onChanged: (value) => _onTextChanged(value),
                  decoration: InputDecoration(
                    fillColor: Colors.grey[150],
                    filled: true,
                    hintText: "Search address",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            Expanded(child: Center(child: const CircularProgressIndicator()))
          else if (_errorMessage != null)
            Expanded(child: Center(child: Text(_errorMessage!)))
          else
            Expanded(
              child: ListView.builder(
                itemCount:
                    _displayDivider
                        ? _suggestions.length + 1
                        : _suggestions.length,
                itemBuilder: (context, index) {
                  AddressSuggestion? suggestion;
                  if (_displayDivider) {
                    if (_suggestions.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    if (_currentSuggestion != null) {
                      if (index == 0) {
                        return Text("Currently selected");
                      } else if (index == 2) {
                        return Text("Suggestions");
                      }
                    } else if (index == 0) {
                      return Text("Suggestions");
                    }
                    final suggestionIndex = index - 1;
                    suggestion = _suggestions[suggestionIndex];
                  } else {
                    suggestion = _suggestions[index];
                  }
                  return SuggestionListItem(
                    onDelete: () {
                      setState(() {
                        _suggestions.remove(suggestion);
                      });
                      widget.onDelete(suggestion);
                      _textEditingController?.text = "";
                    },
                    suggestion: suggestion,
                    onSelected: (selectedSuggestion) async {
                      Address? address = await fetchPlaceDetailFromId(
                        client,
                        widget.googleApiKey,
                        suggestion!.placeId,
                      );
                      if (address != null) {
                        widget.onSelected(address, suggestion);
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class LocationSearchField extends StatefulWidget {
  /// A location search field that allows users to select a physical address
  /// or a virtual location.
  /// The [googleApiKey] is required to use the Google Places API.
  /// The [onSelected] callback is called when a location is selected.
  /// The [inputDecoration] can be used to customize the appearance of the text field.
  /// The [hintText] is the hint text for the text field.
  /// The [labelText] is the label for the text field.
  final String hintText;
  final String labelText;
  final String googleApiKey;
  final InputDecoration? inputDecoration;
  final ValueChanged<Location?> onSelected;
  const LocationSearchField({
    super.key,
    required this.googleApiKey,
    required this.onSelected,
    this.inputDecoration,
    this.hintText = "Search address",
    this.labelText = "Location: in person or virtual",
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField>
    with TickerProviderStateMixin {
  AddressSuggestion? _currentSuggestion;
  TextEditingController? _textEditingController;
  late final TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _textEditingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textEditingController,
      readOnly: true,
      decoration:
          widget.inputDecoration ??
          InputDecoration(
            hintText: widget.hintText,
            labelText: widget.labelText,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
          ),
      onTap: () async {
        Location? selectedLocation = await showModalBottomSheet<Location>(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * .8,
              width: double.infinity,
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: [Tab(text: 'In person'), Tab(text: 'Virtual')],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        AdvancedAddressSearchView(
                          googleApiKey: widget.googleApiKey,
                          initialAddressSuggestion: _currentSuggestion,
                          textEditingController: _textEditingController,
                          onSelected: (address, suggestion) {
                            setState(() {
                              _currentSuggestion = suggestion;
                            });
                            Navigator.pop(context, address);
                          },
                          onDelete: (_) {
                            setState(() {
                              _currentSuggestion = null;
                            });
                          },
                        ),
                        VirtualLocationView(
                          onSubmit: (Location? location) {
                            Navigator.pop(context, location);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
        widget.onSelected(selectedLocation);
        _textEditingController!.text = selectedLocation?.displayText ?? "";
      },
    );
  }
}

class VirtualLocationView extends StatefulWidget {
  /// A view that allows users to select a virtual location.
  /// The [onSubmit] callback is called when a virtual location is selected.
  /// The [initialLocation] is the initial virtual location to display.
  const VirtualLocationView({
    super.key,
    required this.onSubmit,
    this.initialLocation,
  });
  final ValueChanged<Location?> onSubmit;
  final Location? initialLocation;

  @override
  State<VirtualLocationView> createState() => _VirtualLocationViewState();
}

class _VirtualLocationViewState extends State<VirtualLocationView> {
  VirtualLocationValue? _locationValue;
  Location? _currentLocation;
  final TextEditingController _externalLinkTextController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _checkBoxError;
  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    _externalLinkTextController.text = _currentLocation?.displayText ?? "";
  }

  void _onChanged(VirtualLocationValue? value) {
    setState(() {
      _locationValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    var showExternalLinkTextField =
        _locationValue == VirtualLocationValue.externalLink;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<VirtualLocationValue>(
            controlAffinity: ListTileControlAffinity.trailing,
            value: VirtualLocationValue.externalLink,
            groupValue: _locationValue,
            onChanged: _onChanged,
            secondary: CircleAvatar(
              backgroundColor: Colors.grey[400],
              child: Icon(Icons.link),
            ),
            title: Text("External link"),
            subtitle: Text(
              "Add a link so people know where to go when your events starts",
            ),
          ),
          Form(
            key: _formKey,
            child: Visibility(
              visible: showExternalLinkTextField,
              child: TextFormField(
                validator: (value) {
                  if (showExternalLinkTextField && value != null) {
                    if (value.isEmpty) {
                      return "Required";
                    }
                    if (!RegExp(
                      r'^(https?:\/\/)?([\w\-]+\.)+[\w\-]+(\/[\w\-]*)*\/?$',
                    ).hasMatch(value)) {
                      return "Please enter a valid URL";
                    }
                  }
                  return null;
                },
                controller: _externalLinkTextController,
                decoration: InputDecoration(
                  hintText: "External link",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          RadioListTile<VirtualLocationValue>(
            controlAffinity: ListTileControlAffinity.trailing,
            value: VirtualLocationValue.other,
            groupValue: _locationValue,
            onChanged: _onChanged,
            secondary: CircleAvatar(
              backgroundColor: Colors.grey[400],
              child: Icon(Icons.pending),
            ),
            title: Text("Other"),
            subtitle: Text(
              "Include clear instructions in your events details on how to participate",
            ),
          ),
          Visibility(
            visible: _checkBoxError != null,
            child: Text(
              _checkBoxError ?? "",
              style: TextStyle(color: Colors.red),
            ),
          ),
          Expanded(child: SizedBox()),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _checkBoxError = null;
                    });
                    if (_formKey.currentState?.validate() == true) {
                      if (_locationValue == null) {
                        setState(() {
                          _checkBoxError = "Please select an option";
                        });
                      } else {
                        if (_locationValue ==
                            VirtualLocationValue.externalLink) {
                          _currentLocation = VirtualLocation(
                            externalLink: _externalLinkTextController.text,
                          );
                        } else if (_locationValue ==
                            VirtualLocationValue.other) {
                          _currentLocation = VirtualLocation();
                        }
                        widget.onSubmit(_currentLocation);
                      }
                    }
                  },
                  child: Text("Done!"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
