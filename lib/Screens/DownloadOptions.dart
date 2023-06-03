import 'package:flutter/material.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadOptions extends StatefulWidget {
  final YoutubeQueueObject? ytObj;

  DownloadOptions({super.key, required this.ytObj});

  @override
  State<DownloadOptions> createState() => _DownloadOptionsState();
}

class _DownloadOptionsState extends State<DownloadOptions>
    with TickerProviderStateMixin {
  int downloadType = 0;
  int videoQuality = 0;
  int audioQuality = 0;
  late TabController downloadTypeController;
  late TabController videoQualityController;
  late TabController audioQualityController;
  @override
  void initState() {
    super.initState();
    downloadTypeController = TabController(length: 3, vsync: this);
    videoQualityController = TabController(length: 3, vsync: this);
    audioQualityController = TabController(length: 3, vsync: this);
  }

  Widget getVideoQualties() {
    if ((downloadType == 0 || downloadType == 1) &&
        widget.ytObj!.videoOnlyStreams.length >= 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20,
          ),
          const Text('Video Quality',
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  fontSize: 27)),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 48, 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.onBackground,
              ),
              child: TabBar(
                  controller: videoQualityController,
                  onTap: (value) {
                    setState(() {
                      VideoOnlyStreamInfo info;
                      if (value == 0) {
                        info = widget.ytObj!.videoOnlyStreams.values.first;
                      } else if (value == 1) {
                        info = widget.ytObj!.videoOnlyStreams.length < 6
                            ? widget.ytObj!.videoOnlyStreams.values.elementAt(1)
                            : widget.ytObj!.videoOnlyStreams.values
                                .elementAt(2);
                      } else {
                        info = widget.ytObj!.videoOnlyStreams.length < 6
                            ? widget.ytObj!.videoOnlyStreams.values.elementAt(2)
                            : widget.ytObj!.videoOnlyStreams.values
                                .elementAt(4);
                      }
                      widget.ytObj!.selectedStream = info;
                    });
                    print(videoQuality);
                  },
                  unselectedLabelColor: Colors.black,
                  labelColor: Colors.white,
                  indicator: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      shape: BoxShape.rectangle),
                  tabs: [
                    SizedBox(
                      width: 83,
                      height: 32,
                      child: Center(
                          child:
                              Text(widget.ytObj!.videoOnlyStreams.keys.first)),
                    ),
                    SizedBox(
                      width: 83,
                      height: 32,
                      child: Center(
                          child: Text(widget.ytObj!.videoOnlyStreams.length < 6
                              ? widget.ytObj!.videoOnlyStreams.keys.elementAt(1)
                              : widget.ytObj!.videoOnlyStreams.keys
                                  .elementAt(2))),
                    ),
                    SizedBox(
                      width: 83,
                      height: 32,
                      child: Center(
                          child: Text(widget.ytObj!.videoOnlyStreams.length < 6
                              ? widget.ytObj!.videoOnlyStreams.keys.elementAt(2)
                              : widget.ytObj!.videoOnlyStreams.keys
                                  .elementAt(4))),
                    ),
                  ]),
            ),
          )
        ],
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ytObj != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 150,
                      height: 84,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          widget.ytObj!.thumbnail,
                          fit: BoxFit.fill,
                        ),
                      )),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.ytObj!.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(widget.ytObj!.author)
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Download Type',
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: 27)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 14, 48, 8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          child: TabBar(
                              controller: downloadTypeController,
                              onTap: (value) {
                                setState(() {
                                  downloadType = value;
                                  widget.ytObj!.type =
                                      DownloadType.values[downloadType];
                                });
                                print(downloadType);
                              },
                              unselectedLabelColor: Colors.black,
                              labelColor: Colors.white,
                              indicator: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                  shape: BoxShape.rectangle),
                              tabs: const [
                                SizedBox(
                                  width: 83,
                                  height: 32,
                                  child: Center(child: Text('Both')),
                                ),
                                SizedBox(
                                  width: 83,
                                  height: 32,
                                  child: Center(child: Text('Video')),
                                ),
                                SizedBox(
                                  width: 83,
                                  height: 32,
                                  child: Center(child: Text('Audio')),
                                ),
                              ]),
                        ),
                      ),
                      getVideoQualties(),
                      const SizedBox(height: 80),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop<QueueObject>(widget.ytObj);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 10),
                          child: Container(
                            width: double.infinity,
                            height: 43,
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Center(
                              child: Text('Add to Queue',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)),
                            ),
                          ),
                        ),
                      )
                    ]),
              ),
            ]),
      );
    } else {
      return Container();
    }
  }
}
