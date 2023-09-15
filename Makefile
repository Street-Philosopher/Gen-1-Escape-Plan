
BUILD_PATH := dbuild

.phony: all
all: payload converter

.phony: payload
payload:
	echo "payload"
	echo $@

.phony: converter
converter:
	echo "converter"

.phony: clean
clean:
	rm -r $(BUILD_PATH)/*