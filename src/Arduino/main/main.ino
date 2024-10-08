// Basic demo for accelerometer readings from Adafruit MPU6050

#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

#define PRINT_FLOAT_DECIMALS 4

Adafruit_MPU6050 mpu;

void setup(void) {
  Serial.begin(115200);
  while (!Serial) {
    delay(10); // will pause Zero, Leonardo, etc until serial console opens
  }

  // Try to initialize!
  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) {
      delay(10);
    }
  }

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_250_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  Serial.println("Timestamp,AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ");

  delay(100);
}

void loop() {

  /* Get new sensor events with the readings */
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  /* Print out timestamp */
  Serial.print(a.timestamp);
  Serial.print(",");

  /* Print out the values */
  Serial.print(a.acceleration.x, PRINT_FLOAT_DECIMALS);
  Serial.print(",");
  Serial.print(a.acceleration.y, PRINT_FLOAT_DECIMALS);
  Serial.print(",");
  Serial.print(a.acceleration.z, PRINT_FLOAT_DECIMALS);
  Serial.print(",");
  Serial.print(g.gyro.x, PRINT_FLOAT_DECIMALS);
  Serial.print(",");
  Serial.print(g.gyro.y, PRINT_FLOAT_DECIMALS);
  Serial.print(",");
  Serial.print(g.gyro.z, PRINT_FLOAT_DECIMALS);
  Serial.println("");
}
