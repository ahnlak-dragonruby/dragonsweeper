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
		render_board

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
		@cell_status = Array.new( @width * @height, :status_covered )

		# Decide how big the stuff on the right hand side should be
		@label_size = -2.5
		@size_restart = $gtk.calcstringbox( "Restart", @label_size )
		@size_dragon = $gtk.calcstringbox( "888 Dragons To Find", @label_size )
		@size_time = $gtk.calcstringbox( "88:88:88", @label_size )

		while [ @size_restart.x, @size_dragon.x, @size_time.x ].max < ( $gtk.args.grid.w - ( ( @width + 6 ) * @cell_size ) )

			# Try some slightly bigger sizes then
			@size_restart = $gtk.calcstringbox( "Restart", @label_size+0.1 )
			@size_dragon = $gtk.calcstringbox( "888 Dragons To Find", @label_size+0.1 )
			@size_time = $gtk.calcstringbox( "88:88:88", @label_size+0.1 )

			# And nudge up the label size
			@label_size += 0.1
		end 

		@label_size -= 0.1
		@size_restart = $gtk.calcstringbox( "Restart", @label_size )
		@size_dragon = $gtk.calcstringbox( "888 Dragons To Find", @label_size )
		@size_time = $gtk.calcstringbox( "88:88:88", @label_size )
		
		puts @label_size

		# Lastly, work out some sensible offsets
		@board_w = @width * @cell_size
		@board_h = @height * @cell_size
		@board_x = 2 * @cell_size 
		@board_y = $gtk.args.grid.center_y - ( @board_h / 2 )

		@label_x = @board_x + @board_w + ( 2 * @cell_size )
		@label_time_y = $gtk.args.grid.center_y + ( @size_time.y + 20 ) * 1.5
		@label_dragon_y = @label_time_y - 20 - @size_dragon.y - 20
		@label_restart_y = @label_dragon_y - 20 - @size_restart.y - 20

		@label_width = [ @size_restart.x, @size_dragon.x, @size_time.x ].max + 20

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

			end

		end

		# Now, I've been lazy with setting dragon counts, we we need to normalise
		# any overinflated dragons :-)
		@dragons.map! { |cell| cell > DRAGON ? DRAGON : cell }

		# Lastly, remember when we started playing properly
		@start_tick = $gtk.args.tick_count

	end


	# Uncover the specified cell; done in a function to make recursion easier
	def uncover therow, thecol, uncovered = false

		# Sanity check that we're on the board and not already exposed
		if !therow.between?( 0, @height-1 ) || !thecol.between?( 0, @width-1 ) || 
		   ( !uncovered && @cell_status[(therow*@width)+thecol] != :status_covered )
			return
		end
		
		# First off, simply reveal the cell
		if !uncovered
			@cell_status[(therow*@width)+thecol] = :status_revealed
		end

		# If this was a completely empty cell, recurse through our neighbours
		if uncovered || @dragons[(therow*@width)+thecol] == 0
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

		# Normalise the mouse position to the board origin
		mouse_x = ( ( args.inputs.mouse.x - @board_x ) / @cell_size ).floor
		mouse_y = ( ( args.inputs.mouse.y - @board_y ) / @cell_size ).floor

		# Handle if there's been a click
		if args.inputs.mouse.click

			# Save me some typing later on... ;-)
			cell_idx = (mouse_y*@width) + mouse_x

			# The user can do one of three things; click left, click right,
			# or click both. Somwhow we have to handle all of this!
			if args.inputs.mouse.button_left && args.inputs.mouse.button_right

				# Clear around an already-cleared cell
				if @cell_status[cell_idx] == :status_revealed
					uncover mouse_y, mouse_x, true
				end

			# If the user wants to add a gold pile to a covered cell, that's easy
			elsif args.inputs.mouse.button_right

				# Needs to be on the board, and over a covered cell
				if mouse_x.between?( 0, @width-1 ) && mouse_y.between?( 0, @height-1 ) && @cell_status[cell_idx] != :status_revealed

					# We maintain a list of gold pile co-ordinates, and just toggle
					@cell_status[cell_idx] = ( @cell_status[cell_idx] == :status_gold ) ? :status_covered : :status_gold

				end

			# If the user clicks on the board, work out where.
			elsif args.inputs.mouse.button_left

				# Obviously can only act if they're over the board
				if mouse_x.between?( 0, @width-1 ) && mouse_y.between?( 0, @height-1 )

					# If this is the first cell, spawn dragons!
					if !@cell_status.include?(:status_revealed)
						spawn_dragons mouse_y, mouse_x
					end

					# And then simply uncover the cell here
					uncover mouse_y, mouse_x

				end

			end

			# Redraw the board
			render_board

		end

		# Now check for end conditions; have we flagged all the dragons we seek?
		if @cell_status.count :status_gold == dragon_count
		end

		# Have we revealed a dragon?!
		

	end


	# Render the board; because this is quite expensive, we'll only do it when
	# things have changed, into a single render_target that can be pushed out
	# every frame
	def render_board

		# So, we'll rebuild the render target from scratch
		(0...@height).each do |row|
			(0...@width).each do |col|

				# Save myself some typing, and some math cycles...
				cell_idx = (row*@width)+col

				# Check to see if this cell is covered
				if @cell_status[cell_idx] == :status_covered
					cell = @cover_png
				elsif @cell_status[cell_idx] == :status_gold
					cell = @gold_png
				else
					if @dragons[cell_idx] == DRAGON
						cell = @dragon_png
					else
						cell = @cell_png[@dragons[cell_idx]]
					end
				end

				# We know what to draw, so draw it
				$gtk.args.render_target( :board ).width = @board_w
				$gtk.args.render_target( :board ).height = @board_h
				$gtk.args.render_target( :board ).sprites << {
					x: (col*@cell_size), y: (row*@cell_size),
					w: @cell_size, h: @cell_size, path: cell,
				}

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

		# Do similar work for the labels
		args.outputs.solids << {
			x: @label_x, y: @label_time_y, w: @label_width, h: @size_time.y,
			r: 222, g: 222, b: 222,
		}
		args.outputs.solids << {
			x: @label_x, y: @label_dragon_y, w: @label_width, h: @size_dragon.y,
			r: 222, g: 222, b: 222,
		}
		args.outputs.solids << {
			x: @label_x, y: @label_restart_y, w: @label_width, h: @size_restart.y,
			r: 222, g: 222, b: 222,
		}

		(1..10).each do |index|
			args.outputs.borders << { 
				x: @label_x - index, y: @label_time_y - index, 
				w: @label_width + (index*2), h: @size_time.y + (index*2),
				r: 100 + (index*10), g: 100 + (index*10), b: 100 + (index*10),
			}
			args.outputs.borders << { 
				x: @label_x - index, y: @label_dragon_y - index, 
				w: @label_width + (index*2), h: @size_dragon.y + (index*2),
				r: 100 + (index*10), g: 100 + (index*10), b: 100 + (index*10),
			}
			args.outputs.borders << { 
				x: @label_x - index, y: @label_restart_y - index, 
				w: @label_width + (index*2), h: @size_restart.y + (index*2),
				r: 100 + (index*10), g: 100 + (index*10), b: 100 + (index*10),
			}
		end

		# Set up the labels, which yes could possibly be more ... static
		secs_elapsed = ( args.tick_count - @start_tick ).to_i / 60
		args.outputs.labels << {
			x: @label_x + ( @label_width/2 ), y: @label_time_y + @size_time.y,
			size_enum: @label_size, alignment_enum: 1,
			text: "%02d:%02d:%02d" % [(secs_elapsed/3600)%60, (secs_elapsed/60)%60, secs_elapsed%60], 
		}
		args.outputs.labels << {
			x: @label_x + ( @label_width/2 ), y: @label_dragon_y + @size_dragon.y,
			size_enum: @label_size, alignment_enum: 1,
			text: "#{@dragon_count - @cell_status.count(:status_gold)} Dragons To Find", 
		}
		args.outputs.labels << {
			x: @label_x + ( @label_width/2 ), y: @label_restart_y + @size_restart.y,
			size_enum: @label_size, alignment_enum: 1,
			text: "Restart", 
		}

		# Send the board content to the output
		args.outputs.sprites << {
			x: @board_x, y: @board_y, w: @board_w, h: @board_h, path: :board,
			source_x: 0, source_y: 0, source_w: @board_w, source_h: @board_h,
		}

	end


end