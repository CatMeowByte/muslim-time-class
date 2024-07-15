extends Node
class_name Hijri

func get_hijri(year: int, month: int, day: int):
	# Calculate the Julian Day Number
	var julian_day_number = 0
	if (year > 1582) or ((year == 1582) and (month > 10)) or ((year == 1582) and (month == 10) and (day > 14)):
		julian_day_number = (1461 * (year + 4800 + ((month - 14) / 12))) / 4 + (367 * (month - 2 - 12 * ((month - 14) / 12))) / 12 - (3 * ((year + 4900 + ((month - 14) / 12)) / 100)) / 4 + day - 32075
	else:
		julian_day_number = 367 * year - (7 * (year + 5001 + ((month - 9) / 7))) / 4 + (275 * month) / 9 + day + 1729777

	# Adjust the Julian Day Number for the Hijri calendar
	var adjusted_julian_day = julian_day_number - 1948440 + 10632
	var cycle_number = ((adjusted_julian_day - 1) / 10631)
	adjusted_julian_day = adjusted_julian_day - 10631 * cycle_number + 354
	var correction_factor = (((10985 - adjusted_julian_day) / 5316)) * (((50 * adjusted_julian_day) / 17719)) + ((adjusted_julian_day / 5670)) * (((43 * adjusted_julian_day) / 15238))
	adjusted_julian_day = adjusted_julian_day - (((30 - correction_factor) / 15)) * (((17719 * correction_factor) / 50)) - ((correction_factor / 16)) * (((15238 * correction_factor) / 43)) + 29
	var hijri_month = ((24 * adjusted_julian_day) / 709)
	var hijri_day = adjusted_julian_day - ((709 * hijri_month) / 24)
	var hijri_year = 30 * cycle_number + correction_factor - 30

	return {
		"year": hijri_year,
		"month": hijri_month,
		"day": hijri_day,
	}
