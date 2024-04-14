import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/QueueObject.dart';
import '../Widgets/QueueWidget.dart';

class QueueModel with ChangeNotifier {
  final GlobalKey<AnimatedListState> listkey = GlobalKey<AnimatedListState>();
  List<YoutubeQueueObject> _downloadQueue = [];
  List<GlobalKey<QueueWidgetState>> keys = [];
  bool isEmpty = true;

  List<YoutubeQueueObject> get queue {
    return _downloadQueue;
  }

  void delete(int index, bool removeWidget) {
    if (removeWidget) {
      listkey.currentState!.removeItem(
          index,
          ((context, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset(0, 0),
                ).animate(animation),
                child: QueueWidget(
                  index: index,
                ),
              )),
          duration: Duration(milliseconds: 0));
    }
    keys.removeAt(index);
    _downloadQueue.removeAt(index);
    isEmpty = _downloadQueue.isEmpty;
    saveList();
    notifyListeners();
  }

  void add(QueueObject queueObject, {bool fromJson = false, int? index}) {
    keys.add(GlobalKey<QueueWidgetState>());
    Duration time = Duration(milliseconds: fromJson ? 0 : 100);
    listkey.currentState!.insertItem(
        index != null ? index : _downloadQueue.length,
        duration: time);
    if (!fromJson) {
      _downloadQueue.add(queueObject as YoutubeQueueObject);
      saveList();
    }
  }

  void saveList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedData = YoutubeQueueObject.encode(_downloadQueue);
    await prefs.setString('Queue', encodedData);
  }

  void loadList() async {
    await Future.delayed(Duration(milliseconds: 500));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonString = await prefs.getString('Queue');
    print(jsonString);
    if (jsonString != null) {
      _downloadQueue = YoutubeQueueObject.decode(jsonString);
      // to init the animated list
      if (_downloadQueue.isNotEmpty) {
        isEmpty = false;
        notifyListeners();
        SchedulerBinding.instance.addPostFrameCallback((_) {
          int index = 0;
          for (var element in _downloadQueue) {
            add(element, fromJson: true, index: index);
            index++;
          }
        });
        return;
      }

      int index = 0;
      print(_downloadQueue.length);
      for (var element in _downloadQueue) {
        add(element, fromJson: true, index: index);
        index++;
      }
    }
  }
}
