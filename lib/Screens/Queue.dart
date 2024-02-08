// ignore: file_names

import 'dart:async';

import 'package:YT_H264/Models/QueueModel.dart';
import 'package:YT_H264/Screens/EmptyList.dart';
import 'package:flutter/material.dart';
import 'package:YT_H264/Screens/AddPopup.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:YT_H264/Widgets/QueueWidget.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueuePage extends StatefulWidget {
  QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  // ignore: unused_field
  late StreamSubscription _intentDataStreamSubscription;
  String? _sharedText;
  void initState() {
    super.initState();
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen((value) {
      setState(() {
        _sharedText = value[0].path;
        print("Shared: $_sharedText");
      });
    }, onError: (err) => print("ShareError: $err"));
    ReceiveSharingIntent.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        setState(() {
          _sharedText = value[0].path;
          print("Shared: $_sharedText");
        });
      }
      ReceiveSharingIntent.reset();
    });
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Provider.of<QueueModel>(context, listen: false).loadList());
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
              final QueueModel model =
                  Provider.of<QueueModel>(context, listen: false);
              if (model.downloadQueue.isEmpty && jsonString == null) {
                setState(() {
                  model.downloadQueue.add(value as YoutubeQueueObject);
                });
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  model.add(value);
                });
                return;
              }
              model.add(value as YoutubeQueueObject);
              model.add(value);
              print(model.downloadQueue);
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
              child: Consumer(
                builder: (context, value, child) => TextButton(
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
                      final QueueModel model =
                          Provider.of<QueueModel>(context, listen: false);
                      if (model.downloadQueue.isEmpty) {
                        setState(() {
                          model.downloadQueue.add(value as YoutubeQueueObject);
                        });
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          value.add(value);
                        });
                        return;
                      }
                      model.downloadQueue.add(value as YoutubeQueueObject);
                      model.add(value);
                      print(model.downloadQueue);
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
            ),
          )
        ],
      ),
      body: Consumer<QueueModel>(builder: (context, value, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: value.downloadQueue.length == 0
                ? EmptyList()
                : AnimatedList(
                    clipBehavior: Clip.none,
                    key: value.listkey,
                    shrinkWrap: true,
                    itemBuilder: (context, index, animation) {
                      final key = value.keys[index];
                      print(index);
                      Widget item = SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-1, 0),
                          end: Offset(0, 0),
                        ).animate(animation),
                        child: QueueWidget(
                          key: key,
                          ytobj: value.downloadQueue[index],
                          index: index,
                        ),
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
        );
      }),
    );
  }
}
