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

// LD2410C mmWave
#define MMWAVE_RX_PIN   16
#define MMWAVE_TX_PIN   17
#define MMWAVE_OUT_PIN  18

static ld2410 radar;

static FirebaseData fbdo;
static FirebaseConfig fbConfig;
static FirebaseAuth fbAuth;

static unsigned long lastSendTime = 0;
static const unsigned long SEND_INTERVAL = 1500;

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(PIR_PIN, INPUT);
  pinMode(MMWAVE_OUT_PIN, INPUT);

  Serial2.begin(256000, SERIAL_8N1, MMWAVE_RX_PIN, MMWAVE_TX_PIN);
  delay(500);
  radar.begin(Serial2);

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting to WiFi");
  unsigned long wifiStart = millis();
  unsigned long lastDot   = 0;
  while (WiFi.status() != WL_CONNECTED && millis() - wifiStart < 15000) {
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

  Serial.println("Node ready");
}

void loop() {
  radar.read();

  unsigned long now = millis();
  if (now - lastSendTime >= SEND_INTERVAL) {
    lastSendTime = now;

    bool pir      = digitalRead(PIR_PIN) == HIGH;
    bool presence = pir;
    bool movement = pir;

    Serial.printf("PIR=%d  mmWave presence=%d  movement=%d\n",
      pir, presence, movement);

    if (WiFi.status() == WL_CONNECTED) {
      FirebaseJson json;
      json.set("room", "node_01");
      json.set("pirDetected", pir);
      json.set("mmwavePresence", presence);
      json.set("mmwaveMovement", movement);
      json.set("lightLevel", 0);
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
