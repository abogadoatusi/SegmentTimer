import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(MyTeaApp());

class MyTeaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // アプリケーション全体のテーマ設定を行います
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Segment Timer',
      theme: ThemeData(
        // ダークテーマを適用します
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TeaTimerScreen(),
    );
  }
}

class TeaSegment {
  String title;
  int duration;

  TeaSegment({required this.title, required this.duration});
}

class TeaTimerScreen extends StatefulWidget {
  @override
  _TeaTimerScreenState createState() => _TeaTimerScreenState();
}

class _TeaTimerScreenState extends State<TeaTimerScreen> {
  List<TeaSegment> _teaSegments = [];
  int _totalTime = 0;
  int _remainingTime = 0;
  Timer? _timer;
  bool _isPaused = false;
  int _currentSegmentIndex = 0;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    // タイマーの初期化を行います
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            _moveToNextSegment();
          }
        });
      }
    });
    _resetTimer();
  }

  // セグメントごとのタイマーを開始します
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            _moveToNextSegment();
          }
        });
      }
    });
  }

  // タイマーをリセットします
  void _resetTimer() {
    setState(() {
      _remainingTime = _teaSegments.isNotEmpty ? _teaSegments[0].duration : _totalTime;
      _isPaused = false;
      _currentSegmentIndex = 0;
      _startTimer();
    });
  }

  // 次のセグメントに移動します
  void _moveToNextSegment() {
    _playAudio(); // セグメントが終わるたびに音を鳴らします
    if (_currentSegmentIndex < _teaSegments.length - 1) {
      _currentSegmentIndex++;
      _remainingTime = _teaSegments[_currentSegmentIndex].duration;
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  // 音声を再生します
  Future<void> _playAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('alarm.mp3'));
      await _audioPlayer.resume();
      print('Audio played successfully');
    } catch (e) {
      print('Error: $e');
    }
  }

  // 総時間を更新します
  void _updateTotalTime() {
    setState(() {
      if (_teaSegments.isNotEmpty) {
        _totalTime = _teaSegments.map((segment) => segment.duration).reduce((a, b) => a + b);
        _remainingTime = _totalTime;
        _isPaused = false;
      } else {
        _totalTime = 0;
        _remainingTime = 0;
        _isPaused = false;
      }
    });
    _resetTimer();
  }

  // セグメントを削除します
  void _removeSegment(int index) {
    setState(() {
      _teaSegments.removeAt(index);
      _updateTotalTime();
    });
  }

  // セグメントを編集します
  void _editSegment(int index) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController durationController = TextEditingController();

    titleController.text = _teaSegments[index].title;
    durationController.text = _teaSegments[index].duration.toString();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Segment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: durationController,
                decoration: InputDecoration(labelText: 'Duration (seconds)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String title = titleController.text;
                int duration = int.tryParse(durationController.text) ?? 0;
                if (title.isNotEmpty && duration > 0) {
                  setState(() {
                    _teaSegments[index] = TeaSegment(title: title, duration: duration);
                    _updateTotalTime();
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // セグメントの追加ダイアログを表示します
  Future<void> _showAddSegmentDialog() async {
    TextEditingController titleController = TextEditingController();
    TextEditingController durationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Segment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: durationController,
                decoration: InputDecoration(labelText: 'Duration (seconds)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String title = titleController.text;
                int duration = int.tryParse(durationController.text) ?? 0;
                if (title.isNotEmpty && duration > 0) {
                  setState(() {
                    _teaSegments.add(TeaSegment(title: title, duration: duration));
                    _updateTotalTime();
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // ポーズと再開の状態を切り替えます
  void _togglePausedState() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    // UIを構築します
    return Scaffold(
      appBar: AppBar(
        title: Text('Segment Timer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _teaSegments.isNotEmpty ? _teaSegments[_currentSegmentIndex].title : 'Total Segment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              '$_remainingTime seconds',
              style: TextStyle(
                fontSize: 24,
                color: Colors.tealAccent[200],
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _resetTimer();
                  },
                  child: Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _togglePausedState();
                  },
                  child: Text(_isPaused ? 'Resume' : 'Pause'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showAddSegmentDialog();
                  },
                  child: Text('Add Segment'),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Text(
              'Total Time: $_totalTime seconds',
              style: TextStyle(
                fontSize: 20,
                color: Colors.tealAccent[100],
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: _teaSegments.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    color: Colors.blueGrey[800],
                    child: ListTile(
                      title: Text(
                        _teaSegments[index].title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        '${_teaSegments[index].duration} seconds',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.tealAccent[100],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _editSegment(index);
                            },
                            child: Text('Edit'),
                          ),
                          SizedBox(width: 8.0),
                          ElevatedButton(
                            onPressed: () {
                              _removeSegment(index);
                            },
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
