extends Object

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


func _init():
	create_states()

func create_states():
	var patterns : Dictionary = {}
	patterns[Constants.TokenType.Text] = '.*'

	patterns[Constants.TokenType.Number] = '\\-?[0-9]+(\\.[0-9+])?'
	patterns[Constants.TokenType.Str] = '\'([^\'\\\\]*(?:\\.[^\'\\\\]*)*)\''
	patterns[Constants.TokenType.TagMarker] = '\\#'
	patterns[Constants.TokenType.LeftParen] = '\\('
	patterns[Constants.TokenType.RightParen] =  '\\)'
	patterns[Constants.TokenType.EqualTo] = '(==|is(?!\\w)|eq(?!\\w))'
	patterns[Constants.TokenType.EqualToOrAssign] = '(=|to(?!\\w))'
	patterns[Constants.TokenType.NotEqualTo] = '(\\!=|neq(?!\\w))'
	patterns[Constants.TokenType.GreaterThanOrEqualTo] = '(\\>=|gte(?!\\w))'
	patterns[Constants.TokenType.GreaterThan] = '(\\>|gt(?!\\w))'
	patterns[Constants.TokenType.LessThanOrEqualTo] = '(\\<=|lte(?!\\w))'
	patterns[Constants.TokenType.LessThan] = '(\\<|lt(?!\\w))'
	patterns[Constants.TokenType.AddAssign] =  '\\+='
	patterns[Constants.TokenType.MinusAssign] = '\\-='
	patterns[Constants.TokenType.MultiplyAssign] = '\\*='
	patterns[Constants.TokenType.DivideAssign] = '\\/='
	patterns[Constants.TokenType.Add] = '\\+'
	patterns[Constants.TokenType.Minus] = '\\-'
	patterns[Constants.TokenType.Multiply] = '\\*'
	patterns[Constants.TokenType.Divide] = '\\/'
	patterns[Constants.TokenType.Modulo] = '\\%'
	patterns[Constants.TokenType.And] = '(\\&\\&|and(?!\\w))'
	patterns[Constants.TokenType.Or] = '(\\|\\||or(?!\\w))'
	patterns[Constants.TokenType.Xor] = '(\\^|xor(?!\\w))'
	patterns[Constants.TokenType.Not] = '(\\!|not(?!\\w))'
	patterns[Constants.TokenType.Variable] = '\\$([A-Za-z0-9_\\.])+'
	patterns[Constants.TokenType.Comma] = '\\,'
	patterns[Constants.TokenType.TrueToken] = 'true(?!\\w)'
	patterns[Constants.TokenType.FalseToken] = 'false(?!\\w)'
	patterns[Constants.TokenType.NullToken] = 'null(?!\\w)'
	patterns[Constants.TokenType.BeginCommand] = '\\<\\<'
	patterns[Constants.TokenType.EndCommand] = '\\>\\>'
	patterns[Constants.TokenType.OptionStart] = '\\[\\['
	patterns[Constants.TokenType.OptionEnd] = '\\]\\]'
	patterns[Constants.TokenType.OptionDelimit] = '\\|'
	patterns[Constants.TokenType.Identifier] = '[a-zA-Z0-9_:\\.]+'
	patterns[Constants.TokenType.IfToken] = 'if(?!\\w)'
	patterns[Constants.TokenType.ElseToken] = 'else(?!\\w)'
	patterns[Constants.TokenType.ElseIf] = 'elseif(?!\\w)'
	patterns[Constants.TokenType.EndIf] = 'endif(?!\\w)'
	patterns[Constants.TokenType.Set] = 'set(?!\\w)'
	patterns[Constants.TokenType.ShortcutOption] = '\\-\\>\\s*'

	#compound states
	var shortcut_option : String= SHORTCUT + DASH + OPTION
	var shortcut_option_tag : String = shortcut_option + DASH + TAG
	var command_or_expression : String= COMMAND + DASH + OR + DASH + EXPRESSION
	var link_destination : String = LINK + DASH + DESTINATION

	_states = {}

	_states[BASE] = LexerState.new(patterns)
	_states[BASE].add_transition(Constants.TokenType.BeginCommand,COMMAND,true)
	_states[BASE].add_transition(Constants.TokenType.OptionStart,LINK,true)
	_states[BASE].add_transition(Constants.TokenType.ShortcutOption,shortcut_option)
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
	_states[COMMAND].add_transition(Constants.TokenType.Set,ASSIGNMENT)
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

	pass

func tokenize(text:String)->Array:
	
	_indentStack.clear()
	_indentStack.push_front(IntBoolPair.new(0,false))
	_shouldTrackIndent = false

	var tokens : Array  = []

	_currentState = _defaultState

	var lines : PoolStringArray = text.split(LINE_SEPARATOR)
	lines.append('')

	var lineNumber : int = 1

	for line in lines:
		tokens+=tokenize_line(line,lineNumber)
		lineNumber+=1

	var endOfInput : Token = Token.new(Constants.TokenType.EndOfInput,_currentState,lineNumber,0)
	tokens.append(endOfInput)

	# print(tokens)

	return tokens

func tokenize_line(line:String, lineNumber : int)->Array:
	var tokenStack : Array = []

	var freshLine = line.replace('\t','    ').replace('\r','')

	#record indentation
	var indentation = line_indentation(line)
	var prevIndentation : IntBoolPair = _indentStack.front()

	if _shouldTrackIndent && indentation > prevIndentation.key:
		#we add an indenation token to record indent level
		_indentStack.push_front(IntBoolPair.new(indentation,true))

		var indent : Token = Token.new(Constants.TokenType.Indent,_currentState,lineNumber,prevIndentation.key)
		indent.value = '%*s' % [indentation - prevIndentation.key,'']

		_shouldTrackIndent = false
		tokenStack.push_front(indent)

	elif indentation < prevIndentation.key:
		#de-indent and then emit indentaiton token

		while indentation < _indentStack.front().key:
			var top : IntBoolPair = _indentStack.pop_front()
			if top.value:
				var deIndent : Token = Token.new(Constants.TokenType.Dedent,_currentState,lineNumber,0)
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
			var found : RegExMatch = rule.regex.search(freshLine, column)
			
			if !found:
				continue

			var tokenText : String

			if rule.tokenType == Constants.TokenType.Text:
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
				var endIndex : int = found.get_start() + found.get_string().length()

				tokenText = freshLine.substr(startIndex,endIndex-startIndex)
			
			else:
				tokenText = found.get_string()

			column += tokenText.length()

			#pre-proccess string
			if rule.tokenType == Constants.TokenType.Str:
				tokenText = tokenText.substr(1,tokenText.length() - 2)
				tokenText = tokenText.replace('\\\\', '\\')
				tokenText = tokenText.replace('\\\'','\'')

			var token : Token = Token.new(rule.tokenType,_currentState,lineNumber,column,tokenText)
			token.delimitsText = rule.delimitsText

			tokenStack.push_front(token)

			if rule.enterState != null && rule.enterState.length() > 0:

				if !_states.has(rule.enterState):
					printerr('State[%s] not known - line(%s) col(%s)'%[rule.enterState,lineNumber,column])
					return []
				
				enter_state(_states[rule.enterState])

				if _shouldTrackIndent:
					if _indentStack.front().key < indentation:
						_indentStack.append(IntBoolPair.new(indentation,false))
			
			matched = true
			break

		if !matched:
			# TODO: Send out some helpful messages
			printerr('expectedTokens [%s] - line(%s) col(%s)'%['refineErrors.Lexer.tokenize_line',lineNumber,column])
			return []

		var lastWhiteSpace : RegExMatch = whitespace.search(line,column)
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
	var type : int
	var value : String

	var lineNumber : int
	var column : int
	var text : String

	var delimitsText : bool= false
	var paramCount : int
	var lexerState : String

	func _init(type:int,state: LexerState, lineNumber:int = -1,column:int = -1,value:String =''):
		self.type = type
		self.lexerState = state.stateName
		self.lineNumber = lineNumber
		self.column = column
		self.value = value

	func _to_string():
		return '%s (%s) at %s:%s (state: %s)' % [Constants.token_type_name(type),value,lineNumber,column,lexerState]
	

class LexerState:

	var stateName : String
	var patterns : Dictionary
	var rules : Array = []
	var track_indent : bool = false

	func _init(patterns):
		self.patterns = patterns

	func add_transition(type : int, state : String = '',delimitText : bool = false)->Rule:
		var pattern = '\\G%s' % patterns[type]
		# print('pattern = %s' % pattern)
		var rule = Rule.new(type,pattern,state,delimitText)
		rules.append(rule)
		return rule
	
	func add_text_rule(type : int, state : String = '')->Rule:
		if contains_text_rule() :
			printerr('State already contains Text rule')
			return null
		
		var delimiters:Array = []
		for rule in rules:
			if rule.delimitsText:
				delimiters.append('%s' % rule.regex.get_pattern().substr(2))

		var pattern = '\\G((?!%s).)*' % [PoolStringArray(delimiters).join('|')]
		var rule : Rule = add_transition(type,state)
		rule.regex = RegEx.new()
		rule.regex.compile(pattern)
		rule.isTextRule = true
		return rule

	func contains_text_rule()->bool:
		for rule in rules:
			if rule.isTextRule:
				return true
		return false
	

class Rule:
	var regex : RegEx

	var enterState : String
	var tokenType : int
	var isTextRule : bool
	var delimitsText : bool

	func _init(type : int , regex : String, enterState : String, delimitsText:bool):
		self.tokenType = type
		self.regex = RegEx.new()
		self.regex.compile(regex)
		self.enterState = enterState
		self.delimitsText = delimitsText

	func _to_string():
		return '[Rule : %s - %s]' % [Constants.token_type_name(tokenType),regex]

class IntBoolPair:
	var key : int
	var value : bool

	func _init(key:int,value:bool):
		self.key = key
		self.value = value
	
