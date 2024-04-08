// NOTE: THIS IS ONE OF THE MOST POORLY WRITTEN CODE I HAVE EVER WROTE
// TODO: CLEAN QUEUEWIDGET.DART
import 'package:YT_H264/Models/QueueModel.dart';
import 'package:YT_H264/Models/QueueWidgetModel.dart';
import 'package:YT_H264/Services/QueueObject.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:YT_H264/Services/DownloadManager.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

class QueueWidget extends StatefulWidget {
  QueueWidget({super.key});

  @override
  State<QueueWidget> createState() => QueueWidgetState();
}

class QueueWidgetState extends State<QueueWidget>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Dismissible(
        onDismissed: (direction) =>
            Provider.of<QueueModel>(context, listen: false).delete(
                Provider.of<QueueWidgetModel>(context, listen: false).index,
                true),
        key: ValueKey(
            Provider.of<QueueWidgetModel>(context, listen: false).index),
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 151.w,
                    height: 84.h,
                    child: Visibility(
                      visible: MediaQuery.of(context).size.width > 350
                          ? true
                          : false,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          color: Colors.black,
                          child: Padding(
                            padding: const EdgeInsets.all(1.0),
                            child: Image.network(
                                Provider.of<QueueWidgetModel>(context,
                                        listen: false)
                                    .ytObj
                                    .thumbnail,
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.fill,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return Container(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      child: Center(
                                        child: Text(
                                          ". .-. .-. --- .-.",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                      ),
                                    )),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 8.w,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                              child: Text(
                            Provider.of<QueueWidgetModel>(context,
                                    listen: false)
                                .ytObj
                                .title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          )),
                        ),
                        Divider(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Consumer<QueueWidgetModel>(
                                builder: (context, value, child) {
                              if (value.downloadStatus == DownloadStatus.done) {
                                return FilledButton.icon(
                                  onPressed: () => value.ytObj.downloadType ==
                                          DownloadType.AudioOnly
                                      ? value.openAudio()
                                      : value.openVideo(),
                                  icon: Icon(Icons.play_arrow),
                                  label: Text("Play"),
                                );
                              }
                              return OutlinedButton.icon(
                                label: value.buildStatus() ??
                                    Text(
                                      "Download",
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                icon: Icon(value.isDownloading
                                    ? Icons.stop
                                    : Icons.download),
                                style: ButtonStyle(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    minimumSize:
                                        MaterialStateProperty.all(Size.zero),
                                    side: MaterialStateProperty.all(BorderSide(
                                        color: value.isDownloading
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    padding:
                                        MaterialStateProperty.all<EdgeInsets>(
                                            EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 10))),
                                onPressed: () {
                                  if (!value.isDownloading) {
                                    value.download();
                                  } else {
                                    setState(() {
                                      value.isDownloading = false;
                                    });
                                    value.rc!.close();
                                    DownloadManager.stop(
                                        value.downloadStatus,
                                        value.ytObj,
                                        value.downloads!,
                                        value.temps!,
                                        value.stopPort,
                                        value.conversionSession);
                                    setState(() {
                                      value.downloadStatus =
                                          DownloadStatus.waiting;
                                    });
                                  }
                                },
                              );
                            }),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
