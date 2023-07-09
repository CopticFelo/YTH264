import 'dart:io';
import 'dart:isolate';
import 'package:YT_H264/Services/GlobalMethods.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../Widgets/QueueWidget.dart';
import 'QueueObject.dart';

class DownloadManager {
  @pragma('vm:entry-point')
  static void donwloadVideoFromYoutube(Map<String, dynamic> args) async {
    final SendPort sd = args['port'];

    ReceivePort rc = ReceivePort();
    sd.send([rc.sendPort]);

    rc.listen(((message) {
      Isolate.exit();
    }));

    final yt = YoutubeExplode();

    double progress = 0;

    String title = args['ytObj'].validTitle as String;

    if (args['ytObj'].downloadType == DownloadType.VideoOnly ||
        args['ytObj'].downloadType == DownloadType.Muxed) {
      try {
        var stream = yt.videos.streamsClient.get(args['ytObj'].stream);
        final size = args['ytObj'].stream.size.totalBytes;

        var count = 0;
        String? fileDir;
        Directory? directory;

        if (args['ytObj'].downloadType == DownloadType.VideoOnly) {
          directory = args['downloads'];
          fileDir =
              '${directory!.path}/${title}.${args['ytObj'].stream.container.name}';
        } else {
          directory = args['temp'];
          fileDir =
              '${directory!.path}/${title}-V.${args['ytObj'].stream.container.name}';
        }
        print('Video: $fileDir');

        File vidFile = await File(fileDir).create(recursive: true);

        var fileStream = vidFile.openWrite(mode: FileMode.writeOnlyAppend);

        await for (var bytes in stream) {
          fileStream.add(bytes);

          count += bytes.length;
          var currentProgress =
              ((count / size) * 100).isInfinite || ((count / size) * 100).isNaN
                  ? -1.0
                  : ((count / size) * 100);

          if (currentProgress >= 0) {
            progress = currentProgress;
            if (args['ytObj'].downloadType == DownloadType.Muxed) {
              currentProgress = progress / 2;
            }
          }

          print(currentProgress);
          sd.send([DownloadStatus.downloading, currentProgress]);
        }
      } catch (e) {
        sd.send([e.toString()]);
      }
    }

    if (args['ytObj'].downloadType == DownloadType.AudioOnly ||
        args['ytObj'].downloadType == DownloadType.Muxed) {
      try {
        final audioStream =
            yt.videos.streamsClient.get(args['ytObj'].bestAudio);
        final size = args['ytObj'].bestAudio.size.totalBytes;

        var count = 0;
        String? fileDir;
        Directory? directory;

        directory = args['temp'];

        fileDir =
            '${directory!.path}/${title}-A.${args['ytObj'].bestAudio.container.name}';

        File audFile = await File(fileDir).create(recursive: true);

        var fileStream =
            await audFile.openWrite(mode: FileMode.writeOnlyAppend);

        await for (var bytes in audioStream) {
          fileStream.add(bytes);

          count += bytes.length;
          double currentProgress =
              ((count / size) * 100).isInfinite || ((count / size) * 100).isNaN
                  ? -1.0
                  : ((count / size) * 100);

          if (currentProgress >= 0) {
            progress = 100 + currentProgress;
            if (args['ytObj'].downloadType == DownloadType.Muxed) {
              currentProgress = progress / 2;
            }
          }

          print(currentProgress);
          sd.send([DownloadStatus.downloading, currentProgress]);
        }
      } catch (e) {
        sd.send([e.toString()]);
      }
    }

    yt.close();

    if (args['ytObj'].downloadType == DownloadType.VideoOnly) {
      sd.send([DownloadStatus.done, 100.0]);
    } else {
      sd.send([DownloadStatus.converting, 100.0]);
    }
    Isolate.exit();
  }

  static Future<FFmpegSession> convertToMp3(
      Directory? downloads,
      YoutubeQueueObject ytobj,
      Function callBack,
      Directory temp,
      BuildContext context) async {
    String imgPath = '${temp.path}/${ytobj.validTitle}.jpg';

    File? imgfile = await getImageAsFile(ytobj.thumbnail, imgPath);

    String audioDir =
        "${temp.path}/${ytobj.validTitle}-A.${ytobj.bestAudio.container.name}";

    String author = ytobj.author;

    String title = ytobj.title;

    String out = '${downloads!.path}/${ytobj.validTitle}.mp3';

    List<String> args = [];

    if (imgfile != null) {
      args = [
        "-y",
        '-i',
        '$audioDir',
        '-i',
        '$imgPath',
        '-map',
        '0',
        '-map',
        '1',
        '-metadata',
        'artist=$author',
        '-metadata',
        'title=$title',
        '$out'
      ];
    } else {
      args = ['-y', '-i', '$audioDir', '$out'];
    }

    print(args);
    return await FFmpegKit.executeWithArgumentsAsync(args, (session) async {
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode) &&
          !ReturnCode.isCancel(returnCode)) {
        GlobalMethods.snackBarError(session.getOutput().toString(), context);
        clean(ytobj, downloads, temp, true);
      }

      clean(ytobj, downloads, temp, false);

      callBack();

      return;
    }, ((log) {
      print(log.getMessage());
    }));
  }

  static Future<FFmpegSession> mergeIntoMp4(
      Directory? temps,
      Directory? downloads,
      YoutubeQueueObject ytobj,
      Function callBack,
      BuildContext context) async {
    String audioDir =
        "${temps!.path}/${ytobj.validTitle}-A.${ytobj.bestAudio.container.name}";

    String videoDir = "${temps.path}/${ytobj.validTitle}-V.mp4";

    String outDir = "${downloads!.path}/${ytobj.validTitle}.mp4";

    print("${temps.path}");

    List<String> args = [
      '-y',
      '-i',
      '$videoDir',
      '-i',
      '$audioDir',
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '$outDir'
    ];

    return await FFmpegKit.executeWithArgumentsAsync(args, (session) async {
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode) &&
          !ReturnCode.isCancel(returnCode)) {
        String? msg = await session.getOutput();
        GlobalMethods.snackBarError(msg!, context);
        clean(ytobj, downloads, temps, true);
      }

      print(session.getOutput());
      // File oldAudio = File(audioDir);
      // await oldAudio.delete();
      // File oldVideo = File(videoDir);
      // await oldVideo.delete();
      clean(ytobj, downloads, temps, false);
      callBack();
    }, ((log) {
      print(log.getMessage());
    }));
  }

  static Future<File?> getImageAsFile(String uri, String path) async {
    final file = File(path);
    try {
      final response = await http.get(Uri.parse(uri));

      file.writeAsBytesSync(response.bodyBytes);

      return file;
    } catch (e) {
      return null;
    }
  }

  static void stop(
      DownloadStatus ds,
      YoutubeQueueObject queueObject,
      Directory downloads,
      Directory temps,
      SendPort? stopper,
      FFmpegSession? fs) async {
    if (ds == DownloadStatus.downloading) {
      stopper!.send(null);
    } else {
      FFmpegKit.cancel(fs!.getSessionId());
    }
    clean(queueObject, downloads, temps, true);
  }

  static void clean(YoutubeQueueObject queueObject, Directory downloads,
      Directory temps, bool cleanOutFile) async {
    if (queueObject.downloadType == DownloadType.AudioOnly) {
      String path =
          '${downloads.path}/${queueObject.validTitle}-A.${queueObject.bestAudio.container.name}';
      File file = File(path);

      String imgPath = '${temps.path}/${queueObject.validTitle}.jpg';
      File imgFile = File(imgPath);

      String outpath = '${downloads.path}/${queueObject.validTitle}.mp3';
      File outfile = File(outpath);

      try {
        await file.delete();
        await imgFile.delete();
        if (cleanOutFile) {
          await outfile.delete();
        }
      } catch (e) {}
    } else if (queueObject.downloadType == DownloadType.VideoOnly &&
        cleanOutFile) {
      String path = '${downloads.path}/${queueObject.validTitle}.mp4';
      File file = File(path);

      try {
        await file.delete();
      } catch (e) {}
    } else {
      String pathToVid = '${temps.path}/${queueObject.validTitle}-V.mp4';
      File vidfile = File(pathToVid);

      String pathToAud =
          '${temps.path}/${queueObject.validTitle}-A.${queueObject.bestAudio.container.name}';
      File audfile = File(pathToAud);

      String pathToOut = '${downloads.path}/${queueObject.validTitle}.mp4';
      File outfile = File(pathToOut);

      try {
        await vidfile.delete();
        await audfile.delete();
        if (cleanOutFile) {
          await outfile.delete();
        }
      } catch (e) {}
    }
  }
}
