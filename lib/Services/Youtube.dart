import 'package:YT_H264/Services/QueueObject.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

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
    bool isImage = await validateImage(imgUri);
    if (uri.contains("shorts") || !isImage) {
      imgUri = "https://img.youtube.com/vi/${video.id}/0.jpg";
    }

    return YoutubeQueueObject(
        title: video.title,
        author: video.author,
        videoOnlyStreams: vids,
        bestAudio: bestAudio,
        thumbnail: imgUri);
  }

  Future<bool> validateImage(String imageUrl) async {
    http.Response res;
    try {
      res = await http.get(Uri.parse(imageUrl));
    } catch (e) {
      return false;
    }

    if (res.statusCode != 200) return false;
    Map<String, dynamic> data = res.headers;
    return checkIfImage(data['content-type']);
  }

  bool checkIfImage(String param) {
    if (param == 'image/jpeg' || param == 'image/png') {
      return true;
    }
    return false;
  }
}
