import 'dart:async';
import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';
import 'package:innovare_data_table/src/search/search_config.dart';

enum SearchSuggestionType { suggestion, history, popular, filter }

class EnhancedSearchField<T> extends StatefulWidget {
  final SearchConfig<T> config;
  final List<T> data;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final DataTableColorScheme colors;

  const EnhancedSearchField({
    super.key,
    required this.config,
    required this.data,
    this.initialValue,
    required this.onChanged,
    this.onClear,
    required this.colors,
  });

  @override
  State<EnhancedSearchField<T>> createState() => _EnhancedSearchFieldState<T>();
}

class _EnhancedSearchFieldState<T> extends State<EnhancedSearchField<T>>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _suggestionAnimationController;
  late Animation<double> _suggestionFadeAnimation;
  late Animation<Offset> _suggestionSlideAnimation;

  Timer? _debounceTimer;
  List<SearchSuggestion> _suggestions = [];
  List<String> _searchHistory = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();

    _initializeAnimations();
    _loadSearchHistory();

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  void _initializeAnimations() {
    _suggestionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _suggestionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _suggestionAnimationController, curve: Curves.easeOut),
    );

    _suggestionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _suggestionAnimationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _suggestionAnimationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _loadSearchHistory() {
    // TODO: Implementar persistência real
    _searchHistory = ['produto', 'categoria', 'codigo 123'];
  }

  void _saveToHistory(String query) {
    if (query.length < widget.config.minCharacters) return;

    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);

      if (_searchHistory.length > widget.config.maxHistory) {
        _searchHistory = _searchHistory.take(widget.config.maxHistory).toList();
      }
    });

    // TODO: Salvar no storage persistente
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _generateSuggestions();
      _showSuggestionsOverlay();
    } else {
      _hideSuggestionsOverlay();
    }
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: widget.config.debounceMs), () {
      final text = _controller.text.trim(); // ✅ Trim para evitar espaços vazios

      // ✅ SEMPRE chama onChanged, mesmo quando vazio
      widget.onChanged(text);

      if (_focusNode.hasFocus) {
        _generateSuggestions();
        if (text.isNotEmpty) {
          _showSuggestionsOverlay();
        } else {
          _hideSuggestionsOverlay();
        }
      }
    });
  }

  void _generateSuggestions() {
    if (!widget.config.enableSuggestions && !widget.config.enableHistory) {
      return;
    }

    final query = _controller.text.toLowerCase();
    final suggestions = <SearchSuggestion>[];

    // Histórico de busca
    if (widget.config.enableHistory && query.isEmpty) {
      suggestions.addAll(
        _searchHistory.take(3).map((h) => SearchSuggestion.history(h)),
      );
    }

    // Sugestões estáticas
    suggestions.addAll(
      widget.config.staticSuggestions
          .where((s) => s.text.toLowerCase().contains(query))
          .take(3),
    );

    // Sugestões baseadas nos dados
    if (widget.config.enableSuggestions && query.length >= widget.config.minCharacters) {
      suggestions.addAll(_generateDataSuggestions(query));
    }

    setState(() {
      _suggestions = suggestions.take(widget.config.maxSuggestions).toList();
    });

    _updateSuggestionsOverlay();
  }

  List<SearchSuggestion> _generateDataSuggestions(String query) {
    final suggestions = <SearchSuggestion>[];
    final uniqueValues = <String>{};

    for (final item in widget.data.take(100)) { // Limitar para performance
      for (final field in widget.config.searchFields) {
        String? value;

        if (widget.config.fieldGetter != null) {
          value = widget.config.fieldGetter!(item, field);
        } else {
          // Fallback: tentar acessar campo por reflexão/toString
          value = item.toString();
        }

        if (value != null &&
            value.toLowerCase().contains(query) &&
            !uniqueValues.contains(value) &&
            value.toLowerCase() != query) {

          uniqueValues.add(value);
          suggestions.add(SearchSuggestion(
            text: value,
            description: "em $field",
            icon: Icons.search,
          ));

          if (suggestions.length >= 5) break;
        }
      }
      if (suggestions.length >= 5) break;
    }

    return suggestions;
  }

  void _showSuggestionsOverlay() {
    if (_suggestions.isEmpty || _overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _suggestionAnimationController.forward();
  }

  void _hideSuggestionsOverlay() {
    if (_overlayEntry == null) return;

    _suggestionAnimationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateSuggestionsOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedBuilder(
            animation: _suggestionAnimationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _suggestionFadeAnimation,
                child: SlideTransition(
                  position: _suggestionSlideAnimation,
                  child: _buildSuggestionsList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.colors.outline.withOpacity(0.2)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return _buildSuggestionItem(suggestion);
        },
      ),
    );
  }

  Widget _buildSuggestionItem(SearchSuggestion suggestion) {
    return InkWell(
      onTap: () => _selectSuggestion(suggestion),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (suggestion.icon != null) ...[
              Icon(
                suggestion.icon,
                size: 16,
                color: widget.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.colors.onSurface,
                    ),
                  ),
                  if (suggestion.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (suggestion.type == SearchSuggestionType.history)
              GestureDetector(
                onTap: () => _removeFromHistory(suggestion.text),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: widget.colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectSuggestion(SearchSuggestion suggestion) {
    _controller.text = suggestion.text;
    _saveToHistory(suggestion.text);
    widget.onChanged(suggestion.text);
    _hideSuggestionsOverlay();
    _focusNode.unfocus();
  }

  void _removeFromHistory(String item) {
    setState(() {
      _searchHistory.remove(item);
    });
    _generateSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.search_rounded,
          color: widget.colors.onSurfaceVariant,
          size: 20,
        ),
        hintText: widget.config.placeholder,
        hintStyle: TextStyle(
          color: widget.colors.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: widget.colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: widget.colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: widget.colors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: _controller.text.trim().isNotEmpty // ✅ Usar trim()
            ? IconButton(
          icon: Icon(
            Icons.clear_rounded,
            color: widget.colors.onSurfaceVariant,
            size: 18,
          ),
          onPressed: () {
            _controller.clear();
            widget.onChanged(''); // ✅ Chamar onChanged com string vazia
            widget.onClear?.call();
            _generateSuggestions();
          },
        )
            : null,
      ),
      style: TextStyle(
        fontSize: 14,
        color: widget.colors.onSurface,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}