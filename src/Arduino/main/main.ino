// Basic demo for accelerometer readings from Adafruit MPU6050

#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

#define PRINT_FLOAT_DECIMALS 4
#define LOOP_PERIOD_MICROS 8000

Adafruit_MPU6050 mpu;

void setup(void) {
  Serial.begin(115200);
  while (!Serial) {
    delay(10); // will pause Zero, Leonardo, etc until serial console opens
  }

  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) {
      delay(10);
    }
  }

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_250_DEG);

  delay(100);
}

void output_data() {
  /* Print out header */
  static bool first_run = true;
  if (first_run) {
    first_run = false;
    Serial.println("Timestamp,AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ");
  }

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

void loop() {
  /* Define previous time */
  static unsigned long previous_time = 0;

  /* Define current time */
  unsigned long current_time = micros();

  /* Check if enough time has passed */
  if ((current_time - previous_time) > LOOP_PERIOD_MICROS) {

    /* Update previous time */
    previous_time = current_time;

    /* Output data */
    output_data();
  }
}
