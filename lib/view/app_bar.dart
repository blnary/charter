import 'package:charter/view/chart_page.dart';
import 'package:charter/view/charter_page.dart';
import 'package:charter/view/song_page.dart';
import 'package:flutter/material.dart';
import 'package:charter/view/audio_calibrate.dart';
import 'package:charter/view/input_calibrate.dart';

/// Flutter code sample for [AppBar].

List<String> titles = <String>[
  '输入校正',
  '音频校正',
  '歌曲选择',
  '谱面选择',
  '谱面编辑',
];

class AppBarExample extends StatelessWidget {
  const AppBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    const int tabsCount = 5;

    return DefaultTabController(
      initialIndex: 0,
      length: tabsCount,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('bInary 制谱器'),
          // This check specifies which nested Scrollable's scroll notification
          // should be listened to.
          //
          // When `ThemeData.useMaterial3` is true and scroll view has
          // scrolled underneath the app bar, this updates the app bar
          // background color and elevation.
          //
          // This sets `notification.depth == 1` to listen to the scroll
          // notification from the nested `ListView.builder`.
          notificationPredicate: (ScrollNotification notification) {
            return notification.depth == 1;
          },
          // The elevation value of the app bar when scroll view has
          // scrolled underneath the app bar.
          scrolledUnderElevation: 4.0,
          shadowColor: Theme.of(context).shadowColor,
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                icon: const Icon(Icons.input_sharp),
                text: titles[0],
              ),
              Tab(
                icon: const Icon(Icons.audio_file_sharp),
                text: titles[1],
              ),
              Tab(
                icon: const Icon(Icons.select_all_sharp),
                text: titles[2],
              ),
              Tab(
                icon: const Icon(Icons.autofps_select_sharp),
                text: titles[3],
              ),
              Tab(
                icon: const Icon(Icons.bar_chart_sharp),
                text: titles[4],
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            InputPage(),
            AudioPage(),
            SongsPage(),
            ChartsPage(),
            CharterPage(),
          ],
        ),
      ),
    );
  }
}
