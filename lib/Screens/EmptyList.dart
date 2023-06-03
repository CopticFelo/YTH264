import 'package:flutter/material.dart';

class EmptyList extends StatelessWidget {
  const EmptyList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(image: AssetImage('assets/Sad_Magnifying_Glass.png')),
          SizedBox(
            height: 12,
          ),
          Text(
            'No Videos to download',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'Lato'),
          ),
          SizedBox(
            height: 6,
          ),
          Text(
            'Tap on + to add Videos to download',
            style: TextStyle(color: Colors.black, fontSize: 17),
          ),
        ],
      ),
    );
  }
}
