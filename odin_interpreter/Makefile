ODIN_COLLECTION = -collection:pinky=./src
ODIN_FLAGS = -vet
SRC_DIR = src/
OUT_BIN = ../out/pinky
TEST_DIR = tests/
INPUT_PROGRAM = ../programs/example.pinky

run:
	odin build $(SRC_DIR) $(ODIN_COLLECTION) $(ODIN_FLAGS) -out:$(OUT_BIN) && $(OUT_BIN) $(INPUT_PROGRAM)

test:
	odin test $(TEST_DIR) $(ODIN_COLLECTION) -all-packages
