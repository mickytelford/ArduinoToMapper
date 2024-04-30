// Define the pins for each sensor
const int numSensors = 4;
const int triggerPins[numSensors] = {2, 4, 6, 8};
const int echoPins[numSensors] = {3, 5, 7, 9};

void setup() {
  Serial.begin(9600);
  // Initialize trigger pins as outputs and echo pins as inputs
  for (int i = 0; i < numSensors; i++) {
    pinMode(triggerPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
  }
}

void loop() {
  for (int i = 0; i < numSensors; i++) {
    // Trigger the sensor
    digitalWrite(triggerPins[i], LOW);
    delayMicroseconds(2);
    digitalWrite(triggerPins[i], HIGH);
    delayMicroseconds(10);
    digitalWrite(triggerPins[i], LOW);
    
    // Measure the pulse from the echo pin
    long duration = pulseIn(echoPins[i], HIGH);
    
    // Convert the duration into distance
    float distance = duration * 0.034 / 2.0;
    
    // Normalize distance to be between 0 and 1
    distance = constrain(distance, 0, 300); // Limit the maximum distance to 100 cm
    float normalizedDistance = distance / 300.0;
    
    // Print the distance for each sensor
    switch(i) {
      case 0:
        Serial.print("red: ");
        break;
      case 1:
        Serial.print("green: ");
        break;
      case 2:
        Serial.print("blue: ");
        break;
      case 3:
        Serial.print("opacity: ");
        break;
    }
    Serial.println(normalizedDistance, 2); // Print distance to 2 decimal places
    
    delay(10); // Wait a bit before triggering the next sensor
  }
}