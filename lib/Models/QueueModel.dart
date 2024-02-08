import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/QueueObject.dart';
import '../Widgets/QueueWidget.dart';

class QueueModel extends ChangeNotifier {
  final GlobalKey<AnimatedListState> listkey = GlobalKey<AnimatedListState>();
  List<YoutubeQueueObject> downloadQueue = [];
  List<GlobalKey<QueueWidgetState>> keys = [];

  void delete(int index) {
    QueueObject obj = downloadQueue[index];
    listkey.currentState!.removeItem(
        index,
        ((context, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset(0, 0),
              ).animate(animation),
              child:
                  QueueWidget(ytobj: obj as YoutubeQueueObject, index: index),
            )),
        duration: Duration(milliseconds: 100));
    keys.removeAt(index);
    downloadQueue.removeAt(index);
    saveList();
    notifyListeners();
  }

  void add(QueueObject queueObject, {bool fromJson = false, int? index}) {
    keys.add(GlobalKey<QueueWidgetState>());
    Duration time = Duration(milliseconds: fromJson ? 0 : 100);
    listkey.currentState!.insertItem(
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
        notifyListeners();
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
}
