# This file contains methods for helping to define ActiveRecord classes.  There
# may be a better place to put these method definitions.

module Enumerable
	# A local method that, given a two-dimensional enumerable object, will
	# create a hash that maps the nth elements of the array to the mth elements.
	def to_hash(n = 0, m = 1)
		h = Hash.new
		self.each { |i| h[i[n]] = i[m] }
		h
	end
end
require 'metaid'
class Class
	# This method, an instance method of Class, defines several instance methods
	# and a couple of class methods for the caller, friendly setters and getters
	# for the method named by +name+ (with actual values mapped to symbols and
	# strings by +mapping+), and add some validation for the class if it happens
	# to descend from ActiveRecord::Base.  The supplied methods are 
	# 	* Class.name_values, which gives the possible values for the column
	# 	* Class.name_map, which returns a mapping of symbols to integers for the
	# 	  column
	# 	* Class.options, which returns options in the format of [string, int], 
	# 	  for Rails' select tag.
	# 	* Class#name_sym, which returns the symbol mapped to Class#name
	# 	* Class#name_string, which returns the string mapped to Class#name
	# 	* Class#name_sym=, Class#name_string=
	# 	* Class#name_is?, for comparing symbols.
	# 	* Class#name= (ActiveRecord only), which overrides the normal
	# 	  Class#name= so that you can set it as a symbol, string, or integer,
	# 	  and it will do what you expect. 
	#
	# The mapping is expected to be a two-dimensional array with three elements
	# in each row:  the value to be stored in the database, a symbol
	# representing the value, and a string representing the value, for example:
	# 	[[1, :jim, "Jim"],
	# 	 [2, :lunch, "Lunch"]]
	# 
	# This method is very large, mostly because it has the job of defining
	# several other methods.
	def enumerates(name, mapping)
		name = name.to_s
		ints = mapping.map { |i,j,k| i }
		syms = mapping.map { |i,j,k| j }
		intsym = mapping.to_hash(0, 1).freeze
		intstr = mapping.to_hash(0, 2).freeze
		symint = mapping.to_hash(1, 0).freeze
		strint = mapping.to_hash(2, 0).freeze
		
		meta_def(name + '_values') { ints }
		define_method(name + '_values') { ints }
		meta_def(name + '_map') { symint }
		define_method(name + '_map') { symint }
		# This is more a Rails thing, for using the select tag helper.
		for_select = strint.to_a.sort { | x, y |
			# This will make whatever is index 0 be pushed to the end - 0 is a magic index
			if x.last == 0 
				1 
			elsif y.last == 0
				-1
			else 
				x.last <=> y.last
			end
		}.freeze

		meta_def(name + '_options') { for_select }

		define_method(name + '_sym') { intsym[self.send(name)] }
		define_method(name + '_sym=') { |s| self.send(name + '=', symint[s]) }

		if(syms.include?(:other) && 
		   (self.column_names.include?(name + '_other') rescue false) &&
		   (other = symint[:other]))
			define_method(name + '_string') {
				if self.send(name) == other
					self.send(name + '_other')
				else
					intstr[self.send(name)]
				end
			}
		else 
			define_method(name + '_string') { intstr[self.send(name)] }
		end
		define_method(name + '_string=') { |s| self.send(name + '=', strint[s])}
		# The topic of a long debate:
		define_method(name + '_is?') { |s| intsym[self.send(name)] == s }

		# Magic setter method for ActiveRecord objects.  Normally we would check
		# something like instance_variables.include? '@attributes', but
		# unfortunately we don't know when defining a class what the instance
		# methods will be for objects.  Note that the class of the objects
		# starts to matter if you use this part.
		if(Object.const_get('ActiveRecord') && ActiveRecord.const_get('Base') &&
			self.ancestors.include?(ActiveRecord::Base))

			# We may or may not want to do this, since this method doesn't let
			# you do arbitrary validation options.
			validates_inclusion_of name, :in => ints, :allow_nil => true

			define_method(name + '=') { |value|
				if value != '' && ints.include?(value.to_i)
					value = value.to_i
				elsif value.kind_of? Symbol
					value = symint[value]
				elsif value.kind_of? String
					value = strint[value]
				end
				@attributes[name] = value
			}
		end
	end

	# This wraps a phone field named 'colname' with an optional 'colname_ext'
	# field, giving you a 'formatted_colname' for a formatted version including
	# the optional extension.  The setter method for 'colname' is overridden so
	# that any reasonably-formatted phone number can be passed in and the phone
	# and extension will be set.
	# It will also validate the format of the number and extension (you can pass
	# validation options through validation_opts for things like :allow_nil =>
	# false).
	def wrap_phone(colname, validation_opts = {})
		colname = colname.to_s
		extname = colname + '_ext'

		vopts = { 
			:allow_nil => true, 
			:with => /^\d{10}$/,
		}.merge(validation_opts)

		validates_format_of colname, vopts

		# Pretty-prints a phone number.
		define_method('formatted_' + colname) {
			r = send(colname)
			return nil unless r
			r.sub!(/^(\d{3})(\d{3})(\d{4})$/, '(\1) \2-\3')
			if(respond_to?(extname) && send(extname))
				r += " x#{send(extname)}"
			end
			r
		}

		# Sanitizes a phone number.  Very promiscuous with input.
		define_method(colname + '=') { |phv|
			# Strip out any odd symbols (anything besides a digit or 'x') and
			# possibly a leading 1.
			# So '   1-((312) 738-7588  ext. 334 ' becomes "3127387588x334"
			if phv
				cleaned = phv.gsub(/[^\dx]/, '').sub(/^1/, '')
				# Separate into phone number and optional extension.
				ph, ext = cleaned.split('x')
			else
				ph, ext = nil, nil
			end
			@attributes[colname] = ph
			if respond_to?(extname)
				@attributes[extname] = ext
			end
		}
	end
end

class ActiveRecord::Base
end
