BIN=.venv/bin/

setup:
	python -m venv .venv
	$(BIN)pip install jsonnet mypy
	$(BIN)mypy --install-types

setup_done:
	@if [ ! -d ".venv" ]; then echo "You need to run make without arguments first!"; fi

clean:
	rm -rf .venv

update: setup_done
	scripts/update_check
	git -P diff