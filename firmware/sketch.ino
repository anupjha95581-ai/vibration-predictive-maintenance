#include <WiFi.h>
#include <PubSubClient.h>
#include <math.h>

// ---------- settings ----------
const char* WIFI_SSID = "Wokwi-GUEST";
const char* BROKER    = "broker.hivemq.com";
const int   PORT      = 1883;
const char* TOPIC     = "vibmon_AJ_4827/node1/features";

const float FS = 1000.0f;                 // sampling rate (Hz)
const int   N  = 1024;                    // window length (samples)

const int CAL_WINDOWS = 20;               // healthy windows used for calibration
const int RUN_WINDOWS = 100;              // operating windows per machine

const char* CONDS[] = {"healthy", "imbalance", "misalign"};

// ---------- structures (must come before any function) ----------
struct Features {
  float rms, kurt, crest, p2p, p1x, p2x, p3x, ratio;
};

float re[N], im[N];

// state of the machine currently being monitored
int   machineId = -1;
int   winInMachine = 0;
float mA0, mGain, mOff, mSigma;           // fixed properties of this machine
float calSumP1, calSumRms, baseP1, baseRms;

int windowCount = 0;

WiFiClient   wifiClient;
PubSubClient mqtt(wifiClient);

// ---------- random helpers ----------
float randu() { return (float)esp_random() / 4294967296.0f; }
float randn() {
  float u1 = randu() + 1e-9f, u2 = randu();
  return sqrtf(-2.0f * logf(u1)) * cosf(2.0f * PI * u2);
}

// ---------- start monitoring a new (simulated) machine ----------
void newMachine() {
  machineId++;
  winInMachine = 0;
  mA0    = 0.7f + 0.6f * randu();          // baseline vibration level
  mGain  = 1.0f + 0.05f * randn();         // sensor gain error
  mOff   = 0.02f * randn();                // sensor offset
  mSigma = 0.05f + 0.10f * randu();        // noise level
  calSumP1 = 0.0f;  calSumRms = 0.0f;
  baseP1 = 1.0f;    baseRms = 1.0f;
}

// ---------- machine + sensor model (replace with real sensor reads later) ----------
void genWindow(int cond, float sev) {
  float fr  = 30.0f * (1.0f + 0.06f * randn());     // shaft speed drifts
  float ph  = 2.0f * PI * randu();
  float ph2 = 2.0f * PI * randu();
  float ph3 = 2.0f * PI * randu();
  const float lsb = 8.0f / 4096.0f;                 // 12-bit over +/-4 g

  for (int n = 0; n < N; n++) {
    float t = n / FS;
    float x;
    if (cond == 1) {                                // imbalance: stronger 1x
      x = mA0 * (1.0f + sev) * sinf(2.0f * PI * fr * t + ph);
    } else {
      x = mA0 * sinf(2.0f * PI * fr * t + ph);
      if (cond == 2) {                              // misalignment: extra 2x and 3x
        x += sev * (1.2f * sinf(2.0f * PI * 2.0f * fr * t + ph2)
                  + 0.6f * sinf(2.0f * PI * 3.0f * fr * t + ph3));
      }
    }
    x += mSigma * randn();
    x = mGain * x + mOff;
    if (x >  4.0f) x =  4.0f;
    if (x < -4.0f) x = -4.0f;
    x = roundf(x / lsb) * lsb;
    re[n] = x;
    im[n] = 0.0f;
  }
}

// ---------- radix-2 FFT (in place) ----------
void fft(float* xr, float* xi, int n) {
  for (int a = 1, j = 0; a < n; a++) {
    int bit = n >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (a < j) {
      float tr = xr[a]; xr[a] = xr[j]; xr[j] = tr;
      float ti = xi[a]; xi[a] = xi[j]; xi[j] = ti;
    }
  }
  for (int len = 2; len <= n; len <<= 1) {
    float ang = -2.0f * PI / len;
    float wr = cosf(ang), wi = sinf(ang);
    for (int s = 0; s < n; s += len) {
      float cr = 1.0f, ci = 0.0f;
      for (int k = 0; k < len / 2; k++) {
        int u = s + k, v = s + k + len / 2;
        float tr = xr[v] * cr - xi[v] * ci;
        float ti = xr[v] * ci + xi[v] * cr;
        xr[v] = xr[u] - tr;  xi[v] = xi[u] - ti;
        xr[u] += tr;         xi[u] += ti;
        float ncr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = ncr;
      }
    }
  }
}

// ---------- features ----------
float bandPower(float flo, float fhi, float sumw2) {
  float df = FS / N;
  int k0 = (int)ceilf(flo / df);
  int k1 = (int)floorf(fhi / df);
  float p = 0.0f;
  for (int k = k0; k <= k1; k++) {
    float psd = (re[k] * re[k] + im[k] * im[k]) / (FS * sumw2);
    p += 2.0f * psd * df;
  }
  return p;
}

Features computeFeatures() {
  Features f;
  float mean = 0.0f;
  for (int n = 0; n < N; n++) mean += re[n];
  mean /= N;

  float m2 = 0.0f, m4 = 0.0f, mx = -1e9f, mn = 1e9f;
  for (int n = 0; n < N; n++) {
    re[n] -= mean;
    float d2 = re[n] * re[n];
    m2 += d2;  m4 += d2 * d2;
    if (re[n] > mx) mx = re[n];
    if (re[n] < mn) mn = re[n];
  }
  m2 /= N;  m4 /= N;
  f.rms   = sqrtf(m2);
  f.kurt  = m4 / (m2 * m2 + 1e-12f);
  f.crest = fmaxf(mx, -mn) / (f.rms + 1e-12f);
  f.p2p   = mx - mn;

  float sumw2 = 0.0f;
  for (int n = 0; n < N; n++) {
    float w = 0.5f - 0.5f * cosf(2.0f * PI * n / (N - 1));
    re[n] *= w;
    sumw2 += w * w;
  }
  fft(re, im, N);

  f.p1x   = bandPower(24, 36, sumw2);
  f.p2x   = bandPower(50, 70, sumw2);
  f.p3x   = bandPower(78, 102, sumw2);
  f.ratio = (f.p2x + f.p3x) / (f.p1x + 1e-12f);
  return f;
}

// ---------- network ----------
void connectWifi() {
  Serial.print("Connecting to Wi-Fi");
  WiFi.begin(WIFI_SSID, "", 6);
  while (WiFi.status() != WL_CONNECTED) { delay(250); Serial.print("."); }
  Serial.println(" Connected!");
}

void connectMqtt() {
  while (!mqtt.connected()) {
    String id = "esp32-vib-" + String((uint32_t)esp_random(), HEX);
    Serial.print("Connecting to MQTT...");
    if (mqtt.connect(id.c_str())) Serial.println(" Connected!");
    else { Serial.print(" failed rc="); Serial.println(mqtt.state()); delay(2000); }
  }
}

void setup() {
  Serial.begin(115200);
  connectWifi();
  mqtt.setServer(BROKER, PORT);
  mqtt.setBufferSize(768);
  newMachine();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) connectWifi();
  if (!mqtt.connected()) connectMqtt();
  mqtt.loop();

  if (winInMachine >= CAL_WINDOWS + RUN_WINDOWS) newMachine();
  bool calibrating = (winInMachine < CAL_WINDOWS);

  int   cond = 0;
  float sev  = 0.0f;
  if (!calibrating) {                                 // calibration windows are always healthy
    cond = (int)(randu() * 3.0f);
    if (cond > 2) cond = 2;
    sev = 0.3f + 0.7f * randu();
  }

  genWindow(cond, sev);
  uint32_t t0 = micros();
  Features f = computeFeatures();
  uint32_t dt = micros() - t0;

  float rmsN = 0.0f, p1N = 0.0f, p2N = 0.0f, p3N = 0.0f;
  if (calibrating) {
    calSumP1  += f.p1x;
    calSumRms += f.rms;
    if (winInMachine == CAL_WINDOWS - 1) {            // calibration finished
      baseP1  = calSumP1  / CAL_WINDOWS;
      baseRms = calSumRms / CAL_WINDOWS;
    }
  } else {
    rmsN = f.rms / baseRms;
    p1N  = f.p1x / baseP1;
    p2N  = f.p2x / baseP1;                            // 2x power relative to normal 1x power
    p3N  = f.p3x / baseP1;
  }

  char msg[480];
  snprintf(msg, sizeof(msg),
    "{\"n\":%d,\"machine\":%d,\"phase\":\"%s\",\"truth\":\"%s\","
    "\"rms\":%.4f,\"kurt\":%.3f,\"crest\":%.3f,\"p2p\":%.3f,"
    "\"p1x\":%.5f,\"p2x\":%.5f,\"p3x\":%.5f,\"ratio\":%.4f,"
    "\"rms_n\":%.4f,\"p1x_n\":%.4f,\"p2x_n\":%.5f,\"p3x_n\":%.5f}",
    windowCount, machineId, calibrating ? "cal" : "run", CONDS[cond],
    f.rms, f.kurt, f.crest, f.p2p, f.p1x, f.p2x, f.p3x, f.ratio,
    rmsN, p1N, p2N, p3N);

  bool ok = mqtt.publish(TOPIC, msg);
  Serial.printf("[%d] machine %d %-4s %-9s compute %lu us | publish %s\n",
                windowCount, machineId, calibrating ? "cal" : "run", CONDS[cond],
                (unsigned long)dt, ok ? "OK" : "FAILED");
  Serial.println(msg);

  windowCount++;
  winInMachine++;
  delay(1000);
}
