import 'package:YT_H264/Services/QueueObject.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  final _serv = YoutubeExplode();
  Future<YoutubeQueueObject> getVidInfo(String uri) async {
    var video = await _serv.videos.get(uri);
    var vidStream = await _serv.videos.streamsClient.getManifest(video.id);
    Map<String, VideoOnlyStreamInfo> vids = {};
    for (var stream in vidStream.videoOnly) {
      if ((!vids.keys.contains(stream.qualityLabel)) ||
          (vids[stream.qualityLabel]!.container != StreamContainer.mp4)) {
        vids[stream.qualityLabel] = stream;
      }
    }
    var bestAudio = vidStream.audioOnly.withHighestBitrate();
    print(vidStream.videoOnly);
    _serv.close();
    return YoutubeQueueObject(
        title: video.title,
        author: video.author,
        videoOnlyStreams: vids,
        bestAudio: bestAudio,
        thumbnail: 'https://img.youtube.com/vi/${video.id}/0.jpg');
  }
}
