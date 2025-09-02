run:
	odin build src/ -out:out/pinky && out/pinky programs/example.pinky

test:
	odin test tests/ -all-packages
