extends Node
class_name PrayTimes

signal download_completed

enum CalculationMethod {
	SHIA_ITHNA_ASHARI,
	UNIVERSITY_OF_ISLAMIC_SCIENCES_KARACHI,
	ISLAMIC_SOCIETY_OF_NORTH_AMERICA,
	MUSLIM_WORLD_LEAGUE,
	UMM_AL_QURA_UNIVERSITY_MAKKAH,
	EGYPTIAN_GENERAL_AUTHORITY_OF_SURVEY,
	INSTITUTE_OF_GEOPHYSICS_UNIVERSITY_OF_TEHRAN,
	GULF_REGION,
	KUWAIT,
	QATAR,
	MAJLIS_UGAMA_ISLAM_SINGAPURA_SINGAPORE,
	UNION_ORGANIZATION_ISLAMIC_DE_FRANCE,
	DIYANET_ISLERI_BASKANLIGI_TURKEY,
	SPIRITUAL_ADMINISTRATION_OF_MUSLIMS_OF_RUSSIA,
	MOONSIGHTING_COMMITTEE_WORLDWIDE,
	DUBAI,
}

enum LatitudeMethod {
	MIDDLE_OF_THE_NIGHT = 1,
	ONE_SEVENTH = 2,
	ANGLE_BASED = 3,
}

enum Shafaq {
	GENERAL,
	AHMER,
	ABYAD,
}

# Al Adhan API
# Use human-readable geocode instead of coordinate
const API_URL: String = "https://api.aladhan.com/v1/calendarByAddress/{year}?address={geocode}&method={calculation_method}&latitudeAdjustmentMethod={latitude_method}&shafaq={shafaq}&school={hanafi}&midnightMode={jafari}"
const FILE_DIR: String = "user://praytimes"
const FILE_DATA: String = "praytimes.dictionary"

var HTTP: HTTPRequest

static var input_year: int = 0
static var input_geocode: String = "London"
static var input_calculation_method: CalculationMethod = 0
static var input_latitude_method: LatitudeMethod = 0
static var input_shafaq: Shafaq = 0
static var input_hanafi: bool = false
static var input_jafari: bool = false


func is_data_available():
	return FileAccess.file_exists(FILE_DIR + "/" + FILE_DATA)


func download_data(year: int, geocode: String, calculation_method: CalculationMethod, latitude_method: LatitudeMethod, shafaq: Shafaq, hanafi: bool, jafari: bool):
	input_year = year
	input_geocode = geocode
	input_calculation_method = calculation_method
	input_latitude_method = latitude_method
	input_shafaq = shafaq
	input_hanafi = hanafi
	input_jafari = jafari

	_do_request()


func get_data_info():
	if not is_data_available():
		printerr("Data unavailable.")
		return

	var file = FileAccess.open(FILE_DIR + "/" + FILE_DATA, FileAccess.READ)
	var data = file.get_var()["data"]["1"][0]

	var info = {
		"year": data.date.gregorian.year,
		"latitude": data.meta.latitude,
		"longitude": data.meta.longitude,
		"timezone": data.meta.timezone,
		"calculation_method": data.meta.method.id,
		"latitude_method": LatitudeMethod[data.meta.latitudeAdjustmentMethod],
		"hanafi": data.meta.school == "HANAFI",
		"jafari": data.meta.midnightMode == "JAFARI",
	}

	return info


func get_praytimes(month: int, day: int):
	if not is_data_available():
		printerr("Data unavailable.")
		return

	var file = FileAccess.open(FILE_DIR + "/" + FILE_DATA, FileAccess.READ)
	var data = file.get_var()["data"][str(month)][int(day - 1)]["timings"]
	for key in data:
		var time_array = data[key].left(5).split(":")
		data[key] = (int(time_array[0]) * 60) + int(time_array[1])
	return data


func _ready():
	# Create HTTP request node
	HTTP = HTTPRequest.new()
	HTTP.set_timeout(10)
	add_child(HTTP)
	HTTP.request_completed.connect(_on_request_completed)

	# Setup
	DirAccess.make_dir_recursive_absolute(FILE_DIR)


func _do_request():
	var request = HTTP.request(
		API_URL.format({
			"year": str(input_year),
			"geocode": str(input_geocode),
			"calculation_method": str(input_calculation_method),
			"latitude_method": str(input_latitude_method),
			"shafaq": str({0: "general", 1: "ahmer", 2: "abyad"}[input_shafaq]),
			"hanafi": str(int(input_hanafi)),
			"jafari": str(int(input_jafari)),
		})
	)
	if not request == OK:
		printerr("Attempt to request failed.")


func _on_request_completed(result, _response_code, _headers, body):
	var request_retry: Callable = func (message: String):
		printerr(message)
		print("Retrying request...")
		await get_tree().create_timer(5).timeout
		_do_request()
		return

	if not result == HTTPRequest.RESULT_SUCCESS:
		request_retry.call("Request failed.")

	var data = JSON.parse_string(body.get_string_from_utf8())
	if not data:
		request_retry.call("JSON parse failed.")

	var file = FileAccess.open(FILE_DIR + "/" + FILE_DATA, FileAccess.WRITE)
	file.store_var(data)

	download_completed.emit()
