import 'package:charter/model/level.dart';
import 'package:charter/model/song.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charter/model/chart.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({Key? key}) : super(key: key);

  @override
  State createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color oddItemColor = colorScheme.primary.withOpacity(0.05);
    final Color selectedColor = colorScheme.primary.withOpacity(0.50);
    final Color evenItemColor = colorScheme.primary.withOpacity(0.15);

    final chartsProvider = Provider.of<ChartsProvider>(context);
    final levelProvider = Provider.of<LevelProvider>(context);
    final songsProvider = Provider.of<SongsProvider>(context);
    if (chartsProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (chartsProvider.failed) {
      return Center(child: Text(chartsProvider.failureMessage));
    } else {
      final bpm = chartsProvider.level.bpm;
      final offset = chartsProvider.level.offset;
      final offsetMs = offset ~/ 44.1;
      return Row(children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "BPM: $bpm",
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  "偏移: $offsetMs ms",
                  style: const TextStyle(fontSize: 20),
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Does nothing
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("成功选定谱面！"),
                                duration: Duration(seconds: 1)));
                      },
                      child: const Tab(
                          icon: Icon(Icons.hdr_on_select_sharp), text: "选定"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: chartsProvider.charts.length,
            itemBuilder: (context, index) {
              final chart = chartsProvider.charts[index];
              final isSelected = index == chartsProvider.selected;

              return ListTile(
                onTap: () {
                  chartsProvider.select(index);
                  songsProvider.selectFromID(chart.songId);
                  levelProvider.setLevel(
                      chartsProvider.level, chartsProvider.id);
                },
                tileColor: isSelected
                    ? selectedColor
                    : index.isOdd
                        ? oddItemColor
                        : evenItemColor,
                title: Text('${chart.level.name} (${chart.level.difficulty}*)'),
                trailing: isSelected ? const Icon(Icons.check) : null,
              );
            },
          ),
        ),
      ]);
    }
  }
}
