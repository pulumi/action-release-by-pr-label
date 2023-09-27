ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

lint:
	"${ROOT_DIR}lint/shfmt.sh" "${ROOT_DIR}"
	"${ROOT_DIR}lint/shellcheck.sh" "${ROOT_DIR}"
	"${ROOT_DIR}lint/actionlint.sh" "${ROOT_DIR}"

test:
	bats --trace --print-output-on-failure "${ROOT_DIR}test/"

.PHONY: lint test
