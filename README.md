# Godot Android BLE Demo

A simple proof of concept to demonstrate my [GodotAndroidBle](https://github.com/duffrecords/GodotAndroidBle) plugin on the Meta Quest 3. This is meant to read data from a BLE cycling speed and cadence sensor.

### Usage
1. Make sure your sensor is powered on and is set to cycling speed and cadence mode, not cycling power (if your device supports both).
1. Deploy the project to your Quest.
1. Aim the controller at the "Request BT Permissions" button and pull the trigger. A dialog box will pop up asking you to grant permission. If you have already done so, the button will be disabled. 
1. Click the "Start Scan" button. In a moment, the sensor should show up in the "Devices Found list on the right.
1. The plugin will automatically request notifications from the sensor. Begin rotating the sensor and metrics should appear below. The values are the cumulative revolutions, the number of 1/1024 second units elapsed since the last event, and the calculated RPM based on these numbers.

