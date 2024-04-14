import 'dart:isolate';
import 'dart:io';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:flutter/material.dart';
import 'package:YT_H264/Services/DownloadManager.dart';
import 'package:YT_H264/Services/GlobalMethods.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_session.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum DownloadStatus { waiting, downloading, converting, done }

class QueueWidgetModel with ChangeNotifier {
  DownloadStatus downloadStatus = DownloadStatus.waiting;
  double progress = 0;
  ReceivePort? rc;
  SendPort? stopPort;
  bool isDownloading = false;
  Directory? downloads;
  Directory? temps;
  FFmpegSession? conversionSession;
  final BuildContext context;
  final YoutubeQueueObject ytObj;

  QueueWidgetModel({required this.context, required this.ytObj});

  void openAudio() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin info = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await info.androidInfo;
      if (androidInfo.version.sdkInt >= 29) {
        if (await Permission.audio.request().isDenied) {
          GlobalMethods.snackBarError('Missing permissions', context);
          return;
        }
      }
    }

    String path = '${downloads!.path}/${ytObj.validTitle}.mp3';
    var result = await OpenFile.open(path);
  }

  void openVideo() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin info = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await info.androidInfo;
      if (androidInfo.version.sdkInt >= 29) {
        if (await Permission.videos.request().isDenied) {
          GlobalMethods.snackBarError('Missing permissions', context);
          return;
        }
      }
    }

    String path = '${downloads!.path}/${ytObj.validTitle}.mp4';
    var result = await OpenFile.open(path);
  }

  void complete(FFmpegSession session) async {
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode) && !ReturnCode.isCancel(returnCode)) {
      String? msg = await session.getOutput();
      GlobalMethods.snackBarError(msg!, context);
      DownloadManager.clean(ytObj, downloads!, temps!, false);
      downloadStatus = DownloadStatus.waiting;
      isDownloading = false;
      notifyListeners();
      return;
    }

    print(session.getOutput());
    DownloadManager.clean(ytObj, downloads!, temps!, false);
    downloadStatus = DownloadStatus.done;
    isDownloading = false;
    notifyListeners();
  }

  // Builds the status UI
  Widget? buildStatus() {
    print('Status: ${downloadStatus.toString()}');
    // In case of downloading just show a Progress bar
    if (downloadStatus == DownloadStatus.downloading) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(context).colorScheme.onSurface,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary),
                color: Theme.of(context).colorScheme.onSurface,
                value: progress < 0 ? null : progress / 100,
              ),
            ),
          ),
          SizedBox(
            width: 5.w,
          ),
          Text(
            progress < 0 ? '??%' : '${progress.floor()}%',
            style: Theme.of(context).textTheme.labelSmall,
          )
        ],
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

  void download() async {
    isDownloading = true;
    downloadStatus = DownloadStatus.downloading;
    notifyListeners();
    // Assigns the Receiveport fo the Isolate
    rc = ReceivePort();
    // This is just makes sure read/write is permitted on Android 12 and below
    // No need to on Android 13+ and IOS
    if (Platform.isAndroid) {
      DeviceInfoPlugin info = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await info.androidInfo;
      if (androidInfo.version.sdkInt < 33) {
        final storagePermissions = await Permission.storage.status;
        if (!storagePermissions.isGranted) {
          if (await Permission.storage.request().isDenied) {
            GlobalMethods.snackBarError(
                'App Needs Storage Permissions', context);
            isDownloading = false;
            notifyListeners();
            rc!.close();
            downloadStatus = DownloadStatus.waiting;
            notifyListeners();
            return;
          }
        }
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
      'ytObj': ytObj,
      'temp': temps,
      'downloads': downloads,
      // 'showError': errorCallback
    }).then((value) {
      // Returns the Isolate
      return value;
    });
    // Handling Messages between QueueWidget and downloader Isolate
    rc!.listen((data) async {
      print("listen function");
      // Unsafe way of handling messaging (I fixed it in another branch Gotta wait for it to be done)
      if (data.length > 1) {
        // It means that it is a Download Progress Report (Which may or may not be done)
        // data[0] is the Download State
        // data[1] is the Download Progress

        // Set the Progress and Status Accordingly
        this.downloadStatus = data[0];
        this.progress = data[1];
        // if Done (i.e not doing any converstion magic afterwards) Kill the Isolate, close rc and set the UI Up
        if (downloadStatus == DownloadStatus.done) {
          downlaoder.kill();
          isDownloading = false;
          rc!.close();
        }
        notifyListeners();
        // if DownloadStatus (recieved from data[0]) is converting and the media is audioonly
        if (ytObj.downloadType == DownloadType.AudioOnly &&
            downloadStatus == DownloadStatus.converting) {
          // Convert it from .webm (in temp folder) to .mp3 (to be in downloads folder)
          conversionSession = await DownloadManager.convertToMp3(
              downloads, ytObj, complete, temps!, context);
          // Note: that Youtube Explode Muxed Video (i.e doesn't need conversion) only supports upto 720p, thus it is not used
          // if DownloadStatus (recieved from data[0]) is converting and the media is Muxed (i.e Video + Audio)
        } else if (ytObj.downloadType == DownloadType.Muxed &&
            downloadStatus == DownloadStatus.converting) {
          // Combine .webm (in temp folder) + mp4 (audioless, in temp folder) into .mp4 (with audio, to be in downloads folder)
          conversionSession = await DownloadManager.mergeIntoMp4(
              temps, downloads, ytObj, complete, context);
        }
      } else {
        // Means this is either the Sendport that will be used to
        // Stop the Isolate (Download) from the Widget
        // Or an Error
        if (data[0] is SendPort) {
          stopPort = data[0];
        } else {
          // Displays a Snackbar
          this.downloadStatus = DownloadStatus.waiting;
          GlobalMethods.snackBarError(data[0], context, isException: true);
        }
      }
    });
  }
}
