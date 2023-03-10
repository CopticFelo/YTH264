import 'package:YT_H264/Services/QueueObject.dart';
import 'package:remove_emoji/remove_emoji.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

class YoutubeService {
  final _serv = YoutubeExplode();
  Future<YoutubeQueueObject> getVidInfo(String uri) async {
    // if original string contains with music. remove it
    if (uri.contains('music.')) {
      uri = uri.replaceFirst('music.', '');
    }
    // String -> URI Obj
    Uri original = Uri.parse(uri);
    // Disect URI into Hostname and Path
    var cleanUri =
        Uri.https(original.host, original.path, original.queryParameters);
    // Get Video ID and Info
    var video = await _serv.videos.get(cleanUri);
    // Get All Available Streams
    var vidStream = await _serv.videos.streamsClient.getManifest(video.id);
    // Get Video Streams that are mp4
    Map<String, VideoOnlyStreamInfo> vids = {};
    for (var stream in vidStream.videoOnly) {
      if ((!vids.keys.contains(stream.qualityLabel)) ||
          (vids[stream.qualityLabel]!.container != StreamContainer.mp4)) {
        vids[stream.qualityLabel] = stream;
      }
    }
    // Just get the highest quality one (Audio Quality doesn't really matter)
    var bestAudio = vidStream.audioOnly.withHighestBitrate();
    _serv.close();

    // get max res thumbnail
    String imgUri = "https://img.youtube.com/vi/${video.id}/maxresdefault.jpg";
    // check if it even exist (Some videos don't have it)
    bool isImage = await validateImage(imgUri);
    // if not or it is a YT Short just use 0.jpg
    if (uri.contains("shorts") || !isImage) {
      imgUri = "https://img.youtube.com/vi/${video.id}/0.jpg";
    }
    // Make a title that doesn't have un-allowed (& Emojis) characters for filenames
    String validName = video.title
        .replaceAll(r'\', '')
        .replaceAll('/', '')
        .replaceAll('*', '')
        .replaceAll('?', '')
        .replaceAll('"', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '')
        .replaceAll(':', '')
        .replaceAll("'", '')
        .replaceAll('"', '');
    validName = RemoveEmoji().removemoji(validName);
    // Return a queue obj with all the extracted info
    return YoutubeQueueObject(
        title: video.title,
        validTitle: validName,
        author: video.author,
        videoOnlyStreams: vids,
        bestAudio: bestAudio,
        thumbnail: imgUri);
  }

  // Validates if there an image at this Url or not
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

  // Validates if content-type = image
  bool checkIfImage(String param) {
    if (param == 'image/jpeg' || param == 'image/png') {
      return true;
    }
    return false;
  }
}
