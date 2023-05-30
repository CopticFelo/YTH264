import 'dart:convert';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Enum describing the type of the Requested download
enum DownloadType { Muxed, VideoOnly, AudioOnly }

// Abstract Class for Objects in the Download Queue
// The app can only download Videos from youtube for now (It may stay that way)
abstract class QueueObject {
  final String title;
  final String validTitle;
  final String author;

  QueueObject({
    required this.title,
    required this.validTitle,
    required this.author,
  });
}

// Class for Queue Objects Coming from Youtube
class YoutubeQueueObject extends QueueObject {
  // A map of VideoOnly Download Streams
  final Map<String, VideoOnlyStreamInfo> videoOnlyStreams;
  // AudioOnlyStreamInfo Object containing the best Audio Stream
  // Audio Quality isn't important imo, So just get the best one
  final AudioOnlyStreamInfo bestAudio;
  // Video Thumbnail URL
  final String thumbnail;
  // The Selected Stream (Not important if the download type is Muxed or Audio only)
  VideoOnlyStreamInfo? stream;
  // The download type and its Setter
  DownloadType downloadType = DownloadType.Muxed;
  set type(DownloadType type) {
    downloadType = type;
  }

  // The Selected Stream Setter
  set selectedStream(VideoOnlyStreamInfo stream) {
    this.stream = stream;
  }

  // Constructor
  YoutubeQueueObject(
      {required super.title,
      required super.validTitle,
      required super.author,
      required this.videoOnlyStreams,
      required this.bestAudio,
      required this.thumbnail});

  YoutubeQueueObject.complete({
    required super.title,
    required super.validTitle,
    required super.author,
    required this.videoOnlyStreams,
    required this.bestAudio,
    required this.thumbnail,
    required this.downloadType,
    this.stream,
  });

  factory YoutubeQueueObject.fromJson(Map<String, dynamic> jsonData) {
    Map<String, VideoOnlyStreamInfo> vd =
        (jsonData['videoOnlyStreams'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, VideoOnlyStreamInfo.fromJson(value)));
    return YoutubeQueueObject.complete(
        title: jsonData['title'],
        validTitle: jsonData['validTitle'],
        author: jsonData['author'],
        videoOnlyStreams: vd,
        bestAudio: AudioOnlyStreamInfo.fromJson(jsonData['bestAudio']),
        thumbnail: jsonData['thumbnail'],
        downloadType: DownloadType.values[jsonData['downloadType']],
        stream: jsonData['stream'] != null
            ? VideoOnlyStreamInfo.fromJson(jsonData['stream'])
            : null);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> mp = {
      'title': super.title,
      'validTitle': super.validTitle,
      'author': super.author,
      'stream': this.stream,
      'thumbnail': this.thumbnail,
      "videoOnlyStreams": this.videoOnlyStreams,
      'bestAudio': this.bestAudio,
      'downloadType': this.downloadType.index
    };
    // print(jsonEncode(mp));
    return mp;
  }

  static String encode(List<YoutubeQueueObject> ytObjs) => jsonEncode(
        ytObjs.map<Map<String, dynamic>>((obj) => obj.toMap()).toList(),
      );
  static List<YoutubeQueueObject> decode(String ytObjs) =>
      (jsonDecode(ytObjs) as List<dynamic>)
          .map<YoutubeQueueObject>((item) => YoutubeQueueObject.fromJson(item))
          .toList();
}
