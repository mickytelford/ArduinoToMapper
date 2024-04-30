# ArduinoToMapper

A Java app to convert serial communication from an Arduino Uno with four HC-SR04 sensors to OSC messages sent to Madmapper.

This version of the app supports sending messages to quad1, red, green, blue and opacity values. As an addition the data is also converted to EOS OSC messages to send to ETC lighting consoles. At present the data is sent to subs 2, 3, 4 and 5. 

# Setup
On launching the app, the user is given the options for the IP addess and port numbers of madmapper and eos respectively. localhost does work. It also asks what port the arduino is plugged into. 

# Smoothing

There is a smoothing factor applied to the results to give an average of readings to irradicate rogue readings.

# Further Development
I hope to be able to develop this further to allow customisation of the osc messages that are sent as well as allowing different inputs.
