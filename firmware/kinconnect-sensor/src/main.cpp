#include <Arduino.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <ld2410.h>

#define WIFI_SSID       "ESPTEST"
#define WIFI_PASS       "12345678"
#define FIREBASE_URL    "https://kcnct-6c4e4-default-rtdb.firebaseio.com"
#define FIREBASE_SECRET "riKIVmJSQiw3v30UmPmra4OIkzinDfCqhfZIr7ws"

// PIR
#define PIR_PIN         12

// LDR
#define LDR_PIN         4

// LD2410C mmWave
#define MMWAVE_RX_PIN   16
#define MMWAVE_TX_PIN   17
#define MMWAVE_OUT_PIN  18

static ld2410 radar;

static FirebaseData fbdo;
static FirebaseData fbdoSens;
static FirebaseConfig fbConfig;
static FirebaseAuth fbAuth;

static unsigned long lastSendTime = 0;
static const unsigned long SEND_INTERVAL = 1500;

static unsigned long lastSensitivityPoll = 0;
static const unsigned long SENS_POLL_INTERVAL = 5000;

static int  sensitivity      = 50;
static unsigned long alarmThresholdMs = 32000;

static bool sleepModeActive = false;
static unsigned long stillSince = 0;
static bool alarmActive = false;

void updateAlarmThreshold(int sens) {
  float delaySec = 60.0f - (sens / 100.0f) * 55.0f;
  alarmThresholdMs = (unsigned long)(delaySec * 1000);
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(PIR_PIN, INPUT_PULLDOWN);
  pinMode(MMWAVE_OUT_PIN, INPUT);
  pinMode(LDR_PIN, INPUT);

  Serial2.begin(256000, SERIAL_8N1, MMWAVE_RX_PIN, MMWAVE_TX_PIN);
  delay(500);
  radar.begin(Serial2);
  Serial.printf("LD2410C: UART TX=GPIO%d RX=GPIO%d @ 256000 baud\n", MMWAVE_TX_PIN, MMWAVE_RX_PIN);

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting to WiFi");
  unsigned long wifiStart = millis();
  unsigned long lastDot   = 0;
  while (WiFi.status() != WL_CONNECTED && millis() - wifiStart < 30000) {
    if (millis() - lastDot >= 500) { lastDot = millis(); Serial.print("."); }
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\nWiFi connected — IP: %s  channel: %d\n",
      WiFi.localIP().toString().c_str(), WiFi.channel());
  } else {
    Serial.println("\nWiFi FAILED — continuing without cloud");
  }

  Serial.printf("Node MAC: %s\n", WiFi.macAddress().c_str());

  fbConfig.database_url = FIREBASE_URL;
  fbConfig.signer.tokens.legacy_token = FIREBASE_SECRET;
  Firebase.begin(&fbConfig, &fbAuth);
  Firebase.reconnectWiFi(true);
  delay(2000);

  updateAlarmThreshold(sensitivity);
  Serial.println("Node ready");
}

void loop() {
  radar.read();

  unsigned long now = millis();

  bool pir      = digitalRead(PIR_PIN) == HIGH;
  bool mmwOut   = digitalRead(MMWAVE_OUT_PIN) == HIGH;
  bool presence = mmwOut || radar.presenceDetected();
  bool movement = radar.movingTargetDetected();

  int rawLight   = analogRead(LDR_PIN);
  float lightPct = (rawLight / 4095.0f) * 100.0f;

  unsigned long effectiveThreshold = (lightPct < 30.0f) ? alarmThresholdMs * 2 : alarmThresholdMs;

  if (sleepModeActive || !presence || movement) {
    stillSince  = 0;
    alarmActive = false;
  } else {
    if (stillSince == 0) stillSince = now;
    if (now - stillSince >= effectiveThreshold) alarmActive = true;
  }

  if (WiFi.status() == WL_CONNECTED && now - lastSensitivityPoll >= SENS_POLL_INTERVAL) {
    lastSensitivityPoll = now;
    if (Firebase.getInt(fbdoSens, "/nodes/node_01/sensitivity")) {
      int newSens = fbdoSens.intData();
      if (newSens != sensitivity) {
        sensitivity = newSens;
        updateAlarmThreshold(sensitivity);
        Firebase.setInt(fbdo, "/nodes/node_01/sensitivityApplied", sensitivity);
      }
    }
    if (Firebase.getBool(fbdoSens, "/nodes/node_01/sleepModeActive")) {
      sleepModeActive = fbdoSens.boolData();
    }
  }

  if (now - lastSendTime >= SEND_INTERVAL) {
    lastSendTime = now;

    Serial.printf("PIR=%d  presence=%d  movement=%d  alarm=%d  sens=%d  light=%.2f%%\n",
      pir, presence, movement, alarmActive, sensitivity, lightPct);

    if (WiFi.status() == WL_CONNECTED) {
      FirebaseJson json;
      json.set("room", "node_01");
      json.set("pirDetected", pir);
      json.set("mmwavePresence", presence);
      json.set("mmwaveMovement", movement);
      json.set("lightLevel", (float)((int)(lightPct * 100)) / 100.0f);
      json.set("alarmActive", alarmActive);
      json.set("timestamp", (long)millis());

      if (Firebase.set(fbdo, "/nodes/node_01/latest", json)) {
        Serial.println("Firebase: OK");
      } else {
        Serial.println("Firebase: FAIL — " + fbdo.errorReason());
      }
    } else {
      Serial.println("Firebase: skipped (no WiFi)");
    }
  }
}
