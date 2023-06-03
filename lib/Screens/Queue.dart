// ignore: file_names

import 'dart:async';

import 'package:YT_H264/Screens/EmptyList.dart';
import 'package:flutter/material.dart';
import 'package:YT_H264/Screens/AddPopup.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:YT_H264/Widgets/QueueWidget.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueuePage extends StatefulWidget {
  final GlobalKey<AnimatedListState> listkey = GlobalKey<AnimatedListState>();
  QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  // ignore: unused_field
  late StreamSubscription _intentDataStreamSubscription;
  List<YoutubeQueueObject> downloadQueue = [];
  String? _sharedText;
  void initState() {
    super.initState();
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      setState(() {
        _sharedText = value;
        print("Shared: $_sharedText");
      });
    }, onError: (err) {
      print("getLinkStream error: $err");
    });
    ReceiveSharingIntent.getInitialText().then((String? value) {
      setState(() {
        _sharedText = value;
        print("Shared: $_sharedText");
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => loadList());
  }

  void delete(int index) {
    QueueObject obj = downloadQueue[index];
    widget.listkey.currentState!.removeItem(
        index,
        ((context, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset(0, 0),
              ).animate(animation),
              child: QueueWidget(
                  ytobj: obj as YoutubeQueueObject, index: index, rmov: delete),
            )),
        duration: Duration(milliseconds: 100));
    downloadQueue.removeAt(index);
    saveList();
    setState(() {});
  }

  void add(QueueObject queueObject, {bool fromJson = false, int? index}) {
    Duration time = Duration(milliseconds: fromJson ? 0 : 100);
    widget.listkey.currentState!.insertItem(
        index != null ? index : downloadQueue.length - 1,
        duration: time);
    if (!fromJson) {
      saveList();
    }
  }

  void saveList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedData = YoutubeQueueObject.encode(downloadQueue);
    await prefs.setString('Queue', encodedData);
  }

  void loadList() async {
    await Future.delayed(Duration(milliseconds: 500));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonString = await prefs.getString('Queue');
    print(jsonString);
    if (jsonString != null) {
      downloadQueue = YoutubeQueueObject.decode(jsonString);
      // to init the animated list
      if (downloadQueue.isNotEmpty) {
        setState(() {});
        SchedulerBinding.instance.addPostFrameCallback((_) {
          int index = 0;
          for (var element in downloadQueue) {
            add(element, fromJson: true, index: index);
            index++;
          }
        });
        return;
      }

      int index = 0;
      print(downloadQueue.length);
      for (var element in downloadQueue) {
        add(element, fromJson: true, index: index);
        index++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sharedText != null) {
      String uri = _sharedText!;
      _sharedText = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => showModalBottomSheet(
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (context) {
                return AddModalPopup(
                  uri: uri,
                );
              }).then((value) async {
            if (value != null) {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              final String? jsonString = await prefs.getString('Queue');
              if (downloadQueue.isEmpty && jsonString == null) {
                setState(() {
                  downloadQueue.add(value as YoutubeQueueObject);
                });
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  add(value);
                });
                return;
              }
              downloadQueue.add(value as YoutubeQueueObject);
              add(value);
              print(downloadQueue);
              setState(() {});
            }
          }));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text('YT-H264',
            style: GoogleFonts.lato(
                textStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.height * 0.028))),
        actions: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                0,
                MediaQuery.of(context).size.height * 0.01,
                10,
                MediaQuery.of(context).size.height * 0.01),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TextButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        Theme.of(context).colorScheme.onBackground),
                    overlayColor: MaterialStateProperty.all(
                      Colors.grey[700],
                    )),
                onPressed: () => showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (context) {
                      return AddModalPopup();
                    }).then((value) {
                  if (value != null) {
                    if (downloadQueue.isEmpty) {
                      setState(() {
                        downloadQueue.add(value as YoutubeQueueObject);
                      });
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        add(value);
                      });
                      return;
                    }
                    downloadQueue.add(value as YoutubeQueueObject);
                    add(value);
                    print(downloadQueue);
                    setState(() {});
                  }
                }),
                child: Center(
                  child: Text('+',
                      style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize:
                              MediaQuery.of(context).size.height * 0.017)),
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: downloadQueue.length == 0
              ? EmptyList()
              : AnimatedList(
                  clipBehavior: Clip.none,
                  key: widget.listkey,
                  shrinkWrap: true,
                  itemBuilder: (context, index, animation) {
                    print(index);
                    Widget item = SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1, 0),
                        end: Offset(0, 0),
                      ).animate(animation),
                      child: QueueWidget(
                          ytobj: downloadQueue[index],
                          index: index,
                          rmov: delete),
                    );
                    if (index != 0) {
                      return Column(
                        children: [Divider(), item],
                      );
                    }
                    return item;
                  },
                ),
        ),
      ),
    );
  }
}
