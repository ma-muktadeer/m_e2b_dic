import 'dart:async';

import 'package:flutter/material.dart';
import 'package:m_e2b_dic/DbHelper.dart';
import 'package:m_e2b_dic/java/GettingValue.dart';

void main() => runApp(const _MyApp());

class _MyApp extends StatefulWidget {
  const _MyApp({super.key});

  String get title => 'My Data';

  @override
  State<_MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<_MyApp> {
  final String title = 'My Data';
  // DbHelper db = DbHelper();
  final DbHelper db = DbHelper();
  bool isLoading = false;
  bool hasError = false;
  Map<String, Map<String, String>>? dictionaryData;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchHistory = [];
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    // Load search history from shared preferences or local storage
    // For now, we'll use a mock list
    setState(() {
      _searchHistory = ['ABC', 'Hello', 'Flutter', 'Dictionary'];
    });
  }

  void _updateSuggestions(String query) {
    setState(() {
      _showSuggestions = query.isNotEmpty;
      _searchSuggestions = _searchHistory
          .where((term) => term.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _fetchData(String word) async {
    if (word.isEmpty) return;

    setState(() {
      isLoading = true;
      hasError = false;
      dictionaryData = null;
      _showSuggestions = false;
    });

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
      // Modify your dbWork function to accept a word parameter
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        cardTheme: CardTheme(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dictionary', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search for a word...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
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
                  // Search suggestions
                  if (_showSuggestions && _searchSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_searchSuggestions[index]),
                            onTap: () {
                              _searchController.text = _searchSuggestions[index];
                              _fetchData(_searchSuggestions[index]);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading data for "${_searchController.text}"',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
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
            Icon(Icons.menu_book, color: Colors.grey[400], size: 64),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Search for a word'
                  : 'No results found for "${_searchController.text}"',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          dictionaryData!['word']?['word'] ?? '',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (dictionaryData!['pronunciation']?['pronunciation'] != null)
                          Text(
                            '/${dictionaryData!['pronunciation']?['pronunciation'] ?? ''}/',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (dictionaryData!['common_mean']?['common_mean'] != null)
                    Text(
                      dictionaryData!['common_mean']?['common_mean'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Definitions section
          if (dictionaryData!['definition'] != null && dictionaryData!['definition']!.isNotEmpty)
            _buildSectionCard(
              title: 'Definitions',
              content: _buildDefinitionContent(),
            ),

          // More meanings section
          if (dictionaryData!['more_mean'] != null && dictionaryData!['more_mean']!.isNotEmpty)
            _buildSectionCard(
              title: 'More Meanings',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: dictionaryData!['more_mean']!.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• ${entry.value}'),
                  );
                }).toList(),
              ),
            ),

          // Synonyms section
          if (dictionaryData!['synonyms'] != null && dictionaryData!['synonyms']!.isNotEmpty)
            _buildSectionCard(
              title: 'Synonyms',
              content: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: dictionaryData!['synonyms']!.entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    backgroundColor: Colors.blue[50],
                    onDeleted: () {
                      // Optional: Implement synonym search
                      _searchController.text = entry.value;
                      _fetchData(entry.value);
                    },
                    deleteIcon: const Icon(Icons.search, size: 18),
                  );
                }).toList(),
              ),
            ),

          // Additional fields (x1, x2)
          if ((dictionaryData!['x1'] != null && dictionaryData!['x1']!.isNotEmpty) ||
              (dictionaryData!['x2'] != null && dictionaryData!['x2']!.isNotEmpty))
            _buildSectionCard(
              title: 'Additional Information',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dictionaryData!['x1'] != null)
                    ...dictionaryData!['x1']!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• ${entry.value}'),
                      );
                    }),
                  if (dictionaryData!['x2'] != null)
                    ...dictionaryData!['x2']!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• ${entry.value}'),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionContent() {
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  //search word


// You'll need to modify your dbWork function to accept a word parameter:
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
      [word]
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


  // Function to extract content within curly braces for a specific category
  List<String> extractContent(String input, String category) {
    RegExp regex = RegExp('$category\\{(.*?)\\}', multiLine: true);
    Match? match = regex.firstMatch(input);
    if (match != null) {
      return match.group(1)?.split(';') ?? [];
    }
    return [];
  }

// Function to create an array by splitting content
  List<String> createArray(List<String> content) {
    List<String> result = [];
    for (String entry in content) {
      List<String> parts = entry.trim().split(':');
      if (parts.length == 2) {
        result.add(parts[1].trim());
      }
    }
    return result;
  }

}

// class alldata {
//   int? _id;
//   String? word;
//   String? common_mean;
//   String? more_mean;
//   String? noun;
//   String? pronoun;
//   String? adjective;
//   String? verb;
//   String? adverb;
//   String? preposition;
//   String? conjunction;
//   String? article;
//   String? definitions;
//   String? examples;
//   String? synonyms;
// }
