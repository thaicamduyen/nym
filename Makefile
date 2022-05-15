
# include .envs/.testpypi
include .envs/.pypi

.DEFAULT_GOAL := help

define BROWSER_PYSCRIPT
import os, webbrowser, sys

from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

PHONY: help
help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

PHONY: clean
clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

PHONY: clean-build
clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

PHONY: clean-pyc
clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

PHONY: clean-test
clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache
	rm -fr nim-extensions/

PHONY: lint/flake8
lint/flake8: ## check style with flake8
	flake8 nym tests

PHONY: lint/black
lint/black: ## check style with black
	black --check nym tests

PHONY: lint
lint: lint/flake8 lint/black ## check style

PHONY: test
test: ## run tests quickly with the default Python
	pytest

PHONY: test-all
test-all: ## run tests on every Python version with tox
	tox

PHONY: coverage
coverage: ## check code coverage quickly with the default Python
	coverage run --source nym -m pytest
	coverage report -m
	coverage html
	$(BROWSER) htmlcov/index.html

PHONY: docs
docs: ## generate Sphinx HTML documentation, including API docs
	rm -f docs/nym.rst
	rm -f docs/modules.rst
	sphinx-apidoc -o docs/ nym
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

PHONY: servedocs
servedocs: docs ## compile the docs watching for changes
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

PHONY: release
release: dist ## package and upload a release
	twine upload --non-interactive --skip-existing -r pypi -u __token__ dist/*

PHONY: release-sandbox
release-sandbox: dist
	twine upload --non-interactive --skip-existing -r testpypi -u __token__ dist/*

PHONY: dist
dist: clean ## builds source and wheel package
	python setup.py sdist
	python setup.py bdist_wheel
	python -c 'import os, glob; w=glob.glob("dist/*.whl")[0]; os.rename(w, w.replace("linux", "manylinux1"))'
	ls -l dist

.PHONY: format
format:
	isort nym
	black nym

.PHONY: pre-commit
pre-commit:
	pre-commit run --all-files

.PHONY: bumpversion
bumpversion:
	bump2version --current-version 0.1.1 patch
