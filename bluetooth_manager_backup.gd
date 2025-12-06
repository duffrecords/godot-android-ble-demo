extends Node
class_name BluetoothManagerBackup

signal bluetooth_manager_ready

var has_scan_premission
var scan_perm := "android.permission.BLUETOOTH_SCAN"

var has_connect_premission
var connect_perm := "android.permission.BLUETOOTH_CONNECT"


func _ready() -> void:
	print("bluetooth_manager.gd _ready() was called")
	get_tree().on_request_permissions_result.connect(_on_request_permissions_result)


func check_permissions():
	print("granted permissions: " + str(OS.get_granted_permissions()))

	if not OS.get_granted_permissions().has(scan_perm):
		has_scan_premission = request_scan_permission()
		if not has_scan_premission:
			print("Unable to get scan permission")
			return
		
	if not OS.get_granted_permissions().has(connect_perm):
		has_connect_premission = request_connect_permission()
		if not has_connect_premission:
			print("Unable to get connect permission")
			return
		
	# permissions available and bluetooth initialized
	# no longer need to listen for on_request_permissions_result signal
	get_tree().on_request_permissions_result.disconnect(_on_request_permissions_result)
	bluetooth_manager_ready.emit()


func request_scan_permission():
	if not OS.get_granted_permissions().has(scan_perm):
		print("requesting ", scan_perm)
		OS.request_permission(scan_perm)
		return true


func request_connect_permission():
	if not OS.get_granted_permissions().has(connect_perm):
		print("requesting ", connect_perm)
		OS.request_permission(connect_perm)
		return true


func _on_request_permissions_result(permission: String, granted: bool):
	print("Permission ", permission, " = ", granted)
	if permission == scan_perm:
		has_scan_premission = granted
	elif permission == connect_perm:
		has_connect_premission = granted
	if granted:
		check_permissions()
		return granted
