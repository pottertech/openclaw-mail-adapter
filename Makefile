.PHONY: install test clean

SKILL_DIR ?= $(HOME)/.openclaw/skills/openclaw-mail-adapter
CONFIG_DIR ?= $(HOME)/.config/openclaw-mail-adapter

install:
	@echo "Installing openclaw-mail-adapter..."
	mkdir -p $(SKILL_DIR)
	cp -r src bin tests docs README.md SKILL.md Makefile $(SKILL_DIR)/
	chmod +x $(SKILL_DIR)/bin/mail-adapter
	chmod +x $(SKILL_DIR)/src/*.sh
	chmod +x $(SKILL_DIR)/tests/*.sh
	mkdir -p $(CONFIG_DIR)
	@echo "Install complete: $(SKILL_DIR)"

test:
	@echo "Running tests..."
	bash tests/test-send.sh
	@echo "Tests complete"

clean:
	@echo "Cleaning temporary files..."
	rm -f src/*.tmp
	rm -f audit.log
	@echo "Clean complete"

uninstall:
	@echo "Removing openclaw-mail-adapter..."
	rm -rf $(SKILL_DIR)
	@echo "Uninstall complete"

status:
	@echo "Checking installation..."
	@test -d $(SKILL_DIR) && echo "Installed: $(SKILL_DIR)" || echo "Not installed"
	@test -d $(CONFIG_DIR) && echo "Config: $(CONFIG_DIR)" || echo "No config dir"
	@which msmtp >/dev/null && echo "msmtp: OK" || echo "msmtp: MISSING"
	@which mbsync >/dev/null && echo "mbsync: OK" || echo "mbsync: MISSING"
	@which notmuch >/dev/null && echo "notmuch: OK" || echo "notmuch: MISSING"