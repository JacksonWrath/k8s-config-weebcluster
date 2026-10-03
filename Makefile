BIN=.venv/bin/

setup:
	python -m venv .venv
	$(BIN)pip install jsonnet mypy requests
	$(BIN)mypy --install-types

setup_done:
	@if [ ! -d ".venv" ]; then echo "You need to run make without arguments first!"; fi

clean:
	rm -rf .venv

update: setup_done
	scripts/update_check

.PHONY: minikube-start minikube-stop minikube-setup minikube-delete

minikube-start:
	minikube start \
		-p miniweeb \
		--driver=docker \
		--static-ip=192.168.49.100 \
		--apiserver-port=6443 \
		--apiserver-names=api.miniweeb.local

minikube-stop:
	minikube stop -p miniweeb

minikube-setup:
	@# Sets up the minikube cluster and host configuration
	@# Can override helm-controller version with HELM_CONTROLLER_VERSION
	./scripts/minikube_setup.sh

minikube-delete:
	minikube delete -p miniweeb
	@echo "\n--- Cleaning Host Configuration ---"
	@echo "Removing api.miniweeb.local from /etc/hosts (requires sudo)"
	@sudo sed -i '' '/miniweeb.local/d' /etc/hosts || true
	@if [ -f /etc/resolver/miniweeb.local ]; then \
		echo "Removing /etc/resolver/miniweeb.local (requires sudo)"; \
		sudo rm /etc/resolver/miniweeb.local; \
	fi

