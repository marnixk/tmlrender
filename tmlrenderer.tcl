module Tml {

	#
	#	Render the file into a string using the values in the context variable
	#	as replacements in the actual tcl template.
	#
	public render {file {context {}}} {

		# file contents
		set file_contents [read-file $file]

		# transform to a list of instructions
		set render_code [transform $file_contents]

		# join instructions
		set body [join $render_code \n]

		set output ""
			
		# make context variables local
		foreach {var value} $context {
			set $var [uplevel 1 subst [list $value]]
		}

		# execute the generated template
		if 1 $body

		# return the output
		return $output
	}

	#
	#	Transform the 
	#
	protected transform {contents} {
		# storage for list
		lappend code

		# separate lines
		set lines [split $contents \n]

		foreach line $lines {

			# nothing special happening here?
			if {![has-instructions $line]} then {
				lappend code [text-as-output "$line\n"]
			} else {
				deconstruct-line code $line
			}
		}

		return $code
	}



	#
	#	Is able to deconstruct a line with code blocks in it into 
	#	multiple lines of code
	#
	protected deconstruct-line {r_code line} {
		upvar 1 $r_code code 

		set state find-open
		set opening_at -1
		set idx 0

		while {$state != "eol"} {

			if {$state == "find-open"} then {
				# find the opening statement
				set next [string first "<%" $line $idx]

				# cannot find an open brace anymore? just add the rest
				if {$next == -1} then {
					lappend code [text-as-output "[string range $line $idx end]\n"]
					set state eol
				} else {
					lappend code [text-as-output [string range $line $idx $next-1]]
					set opening_at $next
					set state find-close
				}

			} elseif {$state == "find-close"} then { 

				# find the closing statement
				set next [string first "%>" $line $opening_at]
				if {$next == -1} then {
					return -error "cannot find closing '%>' on line: `$line`"
				} 

				set line_of_code [string range $line $opening_at+2 $next-2]
				set parsed_code [parse-code $line_of_code]

				lappend code $parsed_code
				set idx [expr {$next + 2}]
				set state find-open
			}
		}

	}

	#
	#	Parse a line of code and extract the different relevant parts from it and
	#	add them to the code list. 
	#
	protected parse-code {loc} {

		set loc [string trim $loc]

		# starts with equals sign? add result of code to 
		# the output generated content.
		if {[string index $loc 0] == "="} then {
			set code [string trim [string range $loc 1 end]]

		 	return [subst -nocommands {set output "\$output$code"}]
		}

		# if the line ends with a colon, we're going to replace it
		# with the normal TCL `{}` syntax
		set last_char [string range $loc end end]
		if {$last_char == ":"} then {
			return "[string range $loc 0 end-1] \{"
		}

		# if we find the 'end' keyword, we're assuming that we mean to 
		# close a brace.
		if {$loc == "end"} then {
			return "\}"
		}

		return $loc
	}


	#
	#	Read the file into a string
	#
	protected read-file {filename} {
		set fp [open $filename "r"]

		set content ""

		while {![eof $fp]} {
			set content "$content[gets $fp]\n"
		}

		close $fp
		return $content
	}

	#
	#	Does the line contain instructions?
	#
	protected has-instructions {line} {
		return [expr { [string first "<%" $line] > -1 }]
	}

	#
	#	Add a line of code that adds `line` to the output.
	#
	protected text-as-output {line} {
		set line [string map {"\"" "\\\"" } $line ]
		return [subst -nocommands {set output "\$output$line"}]
	}
}