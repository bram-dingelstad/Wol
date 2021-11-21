extends Object
class_name Lexer

const Constants = preload('res://addons/Wol/core/constants.gd')

const LINE_COMENT : String = '//'
const FORWARD_SLASH : String = '/'

const LINE_SEPARATOR : String = '\n'

const BASE : String = 'base'
const DASH : String = '-'
const COMMAND : String = 'command'
const LINK : String = 'link'
const SHORTCUT : String = 'shortcut'
const TAG : String = 'tag'
const EXPRESSION : String = 'expression'
const ASSIGNMENT : String = 'assignment'
const OPTION : String = 'option'
const OR : String = 'or'
const DESTINATION : String = 'destination'

var WHITESPACE : String = '\\s*'

var _states : Dictionary = {}
var _defaultState : LexerState
var _currentState : LexerState

var _indentStack : Array = []
var _shouldTrackIndent : bool = false

var filename = ''
var title = ''
var text = ''

func _init(_filename, _title, _text):
	create_states()

	filename = _filename
	title = _title
	text = _text

func create_states():
	var patterns : Dictionary = {}
	patterns[Constants.TokenType.Text] = ['.*', 'any text']

	patterns[Constants.TokenType.Number] = ['\\-?[0-9]+(\\.[0-9+])?', 'any number']
	patterns[Constants.TokenType.Str] = ['\'([^\'\\\\]*(?:\\.[^\'\\\\]*)*)\'', 'any text']
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

	#compound states
	var shortcut_option : String = SHORTCUT + DASH + OPTION
	var shortcut_option_tag : String = shortcut_option + DASH + TAG
	var command_or_expression : String = COMMAND + DASH + OR + DASH + EXPRESSION
	var link_destination : String = LINK + DASH + DESTINATION

	_states = {}

	_states[BASE] = LexerState.new(patterns)
	_states[BASE].add_transition(Constants.TokenType.BeginCommand,COMMAND,true)
	_states[BASE].add_transition(Constants.TokenType.OptionStart,LINK,true)
	_states[BASE].add_transition(Constants.TokenType.ShortcutOption, shortcut_option)
	_states[BASE].add_transition(Constants.TokenType.TagMarker,TAG,true)
	_states[BASE].add_text_rule(Constants.TokenType.Text)

	_states[TAG] = LexerState.new(patterns)
	_states[TAG].add_transition(Constants.TokenType.Identifier,BASE)

	_states[shortcut_option] = LexerState.new(patterns)
	_states[shortcut_option].track_indent = true
	_states[shortcut_option].add_transition(Constants.TokenType.BeginCommand,EXPRESSION,true)
	_states[shortcut_option].add_transition(Constants.TokenType.TagMarker,shortcut_option_tag,true)
	_states[shortcut_option].add_text_rule(Constants.TokenType.Text,BASE)
	
	_states[shortcut_option_tag] = LexerState.new(patterns)
	_states[shortcut_option_tag].add_transition(Constants.TokenType.Identifier,shortcut_option)

	_states[COMMAND] = LexerState.new(patterns)
	_states[COMMAND].add_transition(Constants.TokenType.IfToken,EXPRESSION)
	_states[COMMAND].add_transition(Constants.TokenType.ElseToken)
	_states[COMMAND].add_transition(Constants.TokenType.ElseIf,EXPRESSION)
	_states[COMMAND].add_transition(Constants.TokenType.EndIf)
	_states[COMMAND].add_transition(Constants.TokenType.Set, ASSIGNMENT)
	_states[COMMAND].add_transition(Constants.TokenType.EndCommand,BASE,true)
	_states[COMMAND].add_transition(Constants.TokenType.Identifier,command_or_expression)
	_states[COMMAND].add_text_rule(Constants.TokenType.Text)

	_states[command_or_expression] = LexerState.new(patterns)
	_states[command_or_expression].add_transition(Constants.TokenType.LeftParen,EXPRESSION)
	_states[command_or_expression].add_transition(Constants.TokenType.EndCommand,BASE,true)
	_states[command_or_expression].add_text_rule(Constants.TokenType.Text)

	_states[ASSIGNMENT] = LexerState.new(patterns)
	_states[ASSIGNMENT].add_transition(Constants.TokenType.Variable)
	_states[ASSIGNMENT].add_transition(Constants.TokenType.EqualToOrAssign, EXPRESSION)
	_states[ASSIGNMENT].add_transition(Constants.TokenType.AddAssign, EXPRESSION)
	_states[ASSIGNMENT].add_transition(Constants.TokenType.MinusAssign, EXPRESSION)
	_states[ASSIGNMENT].add_transition(Constants.TokenType.MultiplyAssign, EXPRESSION)
	_states[ASSIGNMENT].add_transition(Constants.TokenType.DivideAssign, EXPRESSION)

	_states[EXPRESSION] = LexerState.new(patterns)
	_states[EXPRESSION].add_transition(Constants.TokenType.EndCommand, BASE)
	_states[EXPRESSION].add_transition(Constants.TokenType.Number)
	_states[EXPRESSION].add_transition(Constants.TokenType.Str)
	_states[EXPRESSION].add_transition(Constants.TokenType.LeftParen)
	_states[EXPRESSION].add_transition(Constants.TokenType.RightParen)
	_states[EXPRESSION].add_transition(Constants.TokenType.EqualTo)
	_states[EXPRESSION].add_transition(Constants.TokenType.EqualToOrAssign)
	_states[EXPRESSION].add_transition(Constants.TokenType.NotEqualTo)
	_states[EXPRESSION].add_transition(Constants.TokenType.GreaterThanOrEqualTo)
	_states[EXPRESSION].add_transition(Constants.TokenType.GreaterThan)
	_states[EXPRESSION].add_transition(Constants.TokenType.LessThanOrEqualTo)
	_states[EXPRESSION].add_transition(Constants.TokenType.LessThan)
	_states[EXPRESSION].add_transition(Constants.TokenType.Add)
	_states[EXPRESSION].add_transition(Constants.TokenType.Minus)
	_states[EXPRESSION].add_transition(Constants.TokenType.Multiply)
	_states[EXPRESSION].add_transition(Constants.TokenType.Divide)
	_states[EXPRESSION].add_transition(Constants.TokenType.Modulo)
	_states[EXPRESSION].add_transition(Constants.TokenType.And)
	_states[EXPRESSION].add_transition(Constants.TokenType.Or)
	_states[EXPRESSION].add_transition(Constants.TokenType.Xor)
	_states[EXPRESSION].add_transition(Constants.TokenType.Not)
	_states[EXPRESSION].add_transition(Constants.TokenType.Variable)
	_states[EXPRESSION].add_transition(Constants.TokenType.Comma)
	_states[EXPRESSION].add_transition(Constants.TokenType.TrueToken)
	_states[EXPRESSION].add_transition(Constants.TokenType.FalseToken)
	_states[EXPRESSION].add_transition(Constants.TokenType.NullToken)
	_states[EXPRESSION].add_transition(Constants.TokenType.Identifier)

	_states[LINK] = LexerState.new(patterns)
	_states[LINK].add_transition(Constants.TokenType.OptionEnd, BASE, true)
	_states[LINK].add_transition(Constants.TokenType.OptionDelimit, link_destination, true)
	_states[LINK].add_text_rule(Constants.TokenType.Text)

	_states[link_destination] = LexerState.new(patterns)
	_states[link_destination].add_transition(Constants.TokenType.Identifier)
	_states[link_destination].add_transition(Constants.TokenType.OptionEnd, BASE)

	_defaultState = _states[BASE]

	for stateKey in _states.keys():
		_states[stateKey].stateName = stateKey

func tokenize():
	_indentStack.clear()
	_indentStack.push_front(IntBoolPair.new(0, false))
	_shouldTrackIndent = false

	var tokens : Array  = []

	_currentState = _defaultState

	var lines : PoolStringArray = text.split(LINE_SEPARATOR)
	lines.append('')

	var line_number : int = 1

	for line in lines:
		tokens += tokenize_line(line, line_number)
		line_number += 1

	var endOfInput = Token.new(
		Constants.TokenType.EndOfInput,
		_currentState,
		line_number,
		0
	)
	tokens.append(endOfInput)

	return tokens

func tokenize_line(line, line_number):
	var tokenStack : Array = []

	var freshLine = line.replace('\t','    ').replace('\r','')

	#record indentation
	var indentation = line_indentation(line)
	var prevIndentation = _indentStack.front()

	if _shouldTrackIndent && indentation > prevIndentation.key:
		#we add an indenation token to record indent level
		_indentStack.push_front(IntBoolPair.new(indentation,true))

		var indent : Token = Token.new(
			Constants.TokenType.Indent,
			_currentState,
			filename,
			line_number,
			prevIndentation.key
		)
		indent.value = '%*s' % [indentation - prevIndentation.key,'']

		_shouldTrackIndent = false
		tokenStack.push_front(indent)

	elif indentation < prevIndentation.key:
		#de-indent and then emit indentaiton token

		while indentation < _indentStack.front().key:
			var top : IntBoolPair = _indentStack.pop_front()
			if top.value:
				var deIndent : Token = Token.new(Constants.TokenType.Dedent,_currentState,line_number,0)
				tokenStack.push_front(deIndent)
	
	
	var column : int = indentation

	var whitespace : RegEx = RegEx.new()
	var error = whitespace.compile(WHITESPACE)
	if error != OK:
		printerr('unable to compile regex WHITESPACE')
		return []
	
	while column < freshLine.length():

		if freshLine.substr(column).begins_with(LINE_COMENT):
			break
		
		var matched : bool = false

		for rule in _currentState.rules:
			var found = rule.regex.search(freshLine, column)
			
			if !found:
				continue

			var tokenText : String

			if rule.token_type == Constants.TokenType.Text:
				#if this is text then we back up to the most recent
				#delimiting token and treat everything from there as text.
				
				var startIndex : int = indentation

				if tokenStack.size() > 0 :
					while tokenStack.front().type == Constants.TokenType.Identifier:
						tokenStack.pop_front()
					
					var startDelimitToken : Token = tokenStack.front()
					startIndex =  startDelimitToken.column

					if startDelimitToken.type == Constants.TokenType.Indent:
						startIndex += startDelimitToken.value.length()
					if startDelimitToken.type == Constants.TokenType.Dedent:
						startIndex = indentation
				#
				
				column = startIndex
				var end_index = found.get_start() + found.get_string().length()

				tokenText = freshLine.substr(startIndex, end_index - startIndex)
			
			else:
				tokenText = found.get_string()

			column += tokenText.length()

			#pre-proccess string
			if rule.token_type == Constants.TokenType.Str:
				tokenText = tokenText.substr(1, tokenText.length() - 2)
				tokenText = tokenText.replace('\\\\', '\\')
				tokenText = tokenText.replace('\\\'','\'')

			var token = Token.new(
				rule.token_type,
				_currentState,
				filename,
				line_number,
				column,
				tokenText
			)
			token.delimits_text = rule.delimits_text

			tokenStack.push_front(token)

			if rule.enter_state != null and rule.enter_state.length() > 0:
				if not _states.has(rule.enter_state):
					printerr('State[%s] not known - line(%s) col(%s)' % [rule.enter_state, line_number, column])
					return []
				
				enter_state(_states[rule.enter_state])

				if _shouldTrackIndent:
					if _indentStack.front().key < indentation:
						_indentStack.append(IntBoolPair.new(indentation, false))
			
			matched = true
			break

		if not matched:
			var rules = []
			for rule in _currentState.rules:
				rules.append('"%s" (%s)' % [Constants.token_type_name(rule.token_type), rule.human_readable_identifier])

			var error_data = [
				PoolStringArray(rules).join(', ') if rules.size() == 1 else PoolStringArray(rules.slice(0, rules.size() - 2)).join(', ') + ' or %s' % rules[-1],
				filename,
				title,
				line_number,
				column
			]
			assert(false, 'Expected %s in file %s in node "%s" on line #%d (column #%d)' % error_data)

		var lastWhiteSpace = whitespace.search(line, column)
		if lastWhiteSpace:
			column += lastWhiteSpace.get_string().length()
		
	
	tokenStack.invert()

	return tokenStack

func line_indentation(line:String)->int:
	var indentRegex : RegEx = RegEx.new()
	indentRegex.compile('^(\\s*)')

	var found : RegExMatch = indentRegex.search(line)
	
	if !found || found.get_string().length() <= 0:
		return 0

	return found.get_string().length()

func enter_state(state:LexerState):
	_currentState = state;
	if _currentState.track_indent:
		_shouldTrackIndent = true

class Token:
	var type = -1
	var value = ''

	var filename = ''
	var line_number = -1
	var column = -1
	var text = ''

	var delimits_text = false
	var paramCount = -1
	var lexerState = ''

	func _init(_type, _state, _filename, _line_number = -1, _column = -1, _value = ''):
		type = _type
		lexerState = _state.stateName
		filename = _filename
		line_number = _line_number
		column = _column
		value = _value

	func _to_string():
		return '%s (%s) at %s:%s (state: %s)' % [Constants.token_type_name(type),value,line_number,column,lexerState]
	
class LexerState:

	var stateName : String
	var patterns : Dictionary
	var rules : Array = []
	var track_indent : bool = false

	func _init(_patterns):
		patterns = _patterns

	func add_transition(type : int, state : String = '',delimitText : bool = false)->Rule:
		var pattern = '\\G%s' % patterns[type][0]
		# print('pattern = %s' % pattern)
		var rule = Rule.new(type, pattern, patterns[type][1], state, delimitText)
		rules.append(rule)
		return rule
	
	func add_text_rule(type : int, state : String = '')->Rule:
		if contains_text_rule() :
			printerr('State already contains Text rule')
			return null
		
		var delimiters:Array = []
		for rule in rules:
			if rule.delimits_text:
				delimiters.append('%s' % rule.regex.get_pattern().substr(2))

		var pattern = '\\G((?!%s).)*' % [PoolStringArray(delimiters).join('|')]
		var rule : Rule = add_transition(type,state)
		rule.regex = RegEx.new()
		rule.regex.compile(pattern)
		rule.is_text_rule = true
		return rule

	func contains_text_rule()->bool:
		for rule in rules:
			if rule.is_text_rule:
				return true
		return false
	
class Rule:
	var regex : RegEx

	var enter_state : String
	var token_type : int
	var is_text_rule : bool
	var delimits_text : bool
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

class IntBoolPair:
	var key = -1
	var value = false

	func _init(_key, _value):
		key = _key
		value = _value
	
