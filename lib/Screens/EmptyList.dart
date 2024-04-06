import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EmptyList extends StatelessWidget {
  const EmptyList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/Sad_Magnifying_Glass.svg',
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface.withAlpha(100),
                BlendMode.srcIn),
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            'No Videos to download',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            'Tap on + to add Videos to download',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
