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
  // Audio Quality isn't important for me, So just get the best one
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
}
