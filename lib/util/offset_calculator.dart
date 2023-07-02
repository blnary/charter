class OffsetCalculator {
  final int _offset;
  final double _bpm;
  int _lastPressTime = 0;
  int _sampleCount = 0;
  int _lastDelay = 0;
  int _avgDelay = 0;

  int get lastPressTime => _lastPressTime;
  int get lastDelay => _lastDelay;
  int get avgDelay => _avgDelay;

  OffsetCalculator(this._offset, this._bpm);

  void setDelay(int time) {
    int mspb = (60000 / _bpm).round();
    _lastPressTime = time;
    _lastDelay = (_lastPressTime - _offset + mspb ~/ 2) % mspb - mspb ~/ 2;
    _sampleCount++;
    _avgDelay = (_sampleCount * _avgDelay + _lastDelay) ~/ (_sampleCount + 1);
  }
}
