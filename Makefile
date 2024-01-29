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

diff:
	for app in `ls tanka/environments`; do \
		echo "---- $$app diff ----"; \
		PAGER="" tk diff -z tanka/environments/$$app; \
	done

apply:
	@for app in `ls tanka/environments`; do \
		echo "------ checking $$app ------"; \
		PAGER="" tk diff tanka/environments/$$app > /dev/null 2>&1 || tk apply tanka/environments/$$app; \
	done