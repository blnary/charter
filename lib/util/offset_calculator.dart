class OffsetCalculator {
  int _offset = 0;
  double _bpm = 60;
  int _lastPressTime = 0;
  int _sampleCount = 0;
  int _lastDelay = 0;
  int _avgDelay = 0;

  int get lastPressTime => _lastPressTime;
  int get lastDelay => _lastDelay;
  int get avgDelay => _avgDelay;

  void setDelay(int time) {
    if (_bpm == 0) {
      return;
    }
    int mspb = (60000 / _bpm).round();
    _lastPressTime = time;
    _lastDelay = (_lastPressTime - _offset + mspb ~/ 2) % mspb - mspb ~/ 2;
    _sampleCount++;
    _avgDelay = (_sampleCount * _avgDelay + _lastDelay) ~/ (_sampleCount + 1);
  }

  void setOffset(int offset) {
    _offset = offset;
  }

  void setBpm(double bpm) {
    _bpm = bpm;
  }
}
