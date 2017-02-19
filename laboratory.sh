#!/bin/bash

pl1_wins=0
pl1_second=0
pl2_wins=0
pl2_second=0
pl3_wins=0
pl3_second=0
pl4_wins=0
pl4_second=0
test1_wins=0
test1_second=0
test2_wins=0
test2_second=0
test3_wins=0
test3_second=0
test4_wins=0
test4_second=0

count=${1:-50}


for (( i=1; i<=$count; i++ ))
do
    echo -ne "${i}       \r"
    result=$(./halite -q -d '25 25' "ruby files/hungry/MyBot.rb" "python3 ./files/shummie/shummiev85.py" "ruby files/bot_mk13/MyBot.rb" "ruby files/bot_mk11/MyBot.rb")

    declare -a MYRA
    MYRA=($result)

    test ${MYRA[13]} = "1" && ((pl1_wins++))
    test ${MYRA[13]} = "2" && ((pl1_second++))
    test ${MYRA[16]} = "1" && ((pl2_wins++))
    test ${MYRA[16]} = "2" && ((pl2_second++))
    test ${MYRA[19]} = "1" && ((pl3_wins++))
    test ${MYRA[19]} = "2" && ((pl3_second++))
    test ${MYRA[22]} = "1" && ((pl4_wins++))
    test ${MYRA[22]} = "2" && ((pl4_second++))

    echo -ne "${i} test \r"
    result=$(./halite -q -s ${MYRA[11]} -d '25 25' "python3 ./files/erdman/erdman_v26.py" "python3 ./files/shummie/shummiev85.py" "ruby files/bot_mk13/MyBot.rb" "ruby files/bot_mk11/MyBot.rb")

    declare -a TEST
    TEST=($result)

    test ${TEST[13]} = "1" && ((test1_wins++))
    test ${TEST[13]} = "2" && ((test1_second++))
    test ${TEST[16]} = "1" && ((test2_wins++))
    test ${TEST[16]} = "2" && ((test2_second++))
    test ${TEST[19]} = "1" && ((test3_wins++))
    test ${TEST[19]} = "2" && ((test3_second++))
    test ${TEST[22]} = "1" && ((test4_wins++))
    test ${TEST[22]} = "2" && ((test4_second++))

    test ${MYRA[13]} = ${TEST[13]} && test ${MYRA[16]} = ${TEST[16]} && rm ${TEST[10]} && rm ${MYRA[10]}
done

echo
echo "Base"
echo "Win	2nd	Name"
echo "$pl1_wins	$pl1_second	${MYRA[1]}"
echo "$pl2_wins	$pl2_second	${MYRA[3]}"
echo "$pl3_wins	$pl3_second	${MYRA[5]}"
echo "$pl4_wins	$pl4_second	${MYRA[7]}"

echo "Test"
echo "Win	2nd	Name"
echo "$test1_wins	$test1_second	${TEST[1]}"
echo "$test2_wins	$test2_second	${TEST[3]}"
echo "$test3_wins	$test3_second	${TEST[5]}"
echo "$test4_wins	$test4_second	${TEST[7]}"
