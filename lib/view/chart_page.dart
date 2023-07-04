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
    final songsProvider = Provider.of<SongsProvider>(context);
    if (chartsProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (chartsProvider.failed) {
      return Center(child: Text(chartsProvider.failureMessage));
    } else {
      final level = chartsProvider.level;
      final texts = level == null
          ? <Widget>[]
          : [
              Text(
                "BPM: ${level.bpm}",
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                "偏移: ${level.offsetSamp ~/ 44.1} ms",
                style: const TextStyle(fontSize: 20),
              ),
            ];
      return Row(children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: texts,
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
