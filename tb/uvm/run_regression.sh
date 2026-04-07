#!/usr/bin/env bash

set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MAKE_CMD=(make -C "$SCRIPT_DIR")

SEED=${SEED:-1}
RUN_TIME=${RUN_TIME:-10s}
VERB=${VERB:-UVM_MEDIUM}
TB_TOP=${TB_TOP:-tb_top}
FILELIST=${FILELIST:-./filelist.f}
BUILD_NAME=${BUILD_NAME:-regression}

discover_tests() {
    find "$SCRIPT_DIR/tests" -maxdepth 1 -name '*_test.sv' -printf '%f\n' \
        | sed 's/\.sv$//' \
        | grep -v '^apb_spi_base_test$' \
        | sort
}

if [[ $# -gt 0 ]]; then
    TESTS=("$@")
else
    mapfile -t TESTS < <(discover_tests)
fi

if [[ ${#TESTS[@]} -eq 0 ]]; then
    echo "No runnable tests found under $SCRIPT_DIR/tests" >&2
    exit 1
fi

PASS_TESTS=()
FAIL_TESTS=()

run_log_has_failures() {
    local logfile=$1

    [[ -f "$logfile" ]] || return 0

    if grep -Eq 'UVM_(ERROR|FATAL) :[[:space:]]*[1-9][0-9]*' "$logfile"; then
        return 0
    fi

    if grep -q 'failed at ' "$logfile"; then
        return 0
    fi

    return 1
}

echo "Regression configuration:"
echo "  tests    : ${TESTS[*]}"
echo "  seed     : $SEED"
echo "  run_time : $RUN_TIME"
echo "  verbosity: $VERB"
echo "  build    : $BUILD_NAME"
echo "  switches : FSDB=1 COV=1 ASSERT=1 DEBUG=0"
echo

echo "============================================================"
echo "Building shared image"
echo "============================================================"

if ! "${MAKE_CMD[@]}" elab \
    SEED="$SEED" \
    VERB="$VERB" \
    TB_TOP="$TB_TOP" \
    FILELIST="$FILELIST" \
    BUILD_NAME="$BUILD_NAME" \
    FSDB=1 \
    COV=1 \
    ASSERT=1; then
    echo "Shared build failed"
    exit 1
fi

echo

for testname in "${TESTS[@]}"; do
    run_log="$SCRIPT_DIR/sim/run/${testname}_seed_${SEED}/log/run.log"

    echo "============================================================"
    echo "Running $testname"
    echo "============================================================"

    if "${MAKE_CMD[@]}" run \
        TESTNAME="$testname" \
        SEED="$SEED" \
        RUN_TIME="$RUN_TIME" \
        VERB="$VERB" \
        TB_TOP="$TB_TOP" \
        FILELIST="$FILELIST" \
        BUILD_NAME="$BUILD_NAME" \
        FSDB=1 \
        COV=1 \
        ASSERT=1 && ! run_log_has_failures "$run_log"; then
        PASS_TESTS+=("$testname")
        echo "[PASS] $testname"
    else
        FAIL_TESTS+=("$testname")
        echo "[FAIL] $testname"
    fi

    echo
done

echo "Regression summary:"
echo "  total  : ${#TESTS[@]}"
echo "  passed : ${#PASS_TESTS[@]}"
echo "  failed : ${#FAIL_TESTS[@]}"

if [[ ${#PASS_TESTS[@]} -gt 0 ]]; then
    echo "  pass list: ${PASS_TESTS[*]}"
fi

if [[ ${#FAIL_TESTS[@]} -gt 0 ]]; then
    echo "  fail list: ${FAIL_TESTS[*]}"
    exit 1
fi

exit 0
