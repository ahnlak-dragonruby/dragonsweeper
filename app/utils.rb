# utils.rb - part of DragonSweeper
#
# Copyright (c) 2020 Pete Favelle <dragonruby@ahnlak.com>
# This software is distributed under the MIT License - see LICENSE.txt for more information.
#
# A collection of helper classes used in different areas. One day will form
# part of a more established library :-)

class Serializable

	# Should always be defined by the subclass
	def serialize
		raise "Serializable classes must define serialize()"
	end

	# Various handlers to serialize
	def inspect
		serialize.to_s
	end
	def to_s
		serialize.to_s
	end

end
	