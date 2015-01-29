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
		FUNC = '3'
		VOID_FUNC = '7'

		def classes
			relevant_symbols.select { |sym| sym.end_with?(DEALLOC) }.map { |sym| sym[0..-2] }
		end

		def class_name(mangled_class_prefix)
			Swift::demangle_symbol(mangled_class_prefix + DEALLOC).split('.__')[0]
		end

		def functions(mangled_class_prefix)
			relevant_symbols.select { |sym| sym[/^#{mangled_class_prefix}(#{FUNC}|#{VOID_FUNC})/] }
		end

		def relevant_symbols
			@symbols.select { |sym| sym[/^#{CLASS}/] }
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
