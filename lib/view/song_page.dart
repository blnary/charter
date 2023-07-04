import 'package:charter/model/chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:charter/model/song.dart';
import 'package:charter/util/file_upload.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({Key? key}) : super(key: key);

  @override
  State createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  double _bpmForm = 0;
  int _offsetForm = 0;
  late TextEditingController _bpmController;
  late TextEditingController _offsetController;

  Future<String> _selectFile() async {
    try {
      var result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['mp3', 'wav', 'ogg']);
      var bytes = result!.files.first.bytes!;
      var filename = result.files.first.name;
      var msg = await uploadBytes(bytes, filename);
      return msg;
    } catch (error) {
      return error.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color oddItemColor = colorScheme.primary.withOpacity(0.05);
    final Color selectedColor = colorScheme.primary.withOpacity(0.50);
    final Color evenItemColor = colorScheme.primary.withOpacity(0.15);

    final chartsProvider = Provider.of<ChartsProvider>(context);
    final songsProvider = Provider.of<SongsProvider>(context);
    if (songsProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (songsProvider.failed) {
      return Center(child: Text(songsProvider.failureMessage));
    } else {
      final offset = songsProvider.offset;
      final bpm = songsProvider.bpm;

      Future<void> showSettingDialog() async {
        _bpmController = TextEditingController(
          text: bpm.toString(),
        );
        _offsetController = TextEditingController(
          text: offset.toString(),
        );
        return showDialog<void>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('修改歌曲信息'),
              content: IntrinsicHeight(
                child: Column(
                  children: [
                    TextField(
                      controller: _bpmController,
                      decoration: const InputDecoration(labelText: 'BPM'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _bpmForm = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    TextField(
                      controller: _offsetController,
                      decoration: const InputDecoration(labelText: '偏移'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _offsetForm = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('确认'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    String msg = await songsProvider.set(_bpmForm, _offsetForm);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(msg),
                          duration: const Duration(seconds: 1)));
                    }
                  },
                ),
              ],
            );
          },
        );
      }

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
                  "偏移: $offset ms",
                  style: const TextStyle(fontSize: 20),
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        String msg = await songsProvider.sync();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(msg),
                              duration: const Duration(seconds: 1)));
                        }
                      },
                      child:
                          const Tab(icon: Icon(Icons.sync_sharp), text: "同步"),
                    ),
                    TextButton(
                      onPressed: showSettingDialog,
                      child: const Tab(
                          icon: Icon(Icons.settings_sharp), text: "修改"),
                    ),
                    TextButton(
                      onPressed: () async {
                        String msg = await songsProvider.cal();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(msg),
                              duration: const Duration(seconds: 1)));
                        }
                      },
                      child: const Tab(
                          icon: Icon(Icons.science_sharp), text: "计算"),
                    ),
                    TextButton(
                      onPressed: () async {
                        String msg = await _selectFile();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(msg),
                              duration: const Duration(seconds: 1)));
                        }
                      },
                      child:
                          const Tab(icon: Icon(Icons.upload_sharp), text: "上传"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: songsProvider.songs.length,
            itemBuilder: (context, index) {
              final song = songsProvider.songs[index];
              final isSelected = index == songsProvider.selected;

              return ListTile(
                onTap: () {
                  songsProvider.select(index);
                  chartsProvider.initLevel(song.bpm, song.offsetMs);
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
