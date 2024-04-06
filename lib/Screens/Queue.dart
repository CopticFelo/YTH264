// ignore: file_names

import 'dart:async';
import 'dart:developer';

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
              print(model.queue.isEmpty);
              if (model.queue.isEmpty) {
                setState(() {
                  model.isEmpty = false;
                });
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  model.add(value);
                });
                return;
              }
              model.add(value as YoutubeQueueObject);
              print(model.queue);
              setState(() {});
            }
          }));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
          'YT-H264',
        ),
        actions: [
          Consumer(
            builder: (context, value, child) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton.outlined(
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                    print(model.queue.isEmpty.toString());
                    if (model.queue.isEmpty) {
                      setState(() {
                        model.isEmpty = false;
                      });
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        model.add(value);
                      });
                      return;
                    }
                    model.add(value);
                    print(model.queue);
                    setState(() {});
                  }
                }),
              ),
            ),
          )
        ],
      ),
      body: Consumer<QueueModel>(builder: (context, value, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: value.isEmpty
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
                          ytobj: value.queue[index],
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
