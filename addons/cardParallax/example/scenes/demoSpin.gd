extends Node3D

var timePassed;

func _ready():
	timePassed = 0.0;

func _process(delta):
	timePassed += delta;

	# Loop the 'z' spin time, for smoothstep
	# This just makes it go from 1 back to 0
	var zSpinTime = fmod(timePassed * 0.25, 1.0);

	# Extra smooth!!!
	rotation.z = smoothstep(
		0.0, 1.0, smoothstep(
			0.0,
			1.0,
			zSpinTime
		)
	) * TAU;

	# Just a simple tilt on the 'x' spin
	rotation.x = cos(timePassed * 0.125 * TAU) * PI * 0.125;

