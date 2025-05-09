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
  DbHelper db = DbHelper();
  Future<dynamic>? access;
  bool isButtonPrassed = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              // Text("text"),
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    try {
                      isButtonPrassed = true;
                      // access = dbWork(isButtonPrassed);
                      // access = db.initDb();
                    } catch (_) {
                      print('Fetch error');
                    }
                  });
                },
                child: Icon(
                  Icons.add,
                ),
              ),
              if (isButtonPrassed)
                SingleChildScrollView(
                  // scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      FutureBuilder(
                        future: dbWork(isButtonPrassed),
                        // future: access,
                        builder: (context,
                            AsyncSnapshot<Map<String, Map<String, String>>>
                            snapshot) {
                          if (!snapshot.hasData) {
                            isButtonPrassed = false;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            isButtonPrassed = false;
                            return Text("Error");
                          } else {
                            if (snapshot.data != null) {
                              print('snapshot.data');
                              Map<String, Map<String, String>> myMap =
                              Map.from(snapshot.data!);
                              var mKeyList = myMap.keys.toList();
                              // print(myMap.keys);
                              return SizedBox(
                                height:
                                MediaQuery.of(context).size.height * 0.8,
                                width: MediaQuery.of(context).size.width,
                                child: ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  // itemExtent: 90,
                                  itemCount: myMap.length - 1,
                                  itemBuilder: (context, index) {
                                    Map<String, String>? sMap =
                                    myMap[mKeyList[index + 1]];
                                    var sMapKey = sMap!.keys.toList();

                                    return Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      // alignment: Alignment.topLeft,
                                      child: Stack(
                                        alignment: Alignment.topLeft,
                                        children: [
                                          Container(
                                            // height: 100,
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20),
                                            child: Row(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(mKeyList[index + 1]),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * .50,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: sMapKey.length,
                                          itemBuilder: (context, i) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 1.0),
                                              child: Stack(
                                                children: [
                                                  Column(
                                                    children: [
                                                      Text(sMapKey[i]),
                                                      Text(sMap[sMapKey[i]]!),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    //   ],
                                    // );
                                  },
                                ),
                              );
                              // ),
                              //     ],
                              //   ),
                              // );
                            } else {
                              return Text('Data not found');
                            }
                          }
                        },
                      ),
                      // ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, Map<String, String>>> dbWork(res) async {
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
    if (res) {
      value = await d.rawQuery(
          "select w.common_mean, w.word, d.* from details d, words w where w._id = d._id and w.word ='ABC' ORDER BY w.word ASC LIMIT 2"
      );//and d._id = 43073


      Map<String, Map<String, String>> mapAll = <String, Map<String, String>>{};
      detailsKey.forEach((element) {
        Map<String, String> mab = Map();
        if (element != 'common_mean' && element != 'pronunciation' && element != 'word') {
          if (value[0][element].runtimeType != int &&
              value[0][element] != null) {
            print('key : $element');
            print(element == 'common_mean');
            mab = gv.convert2Map(value[0][element]);
          }
          mapAll.putIfAbsent(element, () => mab);
        } else {
          mab[element] = value[0][element];
          mapAll.putIfAbsent(element, () => mab);
        }

      });
      print('=======>>>>>');
      //
      print(mapAll['common_mean']);
      print(value[0]['common_mean']);
      // print(mapAll);

      return mapAll;
      // return value;
    } else {
      res = true;
      return <String, Map<String, String>>{};
      // return const Text("data not found");
    }
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
