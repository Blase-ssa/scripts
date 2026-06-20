#!/usr/bin/env bats

# Подключаем библиотеку, которую тестируем
setup() {
  source "../lib/awg-functions.lib.sh"
}

@test "returns argument when provided" {
  run get_input "ARG_VALUE"
  assert_success
  assert_output "ARG_VALUE"
}

@test "returns piped input when no argument" {
  run bash -c 'echo "PIPE_VALUE" | get_input'
  assert_success
  assert_output "PIPE_VALUE"
}

@test "argument has priority over pipe" {
  run bash -c 'echo "PIPE_VALUE" | get_input "ARG_VALUE"'
  assert_success
  assert_output "ARG_VALUE"
}

@test "fails when no input provided" {
  run get_input
  assert_failure
}

@test "works inside wrapper function (pipe)" {
  run bash -c '
    source "../lib/awg-functions.lib.sh"
    f2() {
      local input
      input="$(get_input "$1")" || return 1
      echo "$input"
    }
    echo "PIPE_F2" | f2
  '
  assert_success
  assert_output "PIPE_F2"
}

@test "works inside wrapper function (argument)" {
  run bash -c '
    source "../lib/awg-functions.lib.sh"
    f2() {
      local input
      input="$(get_input "$1")" || return 1
      echo "$input"
    }
    f2 "ARG_F2"
  '
  assert_success
  assert_output "ARG_F2"
}

@test "wrapper returns error when no input" {
  run bash -c '
    source "./lib/awg-functions.lib.sh"
    f2() {
      local input
      input="$(get_input "$1")" || return 1
      echo "$input"
    }
    f2
  '
  assert_failure
}