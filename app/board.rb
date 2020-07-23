# board.rb - part of DragonSweeper
#
# Copyright (c) 2020 Pete Favelle <dragonruby@ahnlak.com>
# This software is distributed under the MIT License - see LICENSE.txt for more information.
#
# The Board class wraps up the gameplay in one neat package, and essentially
# provides two methods - update, which handles user input and updates the state
# of the game; and render, which draws the state of the game

class Board < Serializable


	# Some handy constants
	DRAGON = 42


	# Constructor; sets up basic defaults
	def initialize

		# Set up some default values here; things like the size of board,
		# level of complexity and suchlike.
		size :small, 1

	end


	# Set up the basic serialization
	def serialize

		{
			width: @width, height: @height, mines: @mines, 
			cell_size: @cell_size,
		}

	end


	# Reset the board to a given size, as well as building the graphical
	# elements that will be required for this size
	def size thesize, thelevel

		# Set the basic metrics
		case thesize
		when :small 				# A 20x20 grid
			@width = 20
			@height = 20
			@dragon_count = 50 * thelevel
			@cell_size = 30
			@cover_png = 'sprites/cover_30.png'
			@dragon_png = 'sprites/dragon_30.png'
			@gold_png = 'sprites/gold_30.png'
			@cell_png = [ 'sprites/cell0_30.png', 'sprites/cell1_30.png', 'sprites/cell2_30.png', 
						  'sprites/cell3_30.png', 'sprites/cell4_30.png', 'sprites/cell5_30.png',
						  'sprites/cell6_30.png', 'sprites/cell7_30.png', 'sprites/cell8_30.png' ]
		end

		# Clear and resize the board array
		@dragons = Array.new( @width * @height, 0 )
		@covered = Array.new( @width * @height, true )

		# And now set up the render targets we'll need
		$gtk.args.render_target( :cellcover ).sprites << {
			x: 0, y: 0, w: @cell_size, h: @cell_size, path: @cover_png,
		}
		$gtk.args.render_target( :dragon ).sprites << {
			x: 0, y: 0, w: @cell_size, h: @cell_size, path: @dragon_png,
		}
		$gtk.args.render_target( :gold ).sprites << {
			x: 0, y: 0, w: @cell_size, h: @cell_size, path: @gold_png,
		}
		(0..8).each do |index|
			$gtk.args.render_target( "cell#{index}".to_sym ).sprites << {
				x: 0, y: 0, w: @cell_size, h: @cell_size, path: @cell_png[index],
			}
		end

		# Lastly, work out some sensible board offsets
		@board_w = @width * @cell_size
		@board_h = @height * @cell_size
		@board_x = $gtk.args.grid.center_x - ( @board_w / 2 )
		@board_y = $gtk.args.grid.center_y - ( @board_h / 2 )

	end


	# Seed the board with the required number of dragons. This is done *after*
	# the player uncovers their first square, to ensure that there is never a 
	# dragon hiding there.
	def spawn_dragons therow, thecol

		# So, we'll loop until we have enough dragons
		while @dragons.count{ |cell| cell >= DRAGON } < @dragon_count

			# Pick a new random location
			new_row = rand( @height )
			new_col = rand( @width )

			# And create a new dragon if it's allowable
			if ( new_row != therow || new_col != thecol ) && @dragons[(new_row*@width)+new_col] < DRAGON

				# Spawn the dragon itself
				@dragons[(new_row*@width)+new_col] = DRAGON

				# And increment the neighbour count all around
				if new_col > 0
					if new_row > 0
						@dragons[((new_row-1)*@width)+new_col-1] += 1
					end
					@dragons[((new_row)*@width)+new_col-1] += 1
					if new_row < @height-1
						@dragons[((new_row+1)*@width)+new_col-1] += 1
					end
				end
				if new_row > 0
					@dragons[((new_row-1)*@width)+new_col] += 1
				end
				if new_row < @height-1
					@dragons[((new_row+1)*@width)+new_col] += 1
				end
				if new_col < @width-1
					if new_row > 0
						@dragons[((new_row-1)*@width)+new_col+1] += 1
					end
					@dragons[((new_row)*@width)+new_col+1] += 1
					if new_row < @height-1
						@dragons[((new_row+1)*@width)+new_col+1] += 1
					end
				end

				puts "Added #{@dragons.count{ |cell| cell >= DRAGON }} dragons..."
				(0...@height).each do |line|
					puts @dragons.slice( line*@width, @width ).to_s
				end

			end

		end

		# Now, I've been lazy with setting dragon counts, we we need to normalise
		# any overinflated dragons :-)
		@dragons.map! { |cell| cell > DRAGON ? DRAGON : cell }
		puts @dragons

	end


	# Uncover the specified cell; done in a function to make recursion easier
	def uncover therow, thecol

		# Sanity check that we're on the board and not already exposed
		if !therow.between?( 0, @height-1 ) || !thecol.between?( 0, @width-1 ) || !@covered[(therow*@width)+thecol]
			return
		end

		# First off, simply reveal the cell
		@covered[(therow*@width)+thecol] = false

		# If this was a completely empty cell, recurse through our neighbours
		if @dragons[(therow*@width)+thecol] == 0
			uncover therow-1, thecol-1
			uncover therow-1, thecol
			uncover therow-1, thecol+1
			uncover therow, thecol-1
			uncover therow, thecol+1
			uncover therow+1, thecol-1
			uncover therow+1, thecol
			uncover therow+1, thecol+1
		end

	end



	# Update; handles user input and updates the state of the game
	def update args

		# If the user clicks on the board, work out where.
		if args.inputs.mouse.button_left

			# Normalise the mouse position to the board origin
			mouse_x = ( ( args.inputs.mouse.x - @board_x ) / @cell_size ).floor
			mouse_y = ( ( args.inputs.mouse.y - @board_y ) / @cell_size ).floor

			# Obviously can only act if they're over the board
			if mouse_x.between?( 0, @width-1 ) && mouse_y.between?( 0, @height-1 )

				# If this is the first cell, spawn dragons!
				if !@covered.include?(false)
					spawn_dragons mouse_y, mouse_x
				end

				# And then simply uncover the cell here
				uncover mouse_y, mouse_x

			end

		end

	end


	# Render; draws the board to the screen
	def render args

		# Might be useful to know the current FPS
		args.outputs.debug << { x: 10, y: args.grid.top - 30, text: args.gtk.current_framerate }.label

		# Use a solid to make sure the board is the right colour
		args.outputs.solids << {
			x: @board_x, y: @board_y, w: @board_w, h: @board_h,
			r: 222, g: 222, b: 222,
		}

		# Draw a nice border around the board
		(1..10).each do |index|
			args.outputs.borders << { 
				x: @board_x - index, y: @board_y - index, 
				w: @board_w + (index*2), h: @board_h + (index*2),
				r: 100 + (index*10), g: 100 + (index*10), b: 100 + (index*10),
			}
		end

		# And then work through the board, rendering appropriately
		(0...@height).each do |row|
			(0...@width).each do |col|

				# Save myself some typing, and some math cycles...
				cell_idx = (row*@width)+col

				# Check to see if this cell is covered
				if @covered[cell_idx]
					cell = :cellcover
				else
					if @dragons[cell_idx] == DRAGON
						cell = :dragon
					else
						cell = "cell#{@dragons[cell_idx]}".to_sym
					end
				end

				# We know what to draw, so draw it
				args.outputs.sprites << {
					x: @board_x + (col*@cell_size),
					y: @board_y + (row*@cell_size),
					w: @cell_size, h: @cell_size, path: cell,
					source_x: 0, source_y: 0, source_w: @cell_size, source_h: @cell_size,					
				}

			end
		end

	end


end