// ignore: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:YT_H264/Screens/AddPopup.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:YT_H264/Widgets/QueueWidget.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueuePage extends StatefulWidget {
  GlobalKey<AnimatedListState> listkey = GlobalKey<AnimatedListState>();
  QueuePage({super.key});

  List<YoutubeQueueObject> donwloadQueue = [];

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  late StreamSubscription _intentDataStreamSubscription;
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

  List<Widget> buildQueue() {
    int count = -1;
    return widget.donwloadQueue.map((e) {
      count++;
      return QueueWidget(
          ytobj: e as YoutubeQueueObject,
          downloadStatus: DownloadStatus.waiting,
          index: count,
          rmov: delete);
    }).toList();
  }

  void delete(int index) {
    QueueObject obj = widget.donwloadQueue[index];
    widget.listkey.currentState!.removeItem(
        index,
        ((context, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset(0, 0),
              ).animate(animation),
              child: QueueWidget(
                  ytobj: obj as YoutubeQueueObject,
                  downloadStatus: DownloadStatus.waiting,
                  index: index,
                  rmov: delete),
            )),
        duration: Duration(milliseconds: 100));
    widget.donwloadQueue.removeAt(index);
    saveList();
  }

  void add(QueueObject queueObject, {bool fromJson = false, int? index}) {
    Duration time = Duration(milliseconds: fromJson ? 0 : 100);
    widget.listkey.currentState!.insertItem(
        index != null ? index : widget.donwloadQueue.length,
        duration: time);
    final ytobj = queueObject as YoutubeQueueObject;
    if (!fromJson) {
      widget.donwloadQueue.add(queueObject as YoutubeQueueObject);
      saveList();
    }
  }

  void saveList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedData = YoutubeQueueObject.encode(widget.donwloadQueue);
    await prefs.setString('Queue', encodedData);
  }

  void loadList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonString = await prefs.getString('Queue');
    print(jsonString);
    if (jsonString != null) {
      widget.donwloadQueue = YoutubeQueueObject.decode(jsonString);
      print(widget.donwloadQueue.length);
      int index = 0;
      for (var element in widget.donwloadQueue) {
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
              }).then((value) {
            if (value != null) {
              add(value);
              print(widget.donwloadQueue);
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
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'Helvetica',
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.height * 0.028)),
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
                    add(value);
                    print(widget.donwloadQueue);
                    setState(() {});
                  }
                }),
                child: Center(
                  child: Text('+',
                      style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Helvetica',
                          fontWeight: FontWeight.bold,
                          fontSize:
                              MediaQuery.of(context).size.height * 0.017)),
                ),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Expanded(
          child: AnimatedList(
            key: widget.listkey,
            shrinkWrap: true,
            itemBuilder: (context, index, animation) {
              print(index);
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: Offset(0, 0),
                ).animate(animation),
                child: QueueWidget(
                    ytobj: widget.donwloadQueue[index] as YoutubeQueueObject,
                    downloadStatus: DownloadStatus.waiting,
                    index: index,
                    rmov: delete),
              );
            },
          ),
        ),
      ),
    );
  }
}
