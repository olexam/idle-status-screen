# idle-status-screen
DESTDIR ?=
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
LIBEXECDIR ?= $(PREFIX)/libexec/idle-status
UNITDIR ?= $(PREFIX)/lib/systemd/system
SYSUSERSDIR ?= $(PREFIX)/lib/sysusers.d
XORGCONFDIR ?= $(PREFIX)/share/X11/xorg.conf.d
PRESETDIR ?= $(PREFIX)/lib/systemd/system-preset

DEB_IMAGE ?= debian:trixie

.PHONY: all check install deb deb-docker clean

all:

check:
	python3 -m py_compile src/idle-status-watcher && rm -rf src/__pycache__
	for f in src/idle-status-monitor src/idle-status-display src/idle-status-attach; do sh -n $$f || exit 1; done
	@if command -v shellcheck >/dev/null; then \
		shellcheck src/idle-status-monitor src/idle-status-display src/idle-status-attach; \
	else echo "shellcheck not installed, skipping"; fi

install:
	install -Dm755 src/idle-status-watcher  $(DESTDIR)$(LIBEXECDIR)/watcher
	install -Dm755 src/idle-status-monitor  $(DESTDIR)$(LIBEXECDIR)/monitor
	install -Dm755 src/idle-status-display  $(DESTDIR)$(LIBEXECDIR)/display
	install -Dm755 src/idle-status-attach   $(DESTDIR)$(LIBEXECDIR)/attach
	install -Dm644 conf/idle-status.default $(DESTDIR)$(SYSCONFDIR)/default/idle-status
	install -Dm644 conf/btop.conf           $(DESTDIR)$(SYSCONFDIR)/idle-status/btop.conf
	install -Dm644 conf/tmux.conf           $(DESTDIR)$(SYSCONFDIR)/idle-status/tmux.conf
	install -Dm644 conf/sysusers.conf       $(DESTDIR)$(SYSUSERSDIR)/idle-status-screen.conf
	install -Dm644 conf/10-idle-status-noblank.conf $(DESTDIR)$(XORGCONFDIR)/10-idle-status-noblank.conf
	install -Dm644 systemd/80-idle-status-screen.preset $(DESTDIR)$(PRESETDIR)/80-idle-status-screen.preset
	install -Dm644 -t $(DESTDIR)$(UNITDIR) systemd/idle-status-monitor.service \
		systemd/idle-status-display.service systemd/idle-status-watcher.service

# Build the .deb natively (needs dpkg-dev and debhelper); result goes to dist/
deb:
	dpkg-buildpackage -b -us -uc
	mkdir -p dist && mv ../idle-status-screen_*.deb ../idle-status-screen_*.buildinfo ../idle-status-screen_*.changes dist/

# Build the .deb inside a Debian container (needs docker); result goes to dist/
deb-docker:
	docker run --rm -v "$(CURDIR)":/src -w /build $(DEB_IMAGE) sh -c '\
		apt-get update -qq && \
		apt-get install -y -qq --no-install-recommends build-essential debhelper >/dev/null && \
		cp -a /src /build/idle-status-screen && cd /build/idle-status-screen && \
		make deb && mkdir -p /src/dist && cp dist/* /src/dist/ && \
		chown -R $(shell id -u):$(shell id -g) /src/dist'

clean:
	rm -rf dist src/__pycache__
