import javax.swing.JOptionPane;
import oscP5.*;
import netP5.*;
import processing.serial.*;
import controlP5.*;

Serial arduinoPort;
OscP5 oscP5;
NetAddress oscAddress;
NetAddress eosAddress;

float redValue = 0;
float greenValue = 0;
float blueValue = 0;
float opacityValue = 0;

int smoothingFactor = 10; // Default smoothing factor
float minRedValue = 0;
float maxRedValue = 1;
float minGreenValue = 0;
float maxGreenValue = 1;
float minBlueValue = 0;
float maxBlueValue = 1;
float minOpacityValue = 0;
float maxOpacityValue = 1;

void setup() {
  size(950, 450); // Adjust the window size as needed
  background(0); // Set background color to black
  
  // OSC setup
  oscP5 = new OscP5(this, 12000);
  // Ask for IP Address
  String ipAddress = JOptionPane.showInputDialog("Enter target IP address (e.g., 192.168.1.101):");
  // Ask for port number
  String portInput = JOptionPane.showInputDialog("Enter port number (e.g., 8010):");
  int portNumber = Integer.parseInt(portInput);
  oscAddress = new NetAddress(ipAddress, portNumber);
  
  // Adjust the COM port according to your Arduino
  String comPort = JOptionPane.showInputDialog("Enter COM port for Arduino (e.g., COM11):");
  arduinoPort = new Serial(this, comPort, 9600);
  
  // Additional prompts for EOS IP Address and Port Number
  String eosIPAddress = JOptionPane.showInputDialog("Enter EOS IP address (e.g., 192.168.1.100):");
  String eosPortInput = JOptionPane.showInputDialog("Enter EOS port number (e.g., 3000):");
  int eosPortNumber = Integer.parseInt(eosPortInput);
  eosAddress = new NetAddress(eosIPAddress, eosPortNumber);
  
  // Create ControlP5 instance
  ControlP5 cp5 = new ControlP5(this);
  
  // Add smoothing factor slider
  cp5.addSlider("smoothingFactor")
     .setPosition(10, 30)
     .setSize(200, 20)
     .setRange(1, 100)
     .setValue(smoothingFactor)
     .setLabelVisible(true)
     .setLabel("Smoothing Factor");
  
  // Add min/max sliders for red, green, blue, and opacity
  addMinMaxSlider(cp5, "minRedValue", 10, 80, "Min Red");
  addMinMaxSlider(cp5, "maxRedValue", 10, 110, "Max Red");
  addMinMaxSlider(cp5, "minGreenValue", 10, 160, "Min Green");
  addMinMaxSlider(cp5, "maxGreenValue", 10, 190, "Max Green");
  addMinMaxSlider(cp5, "minBlueValue", 10, 240, "Min Blue");
  addMinMaxSlider(cp5, "maxBlueValue", 10, 270, "Max Blue");
  addMinMaxSlider(cp5, "minOpacityValue", 10, 320, "Min Opacity");
  addMinMaxSlider(cp5, "maxOpacityValue", 10, 350, "Max Opacity");
  
  // Add help button
  cp5.addButton("help")
     .setPosition(10, 390)
     .setSize(100, 20)
     .setLabel("Help");
}

void draw() {
  background(0);
  
  // Display white square affected by color and opacity values
  float whiteOpacity = map(opacityValue, minOpacityValue, maxOpacityValue, 0, 255);
  float whiteRed = map(redValue, minRedValue, maxRedValue, 0, 255);
  float whiteGreen = map(greenValue, minGreenValue, maxGreenValue, 0, 255);
  float whiteBlue = map(blueValue, minBlueValue, maxBlueValue, 0, 255);
  fill(whiteRed, whiteGreen, whiteBlue, whiteOpacity);
  rect(750, 50, 150, 320);
  
  // Display rectangles representing sensor data
  fill(255, 0, 0, redValue * 255);
  rect(350, 50, 150, 150);
  fill(0);
  text("Red: " + nf(redValue, 0, 2), 300, 210);
  
  fill(0, 255, 0, greenValue * 255);
  rect(550, 50, 150, 150);
  fill(0);
  text("Green: " + nf(greenValue, 0, 2), 500, 210);
  
  fill(0, 0, 255, blueValue * 255);
  rect(350, 220, 150, 150);
  fill(0);
  text("Blue: " + nf(blueValue, 0, 2), 300, 380);
  
  fill(255, opacityValue * 255);
  rect(550, 220, 150, 150);
  fill(0);
  text("Opacity: " + nf(opacityValue, 0, 2), 500, 380);
  
  // Read data from Arduino
  while (arduinoPort.available() > 0) {
    String serialData = arduinoPort.readStringUntil('\n');
    if (serialData != null) {
      // Parse serial data
      serialData = serialData.trim();
      String[] parts = serialData.split(":");
      if (parts.length == 2) {
        String sensor = parts[0];
        float value = float(parts[1]);
        // Update sensor values with smoothing
        updateSensorValues(sensor, value);
        // Send OSC messages
        sendOSCMessage(sensor, smooth(getPreviousValue(sensor), value), oscAddress);
        sendEOSMessage(sensor, smooth(getPreviousValue(sensor), value));
      }
    }
  }
}

void updateSensorValues(String sensor, float value) {
  if (sensor.equals("red")) {
    redValue = smooth(redValue, map(value, minRedValue, maxRedValue, 0, 1));
  } else if (sensor.equals("green")) {
    greenValue = smooth(greenValue, map(value, minGreenValue, maxGreenValue, 0, 1));
  } else if (sensor.equals("blue")) {
    blueValue = smooth(blueValue, map(value, minBlueValue, maxBlueValue, 0, 1));
  } else if (sensor.equals("opacity")) {
    opacityValue = smooth(opacityValue, map(value, minOpacityValue, maxOpacityValue, 0, 1));
  }
}

float getPreviousValue(String sensor) {
  switch (sensor) {
    case "red":
      return redValue;
    case "green":
      return greenValue;
    case "blue":
      return blueValue;
    case "opacity":
      return opacityValue;
    default:
      return 0;
  }
}

float smooth(float previousValue, float newValue) {
  // Simple smoothing using averaging
  float smoothedValue = (previousValue * (smoothingFactor - 1) + newValue) / smoothingFactor;
  return smoothedValue;
}

void sendOSCMessage(String sensor, float value, NetAddress address) {
  OscMessage msg = new OscMessage(getOSCAddress(sensor));
  msg.add(value);
  oscP5.send(msg, address);
}

void sendEOSMessage(String sensor, float value) {
  int subIndex;
  switch (sensor) {
    case "red":
      subIndex = 2;
      break;
    case "green":
      subIndex = 3;
      break;
    case "blue":
      subIndex = 4;
      break;
    case "opacity":
      subIndex = 5;
      break;
    default:
      return;
  }
  OscMessage msg = new OscMessage("/eos/sub/" + subIndex);
  msg.add(value);
  oscP5.send(msg, eosAddress);
}

String getOSCAddress(String sensor) {
  if (sensor.equals("opacity")) {
    return "/surfaces/Quad-1/opacity";
  } else {
    return "/surfaces/Quad-1/color/" + sensor;
  }
}

void addMinMaxSlider(ControlP5 cp5, String variableName, int x, int y, String label) {
  cp5.addSlider(variableName)
     .setPosition(x, y)
     .setSize(200, 20)
     .setRange(0, 1)
     .setValue(getDefaultValue(variableName))
     .setLabelVisible(true)
     .setLabel(label);
}

float getDefaultValue(String variableName) {
  switch (variableName) {
    case "minRedValue":
      return minRedValue;
    case "maxRedValue":
      return maxRedValue;
    case "minGreenValue":
      return minGreenValue;
    case "maxGreenValue":
      return maxGreenValue;
    case "minBlueValue":
      return minBlueValue;
    case "maxBlueValue":
      return maxBlueValue;
    case "minOpacityValue":
      return minOpacityValue;
    case "maxOpacityValue":
      return maxOpacityValue;
    default:
      return smoothingFactor;
  }
}

void help() {
  String helpMessage = "Controls:\n";
  helpMessage += "1. Smoothing Factor: Adjusts the level of smoothing for sensor data.\n";
  helpMessage += "   - Increase this value to smooth out fluctuations in sensor readings.\n";
  helpMessage += "   - Decrease this value for more responsive sensor data.\n\n";
  helpMessage += "2. Min/Max Red, Green, Blue, Opacity: Adjusts the minimum and maximum values for each color channel and opacity.\n";
  helpMessage += "   - Use the minimum sliders to set the lowest value that will be mapped to the color or opacity.\n";
  helpMessage += "   - Use the maximum sliders to set the highest value that will be mapped to the color or opacity.\n";
  helpMessage += "   - Adjust these sliders to fine-tune the color range or opacity level.\n\n";
  helpMessage += "3. Help: Displays this help message.";
  JOptionPane.showMessageDialog(null, helpMessage, "Help", JOptionPane.INFORMATION_MESSAGE);
}
