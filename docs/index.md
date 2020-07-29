Dragon Sweeper
==============

This is a [minesweeper](https://en.wikipedia.org/wiki/Minesweeper_(video_game)) clone
built using [DragonRuby](https://www.dragonruby.org). My original plan was to try
and do this as a "24 hour game", but I kept getting distracted by other issues and
it ended up taking shape over a few days.

Dragon Sweeper is published on [itch.io](https://ahnlak.itch.io/dragonsweeper)

Under The Hood
--------------

The entire game is contained within the `Board` class, defined in 
[board.rb](https://github.com/ahnlak-dragonruby/dragonsweeper/blob/master/app/board.rb). 
This class provides an `update` method which is called every tick to handle any
user input and update the board, and a `render` method to draw the board onto the screen.

Each cell on the board is represented by a sprite; my original intent was to draw
the board from scratch every tick because that was the simplest approach, but on
my desktop machine I started to encounter performance problems once I had more than
a few hundred sprites being rendered every single frame.

Therefore, I rejigged things to redraw the board into a render_target whenever things
changed (as a result of user input), and then draw that render_target as a single
sprite every tick. Performance problems gone, because the board changes relatively
rarely!

Concerns
--------

This is fine for a simple, turn-based game like this is but I do have some concerns
if I had wanted to have every cell animated, for example. But I'll cross that bridge
when I write it.