#!/bin/bash

pl1_wins=0
pl1_second=0
pl2_wins=0
pl2_second=0
pl3_wins=0
pl3_second=0
test1_wins=0
test1_second=0
test2_wins=0
test2_second=0
test3_wins=0
test3_second=0

count=${1:-50}


for (( i=1; i<=$count; i++ ))
do
    echo -ne "${i}       \r"
    result=$(./halite -q -d '30 30' "ruby files/bot_mk14/MyBot.rb" "ruby files/bot_mk13/MyBot.rb" "ruby files/bot_mk12/MyBot.rb")

    declare -a MYRA
    MYRA=($result)

    test ${MYRA[11]} = "1" && ((pl1_wins++))
    test ${MYRA[11]} = "2" && ((pl1_second++))
    test ${MYRA[14]} = "1" && ((pl2_wins++))
    test ${MYRA[14]} = "2" && ((pl2_second++))
    test ${MYRA[17]} = "1" && ((pl3_wins++))
    test ${MYRA[17]} = "2" && ((pl3_second++))

    echo -ne "${i} test \r"
    result=$(./halite -q -s ${MYRA[9]} -d '30 30' "ruby files/bot_mk14_test/MyBot.rb" "ruby files/bot_mk13/MyBot.rb" "ruby files/bot_mk12/MyBot.rb")

    declare -a TEST
    TEST=($result)

    test ${TEST[11]} = "1" && ((test1_wins++))
    test ${TEST[11]} = "2" && ((test1_second++))
    test ${TEST[14]} = "1" && ((test2_wins++))
    test ${TEST[14]} = "2" && ((test2_second++))
    test ${TEST[17]} = "1" && ((test3_wins++))
    test ${TEST[17]} = "2" && ((test3_second++))
done

echo
echo "Base"
echo "Win	2nd	Name"
echo "$pl1_wins	$pl1_second	${MYRA[1]}"
echo "$pl2_wins	$pl2_second	${MYRA[3]}"
echo "$pl3_wins	$pl3_second	${MYRA[5]}"

echo "Test"
echo "Win	2nd	Name"
echo "$test1_wins	$test1_second	${TEST[1]}"
echo "$test2_wins	$test2_second	${TEST[3]}"
echo "$test3_wins	$test3_second	${TEST[5]}"
