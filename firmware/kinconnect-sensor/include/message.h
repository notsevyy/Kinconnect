#pragma once

struct SensorData {
  char room[16];
  int  lightLevel;
  bool pirDetected;
  bool mmwavePresence;
  bool mmwaveMovement;
};
