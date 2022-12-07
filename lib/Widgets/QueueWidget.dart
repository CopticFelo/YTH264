import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:YT_H264/Services/GlobalMethods.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:YT_H264/Services/DownloadManager.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:permission_handler/permission_handler.dart';

enum DownloadStatus { waiting, inQueue, downloading, converting, done, error }

Future<Directory?> getTemp() async {
  Directory? dir;
  dir = await getTemporaryDirectory();
  return dir;
}

Future<Directory?> getDownloads() async {
  Directory? dir;
  if (Platform.isIOS) {
    dir = await getApplicationDocumentsDirectory();
  } else {
    dir = Directory('/storage/emulated/0/Download');
    // Put file in global download folder, if for an unknown reason it didn't exist, we fallback
    // ignore: avoid_slow_async_io
    if (!await dir.exists()) {
      dir = await getExternalStorageDirectory();
    }
  }
  return dir;
}

class QueueWidget extends StatefulWidget {
  YoutubeQueueObject ytobj;
  DownloadStatus downloadStatus;
  double progress = 0;
  final index;
  Function rmov;
  QueueWidget(
      {super.key,
      required this.ytobj,
      required this.downloadStatus,
      required this.index,
      required this.rmov});

  @override
  State<QueueWidget> createState() => _QueueWidgetState();
}

class _QueueWidgetState extends State<QueueWidget> {
  ReceivePort? rc;
  SendPort? stopPort;
  bool isDownloading = false;
  Directory? downloads;
  Directory? temps;

  void download() async {
    rc = ReceivePort();
    final storagePermissions = await Permission.storage.status;
    if (!storagePermissions.isGranted) {
      if (await Permission.storage.request().isDenied) {
        GlobalMethods.snackBarError('App Needs Storage Permissions', context);
        return;
      }
    }
    widget.downloadStatus = DownloadStatus.downloading;
    temps = await getTemp();
    downloads = await getDownloads();
    String audioDir;
    String videoDir;
    String title = widget.ytobj.title;
    title = title
        .replaceAll(r'\', '')
        .replaceAll('/', '')
        .replaceAll('*', '')
        .replaceAll('?', '')
        .replaceAll('"', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '');

    Isolate downlaoder = await Isolate.spawn<Map<String, dynamic>>(
        DownloadManager.donwloadVideoFromYoutube, <String, dynamic>{
      'port': rc!.sendPort,
      'ytObj': widget.ytobj,
      'temp': temps,
      'downloads': downloads,
      // 'showError': errorCallback
    }).then((value) {
      setState(() {
        isDownloading = true;
        downloadButtonWidth = 30;
      });
      return value;
    });
    rc!.listen((data) {
      if (data.length > 1) {
        setState(() {
          widget.downloadStatus = data[0];
          widget.progress = data[1];
          if (widget.downloadStatus == DownloadStatus.done) {
            downlaoder.kill();
            setState(() {
              isDownloading = false;
              downloadButtonWidth = 75;
            });
            rc!.close();
          }
        });
        if (widget.ytobj.downloadType == DownloadType.AudioOnly &&
            widget.downloadStatus == DownloadStatus.converting) {
          DownloadManager.convertToMp3(
              downloads, title, widget.ytobj, refresh, temps!, context);
        } else if (widget.ytobj.downloadType == DownloadType.Muxed &&
            widget.downloadStatus == DownloadStatus.converting) {
          DownloadManager.mergeIntoMp4(
              temps, downloads, title, refresh, context);
        }
      } else {
        if (data[0] is SendPort) {
          stopPort = data[0];
        } else {
          GlobalMethods.snackBarError(data[0], context, isException: true);
        }
      }
    });
  }

  void refresh() {
    setState(() {
      widget.downloadStatus = DownloadStatus.done;
      isDownloading = false;
      downloadButtonWidth = MediaQuery.of(context).size.width * 0.23;
    });
  }

  void errorCallback(String msg) {
    GlobalMethods.snackBarError(msg, context, isException: true);
  }

  Widget? buildStatus() {
    print('Status: ${widget.downloadStatus.toString()}');
    if (widget.downloadStatus == DownloadStatus.downloading) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.28,
            height: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                color: Theme.of(context).colorScheme.onBackground,
                value: widget.progress / 100,
              ),
            ),
          ),
          Text(
            '${widget.progress.floor()}%',
            style: TextStyle(
                fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          )
        ],
      );
    } else if (widget.downloadStatus == DownloadStatus.converting) {
      return const Icon(
        Icons.downloading,
        color: Colors.white,
      );
    } else if (widget.downloadStatus == DownloadStatus.done) {
      return const Icon(
        Icons.done,
        color: Colors.white,
      );
    } else {
      return null;
    }
  }

  double? downloadButtonWidth;
  @override
  Widget build(BuildContext context) {
    downloadButtonWidth = MediaQuery.of(context).size.width * 0.23;
    print('Refreshed');
    String type = '';
    if (widget.ytobj.downloadType == DownloadType.Muxed) {
      type = 'Video+Audio';
    } else if (widget.ytobj.downloadType == DownloadType.VideoOnly) {
      type = 'Video';
    } else {
      type = 'Audio';
    }
    return Card(
      color: Colors.black,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Visibility(
                visible: MediaQuery.of(context).size.width > 350 ? true : false,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.network(
                    widget.ytobj.thumbnail,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Flexible(
              flex: 2,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                        child: Text(
                      widget.ytobj.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                    )),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(type,
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Helvetica',
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  MediaQuery.of(context).textScaleFactor * 10)),
                      Row(
                        children: [
                          TextButton(
                            style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(Size.zero),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: MaterialStateProperty.all(
                                  const EdgeInsets.all(6.0)),
                              shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20))),
                              backgroundColor: MaterialStateProperty.all(
                                  Theme.of(context).colorScheme.onBackground),
                              overlayColor:
                                  MaterialStateProperty.all(Colors.grey),
                            ),
                            onPressed: () => widget.rmov(widget.index),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Helvetica',
                                      fontWeight: FontWeight.bold,
                                      fontSize: MediaQuery.of(context)
                                              .textScaleFactor *
                                          12),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Status:',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Helvetica',
                                fontWeight: FontWeight.bold,
                                fontSize: 10),
                          ),
                          buildStatus() ?? Container(),
                        ],
                      ),
                      TextButton(
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all(Size.zero),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(6.0)),
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          backgroundColor:
                              MaterialStateProperty.all(Colors.white),
                          overlayColor: MaterialStateProperty.all(Colors.grey),
                        ),
                        onPressed: () {
                          if (!isDownloading) {
                            download();
                          } else {
                            rc!.close();
                            DownloadManager.stop(widget.downloadStatus,
                                widget.ytobj, downloads!, temps!, stopPort);
                            setState(() {
                              isDownloading = false;
                              downloadButtonWidth = 75;
                              widget.downloadStatus = DownloadStatus.waiting;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(microseconds: 1000),
                          curve: Curves.easeIn,
                          // width: downloadButtonWidth,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(
                                child: Icon(
                                  isDownloading ? Icons.cancel : Icons.download,
                                  color: Colors.black,
                                  size: 12,
                                ),
                              ),
                              Visibility(
                                visible: !isDownloading,
                                child: Text(
                                  'Download',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Helvetica',
                                      fontWeight: FontWeight.bold,
                                      fontSize: MediaQuery.of(context)
                                              .textScaleFactor *
                                          12),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
