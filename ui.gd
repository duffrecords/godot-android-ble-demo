extends Control

# @onready var bluetooth_manager = BluetoothManager.new()
@onready var permissions_button = $HBoxContainer/VBoxContainer/SetPermissions
@onready var start_scan_button = $HBoxContainer/VBoxContainer/StartScan
@onready var stop_scan_button = $HBoxContainer/VBoxContainer/StopScan
@onready var revs_box = $HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Revs
@onready var last_time_box = $HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/LastTime
@onready var rpm_box = $HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/RPM
@onready var device_list: ItemList = $HBoxContainer/VBoxContainer2/DeviceList

var _plugin_singleton: JNISingleton
var _plugin_name: String = "godotandroidble"

var bluetooth_devices = []
var current_revs = 0
var current_time = 0
var prev_revs = 0
var prev_time = 0
var rpm = 0.0


func _ready() -> void:
	permissions_button.visible = true
	start_scan_button.visible = false
	stop_scan_button.visible = false
	if Engine.has_singleton(_plugin_name):
		_plugin_singleton = Engine.get_singleton(_plugin_name)
		_plugin_singleton.initPlugin()
		if _plugin_singleton.isBluetoothEnabled():
			#get_tree().on_request_permissions_result.connect(_on_request_permissions_result)
			BlePermissionsManager.permissions_done.connect(_on_permissions_done)
			_connect_signals()
			print("checking Bluetooth permissions")
			# bluetooth_manager.check_permissions()
			BlePermissionsManager.ensure_permissions()
	elif OS.has_feature("template"):
		printerr(_plugin_name, " singleton not found!")


func _on_permissions_done(all_ok: bool, results: Dictionary) -> void:
	print("all permissions granted: " + str(all_ok))
	print(results)
	permissions_button.visible = false
	start_scan_button.visible = true
	stop_scan_button.visible = true
	revs_box.text = str(current_revs)
	last_time_box.text = str(current_time)
	rpm_box.text = str(rpm)


func _on_cycling_cadence_measurement_received(measurement: Dictionary) -> void:
	var wheel_revs = measurement["cumulative_wheel_revs"]
	var wheel_time = measurement["last_wheel_event_time"]
	var crank_revs = measurement["cumulative_crank_revs"]
	var crank_time = measurement["last_crank_event_time"]
	prev_revs = current_revs
	prev_time = current_time
	if wheel_revs:
		current_revs = wheel_revs
	elif crank_revs:
		current_revs = crank_revs
	if wheel_time:
		current_time = wheel_time
	elif crank_time:
		current_time = crank_time
	if crank_revs:
		var dt_revs = (current_revs - prev_revs) % 65536
		if dt_revs == 0:
			rpm = 0.0
			return
		elif dt_revs < 0:
			dt_revs += 65536
		var dt_time_raw = (current_time - prev_time) % 65536
		if dt_time_raw < 0:
			dt_time_raw += 65536
		var dt_time_sec = dt_time_raw / 1024.0
		if dt_time_sec > 3.0:
			rpm = 0.0
		elif dt_time_sec > 0.0:
			rpm = (dt_revs / dt_time_sec) * 60.0
		else:
			rpm = 0.0
	revs_box.text = str(current_revs)
	last_time_box.text = str(current_time)
	rpm_box.text = str(int(rpm))


func _connect_signals() -> void:
	_plugin_singleton.connect("plugin_message", _on_plugin_message_received)
	_plugin_singleton.connect("bluetooth_device_found", _on_device_found)
	_plugin_singleton.connect("bluetooth_device_connected", _on_device_connected)
	_plugin_singleton.connect("bluetooth_device_disconnected", _on_device_disconnected)
	_plugin_singleton.connect("cycling_cadence_measurement_received", _on_cycling_cadence_measurement_received)
	_plugin_singleton.connect("current_time_received", _on_current_time_received)
	_plugin_singleton.connect("manufacturer_name_received", _on_manufacturer_name_received)
	_plugin_singleton.connect("model_number_received", _on_model_number_received)
	_plugin_singleton.connect("battery_level_received", _on_battery_level_received)


func _on_plugin_message_received(message: String) -> void:
	print(message)


func _on_set_permissions_pressed() -> void:
	print("requesting Bluetooth permissions")
	# bluetooth_manager.check_permissions()
	BlePermissionsManager.ensure_permissions()


func _on_start_scan_pressed() -> void:
	device_list.clear()
	if _plugin_singleton:
		print("scanning for cycling service")
		_plugin_singleton.scanForCscService()


func _on_stop_scan_pressed() -> void:
	if _plugin_singleton:
		print("stopping scan")
		_plugin_singleton.stopScanning()


func _on_device_found(device: Dictionary) -> void:
	var row = "%s\t%s  %d" % [device["name"], device["address"], device["rssi"]]
	print("device found: " + row)
	var found = false
	for dev in bluetooth_devices:
		if dev.address == dev["address"]:
			found = true
			break
	if not found:
		bluetooth_devices.append(device)
		device_list.add_item(device["name"])


func _on_device_connected(dev_name: String, address: String) -> void:
	print("device connected: " + dev_name + "\t" + address)


func _on_device_disconnected(dev_name: String, address: String, status: String) -> void:
	print("device disconnected: " + dev_name + "\t" + address + "\t" + status)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_timer_timeout() -> void:
	_plugin_singleton.stopScanning()


func _on_device_list_item_selected(index: int) -> void:
	var device = bluetooth_devices[index]
	print(device["name"] + " selected")


func _on_battery_level_received(level: int) -> void:
	print("battery level: " + str(level))


func _on_current_time_received(t: String) -> void:
	print("current time: " + t)


func _on_manufacturer_name_received(manufacturer: String) -> void:
	print("manufacturer: " + manufacturer)


func _on_model_number_received(model: String) -> void:
	print("model number: " + model)
