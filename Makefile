# Developer entry points. Requires the Connect IQ SDK; see README.md for
# one-time setup (SDK, device files and a signing key).

DEVICE ?= fr55
KEY ?= $(HOME)/.garmin-keys/developer_key.der
TYPE_CHECK ?= 2

SDK_BIN := $(shell connect-iq-sdk-manager sdk current-path --bin 2>/dev/null)
ifeq ($(SDK_BIN),)
SDK_BIN := $(shell ls -d "$(HOME)/Library/Application Support/Garmin/ConnectIQ/Sdks"/*/bin 2>/dev/null | sort | tail -1)
endif

MONKEYC = "$(SDK_BIN)/monkeyc"
MONKEYDO = "$(SDK_BIN)/monkeydo"
SIMULATOR = "$(SDK_BIN)/connectiq"

.PHONY: help key build test-build test sim package illustrations clean

help:
	@echo "Targets:"
	@echo "  key            Generate a developer signing key (once)"
	@echo "  build          Compile a debug build for DEVICE (default: fr55)"
	@echo "  test-build     Compile the unit-test build for DEVICE"
	@echo "  sim            Launch the Connect IQ simulator"
	@echo "  test           Run unit tests on the simulator (start 'make sim' first)"
	@echo "  package        Build the store-ready .iq package (all devices)"
	@echo "  illustrations  Regenerate stretch illustrations from scripts/"
	@echo "  clean          Remove build output"

key:
	@mkdir -p $(dir $(KEY))
	@test -f $(KEY) || ( \
		openssl genrsa -out $(KEY:.der=.pem) 4096 && \
		openssl pkcs8 -topk8 -inform PEM -outform DER \
			-in $(KEY:.der=.pem) -out $(KEY) -nocrypt && \
		echo "Developer key created at $(KEY)" )

build: key
	@mkdir -p bin
	$(MONKEYC) -f monkey.jungle -d $(DEVICE) -o bin/Stretches-$(DEVICE).prg \
		-y $(KEY) -w -l $(TYPE_CHECK)

test-build: key
	@mkdir -p bin
	$(MONKEYC) -f monkey.jungle -d $(DEVICE) -o bin/Stretches-tests.prg \
		-y $(KEY) -w -l $(TYPE_CHECK) --unit-test

sim:
	$(SIMULATOR) &

# monkeydo's exit code is unreliable; gate on the printed result summary.
test: test-build
	@$(MONKEYDO) bin/Stretches-tests.prg $(DEVICE) -t | tee bin/test-output.log; \
	grep -q "^PASSED" bin/test-output.log && ! grep -qE "^FAILED|^ERRORED" bin/test-output.log

package: key
	@mkdir -p dist
	$(MONKEYC) -e -f monkey.jungle -o dist/Stretches.iq -y $(KEY) -r -w

illustrations:
	python3 scripts/generate_illustrations.py

clean:
	rm -rf bin dist
