#!/bin/sh

symbols() {
	xcrun nm -g "$1"|awk '{print $3}'|grep '^__T'|sort|uniq
}

run_test() {
	xcrun -sdk macosx swiftc "$1.swift"
	./swift-dump.rb "$1"|xcrun -sdk macosx swiftc -

	symbols "$1" >"$1.syms"
	symbols main|sed "s/4main/${#1}$1/g" >main.syms
	diff "$1.syms" main.syms
}

trap 'rm -f f test main *.syms' EXIT
set -e

run_test "test"
run_test "f"
