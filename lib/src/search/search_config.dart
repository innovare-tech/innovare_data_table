import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/search/enhanced_search_field.dart';

class SearchConfig<T> {
  final String placeholder;
  final List<String> searchFields;
  final int minCharacters;
  final int debounceMs;
  final bool enableSuggestions;
  final bool enableHistory;
  final int maxSuggestions;
  final int maxHistory;
  final List<SearchSuggestion> staticSuggestions;
  final String Function(T item, String field)? fieldGetter;
  final Widget Function(SearchSuggestion suggestion)? suggestionBuilder;
  final VoidCallback? onClearHistory;

  const SearchConfig({
    this.placeholder = "Buscar...",
    this.searchFields = const [],
    this.minCharacters = 2,
    this.debounceMs = 300,
    this.enableSuggestions = true,
    this.enableHistory = true,
    this.maxSuggestions = 5,
    this.maxHistory = 10,
    this.staticSuggestions = const [],
    this.fieldGetter,
    this.suggestionBuilder,
    this.onClearHistory,
  });

  factory SearchConfig.simple({
    String placeholder = "Buscar...",
    List<String> searchFields = const [],
  }) {
    return SearchConfig<T>(
      placeholder: placeholder,
      searchFields: searchFields,
      enableSuggestions: false,
      enableHistory: false,
    );
  }

  factory SearchConfig.withSuggestions({
    String placeholder = "Buscar...",
    List<String> searchFields = const [],
    List<SearchSuggestion> suggestions = const [],
    int maxSuggestions = 5,
  }) {
    return SearchConfig<T>(
      placeholder: placeholder,
      searchFields: searchFields,
      staticSuggestions: suggestions,
      maxSuggestions: maxSuggestions,
      enableHistory: false,
    );
  }

  factory SearchConfig.full({
    String placeholder = "Buscar...",
    List<String> searchFields = const [],
    String Function(T item, String field)? fieldGetter,
    int maxSuggestions = 8,
    int maxHistory = 10,
  }) {
    return SearchConfig<T>(
      placeholder: placeholder,
      searchFields: searchFields,
      fieldGetter: fieldGetter,
      maxSuggestions: maxSuggestions,
      maxHistory: maxHistory,
    );
  }
}

class SearchSuggestion {
  final String text;
  final String? description;
  final IconData? icon;
  final SearchSuggestionType type;
  final Map<String, dynamic>? metadata;

  const SearchSuggestion({
    required this.text,
    this.description,
    this.icon,
    this.type = SearchSuggestionType.suggestion,
    this.metadata,
  });

  factory SearchSuggestion.history(String text) {
    return SearchSuggestion(
      text: text,
      icon: Icons.history,
      type: SearchSuggestionType.history,
    );
  }

  factory SearchSuggestion.popular(String text, {String? description}) {
    return SearchSuggestion(
      text: text,
      description: description,
      icon: Icons.trending_up,
      type: SearchSuggestionType.popular,
    );
  }

  factory SearchSuggestion.filter(String text, String field, dynamic value) {
    return SearchSuggestion(
      text: text,
      description: "Filtrar por $field",
      icon: Icons.filter_list,
      type: SearchSuggestionType.filter,
      metadata: {'field': field, 'value': value},
    );
  }
}
