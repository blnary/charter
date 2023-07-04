class OffsetCalculator {
  double _offsetMs = 0;
  double _bpm = 60;
  double _lastPressTime = 0;
  int _sampleCount = 0;
  double _lastDelay = 0;
  double _avgDelay = 0;

  double get lastPressTime => _lastPressTime;
  double get lastDelay => _lastDelay;
  double get avgDelay => _avgDelay;

  void setDelay(double time) {
    if (_bpm == 0) {
      return;
    }
    double mspb = 60000 / _bpm;
    _lastPressTime = time;
    double unitCount = (_lastPressTime - _offsetMs) / mspb;
    _lastDelay = (unitCount - unitCount.round()) * mspb;
    _sampleCount++;
    _avgDelay = (_sampleCount * _avgDelay + _lastDelay) / (_sampleCount + 1);
  }

  void setOffsetMs(double offsetMs) {
    _offsetMs = offsetMs;
  }

  void setBpm(double bpm) {
    _bpm = bpm;
  }
}
