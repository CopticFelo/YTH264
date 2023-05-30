import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

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
                fontFamily: 'Helvetica',
                fontWeight: FontWeight.bold,
                fontSize: 20),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'Click on + to add Videos to download',
            style: TextStyle(
                color: Colors.black, fontFamily: 'Helvetica', fontSize: 17),
          ),
        ],
      ),
    );
  }
}
