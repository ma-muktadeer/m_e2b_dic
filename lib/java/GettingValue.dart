// ignore_for_file: unnecessary_string_interpolations

class GettingValue {
  var detailsKey = [
    '_id',
    'pronunciation',
    'more_mean',
    'definition',
    'synonyms',
    'x1',
    'x2'
  ];

  // Map<String, String> gettingDetailsValue(String value) {
  //   Map<String, String> res = Map();
  //   for (String col in detailsKey) {
  //     res[col] = value[col];
  //   }
  // }

  // Map<String, String> convert2Map(String value) {
  //   // String pronunciation = value['pronunciation'];
  //   // var decoded = json.decode(value);
  //
  //   // var map = Map.fromIterable(decoded);
  //
  //   print('---------method-------');
  //   // print(value);
  //   // print(value);
  //   // // print(map[map.\]);
  //   // print(map.values);
  //
  //   RegExp regExp = RegExp(r"\[([^\]]*)\]");
  //
  //   Iterable<Match> matches = regExp.allMatches(value);
  //
  //   List<String> sKeys = [];
  //
  //   for (Match match in matches) {
  //     // Access the captured group inside the brackets
  //     // String? matchedWord = match.group(1);
  //     // print(matchedWord);
  //     sKeys.add(match.group(1)!.trim());
  //   }
  //   // print(sKeys);
  //
  //   List<int> indices = gettingInd2String(value, '}');
  //
  //   Map<String, String> mab = {};
  //
  //   // print('Indices of "}": $indices');
  //
  //   if (indices.length > 0) {
  //     for (String adverb in sKeys) {
  //       // var adverb = 'noun';
  //       // print('adverb is : $adverb');
  //       int a = value.toString().indexOf('[$adverb]');
  //       // print('a is : $a');
  //
  //       if (a > 0) {
  //         int b = indices.firstWhere((element) => element > a);
  //         // print('b is : $b');
  //
  //         // var ab = value.toString().trim().substring(a, value.length).trim();
  //         var ab = value
  //             .toString()
  //             .trim()
  //             .substring(a + adverb.length + 3, b)
  //             .trim();
  //         // print('ab is : $ab');
  //         List<String> abAry = ab.split(';');
  //         // print('abAry is : $abAry');
  //         // print('abAry 1 is : ${abAry[0]}');
  //         // print('abAry 2 is : ${abAry[1]}');
  //         // print(abAry.length);
  //         if (abAry.length > 1) {
  //           mab = array2Map(abAry);
  //         } else {
  //           mab[adverb] = abAry[0];
  //         }
  //       }
  //     }
  //   }
  //   // print('Map value is : $mab');
  //
  //   return mab;
  // }

  Map<String, String> convert2Map(String value) {
    print('---------convert2Map method-------');
    print('Input value: $value');

    if (value.isEmpty) return {};

    // Extract tags like [noun], [verb] etc.
    RegExp tagExp = RegExp(r"\[([^\]]*)\]");
    Iterable<Match> tagMatches = tagExp.allMatches(value);
    List<String> tags = tagMatches.map((m) => m.group(1)!.trim()).where((t) => t.isNotEmpty).toList();

    // Extract content blocks between {}
    RegExp contentExp = RegExp(r"\{(.*?)\}");
    Iterable<Match> contentMatches = contentExp.allMatches(value);
    List<String> contents = contentMatches.map((m) => m.group(1)!.trim()).where((c) => c.isNotEmpty).toList();

    Map<String, String> resultMap = {};

    for (int i = 0; i < tags.length && i < contents.length; i++) {
      String tag = tags[i];
      String content = contents[i];

      if (content.isNotEmpty) {
        // Call _parseDefinitionContent here for proper formatting
        resultMap[tag] = _parseDefinitionContent(content);
      }
    }

    print('Result map: $resultMap');
    return resultMap;
  }

  String _parseDefinitionContent(String content) {
    List<String> items = content.split(';')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Handle numbered definitions (1:, 2:)
    if (items.any((item) => RegExp(r'^\d+:').hasMatch(item))) {
      return items.map((item) {
        final match = RegExp(r'^(\d+:)').firstMatch(item);
        return match != null
            ? item.replaceFirst(match.group(0)!, '${match.group(1)} ')
            : item;
      }).join('\n');
    }

    // Default formatting with bullet points
    return items.map((item) => '• $item').join('\n');
  }

  Map<String, String> array2Map(List<String> abAry) {
    Map<String, String> mab = {};
    for (String item in abAry) {
      try {
        if (item.length > 1) {
          try {
            var [key, value] = item.trim().split(':');
            List<String> keys = key.split(' ');
            // print('keys is $keys');
            if (keys.length == 1) {
              mab[key] = value;
            } else {
              // print(key);
            }
          } catch (e) {
            print(e);
          }
        }
      } catch (e) {
        print(e);
      }
    }
    return mab;
  }

  List<int> gettingInd2String(String value, String findBy) {
    Iterable<RegExpMatch> matches =
        RegExp('$findBy', caseSensitive: false).allMatches(value.toString());

    List<int> indices = matches.map((match) => match.start).toList();
    return indices;
  }
}
