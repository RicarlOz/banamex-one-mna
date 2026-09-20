.PHONY: install lint format test eval pipeline

install:
	pip install -e ".[dev]"
	pre-commit install

lint:
	ruff check src tests

format:
	ruff format src tests

test:
	pytest

eval:
	python -m evals.run

pipeline:
	dvc repro
