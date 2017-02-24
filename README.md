# [Halite](https://halite.io/)

Whew! It's over. Or at least, it WAS over for most people about a week ago. I've delayed releasing my bot because my company is running a private server this week for our own competition. Don't want to give anybody an edge; our deadline for bot submission was the morning of Monday February 20, with final outcomes on Friday, February 24. 

This has been a bit of a whirlwind few weeks. I found out about this because... my company is running a private competition. :) We got the email on January 30, and my life has been all downhill from there. 

Thanks to the organizers, Two Sigma, particularly @truell and @sydriax for their amazing hard work on this project. Thanks to Josh Klun for sending out the email and running the Nerdery server. Thanks to @nmalaguti for the excellent tuturial that really ramped me up quickly on the basics. Thanks to the competitors who released their code after the competition was over and all the amazing writeups; it really helped me to clarify my thinking.

# Bot overview

Bots Mark 1-6(ish) are the process of me working through [improving the random bot](https://halite.io/basics_improve_random.php) and [nmalaguti's tutorial](http://forums.halite.io/t/so-youve-improved-the-random-bot-now-what/482). Pretty straightforward. I believe Mark 6 ended up around the mid-400s.

## Mark 7, 8, 9: Aware of my surroundings

Mark 7 is a bit of a refactor, and starts to lean on OO design a little more. I start to maintain a single map instance over the course of the game, rather than reinitializing it every turn. Each turn it just gets updated with new owner and strength values. Along the same vein, Site objects are maintained across turns in memory as well, and get their owner/strength values updated each turn. I also added the concept of 'neighbors'. Each Neighbor object is a decorator around a site instance, with knowledge of which 'direction' it is a neighbor from. On game start up, sites are initialized, then all sites are looped through and assigned their direct neighbors:

    . n .
    w o e
    . s .

Each neighbor holds a reference to the site that it's on, and the direction it 'moved' to get to the current location. So for example, if the 'o' in the map above is the site we're considering, and it's at location x: 0 y: 0, it has four neighbors:

```ruby
site.neighbors
#=> { north: <Neighbor site(x: 0, y: 1)  direction: :north>, 
      east:  <Neighbor site(x: 1, y: 0) direction: :east>,
      south: <Neighbor site(x: 0, y: -1)  direction: :south>, 
      west:  <Neighbor site(x: -1, y: 0)  direction: :west> }
```

It's essentially a recursive tree of all the locations on the map. If you wanted to, you can ask a site for its neighbors, and the neighbors for their neighbors, etc, etc, etc. There's only one Site object for each location on the map, but there can be multiple Neighbors in existance for any given (x,y) coordinate.

This allowed me to create a rather 'dumb' decisionmaking algorithm. Each site evaluates it's surroundings to decide where to go. It asks the map for all the surroundings in n distance. The map returns a cone of Neighbor objects in those dimentions in each direction. There are double neighbors for the corners:

    nw n  n  n  n  n  ne
    w  nw n  n  n  ne e
    w  w  nw n  ne e  e
    w  w  w  o  e  e  e
    w  w  sw s  se e  e
    w  sw s  s  s  se e
    sw s  s  s  s  s  se

Then I loop through all the neutral neighbors and select the most 'interesting' one. At this point, I knew that I needed to weigh strength and production together to decide what was the most interesting, but I didn't know what that relationship needed to be. I settled on this:

```ruby
def interesting
  if strength == 0
    return production**2
  end
  (production**2).to_f/strength
end
```

Production was generally between 0-20, while strength was 0-255. The square of production over strength gives a fairly good approximation of best sites if you're sorting by largest first. It wasn't until I read some of the writeups that I realized (duh) that the best valuation of interestingness is just "time to recover from taking the site" (strength/production). 

The algorithm simply selected the most interesting site within 4-6 blocks, and moved toward it if the current site was strong enough to take the neighbor in that direction.

Despite the fact that Mark 7 is buggy as all get out, this very effectively produced decent tunneling behavior, at least for maps with a some amout of variation within the immediate area. It beats the pants off the Mark 6 bot.

Mark 8 and Mark 9 refine the idea much better, weighing the 'interestingness' over the distance that the site is away, and summing the 'interesting' scores for each direction to decide the best move for each piece. Mark 9 changes the distance to search depending on the number of neutral sites left on the board. I'm still not 100% that it made any difference at all. Mark 9 retired at rank 133.

These bots are still really dumb about expanding from the middle of my territory when the 'search' algorithm doesn't see any sites that aren't mine. They use a only slightly improved version of the 'improved' and 'overkill' bot with a fallback direction that cycles through the cardinal directions every 20 turns. I never particularly improved this through the end of the official Halite competition.

## Mark 10 thru 13: Refining and experimenting

The major improvement that I managed to make between Mk 9 and the end of the game was creating a way to avoid unnecessary bad merges. 

Each site started to track moves into their own space. If a site was going to go north, it would create a Move object and then give it to the site to the north. 

When the site to the north evaluates its own moves, it can decide if it's 'allowed' to stay still based on the total strength of all planned moves into its space.

This rocketed my bot into the ~100 range. 

I also started respecting the Non-Aggression-Pact. I'd seen a few bots implementing it, and it seemed like an excellent strategy for conserving strength until needed. 

Mark 11 and 12 stabilized right around 40-45 on the scoreboard.

These were still pretty buggy. The combination of 'allowed moves' plus the NAP meant that sometimes max-sized pieces got stuck in corners while other pieces moved toward them. The NAP logic incorrectly identified neutral sites with empty sites next to them as not being 'walls' which caused lots of intrusions into enemy sites that might have been better left alone. 

Mark 12 currently holds the unnofficial world record for the [unofficial single player mode](http://forums.halite.io/t/introducing-unofficial-halite-single-player-mode/573) for the 50x50 seed 123456789 map at [151 frames](https://nmalaguti.github.io/halite-visualizer/?url=https%3A%2F%2Fdl.dropboxusercontent.com%2Fu%2F1233404%2F417650-123456789.hlt). 

Mark 13 was a couple of bugfixes and improvements to Mark 12, uploaded to the Halite site in the wee hours of the morning on Sunday before the Halite competition switched to the finals. My tests since then say that Mark 13 is only marginally better or possibly worse than Mark 12. ¯\\\_(ツ)_/¯ 

The Halite finale was somewhat anti-climactic for my bot. Mark 13 ended up being the final version when submissions were cut off. It did worse in the end than Mark 11 and 12 - possibly just a streak of bad luck, but it ended at Rank 82 and hovered around 65-70 during the week of the competition.

## Nerdery Competition

The Nerdery winter code challenge is to submit a bot by the week of February 20. The collection of bots compete tournament style, 4 bots on a 25x25 map, scoring 3, 2, and 1 points for first, second, and third place in each round. The top six bots battle on a 40x40 map, sudden death. Prizes are forturne and glory, plus bragging rights until the summer games.

Since the Nerdery competition happened after the main Halite competition was over, there were some questions around using the code released by other competitors within our own games. The word arrived from on high: please don't submit somebody else's bot, but feel free to be inspired. Nerd's honor.

My final few versions that I experimented with during the weekend of February 18 were inspired heavily by the ['gold bot'](http://braino.org/thoughts/halite_the_simple_way.html) and Erdman's [third place bot](https://github.com/erdman/erdman-halite-bots/blob/master/README.md). Erdman's bot is in Python, while my submission is ruby; that said, I 'borrowed' his logic and weighing algorithms heavily for my final submission.

The process of building out this final bot is documented in the `/gold` and `/hungry_v*` directories; the final submission is in the `/jheilema` directory. 

The basic concept is creating a weighted map of the best sites to visit. The on each turn, the Decisionmaker loops through all the neutral sites on the map and collects their 'initial scores':

```ruby
def initial_score
  # 0 production sites are useless. don't capture them.
  # initial values for enemy sites are also useless.
  if production == 0 || enemy?
    return Float::INFINITY
  end

  # assume the site is on a battlefront, maybe not ours.
  # it's pretty valuable. there's overkill to be had around here,
  # more for each enemy.
  if blank_neutral?
    return neighbors.select(&:enemy?).length * Decisionmaker::ENEMY_ROI
  end

  # turns to recover!
  return strength.to_f/production
end
```

Lower scores are better, and are mostly keyed around `strength/production`, the calculation of the number of turns to recover if you capture a site. 

Once all neutral sites are scored this way, they all go into a sorted set or priority queue. The Ruby stdlib implementation of SortedSet is unhelpfully slow if you don't have a particular gem installed, so I ended up finding an alternetive implementation that I added to this repo.

The bot next loops through that queue, taking the lowest (best) scoring item off the top of the list. The score of the best site is combined with the scores of the neighbor by:

    best*90% + neighbor*10%

This weighs the neighbor more heavily by what it can reach, but the neighbor still influences the final score. The neighbor with it's new score is then put back into the sorted queue. The original best scoring site is set aside into a collection list, tracking that we've found the 'best' scores already. Then we grab the next best scoring site off of the queue, and do it again.

This way, if you had a section of the board where the initial scores look something like this:

    2    2
    2    1
    1    1

The eventual scores would look like this (lower is better!):

    1.1081   1.1
    1.01     1
    1        1

The site in the second row, first column is more valuable than the first row, second column: it has immediate access to two '1-point' sites, while the second site is only next to one such site. The first row, first column site is still good, but not as good as either of the other two.

Enemy sites and 0-production sites are unpathable and are excluded from this algorithm by just giving them an infinite score.

Once the algorithm reaches friendly sites, it stops calculating cost as a function of strength/production; it starts being a much simpler calculation of `score + 0.2*distance^2` from a border. Each time a friendly site is added back into the queue, the distance value is increased. The site production is used as a tiebreaker in case the degraded score is equivalent, since it's better to move over a lower production site than a higher one.

Since empty neutral sites next to enemies are scored negatively, this pretty automatically starts moving pieces towards battlefronts.

Once all the pieces on the board have scores assigned, the bot creates a 'plan of attack' for taking border pieces in the most efficient way possible. This starts on line 125 of the Decisionmaker. Erdman calls this 'redlight/greenlight'. Essentially it allows the bot to decide if a collection of pieces have the strength to take a border piece if they're all combined together.

It creates a tree where the roots are any borders around the edge of friendly territory. The tree is constructed by adding each friendly site next to the border, and 'point' the friendly site at their lowest scoring neighbor.

Eventually it might have a structure that looks like this:

```ruby
{ 
  <Site @location=(0,0) @score=1> => {
    <Site @location=(1,0) @score=3> => {},
    <Site @location=(0,1) @score=2> => {
      <Site @location=(1,1) @score=3> => {}
    },
  },
  <Site @location=(2,3) @score=3> => {
    <Site @location=(3,3) @score=4> => {},
  },
}
```

Once the tree has been constructed, each 'branch' of the tree is compared to it's root site. The tree is walked one level at a time, closest to furthest, evaluating at each level to see if there's enough collected strength to take over the root site. If there is, then the level of the tree being evaluated is given the 'greenlight' and begins automatically moving forward toward the border, collecting the closer levels along the way.


