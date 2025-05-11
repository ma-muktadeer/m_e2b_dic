import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../DbHelper.dart';
import '../java/GettingValue.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final DbHelper db = DbHelper();
  bool isLoading = false;
  bool hasError = false;
  Map<String, Map<String, String>>? dictionaryData;
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchHistory = [];
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    _searchController = TextEditingController();
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    // Load search history from shared preferences or local storage
    setState(() {
      _searchHistory = ['Flutter', 'Dictionary', 'Material', 'Design'];
    });
  }

  void _updateSuggestions(String query) async {
    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    final suggestions = await searchWord(query.toUpperCase());

    if (suggestions.isEmpty) {
      _removeOverlay();
      return;
    }

    setState(() {
      _searchSuggestions = suggestions;
      _showSuggestions = true;
    });

    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _searchSuggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_searchSuggestions[index]),
                    onTap: () {
                      _searchController.text = _searchSuggestions[index];
                      _fetchData(_searchSuggestions[index]);
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _fetchData(String word) async {
    if (word.isEmpty) return;

    setState(() {
      isLoading = true;
      hasError = false;
      dictionaryData = null;
      _showSuggestions = false;
    });
    _removeOverlay();

    // Add to search history if not already present
    if (!_searchHistory.contains(word)) {
      setState(() {
        _searchHistory.insert(0, word);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }

    try {
      final result = await dbWork(word.toUpperCase());

      if (result.isEmpty) {
        throw Exception('No data found for "$word"');
      }

      setState(() {
        dictionaryData = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionary'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search History'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchHistory.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(_searchHistory[index]),
                        onTap: () {
                          _searchController.text = _searchHistory[index];
                          _fetchData(_searchHistory[index]);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search for a word...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _updateSuggestions('');
                      _searchFocusNode.unfocus();
                    },
                  )
                      : null,
                ),
                onChanged: _updateSuggestions,
                onSubmitted: (term) {
                  _fetchData(term.trim());
                },
              ),
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading data for "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _fetchData(_searchController.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (dictionaryData == null || dictionaryData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book,
                color: colorScheme.onSurface.withOpacity(0.38), size: 64),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Search for a word'
                  : 'No results found for "${_searchController.text}"',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word header card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Text(
                                dictionaryData!['word']?['word'] ?? '',
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (dictionaryData!['pronunciation']?['pronunciation'] != null)
                                Text(
                                  '/${dictionaryData!['pronunciation']?['pronunciation'] ?? ''}/',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.content_copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text: dictionaryData!['word']?['word'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dictionaryData!['common_mean']?['common_mean'] != null)
                    Text(
                      dictionaryData!['common_mean']?['common_mean'] ?? '',
                      style: textTheme.titleMedium,
                    ),
                ],
              ),
            ),
          ),

          // Definitions section
          if (dictionaryData!['definition'] != null &&
              dictionaryData!['definition']!.isNotEmpty)
            _buildSectionCard(
              title: 'Definitions',
              icon: Icons.description,
              content: _buildDefinitionContent(),
            ),

          // More meanings section
          if (dictionaryData!['more_mean'] != null &&
              dictionaryData!['more_mean']!.isNotEmpty)
            _buildSectionCard(
              title: 'More Meanings',
              icon: Icons.list,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: dictionaryData!['more_mean']!.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 8),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: colorScheme.primary,
                          ),
                        ),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Synonyms section
          if (dictionaryData!['synonyms'] != null &&
              dictionaryData!['synonyms']!.isNotEmpty)
            _buildSectionCard(
              title: 'Synonyms',
              icon: Icons.compare_arrows,
              content: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: dictionaryData!['synonyms']!.entries.map((entry) {
                  return InputChip(
                    label: Text(entry.value),
                    onPressed: () {
                      _searchController.text = entry.value;
                      _fetchData(entry.value);
                    },
                    deleteIcon: const Icon(Icons.search, size: 18),
                    onDeleted: () {
                      _searchController.text = entry.value;
                      _fetchData(entry.value);
                    },
                  );
                }).toList(),
              ),
            ),

          // Additional fields (x1, x2)
          if ((dictionaryData!['x1'] != null &&
              dictionaryData!['x1']!.isNotEmpty) ||
              (dictionaryData!['x2'] != null &&
                  dictionaryData!['x2']!.isNotEmpty))
            _buildSectionCard(
              title: 'Additional Information',
              icon: Icons.info_outline,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dictionaryData!['x1'] != null)
                    ...dictionaryData!['x1']!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 8),
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: colorScheme.primary,
                              ),
                            ),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      );
                    }),
                  if (dictionaryData!['x2'] != null)
                    ...dictionaryData!['x2']!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 8),
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: colorScheme.primary,
                              ),
                            ),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget content,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionContent() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dictionaryData!['definition']!.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.value,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<List<String>> searchWord(String word) async {
    if (word.isEmpty) {
      return [];
    }

    try {
      final dbInstance = await db.initDb();

      // Search in words table and common_mean from details table
      final results = await dbInstance.rawQuery(
        'SELECT word FROM words WHERE word LIKE ? OR common_mean LIKE ? ORDER BY word ASC LIMIT 20',
        ['$word%', '$word%'],
      );
      return _processResults(results);
    } catch (e) {
      print('Error searching for word: $e');
      return [];
    }
  }
  List<String> _processResults(List<Map<String, dynamic>> results) {
    return results
        .map((row) => row['word']?.toString())
        .whereType<String>()
        .where((word) => word.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<Map<String, Map<String, String>>> dbWork(String word) async {
    var detailsKey = [
      '_id',
      'word',
      'common_mean',
      'pronunciation',
      'more_mean',
      'definition',
      'synonyms',
      'x1',
      'x2'
    ];

    GettingValue gv = GettingValue();
    var d = await db.initDb();
    var value;

    value = await d.rawQuery(
      "select w.common_mean, w.word, d.* from details d, words w where w._id = d._id and w.word = ? ORDER BY w.word ASC",
      [word],
    );

    Map<String, Map<String, String>> mapAll = <String, Map<String, String>>{};

    detailsKey.forEach((element) {
      Map<String, String> mab = Map();
      if (element != 'common_mean' && element != 'pronunciation' && element != 'word') {
        if (value[0][element].runtimeType != int && value[0][element] != null) {
          mab = gv.convert2Map(value[0][element]);
        }
        mapAll.putIfAbsent(element, () => mab);
      } else {
        mab[element] = value[0][element];
        mapAll.putIfAbsent(element, () => mab);
      }
    });

    return mapAll;
  }
}