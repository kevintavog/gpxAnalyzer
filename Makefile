# In case I don't remember these commands...

build:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

test:
	swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

release-build:
	swift build -c release -Xswiftc -static-stdlib -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

update:
	swift package update
