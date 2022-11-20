import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum DownloadType { Muxed, VideoOnly, AudioOnly }

abstract class QueueObject {
  final String title;
  final String author;

  QueueObject({
    required this.title,
    required this.author,
  });
}

class YoutubeQueueObject extends QueueObject {
  final Map<String, VideoOnlyStreamInfo> videoOnlyStreams;
  final AudioOnlyStreamInfo bestAudio;
  final String thumbnail;

  VideoOnlyStreamInfo? stream;

  DownloadType downloadType = DownloadType.Muxed;
  set type(DownloadType type) {
    downloadType = type;
  }

  set selectedStream(VideoOnlyStreamInfo stream) {
    this.stream = stream;
  }

  YoutubeQueueObject(
      {required super.title,
      required super.author,
      required this.videoOnlyStreams,
      required this.bestAudio,
      required this.thumbnail});
}
