build:
	swift build -c debug --arch arm64 --arch x86_64
	@cp .build/apple/Products/Debug/MQVMRunner ./

test:
	swift test -c debug --arch arm64

install:
	@if ! which swift >/dev/null 2>&1; then \
		echo "Xcode not found; using prebuilt binary..."; \
	else \
		$(MAKE) build; \
	fi
	@sh install.sh
