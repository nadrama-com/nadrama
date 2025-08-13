#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0

set -eo pipefail

CURRENT=$(dirname "$(readlink -f "$0")")

# Check if kyverno CLI is available
if ! command -v kyverno &> /dev/null; then
    echo "Error: kyverno CLI is not installed or not in PATH"
    echo "Please install kyverno CLI to run these tests (e.g. brew install kyverno)"
    echo "NOTE: until https://github.com/kyverno/kyverno/issues/13829 is fixed,"
    echo "you must install the fork at https://github.com/nadrama-com/kyverno/tree/fix-13829"
    exit 1
fi
# note there are two more bugs to fix to ensure these tests pass correctly:
# https://github.com/kyverno/kyverno/blob/main/pkg/admissionpolicy/validate.go#L139
# 1. `resource.GetNamespace()` should be `namespaceName`
# 2. `admission.Create` should a property on the test table e.g. system-vap should be admission.Delete

# Run table-driven tests for VAP policies using Kyverno CLI
echo "Running tests via kyverno CLI..."
echo ""

# Run each test file individually
for test_file in "${CURRENT}/tests"/*.yaml; do
    if [[ -f "$test_file" ]]; then
        test_name=$(basename "$test_file")
        printf "%0.s-" {1..80} && printf "%0.s\n" {1..2}
        echo "Running test: $test_name"
        CMD="kyverno test ${CURRENT}/tests --file-name $test_name --detailed-results"
        echo $CMD
        ${CMD}
    fi
done

# If no tests failed, print success message
echo "All tests passed."
