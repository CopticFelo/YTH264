// NOTE: THIS IS ONE OF THE MOST POORLY WRITTEN CODE I HAVE EVER WROTE
// TODO: CLEAN QUEUEWIDGET.DART
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:YT_H264/Services/GlobalMethods.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:YT_H264/Services/DownloadManager.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:permission_handler/permission_handler.dart';

// Enum describing the varoius states of the download
enum DownloadStatus { waiting, inQueue, downloading, converting, done, error }

// It just gets the temp dir
Future<Directory?> getTemp() async {
  Directory? dir;
  dir = await getTemporaryDirectory();
  return dir;
}

// It just gets the downloads dir
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
  // The obj the widget is handling
  YoutubeQueueObject ytobj;
  // the Status of the download for UI elements to keep track of
  DownloadStatus downloadStatus;
  // download progress (if progress > 0: downloading)
  double progress = 0;
  // index of the widget
  final index;
  // function to remove from Download List
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
  bool isDownloading = false; // This shouldn't Exist
  Directory? downloads;
  Directory? temps;

  // Function to start the download
  void download() async {
    // Assigns the Recieveport fo the Isolate
    rc = ReceivePort();
    // This is just makes sure read/write is permited
    final storagePermissions = await Permission.storage.status;
    if (!storagePermissions.isGranted) {
      if (await Permission.storage.request().isDenied) {
        GlobalMethods.snackBarError('App Needs Storage Permissions', context);
        return;
      }
    }
    // Status: Downloading
    widget.downloadStatus = DownloadStatus.downloading;
    // Get the temp dir
    temps = await getTemp();
    // Get the Downloads dir
    downloads = await getDownloads();
    // // Gets the title
    // String title = widget.ytobj.title;
    // // Filters the title of non-allowed characters for filenames
    // title = title
    //     .replaceAll(r'\', '')
    //     .replaceAll('/', '')
    //     .replaceAll('*', '')
    //     .replaceAll('?', '')
    //     .replaceAll('"', '')
    //     .replaceAll('<', '')
    //     .replaceAll('>', '')
    //     .replaceAll('|', '');
    // Spawns an Isolate of the Function DownloadManager.downloadVideoFromYoutube
    Isolate downlaoder = await Isolate.spawn<Map<String, dynamic>>(
        DownloadManager.donwloadVideoFromYoutube, <String, dynamic>{
      'port': rc!.sendPort,
      'ytObj': widget.ytobj,
      'temp': temps,
      'downloads': downloads,
      // 'showError': errorCallback
    }).then((value) {
      // Once the Isolate is spawned
      // It sets the var isDownloading to true and shrinks the download button
      // Why? I am not sure, the DownloadStatus var should be responsible for this crap
      // oh well
      // TODO: Refactor this Crap
      setState(() {
        isDownloading = true;
        downloadButtonWidth = 30;
      });
      return value;
    });
    // Handling Messages between QueueWidget and downloader Isolate
    rc!.listen((data) {
      // Unsafe way of handling messaging (I fixed it in another branch Gotta wait for it to be done)
      if (data.length > 1) {
        // It means that it is a Download Progress Report (Which may or may not be done)
        // data[0] is the Download State
        // data[1] is the Download Progress
        setState(() {
          // Set the Progress and Status Accordingly
          widget.downloadStatus = data[0];
          widget.progress = data[1];
          // if Done (i.e not doing any converstion magic afterwards) Kill the Isolate, close rc and set the UI Up
          if (widget.downloadStatus == DownloadStatus.done) {
            downlaoder.kill();
            setState(() {
              isDownloading = false;
              downloadButtonWidth = 75;
            });
            rc!.close();
          }
        });
        // if DownloadStatus (recieved from data[0]) is converting and the media is audioonly
        if (widget.ytobj.downloadType == DownloadType.AudioOnly &&
            widget.downloadStatus == DownloadStatus.converting) {
          // Convert it from .webm (in temp folder) to .mp3 (to be in downloads folder)
          DownloadManager.convertToMp3(downloads, widget.ytobj.validTitle,
              widget.ytobj, refresh, temps!, context);
          // Note: that Youtube Explode Muxed Video (i.e doesn't need conversion) only supports upto 720p, thus it is not used
          // if DownloadStatus (recieved from data[0]) is converting and the media is Muxed (i.e Video + Audio)
        } else if (widget.ytobj.downloadType == DownloadType.Muxed &&
            widget.downloadStatus == DownloadStatus.converting) {
          // Combine .webm (in temp folder) + mp4 (audioless, in temp folder) into .mp4 (with audio, to be in downloads folder)
          DownloadManager.mergeIntoMp4(
              temps, downloads, widget.ytobj.validTitle, refresh, context);
        }
      } else {
        // Means this is either the Sendport that will be used to
        // Stop the Isolate (Download) from the Widget
        // Or an Error
        if (data[0] is SendPort) {
          stopPort = data[0];
        } else {
          // Displays a Snackbar
          GlobalMethods.snackBarError(data[0], context, isException: true);
        }
      }
    });
  }

  // Used by external Functions to notify the widget that the download (Conversion) is done
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

  // Builds the status UI (i.e the UI next to the word Status: on the UI)
  Widget? buildStatus() {
    print('Status: ${widget.downloadStatus.toString()}');
    // In case of downloading just show a Progress bar
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
      // In case of conversion show a random download symbol (To be looked into)
    } else if (widget.downloadStatus == DownloadStatus.converting) {
      return const Icon(
        Icons.downloading,
        color: Colors.white,
      );
      // In the case of the Download being done, show a done symbol
    } else if (widget.downloadStatus == DownloadStatus.done) {
      return const Icon(
        Icons.done,
        color: Colors.white,
      );
      // Else show nothing (i.e when the user hasn't clicked the download button)
    } else {
      return null;
    }
  }

  double?
      downloadButtonWidth; // This should be refactored into a map of some sort
  @override
  Widget build(BuildContext context) {
    // default download button Width
    downloadButtonWidth = MediaQuery.of(context).size.width * 0.23;
    print('Refreshed');
    // The Text to be displayed under the Video Title
    String type = '';
    if (widget.ytobj.downloadType == DownloadType.Muxed) {
      type = 'Video+Audio';
    } else if (widget.ytobj.downloadType == DownloadType.VideoOnly) {
      type = 'Video';
    } else {
      type = 'Audio';
    }
    // UI
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
