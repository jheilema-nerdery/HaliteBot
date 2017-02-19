[ ] Weight/target weakest enemy 


[ ] check for the swap-places bug :/
[ ] take production values into account when calculating moves
    - order by production first
    - get the average production of all owned spaces
    - if peice has higher than average production, prefer waiting, allow other peices to merge (?)
[ ] make the wall two blocks thick normally.
[ ] reduce the interestingness of wall blocks and enemy blocks behind walls
[ ] breech walls if enemy strength + production ratio is less than mine
    - (prod/str or str/prod?)
[ ] track the comparison between str/prod for each enemy vs me. 
[ ] weight smaller targets more strongly/larger weakly.

[ ] early vs mid-game should be keyed off of making contact w/ an enemy.
[ ] early game: distance should be a stronger indicator
[ ] very early game: own spaces shouldn't affect interestingness (encourage merging)
[ ] very early game: enemy spaces should be a little more expensive
[x] create a 'crashy' bot that can collect some 255 squares and then crash
[x] make sure my bot can account for crashy bots
[x] don't waste strength on bad merges
[x] sort peices by strength/prod ratios, then move only a % of them?
[x] if there is a neutral piece between me & an enemy, wait.

[x] revisit overkill and attack strategies
[ ] identify valuable sites and then pathfind to them?
[ ] Machine learning, can it teach specifics about an algorythm? Weights of goal sites, most effective search areas, targeting enemies, how long should a piece wait until it moves?
[ ] watch comparisons between str/territory/production + enemies. Change strategy depending.
    - If there's a low average prod/str ratio over the map, don't wall in; aggression rewards those who can take over other's territory early
[ ] watch the speed of the map. Change strategy depending.
[ ] pathfinding
