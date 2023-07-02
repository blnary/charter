import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charter/model/song.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({Key? key}) : super(key: key);

  @override
  State createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color oddItemColor = colorScheme.primary.withOpacity(0.05);
    final Color selectedColor = colorScheme.primary.withOpacity(0.50);
    final Color evenItemColor = colorScheme.primary.withOpacity(0.15);

    final songsProvider = Provider.of<SongsProvider>(context);
    if (songsProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (songsProvider.failed) {
      return Center(child: Text(songsProvider.failureMessage));
    } else {
      return Row(children: [
        Expanded(child: Container(color: Colors.transparent)),
        Expanded(
          child: ListView.builder(
            itemCount: songsProvider.songs.length,
            itemBuilder: (context, index) {
              final song = songsProvider.songs[index];
              final isSelected = index == songsProvider.selected;

              return ListTile(
                onTap: () {
                  songsProvider.select(index);
                },
                tileColor: isSelected
                    ? selectedColor
                    : index.isOdd
                        ? oddItemColor
                        : evenItemColor,
                title: Text(song.name),
                trailing: isSelected ? const Icon(Icons.check) : null,
              );
            },
          ),
        ),
      ]);
    }
  }
}
