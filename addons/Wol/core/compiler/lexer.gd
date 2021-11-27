extends Object

const Constants = preload('res://addons/Wol/core/Constants.gd')

const LINE_COMENT = '//'
const FORWARD_SLASH = '/'
const LINE_SEPARATOR = '\n'

const BASE = 'base'
const DASH = '-'
const COMMAND = 'command'
const LINK = 'link'
const SHORTCUT = 'shortcut'
const TAG = 'tag'
const EXPRESSION = 'expression'
const ASSIGNMENT = 'assignment'
const OPTION = 'option'
const OR = 'or'
const DESTINATION = 'destination'
const INLINE = 'inline'
const FORMAT_FUNCTION = 'format'

var WHITESPACE = '\\s*'

var filename = ''
var title = ''
var text = ''

var states = {}
var default_state
var current_state

var indent_stack = []
var should_track_indent = false

func _init(_filename, _title, _text):
	createstates()

	filename = _filename
	title = _title
	text = _text

func createstates():
	var patterns = {}
	patterns[Constants.TokenType.Text] = ['.*', 'any text']

	patterns[Constants.TokenType.Number] = ['\\-?[0-9]+(\\.[0-9+])?', 'any number']
	patterns[Constants.TokenType.Str] = ['\"([^\"\\\\]*(?:\\.[^\"\\\\]*)*)\"', 'any text']
	patterns[Constants.TokenType.TagMarker] = ['\\#', 'a tag #']
	patterns[Constants.TokenType.LeftParen] = ['\\(', 'left parenthesis (']
	patterns[Constants.TokenType.RightParen] =  ['\\)', 'right parenthesis )']
	patterns[Constants.TokenType.EqualTo] = ['(==|is(?!\\w)|eq(?!\\w))', '"=", "is" or "eq"']
	patterns[Constants.TokenType.EqualToOrAssign] = ['(=|to(?!\\w))', '"=" or "to"']
	patterns[Constants.TokenType.NotEqualTo] = ['(\\!=|neq(?!\\w))', '"!=" or "neq"']
	patterns[Constants.TokenType.GreaterThanOrEqualTo] = ['(\\>=|gte(?!\\w))', '">=" or "gte"']
	patterns[Constants.TokenType.GreaterThan] = ['(\\>|gt(?!\\w))', '">" or "gt"']
	patterns[Constants.TokenType.LessThanOrEqualTo] = ['(\\<=|lte(?!\\w))', '"<=" or "lte"']
	patterns[Constants.TokenType.LessThan] = ['(\\<|lt(?!\\w))', '"<" or "lt"']
	patterns[Constants.TokenType.AddAssign] =  ['\\+=', '"+="']
	patterns[Constants.TokenType.MinusAssign] = ['\\-=', '"-="']
	patterns[Constants.TokenType.MultiplyAssign] = ['\\*=', '"*="']
	patterns[Constants.TokenType.DivideAssign] = ['\\/=', '"/="']
	patterns[Constants.TokenType.Add] = ['\\+', '"+"']
	patterns[Constants.TokenType.Minus] = ['\\-', '"-"']
	patterns[Constants.TokenType.Multiply] = ['\\*', '"*"']
	patterns[Constants.TokenType.Divide] = ['\\/', '"/"']
	patterns[Constants.TokenType.Modulo] = ['\\%', '"%"']
	patterns[Constants.TokenType.And] = ['(\\&\\&|and(?!\\w))', '"&&" or "and"']
	patterns[Constants.TokenType.Or] = ['(\\|\\||or(?!\\w))', '"||" or "or"']
	patterns[Constants.TokenType.Xor] = ['(\\^|xor(?!\\w))', '"^" or "xor"']
	patterns[Constants.TokenType.Not] = ['(\\!|not(?!\\w))', '"!" or "not"']
	patterns[Constants.TokenType.Variable] = ['\\$([A-Za-z0-9_\\.])+', 'any variable']
	patterns[Constants.TokenType.Comma] = ['\\,', '","']
	patterns[Constants.TokenType.TrueToken] = ['true(?!\\w)', '"true"']
	patterns[Constants.TokenType.FalseToken] = ['false(?!\\w)', '"false"']
	patterns[Constants.TokenType.NullToken] = ['null(?!\\w)', '"null"']
	patterns[Constants.TokenType.BeginCommand] = ['\\<\\<', 'beginning of a command "<<"']
	patterns[Constants.TokenType.EndCommand] = ['\\>\\>', 'ending of a command ">>"']
	patterns[Constants.TokenType.OptionStart] = ['\\[\\[', 'start of an option "[["']
	patterns[Constants.TokenType.OptionEnd] = ['\\]\\]', 'end of an option "]]"']
	patterns[Constants.TokenType.OptionDelimit] = ['\\|', 'middle of an option "|"']
	patterns[Constants.TokenType.Identifier] = ['[a-zA-Z0-9_:\\.]+', 'any reference to another node']
	patterns[Constants.TokenType.IfToken] = ['if(?!\\w)', '"if"']
	patterns[Constants.TokenType.ElseToken] = ['else(?!\\w)', '"else"']
	patterns[Constants.TokenType.ElseIf] = ['elseif(?!\\w)', '"elseif"']
	patterns[Constants.TokenType.EndIf] = ['endif(?!\\w)', '"endif"']
	patterns[Constants.TokenType.Set] = ['set(?!\\w)', '"set"']
	patterns[Constants.TokenType.ShortcutOption] = ['\\-\\>\\s*', '"->"']
	patterns[Constants.TokenType.ExpressionFunctionStart] = ['\\{', '"{"']
	patterns[Constants.TokenType.ExpressionFunctionEnd] = ['\\}', '"}"']
	patterns[Constants.TokenType.FormatFunctionStart] = ['(?<!\\[)\\[(?!\\[)', '"["']
	patterns[Constants.TokenType.FormatFunctionEnd] = ['\\]', '"]"']

	var shortcut_option = SHORTCUT + DASH + OPTION
	var shortcut_option_tag = shortcut_option + DASH + TAG
	var command_or_expression = COMMAND + DASH + OR + DASH + EXPRESSION
	var link_destination = LINK + DASH + DESTINATION
	var format_expression = FORMAT_FUNCTION + DASH + EXPRESSION
	var inline_expression = INLINE + DASH + EXPRESSION
	var link_inline_expression = LINK + DASH + INLINE + DASH + EXPRESSION
	var link_format_expression = LINK + DASH + FORMAT_FUNCTION + DASH + EXPRESSION

	states = {}

	states[BASE] = LexerState.new(patterns)
	states[BASE].add_transition(Constants.TokenType.BeginCommand, COMMAND, true)
	states[BASE].add_transition(Constants.TokenType.ExpressionFunctionStart, inline_expression, true)
	states[BASE].add_transition(Constants.TokenType.FormatFunctionStart, FORMAT_FUNCTION, true)
	states[BASE].add_transition(Constants.TokenType.OptionStart, LINK, true)
	states[BASE].add_transition(Constants.TokenType.ShortcutOption, shortcut_option)
	states[BASE].add_transition(Constants.TokenType.TagMarker, TAG, true)
	states[BASE].add_text_rule(Constants.TokenType.Text)

	#TODO: FIXME - Tags are not being proccessed properly this way. We must look for the format #{identifier}:{value}
	#              Possible solution is to add more transitions
	states[TAG] = LexerState.new(patterns)
	states[TAG].add_transition(Constants.TokenType.Identifier, BASE)

	states[shortcut_option] = LexerState.new(patterns)
	states[shortcut_option].track_indent = true
	states[shortcut_option].add_transition(Constants.TokenType.BeginCommand, EXPRESSION, true)
	states[shortcut_option].add_transition(Constants.TokenType.ExpressionFunctionStart, inline_expression, true)
	states[shortcut_option].add_transition(Constants.TokenType.TagMarker, shortcut_option_tag, true)
	states[shortcut_option].add_text_rule(Constants.TokenType.Text, BASE)
	
	states[shortcut_option_tag] = LexerState.new(patterns)
	states[shortcut_option_tag].add_transition(Constants.TokenType.Identifier, shortcut_option)

	states[COMMAND] = LexerState.new(patterns)
	states[COMMAND].add_transition(Constants.TokenType.IfToken, EXPRESSION)
	states[COMMAND].add_transition(Constants.TokenType.ElseToken)
	states[COMMAND].add_transition(Constants.TokenType.ElseIf, EXPRESSION)
	states[COMMAND].add_transition(Constants.TokenType.EndIf)
	states[COMMAND].add_transition(Constants.TokenType.Set, ASSIGNMENT)
	states[COMMAND].add_transition(Constants.TokenType.EndCommand, BASE, true)
	states[COMMAND].add_transition(Constants.TokenType.Identifier, command_or_expression)
	states[COMMAND].add_text_rule(Constants.TokenType.Text)

	states[command_or_expression] = LexerState.new(patterns)
	states[command_or_expression].add_transition(Constants.TokenType.LeftParen, EXPRESSION)
	states[command_or_expression].add_transition(Constants.TokenType.EndCommand, BASE, true)
	states[command_or_expression].add_text_rule(Constants.TokenType.Text)

	states[ASSIGNMENT] = LexerState.new(patterns)
	states[ASSIGNMENT].add_transition(Constants.TokenType.Variable)
	states[ASSIGNMENT].add_transition(Constants.TokenType.EqualToOrAssign, EXPRESSION)
	states[ASSIGNMENT].add_transition(Constants.TokenType.AddAssign, EXPRESSION)
	states[ASSIGNMENT].add_transition(Constants.TokenType.MinusAssign, EXPRESSION)
	states[ASSIGNMENT].add_transition(Constants.TokenType.MultiplyAssign, EXPRESSION)
	states[ASSIGNMENT].add_transition(Constants.TokenType.DivideAssign, EXPRESSION)

	states[FORMAT_FUNCTION] = LexerState.new(patterns)
	states[FORMAT_FUNCTION].add_transition(Constants.TokenType.FormatFunctionEnd, BASE, true)
	states[FORMAT_FUNCTION].add_transition(Constants.TokenType.ExpressionFunctionStart, format_expression, true)
	states[FORMAT_FUNCTION].add_text_rule(Constants.TokenType.Text)


	states[format_expression] = LexerState.new(patterns)
	states[format_expression].add_transition(Constants.TokenType.ExpressionFunctionEnd, FORMAT_FUNCTION)
	form_expression_state(states[format_expression])

	states[inline_expression] = LexerState.new(patterns)
	states[inline_expression].add_transition(Constants.TokenType.ExpressionFunctionEnd, BASE)
	form_expression_state(states[inline_expression])

	states[EXPRESSION] = LexerState.new(patterns)
	states[EXPRESSION].add_transition(Constants.TokenType.EndCommand, BASE)
	# states[EXPRESSION].add_transition(Constants.TokenType.FormatFunctionEnd, BASE)
	form_expression_state(states[EXPRESSION])

	states[LINK] = LexerState.new(patterns)
	states[LINK].add_transition(Constants.TokenType.OptionEnd, BASE, true)
	states[LINK].add_transition(Constants.TokenType.ExpressionFunctionStart, link_inline_expression, true)
	states[LINK].add_transition(Constants.TokenType.FormatFunctionStart, link_format_expression, true)
	states[LINK].add_transition(Constants.TokenType.FormatFunctionEnd, LINK, true)
	states[LINK].add_transition(Constants.TokenType.OptionDelimit, link_destination, true)
	states[LINK].add_text_rule(Constants.TokenType.Text)

	states[link_format_expression] = LexerState.new(patterns)
	states[link_format_expression].add_transition(Constants.TokenType.FormatFunctionEnd, LINK, true)
	states[link_format_expression].add_transition(Constants.TokenType.ExpressionFunctionStart, link_inline_expression, true)
	states[link_format_expression].add_text_rule(Constants.TokenType.Text)

	states[link_inline_expression] = LexerState.new(patterns)
	states[link_inline_expression].add_transition(Constants.TokenType.ExpressionFunctionEnd, LINK)
	form_expression_state(states[link_inline_expression])

	states[link_destination] = LexerState.new(patterns)
	states[link_destination].add_transition(Constants.TokenType.Identifier)
	states[link_destination].add_transition(Constants.TokenType.OptionEnd, BASE)

	default_state = states[BASE]

	for key in states.keys():
		states[key].name = key

func form_expression_state(expression_state):
	expression_state.add_transition(Constants.TokenType.Number)
	expression_state.add_transition(Constants.TokenType.Str)
	expression_state.add_transition(Constants.TokenType.LeftParen)
	expression_state.add_transition(Constants.TokenType.RightParen)
	expression_state.add_transition(Constants.TokenType.EqualTo)
	expression_state.add_transition(Constants.TokenType.EqualToOrAssign)
	expression_state.add_transition(Constants.TokenType.NotEqualTo)
	expression_state.add_transition(Constants.TokenType.GreaterThanOrEqualTo)
	expression_state.add_transition(Constants.TokenType.GreaterThan)
	expression_state.add_transition(Constants.TokenType.LessThanOrEqualTo)
	expression_state.add_transition(Constants.TokenType.LessThan)
	expression_state.add_transition(Constants.TokenType.Add)
	expression_state.add_transition(Constants.TokenType.Minus)
	expression_state.add_transition(Constants.TokenType.Multiply)
	expression_state.add_transition(Constants.TokenType.Divide)
	expression_state.add_transition(Constants.TokenType.Modulo)
	expression_state.add_transition(Constants.TokenType.And)
	expression_state.add_transition(Constants.TokenType.Or)
	expression_state.add_transition(Constants.TokenType.Xor)
	expression_state.add_transition(Constants.TokenType.Not)
	expression_state.add_transition(Constants.TokenType.Variable)
	expression_state.add_transition(Constants.TokenType.Comma)
	expression_state.add_transition(Constants.TokenType.TrueToken)
	expression_state.add_transition(Constants.TokenType.FalseToken)
	expression_state.add_transition(Constants.TokenType.NullToken)
	expression_state.add_transition(Constants.TokenType.Identifier)

func tokenize():
	var tokens = []

	indent_stack.clear()
	indent_stack.push_front([0, false])
	should_track_indent = false
	current_state = default_state

	var lines = text.split(LINE_SEPARATOR)
	var line_number = 1

	lines.append('')

	for line in lines:
		tokens += tokenize_line(line, line_number)
		line_number += 1

	var end_of_input = Token.new(
		Constants.TokenType.EndOfInput,
		current_state,
		line_number,
		0
	)
	tokens.append(end_of_input)

	return tokens

func tokenize_line(line, line_number):
	var token_stack = []

	var fresh_line = line.replace('\t','    ').replace('\r','')

	var indentation = line_indentation(line)
	var previous_indentation = indent_stack.front()[0]

	if should_track_indent && indentation > previous_indentation:
		indent_stack.push_front([indentation, true])

		var indent = Token.new(
			Constants.TokenType.Indent,
			current_state,
			filename,
			line_number,
			previous_indentation
		)
		indent.value = '%*s' % [indentation - previous_indentation, '']

		should_track_indent = false
		token_stack.push_front(indent)

	elif indentation < previous_indentation:
		while indentation < indent_stack.front()[0]:
			var top = indent_stack.pop_front()[1]
			if top:
				var deindent = Token.new(Constants.TokenType.Dedent, current_state, line_number, 0)
				token_stack.push_front(deindent)
	
	var column = indentation
	var whitespace = RegEx.new()
	whitespace.compile(WHITESPACE)

	while column < fresh_line.length():
		if fresh_line.substr(column).begins_with(LINE_COMENT):
			break
		
		var matched = false

		for rule in current_state.rules:
			var found = rule.regex.search(fresh_line, column)
			
			if !found:
				continue

			var token_text = ''

			# NOTE: If this is text then we back up to the most recent delimiting token
			#		and treat everything from there as text.
			if rule.token_type == Constants.TokenType.Text:
				
				var start_index = indentation

				if token_stack.size() > 0 :
					while token_stack.front().type == Constants.TokenType.Identifier:
						token_stack.pop_front()
					
					var start_delimit_token = token_stack.front()
					start_index =  start_delimit_token.column

					if start_delimit_token.type == Constants.TokenType.Indent:
						start_index += start_delimit_token.value.length()
					if start_delimit_token.type == Constants.TokenType.Dedent:
						start_index = indentation
				
				column = start_index
				var end_index = found.get_start() + found.get_string().length()

				token_text = fresh_line.substr(start_index, end_index - start_index)
			else:
				token_text = found.get_string()

			column += token_text.length()

			if rule.token_type == Constants.TokenType.Str:
				token_text = token_text.substr(1, token_text.length() - 2)
				token_text = token_text.replace('\\\\', '\\')
				token_text = token_text.replace('\\\'','\'')

			var token = Token.new(
				rule.token_type,
				current_state,
				filename,
				line_number,
				column,
				token_text
			)
			token.delimits_text = rule.delimits_text

			token_stack.push_front(token)

			if rule.enter_state != null and rule.enter_state.length() > 0:
				if not states.has(rule.enter_state):
					printerr('State[%s] not known - line(%s) col(%s)' % [rule.enter_state, line_number, column])
					return []
				
				enter_state(states[rule.enter_state])

				if should_track_indent:
					if indent_stack.front()[0] < indentation:
						indent_stack.append([indentation, false])
			
			matched = true
			break

		if not matched:
			var rules = []
			for rule in current_state.rules:
				rules.append('"%s" (%s)' % [Constants.token_type_name(rule.token_type), rule.human_readable_identifier])

			var error_data = [
				PoolStringArray(rules).join(', ') if rules.size() == 1 else PoolStringArray(rules.slice(0, rules.size() - 2)).join(', ') + ' or %s' % rules[-1],
				filename,
				title,
				line_number,
				column
			]
			assert(false, 'Expected %s in file %s in node "%s" on line #%d (column #%d)' % error_data)

		var last_whitespace = whitespace.search(line, column)
		if last_whitespace:
			column += last_whitespace.get_string().length()
		
	
	token_stack.invert()

	return token_stack

func line_indentation(line):
	var indent_regex = RegEx.new()
	indent_regex.compile('^(\\s*)')

	var found = indent_regex.search(line)
	
	if !found or found.get_string().length() <= 0:
		return 0

	return found.get_string().length()

func enter_state(state):
	current_state = state;
	if current_state.track_indent:
		should_track_indent = true

class Token:
	var type = -1
	var value = ''

	var filename = ''
	var line_number = -1
	var column = -1
	var text = ''

	var delimits_text = false
	var parameter_count = -1
	var lexer_state = ''

	func _init(_type, _state, _filename, _line_number = -1, _column = -1, _value = ''):
		type = _type
		lexer_state = _state.name
		filename = _filename
		line_number = _line_number
		column = _column
		value = _value

	func _to_string():
		return '%s (%s) at %s:%s (state: %s)' % [Constants.token_type_name(type), value, line_number, column, lexer_state]
	
class LexerState:
	var name = ''
	var patterns = {}
	var rules = []
	var track_indent = false

	func _init(_patterns):
		patterns = _patterns

	func add_transition(type, state = '', delimit_text = false):
		var pattern = '\\G%s' % patterns[type][0]
		var rule = Rule.new(type, pattern, patterns[type][1], state, delimit_text)
		rules.append(rule)
		return rule
	
	func add_text_rule(type, state = ''):
		if contains_text_rule() :
			printerr('State already contains Text rule')
			return null
		
		var delimiters:Array = []
		for rule in rules:
			if rule.delimits_text:
				delimiters.append('%s' % rule.regex.get_pattern().substr(2))

		var pattern = '\\G((?!%s).)*' % [PoolStringArray(delimiters).join('|')]
		var rule = add_transition(type, state)
		rule.regex = RegEx.new()
		rule.regex.compile(pattern)
		rule.is_text_rule = true
		return rule

	func contains_text_rule():
		for rule in rules:
			if rule.is_text_rule:
				return true
		return false
	
class Rule:
	var regex

	var enter_state = ''
	var token_type = -1
	var is_text_rule = false
	var delimits_text = false
	var human_readable_identifier = ''

	func _init(_type, _regex, _human_readable_identifier, _enter_state, _delimits_text):
		token_type = _type

		regex = RegEx.new()
		regex.compile(_regex)

		human_readable_identifier = _human_readable_identifier
		enter_state = _enter_state
		delimits_text = _delimits_text

	func _to_string():
		return '[Rule : %s (%s) - %s]' % [Constants.token_type_name(token_type), human_readable_identifier, regex]
