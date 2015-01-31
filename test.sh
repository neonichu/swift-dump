#!/bin/sh

symbols() {
	xcrun nm -g "$1"|awk '{print $3}'|grep '^__T'|sort|uniq
}

trap 'rm -f test main *.syms' EXIT
set -e

xcrun -sdk macosx swiftc test.swift
./swift-dump.rb test|xcrun -sdk macosx swiftc -

symbols test >test.syms
symbols main|sed 's/4main/4test/g' >main.syms
diff test.syms main.syms
