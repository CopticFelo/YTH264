// ignore: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:YT_H264/Screens/AddPopup.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:YT_H264/Widgets/QueueWidget.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class QueuePage extends StatefulWidget {
  GlobalKey<AnimatedListState> listkey = GlobalKey<AnimatedListState>();
  QueuePage({super.key});

  List<QueueObject> donwloadQueue = [];

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
  }

  void add(QueueObject queueObject) {
    widget.listkey.currentState!.insertItem(widget.donwloadQueue.length,
        duration: Duration(milliseconds: 100));
    widget.donwloadQueue.add(queueObject);
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
        title: Text('Queue',
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
                  child: Text('+ Add',
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 43,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.height * 0.025,
                    ),
                    Text('Download All',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Helvetica',
                            fontWeight: FontWeight.bold,
                            fontSize:
                                MediaQuery.of(context).textScaleFactor * 25))
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Expanded(
              child: AnimatedList(
                key: widget.listkey,
                shrinkWrap: true,
                itemBuilder: (context, index, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset(0, 0),
                    ).animate(animation),
                    child: QueueWidget(
                        ytobj:
                            widget.donwloadQueue[index] as YoutubeQueueObject,
                        downloadStatus: DownloadStatus.waiting,
                        index: index,
                        rmov: delete),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
