APP := dist/Awake.app

.PHONY: build run clean

build:
	./scripts/build-app.sh

run: build
	@pkill -x Awake || true
	open $(APP)

clean:
	rm -rf .build dist
