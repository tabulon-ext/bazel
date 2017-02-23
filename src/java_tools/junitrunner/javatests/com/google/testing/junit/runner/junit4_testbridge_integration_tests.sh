#!/bin/bash
#
# Copyright 2015 The Bazel Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Integration testing of the test bridge protocol for JUnit4 tests.
# This is a test filter passed by "bazel test --test_filter".
#
# These tests operate by executing test methods in a testbed program
# and checking the output.
#

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

TESTBED="${PWD}/$1"
SUITE_PARAMETER="$2"
TESTBED_LIB_LOCATION="${PWD}/$3"
SUITE_FLAG="-D${SUITE_PARAMETER}=com.google.testing.junit.runner.testbed.JUnit4TestbridgeExercises"
XML_OUTPUT_FILE="${TEST_TMPDIR}/test.xml"

shift 2
source ${DIR}/testenv.sh || { echo "testenv.sh not found!" >&2; exit 1; }

#######################

function set_up() {
  # By default, the environment flag is unset.
  declare +x TESTBRIDGE_TEST_ONLY
}

# Test that we respond to TESTBRIDGE_TEST_ONLY in JUnit4 tests.
function test_Junit4() {
  cd $TEST_TMPDIR

  # Pass the test target classpath through the environment variable
  declare -x TEST_TARGET_CLASSPATH="$TESTBED_LIB_LOCATION"

  # Run the test without environment flag; it should fail.
  declare +x TESTBRIDGE_TEST_ONLY
  $TESTBED --jvm_flag=${SUITE_FLAG} >& $TEST_log && fail "Expected failure"
  expect_log 'Failures: 1'

  # Run the test with environment flag.
  declare -x TESTBRIDGE_TEST_ONLY="doRun"
  $TESTBED --jvm_flag=${SUITE_FLAG} >& $TEST_log || fail "Expected success"
  expect_log 'OK.*1 test'

  # Finally, run the test once again without environment flag; it should fail.
  declare +x TESTBRIDGE_TEST_ONLY
  $TESTBED --jvm_flag=${SUITE_FLAG} >& $TEST_log && fail "Expected failure again"
  expect_log 'Failures: 1'

  # Remove the XML output with failures, so it does not get picked up to
  # indicate a failure.
  rm -rf "${XML_OUTPUT_FILE}" || fail "failed to remove XML output"
}

# Test that TESTBRIDGE_TEST_ONLY is overridden by a direct flag.
function test_Junit4FlagOverridesEnv() {
  cd $TEST_TMPDIR

  # Pass the test target classpath through the environment variable
  declare -x TEST_TARGET_CLASSPATH="$TESTBED_LIB_LOCATION"

  # Run the test with both environment and command line flags.
  declare -x TESTBRIDGE_TEST_ONLY="doNotRun"
  $TESTBED --jvm_flag=${SUITE_FLAG} --test_filter doRun >& $TEST_log || \
      fail "Expected success"
  expect_log 'OK.*1 test'

  declare -x TESTBRIDGE_TEST_ONLY="doRun"
  $TESTBED --jvm_flag=${SUITE_FLAG} --test_filter doNotRun >& $TEST_log && \
      fail "Expected failure"
  expect_log 'Failures: 1'
}

run_suite "testbridge_test_only"
