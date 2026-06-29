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
COV=${COV:-1}
FSDB=${FSDB:-0}
ASSERT=${ASSERT:-1}
DEBUG=${DEBUG:-0}
REGRESSION_SUITE=${REGRESSION_SUITE:-normal}

# Normal suite: legal, spec-compliant tests. This is the default signoff path.
NORMAL_TESTS=(
    smoke_test
    cold_reset_test
    soft_reset_test
    apb_reg_access_test
    apb_reg_semantics_test
    apb_back_to_back_test
    clkdiv_test
    mode_sweep_test
    cont_mode_test
    tx_rx_en_control_test
    start_rejection_test
    fifo_basic_test
    fifo_boundary_test
    irq_basic_test
    irq_clear_priority_test
    irq_stress_test
    pslverr_test
    cfg_cross_coverage_test
)

# Corner scenarios: deliberately abnormal or coverage-closure stimuli.
# Format:
#   scenario_name|testname|assert|run_tag|user_sim_opts|description
CORNER_SCENARIOS=(
    "raw_apb_unselected|pslverr_test|0|_raw_apb_unselected|+RAW_APB_UNSELECTED|APB protocol-negative psel=0/penable=1 access"
)

usage() {
    cat <<'USAGE'
Usage:
  ./run_regression.sh [test ...]

Environment:
  REGRESSION_SUITE=normal|corner|all   Select regression suite. Default: normal.
  SEED=<n> RUN_TIME=<time> VERB=<uvm_verbosity>
  BUILD_NAME=<name> COV=0|1 FSDB=0|1 ASSERT=0|1 DEBUG=0

Notes:
  - normal: legal spec-compliant tests, ASSERT defaults to 1.
  - corner: abnormal/coverage-closure scenarios, each scenario owns its
            assertion setting, plusargs, build suffix, and run tag.
  - Positional test arguments override NORMAL_TESTS and run as a normal ad-hoc
    list. Corner scenarios are selected only by REGRESSION_SUITE=corner|all.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

validate_known_tests() {
    local testname

    for testname in "$@"; do
        if [[ ! -f "$SCRIPT_DIR/tests/${testname}.sv" ]]; then
            echo "Unknown test: $testname" >&2
            echo "Expected file: $SCRIPT_DIR/tests/${testname}.sv" >&2
            exit 1
        fi
        if [[ "$testname" == "apb_spi_base_test" ]]; then
            echo "Base test is not directly runnable: $testname" >&2
            exit 1
        fi
    done
}

PASS_ITEMS=()
FAIL_ITEMS=()

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

build_image() {
    local build_name=$1
    local assert=$2
    local label=$3

    echo "============================================================"
    echo "Building $label image: $build_name ASSERT=$assert"
    echo "============================================================"

    "${MAKE_CMD[@]}" elab \
        SEED="$SEED" \
        VERB="$VERB" \
        TB_TOP="$TB_TOP" \
        FILELIST="$FILELIST" \
        BUILD_NAME="$build_name" \
        FSDB="$FSDB" \
        COV="$COV" \
        ASSERT="$assert" \
        DEBUG="$DEBUG"
}

run_one() {
    local item_name=$1
    local testname=$2
    local build_name=$3
    local assert=$4
    local run_tag=$5
    local user_sim_opts=$6
    local run_log="$SCRIPT_DIR/sim/run/${testname}_seed_${SEED}${run_tag}/log/run.log"

    echo "============================================================"
    echo "Running $item_name"
    echo "  test      : $testname"
    echo "  build     : $build_name"
    echo "  assert    : $assert"
    echo "  run_tag   : ${run_tag:-<none>}"
    echo "  plusargs  : ${user_sim_opts:-<none>}"
    echo "============================================================"

    if "${MAKE_CMD[@]}" run \
        TESTNAME="$testname" \
        SEED="$SEED" \
        RUN_TIME="$RUN_TIME" \
        VERB="$VERB" \
        TB_TOP="$TB_TOP" \
        FILELIST="$FILELIST" \
        BUILD_NAME="$build_name" \
        RUN_TAG="$run_tag" \
        FSDB="$FSDB" \
        COV="$COV" \
        ASSERT="$assert" \
        DEBUG="$DEBUG" \
        USER_SIM_OPTS="$user_sim_opts" && ! run_log_has_failures "$run_log"; then
        PASS_ITEMS+=("$item_name")
        echo "[PASS] $item_name"
    else
        FAIL_ITEMS+=("$item_name")
        echo "[FAIL] $item_name"
    fi

    echo
}

run_normal_suite() {
    local tests=("$@")

    if [[ ${#tests[@]} -eq 0 ]]; then
        tests=("${NORMAL_TESTS[@]}")
    fi

    validate_known_tests "${tests[@]}"

    build_image "$BUILD_NAME" "$ASSERT" "normal" || {
        echo "Normal suite build failed"
        exit 1
    }

    echo

    local testname
    for testname in "${tests[@]}"; do
        run_one "normal/$testname" "$testname" "$BUILD_NAME" "$ASSERT" "" "${USER_SIM_OPTS:-}"
    done
}

run_corner_suite() {
    local scenario testname scenario_assert run_tag user_sim_opts description build_name

    for entry in "${CORNER_SCENARIOS[@]}"; do
        IFS='|' read -r scenario testname scenario_assert run_tag user_sim_opts description <<< "$entry"
        validate_known_tests "$testname"

        build_name="${BUILD_NAME}_${scenario}"
        build_image "$build_name" "$scenario_assert" "corner/$scenario" || {
            echo "Corner scenario build failed: $scenario"
            exit 1
        }

        echo "Corner description: $description"
        run_one "corner/$scenario" "$testname" "$build_name" "$scenario_assert" "$run_tag" "$user_sim_opts"
    done
}

echo "Regression configuration:"
echo "  suite    : $REGRESSION_SUITE"
echo "  seed     : $SEED"
echo "  run_time : $RUN_TIME"
echo "  verbosity: $VERB"
echo "  build    : $BUILD_NAME"
echo "  switches : FSDB=$FSDB COV=$COV ASSERT=$ASSERT DEBUG=$DEBUG"
if [[ $# -gt 0 ]]; then
    echo "  ad-hoc   : $*"
fi
echo

case "$REGRESSION_SUITE" in
    normal)
        run_normal_suite "$@"
        ;;
    corner)
        if [[ $# -gt 0 ]]; then
            echo "Positional test override is only supported for REGRESSION_SUITE=normal" >&2
            exit 1
        fi
        run_corner_suite
        ;;
    all)
        if [[ $# -gt 0 ]]; then
            echo "Positional test override is only supported for REGRESSION_SUITE=normal" >&2
            exit 1
        fi
        run_normal_suite
        run_corner_suite
        ;;
    *)
        echo "Unsupported REGRESSION_SUITE=$REGRESSION_SUITE" >&2
        usage >&2
        exit 1
        ;;
esac

echo "Regression summary:"
echo "  total  : $(( ${#PASS_ITEMS[@]} + ${#FAIL_ITEMS[@]} ))"
echo "  passed : ${#PASS_ITEMS[@]}"
echo "  failed : ${#FAIL_ITEMS[@]}"

if [[ ${#PASS_ITEMS[@]} -gt 0 ]]; then
    echo "  pass list: ${PASS_ITEMS[*]}"
fi

if [[ ${#FAIL_ITEMS[@]} -gt 0 ]]; then
    echo "  fail list: ${FAIL_ITEMS[*]}"
    exit 1
fi

exit 0
