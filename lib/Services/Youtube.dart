import 'package:YT_H264/Services/QueueObject.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  final _serv = YoutubeExplode();
  Future<YoutubeQueueObject> getVidInfo(String uri) async {
    Uri original = Uri.parse(uri);
    var cleanUri = Uri.https(original.host, original.path);
    var video = await _serv.videos.get(cleanUri);
    var vidStream = await _serv.videos.streamsClient.getManifest(video.id);
    Map<String, VideoOnlyStreamInfo> vids = {};
    for (var stream in vidStream.videoOnly) {
      if ((!vids.keys.contains(stream.qualityLabel)) ||
          (vids[stream.qualityLabel]!.container != StreamContainer.mp4)) {
        vids[stream.qualityLabel] = stream;
      }
    }
    var bestAudio = vidStream.audioOnly.withHighestBitrate();
    _serv.close();

    // get max res thumbnail
    String imgUri = "https://img.youtube.com/vi/${video.id}/maxresdefault.jpg";
    if (uri.contains("shorts")) {
      imgUri = "https://img.youtube.com/vi/${video.id}/0.jpg";
    }

    return YoutubeQueueObject(
        title: video.title,
        author: video.author,
        videoOnlyStreams: vids,
        bestAudio: bestAudio,
        thumbnail: imgUri);
  }
}
