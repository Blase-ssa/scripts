#!/bin/bash

_get_input(){
  local input
  if [[ -n "$1" ]]; then
    # передан как аргумент
    input="$1"
  elif [[ ! -t 0 ]]; then
    # передан через пайп
    input="$(cat)"
  else
    echo "No input provided" >&2
    return 1
  fi
  printf '%s' "$input"
}

f2() {
  local input
  input="$(_get_input "$1")" || return 1
  echo "${input}"
}

echo "test 1: pipe, direct"| _get_input
echo
_get_input "test 2: arg, direct"
echo
echo "test 3: pipe --> f2"| f2
f2 "test 4: arg --> f2"
echo "test 5: no input '$(f2)'"
echo "test 6: pipe "|f2 "and arg"
