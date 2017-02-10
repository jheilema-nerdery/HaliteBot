#!/bin/bash
bot_starter=ruby
usage="halite game runner\n\n"
usage+="usage: runner.sh [-d <dimensions>] [-s <seed>] [-r <num>] [-2..6 <bot>] [-b <bot>] [..] [-b <bot>]\n\n"
usage+="options:\n"
usage+="    -b      bot filename\n"
usage+="    -d      dimensions (default: \"25 25\")\n"
usage+="    -s      seed\n"
usage+="    -r      number of trials to run (default: 1)\n"
usage+="    -2..6   run N copies of this bot, e.g. -3 OverkillBot.py\n"
usage+="\nexamples:\n"
usage+="    runner.sh -b MyBot.py -b OverkillBot.py\n"
usage+="    runner.sh -b MyBot.py -2 OverkillBot.py\n"
usage+="    runner.sh -d \"30 30\" MyBot.py\n"
dimensions="25 25"
num_trials=1
while getopts ":b:d:s:r:2:3:4:5:6:" opt
do
    case $opt in
        b  ) bots+=("$OPTARG")      ;;
        d  ) dimensions="$OPTARG"   ;;
        s  ) seed="-s $OPTARG"      ;;
        r  ) num_trials=$OPTARG     ;;
        2  ) bot2+=($OPTARG)        ;;
        3  ) bot3+=($OPTARG)        ;;
        4  ) bot4+=($OPTARG)        ;;
        5  ) bot5+=($OPTARG)        ;;
        6  ) bot6+=($OPTARG)        ;;
        \? ) echo -e "$usage"
             exit 1
    esac
done
shift $(($OPTIND - 1))
contestants="${bots[@]} ${bot2[@]} ${bot2[@]} ${bot3[@]} ${bot3[@]} ${bot3[@]} ${bot4[@]} ${bot4[@]} ${bot4[@]} ${bot4[@]} ${bot5[@]} ${bot5[@]} ${bot5[@]} ${bot5[@]} ${bot5[@]} ${bot6[@]} ${bot6[@]} ${bot6[@]} ${bot6[@]} ${bot6[@]} ${bot6[@]}"
if [[ "$contestants" =~ ^[[:space:]]+$ ]]; then
    echo -e "$usage"
    exit 1
fi
bots=($contestants)
contestants=""
for bot in ${bots[@]}; do
    contestants+="\"$bot_starter $bot\" "
done
trial_log=$(find . -name "trial-run*.log")
if [[ -n $trial_log ]]; then
    rm trial-run*.log
fi
logfile=trial-run-$(date +"%Y%m%d-%I%M%S").log
for i in $(seq 1 $num_trials); do
    if [ $num_trials -eq 1 ]; then
        eval ./halite -d "\"$dimensions\"" $seed "$contestants"
    else
        eval ./halite -d "\"$dimensions\"" $seed "$contestants" | grep '^Player' >> $logfile
    fi
    if [ -e games ]; then
        mv *.hlt games
        cd games
        if [ $(ls | wc -l) -gt 10 ]; then
            ls -rt *hlt | head -5 | xargs rm
        fi
        cd ..
    fi
    if [ $num_trials -gt 1 ]; then
        leader=$(grep 'rank #1' $logfile | sed -E 's/^[^,]+, ([^,]+),.*$/\1/' | sort | uniq -c | sort -r | head -1)
        echo -ne "   $i of $num_trials $leader                      \r"
    fi
done
error_log=$(find . -name "[0-9]-*.log")
if [[ -n $error_log ]]; then
    cat [0-9]-*.log
    rm [0-9]-*.log
fi
if [ $num_trials -gt 1 ]; then
    echo -e "\nwins:"
    grep 'rank #1' $logfile | sed -E 's/^[^,]+, ([^,]+),.*$/\1/' | sort | uniq -c | sort -r
fi
