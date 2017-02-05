#!/bin/bash

pl1_wins=0
pl1_second=0

pl2_wins=0
pl2_second=0

pl3_wins=0
pl3_second=0

pl4_wins=0
pl4_second=0

for i in {1..100}
  do
    echo -ne "${i} \r"
    result=$(./runGame.sh)

    declare -a MYRA
    MYRA=($result)

    # test ${MYRA[9]} = "1" && ((pl1_wins++))
    # test ${MYRA[9]} = "2" && ((pl1_second++))

    # test ${MYRA[12]} = "1" && ((pl2_wins++))
    # test ${MYRA[12]} = "2" && ((pl2_second++))


    test ${MYRA[11]} = "1" && ((pl1_wins++))
    test ${MYRA[11]} = "2" && ((pl1_second++))

    test ${MYRA[14]} = "1" && ((pl2_wins++))
    test ${MYRA[14]} = "2" && ((pl2_second++))

    test ${MYRA[17]} = "1" && ((pl3_wins++))
    test ${MYRA[17]} = "2" && ((pl3_second++))


    # test ${MYRA[13]} = "1" && ((pl1_wins++))
    # test ${MYRA[13]} = "2" && ((pl1_second++))

    # test ${MYRA[16]} = "1" && ((pl2_wins++))
    # test ${MYRA[16]} = "2" && ((pl2_second++))

    # test ${MYRA[19]} = "1" && ((pl3_wins++))
    # test ${MYRA[19]} = "2" && ((pl3_second++))

    # test ${MYRA[22]} = "1" && ((pl4_wins++))
    # test ${MYRA[22]} = "2" && ((pl4_second++))
  done

echo
echo "Win	2nd	Name"
echo "$pl1_wins	$pl1_second	${MYRA[1]}"
echo "$pl2_wins	$pl2_second	${MYRA[3]}"
echo "$pl3_wins	$pl3_second	${MYRA[5]}"
# echo "$pl4_wins	$pl4_second	${MYRA[7]}"
