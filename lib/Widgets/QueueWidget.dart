// NOTE: THIS IS ONE OF THE MOST POORLY WRITTEN CODE I HAVE EVER WROTE
// TODO: CLEAN QUEUEWIDGET.DART
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:YT_H264/Services/GlobalMethods.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final YoutubeQueueObject ytobj;
  // index of the widget
  final index;
  // function to remove from Download List
  final Function rmov;

  QueueWidget(
      {super.key,
      required this.ytobj,
      required this.index,
      required this.rmov});

  @override
  State<QueueWidget> createState() => QueueWidgetState();
}

class QueueWidgetState extends State<QueueWidget>
    with SingleTickerProviderStateMixin {
  DownloadStatus downloadStatus = DownloadStatus.waiting;
  // the Status of the download for UI elements to keep track of
  // download progress (if progress > 0: downloading)
  double progress = 0;
  ReceivePort? rc;
  SendPort? stopPort;
  bool isDownloading = false; // This shouldn't Exist
  Directory? downloads;
  Directory? temps;
  FFmpegSession? conversionSession;
  late AnimationController _controller;
  late Animation<Offset> _slide;

  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _slide = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(1, 0),
    ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut));
  }

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
    downloadStatus = DownloadStatus.downloading;
    // Get the temp dir
    temps = await getTemp();
    // Get the Downloads dir
    downloads = await getDownloads();
    // Spawns an Isolate of the Function DownloadManager.downloadVideoFromYoutube
    Isolate downlaoder = await Isolate.spawn<Map<String, dynamic>>(
        DownloadManager.donwloadVideoFromYoutube, <String, dynamic>{
      'port': rc!.sendPort,
      'ytObj': widget.ytobj,
      'temp': temps,
      'downloads': downloads,
      // 'showError': errorCallback
    }).then((value) {
      // Returns the Isolate
      return value;
    });
    // Handling Messages between QueueWidget and downloader Isolate
    rc!.listen((data) async {
      // Unsafe way of handling messaging (I fixed it in another branch Gotta wait for it to be done)
      if (data.length > 1) {
        // It means that it is a Download Progress Report (Which may or may not be done)
        // data[0] is the Download State
        // data[1] is the Download Progress
        setState(() {
          // Set the Progress and Status Accordingly
          downloadStatus = data[0];
          progress = data[1];
          // if Done (i.e not doing any converstion magic afterwards) Kill the Isolate, close rc and set the UI Up
          if (downloadStatus == DownloadStatus.done) {
            downlaoder.kill();
            setState(() {
              isDownloading = false;
              _controller.reverse();
            });
            rc!.close();
          }
        });
        // if DownloadStatus (recieved from data[0]) is converting and the media is audioonly
        if (widget.ytobj.downloadType == DownloadType.AudioOnly &&
            downloadStatus == DownloadStatus.converting) {
          // Convert it from .webm (in temp folder) to .mp3 (to be in downloads folder)
          conversionSession = await DownloadManager.convertToMp3(
              downloads, widget.ytobj, refresh, temps!, context);
          // Note: that Youtube Explode Muxed Video (i.e doesn't need conversion) only supports upto 720p, thus it is not used
          // if DownloadStatus (recieved from data[0]) is converting and the media is Muxed (i.e Video + Audio)
        } else if (widget.ytobj.downloadType == DownloadType.Muxed &&
            downloadStatus == DownloadStatus.converting) {
          // Combine .webm (in temp folder) + mp4 (audioless, in temp folder) into .mp4 (with audio, to be in downloads folder)
          conversionSession = await DownloadManager.mergeIntoMp4(
              temps, downloads, widget.ytobj, refresh, context);
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
      downloadStatus = DownloadStatus.done;
      isDownloading = false;
      _controller.reverse();
    });
  }

  void errorCallback(String msg) {
    GlobalMethods.snackBarError(msg, context, isException: true);
  }

  // Builds the status UI
  Widget? buildStatus() {
    print('Status: ${downloadStatus.toString()}');
    // In case of downloading just show a Progress bar
    if (downloadStatus == DownloadStatus.downloading) {
      return Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 67.w,
              height: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  backgroundColor: Theme.of(context).colorScheme.onBackground,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                  color: Theme.of(context).colorScheme.onBackground,
                  value: progress < 0 ? null : progress / 100,
                ),
              ),
            ),
            SizedBox(
              width: 10.w,
            ),
            Text(
              progress < 0 ? '??%' : '${progress.floor()}%',
              style: TextStyle(
                fontSize: 15.sp,
              ),
            )
          ],
        ),
      );
    } else if (downloadStatus == DownloadStatus.converting) {
      return Text(
        'Converting...',
        style: TextStyle(fontFamily: "Lato", fontSize: 10.sp),
      );
    } else if (downloadStatus == DownloadStatus.done) {
      return Text(
        "Done",
        style: TextStyle(fontFamily: "Lato", fontSize: 10.sp),
      );
      // Else show nothing (i.e when the user hasn't clicked the download button)
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Refreshed');
    // The Text to be displayed under the Video Title
    String type = '';
    if (widget.ytobj.downloadType == DownloadType.Muxed) {
      type = 'Video + Audio';
    } else if (widget.ytobj.downloadType == DownloadType.VideoOnly) {
      type = 'Video';
    } else {
      type = 'Audio';
    }
    // UI
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 144.w,
              height: 80.h,
              child: Visibility(
                visible: MediaQuery.of(context).size.width > 350 ? true : false,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    widget.ytobj.thumbnail,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 10.w,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                        child: Text(
                      widget.ytobj.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                          fontSize: 11.sp),
                    )),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${widget.ytobj.author} · $type",
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w200,
                              fontSize: 9.sp)),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildStatus() ?? Container(),
                        Padding(
                          padding: EdgeInsets.all(2.r),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SlideTransition(
                                position: _slide,
                                child: ClipOval(
                                  child: Material(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                    child: InkWell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.r),
                                        child: Icon(
                                          isDownloading
                                              ? Icons.cancel
                                              : Icons.download,
                                          size: 16.w,
                                        ),
                                      ),
                                      onTap: () {
                                        if (!isDownloading) {
                                          setState(() {
                                            isDownloading = true;
                                            downloadStatus =
                                                DownloadStatus.downloading;
                                            _controller.forward();
                                          });
                                          download();
                                        } else {
                                          setState(() {
                                            isDownloading = false;
                                          });
                                          rc!.close();
                                          DownloadManager.stop(
                                              downloadStatus,
                                              widget.ytobj,
                                              downloads!,
                                              temps!,
                                              stopPort,
                                              conversionSession);
                                          setState(() {
                                            downloadStatus =
                                                DownloadStatus.waiting;
                                          });
                                          _controller.reverse();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Visibility(
                                maintainAnimation: true,
                                maintainState: true,
                                maintainSize: true,
                                visible: !isDownloading,
                                child: ClipOval(
                                  child: Material(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                    child: InkWell(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.r),
                                          child: Icon(
                                            Icons.delete_rounded,
                                            size: 16.w,
                                          ),
                                        ),
                                        onTap: () => widget.rmov(widget.index)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
