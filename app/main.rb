# main.rb - part of DragonSweeper
#
# Copyright (c) 2020 Pete Favelle <dragonruby@ahnlak.com>
# This software is distributed under the MIT License - see LICENSE.txt for more information.
#
# This is the main entry file, which contains the 'tick' handler for DR.
# It is also the *only* place that should be require'ing other files.

$gtk.require 'app/utils.rb'
$gtk.require 'app/board.rb'


# Initialiser; called at launch, this is where we set up the defaults in the
# state. Can be called again on reset, to re-initialise the entire game
def init args

	# Keep track of a release version
	args.state.version = "1.0.20200728"

	# Create a Board which holds everything about the current board
	args.state.board = Board.new()

	# Make sure the version is always shown
	args.outputs.static_labels.clear
	args.outputs.static_labels << {
		x: 20, y: 30, text: "Version V#{args.state.version}", size_enum: -2,
	}

end


# Main tick handler; called every frame
def tick args

	# In the very first tick - or on a reset - call the initialiser
	if args.state.tick_count == 0
		init args
	end

	# Set up the basic screen parameters
	args.outputs.background_color = [ 255, 255, 255, 255 ]

	# The core logic is simple; update the Board first
	args.state.board.update args

	# And then render it
	args.state.board.render args

end