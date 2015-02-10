#!/usr/bin/env ruby

module Swift
	def self.demangle_symbol(symbol)
		`xcrun swift-demangle #{symbol}`.split('---> ')[1][0..-2]
	end

	def self.default_value(type)
		case type
		when 'Int'
			return '0'
		when String
			return '""'
		end

		'nil'
	end

	class Executable
		def initialize(executable)
			nm_out = `xcrun nm -g #{executable}`

			@executable = executable
			@symbols = nm_out.lines.map { |line| line.split(' ')[2] }.compact
		end

		def swift_symbols
			@symbols.select { |sym| sym[/^__T/] }
		end

		def to_s
			dump = <<-DUMP
// Code generated from `#{@executable}`
import Foundation

DUMP

			classes.each do |sclass|
				c_name = class_name(sclass)
				dump << "class #{c_name.split('.')[1]} {\n"

				variables(sclass).each do |var|
					v = Swift::demangle_symbol(var).split('.')[2]

					mangled_type = var.gsub(/^#{sclass}g[0-9]+#{v}/, '')
					type = Swift::demangle_symbol(var).split(' : ')[1]
					type = type.gsub(/Swift\./, '')

					init = ''
					if has_direct_field(sclass, v, mangled_type)
						init = " = #{Swift::default_value(type)} "
					end

					declaration = 'var'
					unless has_setter(sclass, v, mangled_type)
						if has_direct_field(sclass, v, mangled_type)
							declaration = 'let'
						else
							init = " { return #{Swift::default_value(type)} } "
						end
					end

					dump << "#{declaration} #{v}: #{type}#{init}\n"
				end

				functions(sclass).each do |func|
					f = Swift::demangle_symbol(func).gsub(/ \(#{c_name}\)/, '')
					f = f.gsub(/^#{c_name}\./, '')
					f = f.gsub(/Swift\./, '')
					
					return_statement = ''
					return_type = f.split('-> ')[1]
					if return_type != '()'
						return_statement = " return #{Swift::default_value(return_type)} "
					end

					dump << "func #{f} {#{return_statement}}\n"
				end

				dump << "}\n"
			end

			dump
		end

		private

		CLASS = '__TFC'
		DEALLOC = 'D'
		DIRECT = '__TWvdvC'

		def classes
			relevant_symbols.select { |sym| sym.end_with?(DEALLOC) }.map { |sym| sym[0..-2] }
		end

		def class_name(mangled_class_prefix)
			Swift::demangle_symbol(mangled_class_prefix + DEALLOC).split('.__')[0]
		end

		def has_direct_field(mangled_class_prefix, variable_name, mangled_type)
			prefix = mangled_class_prefix.gsub(CLASS, DIRECT)
			expected_sym = "#{prefix}#{variable_name.length}#{variable_name}#{mangled_type}"
			@symbols.select{ |sym| sym == expected_sym }.length > 0
		end

		def functions(mangled_class_prefix)
			relevant_symbols.select { |sym| sym[/^#{mangled_class_prefix}[0-9]+/] }
		end

		def has_materialize(mangled_class_prefix, variable_name, mangled_type)
			expected_sym = "#{mangled_class_prefix}m[0-9]+#{variable_name}#{mangled_type}"
			relevant_symbols.select { |sym| sym[/^#{expected_sym}/] }.length > 0
		end

		def has_setter(mangled_class_prefix, variable_name, mangled_type)
			expected_sym = "#{mangled_class_prefix}s[0-9]+#{variable_name}#{mangled_type}"
			relevant_symbols.select { |sym| sym[/^#{expected_sym}/] }.length > 0
		end

		def relevant_symbols
			@symbols.select { |sym| sym[/^#{CLASS}/] }
		end

		def variables(mangled_class_prefix)
			relevant_symbols.select { |sym| sym[/^#{mangled_class_prefix}g[0-9]+/] }
		end
	end
end

##############################################################################

if ARGV.first.nil?
	puts 'Please provide the path to an executable as first argument'
	exit 2
end

exec = Swift::Executable.new(ARGV.first)
puts exec
