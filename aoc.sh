#!/bin/sh

USAGE="Usage: ./aoc.sh [-d] [-t] NNa\n\n  -d: compile in debug mode\n  -t: use test input"
SUFFIX=".txt"
OPTIMIZE="ReleaseSafe"

while getopts dt o
do
    case $o in
        d) OPTIMIZE="Debug";;
        t) SUFFIX=".test.txt";;
        \?) echo "$USAGE"; exit 1;;
    esac
done
shift $(("$OPTIND" - 1))

DAY="${1:?No day provided}"
DAY_NUMBER_ONLY=$(echo "$DAY" | sed 's/[a-z]//')

if [ -e "input/${DAY}${SUFFIX}" ]
then
    INPUT="input/${DAY}${SUFFIX}"
else
    INPUT="input/${DAY_NUMBER_ONLY}${SUFFIX}"
fi

zig build "-Doptimize=$OPTIMIZE" "run-day${DAY}" <"$INPUT"
