#!/bin/bash

# ./halite -q  -d '30 30'\
#             "ruby files/gold/MyBot.rb" \
#             "ruby files/bot_mk12/MyBot.rb" \
#             "ruby files/bot_mk13/MyBot.rb" \
#             "ruby files/bot_mk11/MyBot.rb"

./halite -q -d '25 25' "ruby files/hungry_v5/MyBot.rb" "python3 ./files/shummie/shummiev85.py" "ruby files/bot_mk13/MyBot.rb" "ruby files/bot_mk11/MyBot.rb"

# ./halite -q -d '30 30'\
#             "ruby files/bot_mk13/MyBot.rb" \
#             "ruby files/bot_mk12/MyBot.rb"

# ./halite -d '20 20' "ruby files/bot_mk11/MyBot.rb" \
#           "ruby files/bot_mk9/MyBot.rb"

# ./halite -q  \
#             "ruby files/bot_mk13/MyBot.rb" \
#             "ruby files/bot_mk8/MyBot.rb" \
#             "ruby files/crashy/MyBot.rb"
