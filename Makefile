BIN=.venv/bin/

setup:
	python -m venv .venv
	$(BIN)pip install jsonnet mypy
	$(BIN)mypy --install-types
	
clean:
	rm -rf .venv