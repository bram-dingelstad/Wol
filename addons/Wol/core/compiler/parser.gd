extends Object

const Constants = preload('res://addons/Wol/core/Constants.gd')
const Lexer = preload('res://addons/Wol/core/compiler/Lexer.gd')
const Value = preload('res://addons/Wol/core/Value.gd')

var tokens = []
var title = ''

func _init(_title, _tokens):
	title = _title
	tokens = _tokens
	
enum Associativity {
	Left,
	Right,
	None
}

func parse_node():
	return WolNode.new('Start', null, self)

func next_symbol_is(valid_types):
	var type = self.tokens.front().type
	for valid_type in valid_types:
		if type == valid_type:
			return true
	return false

# NOTE:0 look ahead for `<<` and `else`
func next_symbols_are(valid_types):
	var temporary = [] + tokens
	for type in valid_types:
		if temporary.pop_front().type != type:
			return false
	return true

func expect_symbol(token_types = []):
	var token = tokens.pop_front() as Lexer.Token
	
	if token_types.size() == 0:
		if token.type == Constants.TokenType.EndOfInput:
			assert(false, 'Unexpected end of input')
			return null
		return token

	for type in token_types:
		if token.type == type:
			return token
	
	var token_names = []
	for type in token_types:
		token_names.append(Constants.token_type_name(type))

	var error_guess = '\n'

	if Constants.token_type_name(token.type) == 'Identifier' \
			and Constants.token_type_name(token_types[0]) == 'OptionEnd':
		error_guess += 'Does the node your refer to have a space in it?'
	else:
		error_guess = ''

	var error_data = [
		token.filename,
		title,
		token.line_number,
		token.column,
		PoolStringArray(token_names).join(', '),
		Constants.token_type_name(token.type),
		error_guess
	]
	assert(false, '[%s|%s:%d:%d]:\nExpected token "%s" but got "%s"%s' % error_data)

static func tab(indent_level, input, newline = true):
	return '%*s| %s%s' % [indent_level * 2, '', input, '' if not newline else '\n']

class ParseNode:
	var name = ''

	var parent
	var line_number = -1
	var tags = []

	func _init(_parent, _parser):
		parent = _parent

		var tokens = _parser.tokens as Array
		if tokens.size() > 0:
			line_number = tokens.front().line_number
		else:
			line_number = -1

		tags = []

	func tree_string(_indent_level):
		return 'Not_implemented'

	func tags_to_string(_indent_level):
		return 'TAGS<tags_to_string>NOTIMPLEMENTED'

	func get_node_parent():
		var node = self
		while node != null:
			if node is ParseNode:
				return node as WolNode
			node = node.parent
		return null

	func tab(indent_level, input, newline = true):
		return '%*s| %s%s' % [ indent_level * 2, '', input, '' if !newline else '\n']
	
class WolNode extends ParseNode:
	var source  = ''
	
	var editor_node_tags = []
	var statements = []

	func _init(name, parent, parser).(parent, parser):
		self.name = name
		while parser.tokens.size() > 0 \
				and not parser.next_symbol_is([Constants.TokenType.Dedent, Constants.TokenType.EndOfInput]):
			statements.append(Statement.new(self, parser))

	func tree_string(indent_level):
		var info = []
		for statement in statements:
			info.append(statement.tree_string(indent_level + 1))

		return PoolStringArray(info).join('')

# TODO: Evaluate use
class Header extends ParseNode:
	pass

class Statement extends ParseNode:
	var Type = Constants.StatementTypes

	var type = -1
	var block
	var if_statement
	var option_statement
	var assignment
	var shortcut_option_group
	var custom_command
	var line = ''

	func _init(parent, parser).(parent, parser):
		if Block.can_parse(parser):
			block  = Block.new(self, parser)
			type = Type.Block

		elif IfStatement.can_parse(parser):
			if_statement = IfStatement.new(self, parser)
			type = Type.IfStatement

		elif OptionStatement.can_parse(parser):
			option_statement = OptionStatement.new(self, parser)
			type = Type.OptionStatement

		elif Assignment.can_parse(parser):
			assignment = Assignment.new(self, parser)
			type = Type.AssignmentStatement

		elif ShortcutOptionGroup.can_parse(parser):
			shortcut_option_group = ShortcutOptionGroup.new(self, parser)
			type = Type.ShortcutOptionGroup

		elif CustomCommand.can_parse(parser):
			custom_command = CustomCommand.new(self, parser)
			type = Type.CustomCommand

		elif parser.next_symbol_is([Constants.TokenType.Text]):
			line = parser.expect_symbol([Constants.TokenType.Text]).value
			type = Type.Line

		else:
			printerr('Expected a statement but got %s instead. (probably an imbalanced if statement)' % parser.tokens.front()._to_string())
		
		var tags = []

		while parser.next_symbol_is([Constants.TokenType.TagMarker]):
			parser.expect_symbol([Constants.TokenType.TagMarker])
			var tag = parser.expect_symbol([Constants.TokenType.Identifier]).value
			tags.append(tag)

		if tags.size() > 0:
			self.tags = tags

	func tree_string(indent_level):
		var info = []

		match type:
			Type.Block:
				info.append(block.tree_string(indent_level))
			Type.IfStatement:
				info.append(if_statement.tree_string(indent_level))
			Type.AssignmentStatement:
				info.append(assignment.tree_string(indent_level))
			Type.OptionStatement:
				info.append(option_statement.tree_string(indent_level))
			Type.ShortcutOptionGroup:
				info.append(shortcut_option_group.tree_string(indent_level))
			Type.CustomCommand:
				info.append(custom_command.tree_string(indent_level))
			Type.Line:
				info.append(tab(indent_level, 'Line: %s' % line))
			_:
				printerr('Cannot print statement')

		return PoolStringArray(info).join('')

class CustomCommand extends ParseNode:

	enum Type {
		Expression,
		ClientCommand
	}

	var type = -1
	var expression
	var client_command

	func _init(parent, parser).(parent, parser):
		parser.expect_symbol([Constants.TokenType.BeginCommand])

		var command_tokens = []
		command_tokens.append(parser.expect_symbol())

		while not parser.next_symbol_is([Constants.TokenType.EndCommand]):
			command_tokens.append(parser.expect_symbol())

		parser.expect_symbol([Constants.TokenType.EndCommand])
		
		#if first token is identifier and second is leftt parenthesis
		#evaluate as function
		if (command_tokens.size() > 1 && command_tokens[0].type == Constants.TokenType.Identifier
			&& command_tokens[1].type == Constants.TokenType.LeftParen):
			var p = get_script().new(command_tokens, parser.library)
			expression = ExpressionNode.parse(self, p)
			type = Type.Expression
		else:
			#otherwise evaluuate command
			type = Type.ClientCommand
			self.client_command = command_tokens[0].value
	
	func tree_string(indent_level):
		match type:
			Type.Expression:
				return tab(indent_level, 'Expression: %s' % expression.tree_string(indent_level+1))
			Type.ClientCommand:
				return tab(indent_level, 'Command: %s' % client_command)
		return ''
	
	static func can_parse(parser):
		return (parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.Text])
				or parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.Identifier]))
		
class ShortcutOptionGroup extends ParseNode:
	var options = []

	func _init(parent, parser).(parent, parser):

		# parse options until there is no more
		# expect one otherwise invalid

		var index = 1
		options.append(ShortCutOption.new(index, self, parser))
		index += 1
		while parser.next_symbol_is([Constants.TokenType.ShortcutOption]):
			options.append(ShortCutOption.new(index, self, parser))
			index += 1

	func tree_string(indent_level):
		var info = []

		info.append(tab(indent_level, 'Shortcut Option Group{'))

		for option in options:
			info.append(option.tree_string(indent_level+1))

		info.append(tab(indent_level, '}'))

		return PoolStringArray(info).join('')
	
	static func can_parse(parser):
		return parser.next_symbol_is([Constants.TokenType.ShortcutOption])

class ShortCutOption extends ParseNode:
	var label = ''
	var condition
	var node

	func _init(index, parent, parser).(parent, parser):
		parser.expect_symbol([Constants.TokenType.ShortcutOption])
		label = parser.expect_symbol([Constants.TokenType.Text]).value

		# NOTE: Parse the conditional << if $x >> when it exists
		var tags = []
		while parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.IfToken]) \
			or parser.next_symbol_is([Constants.TokenType.TagMarker]):
			
			if parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.IfToken]):
				parser.expect_symbol([Constants.TokenType.BeginCommand])
				parser.expect_symbol([Constants.TokenType.IfToken])
				condition = ExpressionNode.parse(self, parser)
				parser.expect_symbol([Constants.TokenType.EndCommand])

			elif parser.next_symbol_is([Constants.TokenType.TagMarker]):
				parser.expect_symbol([Constants.TokenType.TagMarker])
				var tag = parser.expect_symbol([Constants.TokenType.Identifier]).value
				tags.append(tag)

		
		self.tags = tags
		# parse remaining statements

		if parser.next_symbol_is([Constants.TokenType.Indent]):
			parser.expect_symbol([Constants.TokenType.Indent])
			node = WolNode.new('%s.%s' % [parent.name, index], self, parser)
			parser.expect_symbol([Constants.TokenType.Dedent])


	func tree_string(indent_level):
		var info = []

		info.append(tab(indent_level, 'Option \'%s\'' % label))

		if condition != null:
			info.append(tab(indent_level + 1, '(when:'))
			info.append(condition.tree_string(indent_level + 2))
			info.append(tab(indent_level + 1, '),'))

		if node != null:
			info.append(tab(indent_level, '{'))
			info.append(node.tree_string(indent_level + 1))
			info.append(tab(indent_level, '}'))

		return PoolStringArray(info).join('')
	
#Blocks are groups of statements with the same indent level
class Block extends ParseNode:
	
	var statements = []

	func _init(parent, parser).(parent, parser):
		#read indent
		parser.expect_symbol([Constants.TokenType.Indent])

		#keep reading statements until we hit a dedent
		while not parser.next_symbol_is([Constants.TokenType.Dedent]):
			#parse all statements including nested blocks
			statements.append(Statement.new(self, parser))

		#clean up dedent
		parser.expect_symbol([Constants.TokenType.Dedent])
	
		
	func tree_string(indent_level):
		var info = []

		info.append(tab(indent_level, 'Block {'))

		for statement in statements:
			info.append(statement.tree_string(indent_level + 1))

		info.append(tab(indent_level, '}'))

		return PoolStringArray(info).join('')

	static func can_parse(parser):
		return parser.next_symbol_is([Constants.TokenType.Indent])

# NOTE: Option Statements are links to other nodes
class OptionStatement extends ParseNode:
	var destination = ''
	var label = ''

	func _init(parent, parser).(parent, parser):
		var strings = []

		# NOTE: parse [[LABEL
		parser.expect_symbol([Constants.TokenType.OptionStart])
		strings.append(parser.expect_symbol([Constants.TokenType.Text]).value)

		# NOTE: if there is a | get the next string
		if parser.next_symbol_is([Constants.TokenType.OptionDelimit]):
			parser.expect_symbol([Constants.TokenType.OptionDelimit])
			var t = parser.expect_symbol([Constants.TokenType.Text, Constants.TokenType.Identifier])

			strings.append(t.value as String)
		
		label = strings[0] if strings.size() > 1 else ''
		destination = strings[1] if strings.size() > 1 else strings[0]

		parser.expect_symbol([Constants.TokenType.OptionEnd])

	func tree_string(indent_level):
		if label != null:
			return tab(indent_level, 'Option: %s -> %s' % [label, destination])
		else:
			return tab(indent_level, 'Option: -> %s' % destination)

	static func can_parse(parser):
		return parser.next_symbol_is([Constants.TokenType.OptionStart])

class IfStatement extends ParseNode:
	var clauses = []#

	func _init(parent, parser).(parent, parser):
		
		#<<if Expression>>
		var prime = Clause.new()

		parser.expect_symbol([Constants.TokenType.BeginCommand])
		parser.expect_symbol([Constants.TokenType.IfToken])
		prime.expression = ExpressionNode.parse(self, parser)
		parser.expect_symbol([Constants.TokenType.EndCommand])

		#read statements until 'endif' or 'else' or 'else if'
		var statements = []#statement
		while not parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.EndIf]) \
				and not parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.ElseToken]) \
				and not parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.ElseIf]):
			
			statements.append(Statement.new(self, parser))

			#ignore dedent
			while parser.next_symbol_is([Constants.TokenType.Dedent]):
				parser.expect_symbol([Constants.TokenType.Dedent])
		
		prime.statements = statements
		clauses.append(prime)

		#handle all else if
		while parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.ElseIf]):
			var clause_elif = Clause.new()

			#parse condition syntax
			parser.expect_symbol([Constants.TokenType.BeginCommand])
			parser.expect_symbol([Constants.TokenType.ElseIf])
			clause_elif.expression = ExpressionNode.parse(self, parser)
			parser.expect_symbol([Constants.TokenType.EndCommand])


			var elif_statements = []#statement
			while not parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.EndIf]) \
					and not parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.ElseToken]) \
					and not parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.ElseIf]):
				
				elif_statements.append(Statement.new(self, parser))

				#ignore dedent
				while parser.next_symbol_is([Constants.TokenType.Dedent]):
					parser.expect_symbol([Constants.TokenType.Dedent])
			
			clause_elif.statements = statements
			clauses.append(clause_elif)
		
		#handle else if exists
		if (parser.next_symbols_are([Constants.TokenType.BeginCommand,
			Constants.TokenType.ElseToken, Constants.TokenType.EndCommand])):

			#expect no expression - just <<else>>
			parser.expect_symbol([Constants.TokenType.BeginCommand])
			parser.expect_symbol([Constants.TokenType.ElseToken])
			parser.expect_symbol([Constants.TokenType.EndCommand])

			#parse until hit endif
			var clause_else = Clause.new()
			var el_statements = []#statement
			while not parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.EndIf]):
				el_statements.append(Statement.new(self, parser))

			clause_else.statements = el_statements
			clauses.append(clause_else)

			#ignore dedent
			while parser.next_symbol_is([Constants.TokenType.Dedent]):
				parser.expect_symbol([Constants.TokenType.Dedent])

		#finish
		parser.expect_symbol([Constants.TokenType.BeginCommand])
		parser.expect_symbol([Constants.TokenType.EndIf])
		parser.expect_symbol([Constants.TokenType.EndCommand])


	func tree_string(indent_level):
		var info = []
		var first = true

		for clause in clauses:
			if first:
				info.append(tab(indent_level, 'if:'))
			elif clause.expression!=null:
				info.append(tab(indent_level, 'Else If'))
			else:
				info.append(tab(indent_level, 'Else:'))

			info.append(clause.tree_string(indent_level +1))

		return info.join('')

	static func can_parse(parser):
		return parser.next_symbols_are([Constants.TokenType.BeginCommand, Constants.TokenType.IfToken])
	pass

class ValueNode extends ParseNode:
	var value

	func _init(parent, parser, token = null).(parent, parser):

		var t = token
		if t == null :
			parser.expect_symbol([Constants.TokenType.Number,
		Constants.TokenType.Variable, Constants.TokenType.Str])
		use_token(t)

	#store value depending on type
	func use_token(token):
		match token.type:
			Constants.TokenType.Number:
				value = Value.new(float(token.value))
			Constants.TokenType.Str:
				value = Value.new(token.value)
			Constants.TokenType.FalseToken:
				value = Value.new(false)
			Constants.TokenType.TrueToken:
				value = Value.new(true)
			Constants.TokenType.Variable:
				value = Value.new(null)
				value.type = Constants.ValueType.Variable
				value.variable = token.value
			Constants.TokenType.NullToken:
				value = Value.new(null)
			_:
				printerr('%s, Invalid token type' % token.name)

	func tree_string(indent_level):
		return tab(indent_level, '%s' % value.value())

class ExpressionNode extends ParseNode:
	var type
	var value
	var function
	var parameters = []

	func _init(parent, parser, _value, _function = '', _parameters = []).(parent, parser):

		if _value != null:
			type = Constants.ExpressionType.Value
			value = _value
		else:
			type = Constants.ExpressionType.FunctionCall
			function = _function
			parameters = _parameters
	
	func tree_string(indent_level):
		var info = []
		match type:
			Constants.ExpressionType.Value:
				return value.tree_string(indent_level)

			Constants.ExpressionType.FunctionCall:
				info.append(tab(indent_level, 'Func[%s - parameters(%s)]:{'%[function, parameters.size()]))
				for param in parameters:
					info.append(param.tree_string(indent_level+1))
				info.append(tab(indent_level, '}'))

		return info.join('')

	# using Djikstra's shunting-yard algorithm to convert stream of expresions into postfix notation,
	# & then build a tree of expressions
	static func parse(parent, parser):
		var rpn = []
		var op_stack = []
			
		#track parameters
		var func_stack = []
		
		var valid_types = [
			Constants.TokenType.Number,
			Constants.TokenType.Variable,
			Constants.TokenType.Str,
			Constants.TokenType.LeftParen,
			Constants.TokenType.RightParen,
			Constants.TokenType.Identifier,
			Constants.TokenType.Comma,
			Constants.TokenType.TrueToken,
			Constants.TokenType.FalseToken,
			Constants.TokenType.NullToken
		]
		valid_types += Operator.op_types()
		valid_types.invert()

		var last

		#read expression content
		while parser.tokens.size() > 0 && parser.next_symbol_is(valid_types):
			var next = parser.expect_symbol(valid_types)

			if next.type == Constants.TokenType.Variable \
					or next.type == Constants.TokenType.Number \
					or next.type == Constants.TokenType.Str \
					or next.type == Constants.TokenType.FalseToken \
					or next.type == Constants.TokenType.TrueToken \
					or next.type == Constants.TokenType.NullToken:
				
				#output primitives
				rpn.append(next)
			elif next.type == Constants.TokenType.Identifier:
				op_stack.push_back(next)
				func_stack.push_back(next)

				#next token is parent - left
				next = parser.expect_symbol([Constants.TokenType.LeftParen])
				op_stack.push_back(next)

			elif next.type == Constants.TokenType.Comma:
				#resolve sub expression before moving on
				while op_stack.back().type != Constants.TokenType.LeftParen:
					var p = op_stack.pop_back()
					if p == null:
						printerr('unbalanced parenthesis %s ' % next.name)
						break
					rpn.append(p)

				
				#next token in op_stack left paren
				# next parser token not allowed to be right paren or comma
				if parser.next_symbol_is([Constants.TokenType.RightParen,
					Constants.TokenType.Comma]):
					printerr('Expected Expression : %s' % parser.tokens.front().name)
				
				#find the closest function on stack
				#increment parameters
				func_stack.back().param_count+=1
				
			elif Operator.is_op(next.type):
				#this is an operator

				#if this is a minus, we need to determine if it is a
				#unary minus or a binary minus.
				#unary minus looks like this : -1
				#binary minus looks like this 2 - 3
				#thins get complex when we say stuff like: 1 + -1
				#but its easier when we realize that a minus
				#is only unary when the last token was a left paren,
				#an operator, or its the first token.

				if next.type == Constants.TokenType.Minus:
					if last == null \
							or last.type == Constants.TokenType.LeftParen \
							or Operator.is_op(last.type):
						#unary minus
						next.type = Constants.TokenType.UnaryMinus
				
				#cannot assign inside expression
				# x = a is the same as x == a
				if next.type == Constants.TokenType.EqualToOrAssign:
					next.type = Constants.TokenType.EqualTo

				#operator precedence
				while (ExpressionNode.is_apply_precedence(next.type, op_stack)):
					var op = op_stack.pop_back()
					rpn.append(op)

				op_stack.push_back(next)
			
			elif next.type == Constants.TokenType.LeftParen:
				#entered parenthesis sub expression
				op_stack.push_back(next)
			elif next.type == Constants.TokenType.RightParen:
				#leaving sub expression
				# resolve order of operations
				while op_stack.back().type != Constants.TokenType.LeftParen:
					rpn.append(op_stack.pop_back())
					if op_stack.back() == null:
						printerr('Unbalanced parenthasis #RightParen. Parser.ExpressionNode')
				
				
				op_stack.pop_back()
				if op_stack.back().type == Constants.TokenType.Identifier:
					#function call
					#last token == left paren this == no parameters
					#else
					#we have more than 1 param
					if last.type != Constants.TokenType.LeftParen:
						func_stack.back().param_count+=1
					
					rpn.append(op_stack.pop_back())
					func_stack.pop_back()

			#record last token used
			last = next

		#no more tokens : pop operators to output
		while op_stack.size() > 0:
			rpn.append(op_stack.pop_back())

		#if rpn is empty then this is not expression
		if rpn.size() == 0:
			printerr('Error parsing expression: Expression not found!')

		#build expression tree
		var first = rpn.front()
		var eval_stack = []#ExpressionNode

		while rpn.size() > 0:
			var next = rpn.pop_front()
			if Operator.is_op(next.type):
				#operation
				var info = Operator.op_info(next.type)

				if eval_stack.size() < info.arguments:
					printerr('Error parsing : Not enough arguments for %s [ got %s expected - was %s]'%[Constants.token_type_name(next.type), eval_stack.size(), info.arguments])

				var function_parameters = []
				for _i in range(info.arguments):
					function_parameters.append(eval_stack.pop_back())

				function_parameters.invert()

				var function_name = get_func_name(next.type)
				var expression = ExpressionNode.new(parent, parser, null, function_name, function_parameters)
				
				eval_stack.append(expression)

			# A function call
			elif next.type == Constants.TokenType.Identifier:
				var function_name = next.value

				var function_parameters = []
				for _i in range(next.param_count):
					function_parameters.append(eval_stack.pop_back())
				
				function_parameters.invert()

				var expression = ExpressionNode.new(parent, parser, null, function_name, function_parameters)
	
				eval_stack.append(expression)

			# A raw value
			else:
				var raw_value = ValueNode.new(parent, parser, next)
				var expression = ExpressionNode.new(parent, parser, raw_value)
				eval_stack.append(expression)

		
		#we should have a single root expression left
		#if more then we failed ---- NANI
		if eval_stack.size() != 1:
			printerr('[%s] Error parsing expression (stack did not reduce correctly )' % first.name)

		return eval_stack.pop_back()

	static func get_func_name(_type):
		var string = ''
		
		for key in Constants.TokenType.keys():
			if Constants.TokenType[key] == _type:
				return key					
		return string

	static func is_apply_precedence(_type, operator_stack):
		if operator_stack.size() == 0:
			return false
		
		if not Operator.is_op(_type):
			assert(false, 'Unable to parse expression!')
		
		var second = operator_stack.back().type

		if not Operator.is_op(second):
			return false
		
		var first_info = Operator.op_info(_type)
		var second_info = Operator.op_info(second)

		return \
			(first_info.associativity == Associativity.Left \
				and first_info.precedence <= second_info.precedence) \
			or \
			(first_info.associativity == Associativity.Right \
						and first_info.precedence < second_info.precedence)

class Assignment extends ParseNode:
	var destination
	var value
	var operation

	func _init(parent, parser).(parent, parser):
		parser.expect_symbol([Constants.TokenType.BeginCommand])
		parser.expect_symbol([Constants.TokenType.Set])
		destination = parser.expect_symbol([Constants.TokenType.Variable]).value
		operation = parser.expect_symbol(Assignment.valid_ops()).type
		value = ExpressionNode.parse(self, parser)
		parser.expect_symbol([Constants.TokenType.EndCommand])

	func tree_string(indent_level):
		var info = []
		info.append(tab(indent_level, 'set:'))
		info.append(tab(indent_level + 1, destination))
		info.append(tab(indent_level + 1, Constants.token_type_name(operation)))
		info.append(value.tree_string(indent_level + 1))
		return info.join('')

		
	static func can_parse(parser):
		return parser.next_symbols_are([
			Constants.TokenType.BeginCommand,
			Constants.TokenType.Set
		])

	static func valid_ops():
		return [
			Constants.TokenType.EqualToOrAssign,
			Constants.TokenType.AddAssign,
			Constants.TokenType.MinusAssign,
			Constants.TokenType.DivideAssign,
			Constants.TokenType.MultiplyAssign
		]

class Operator extends ParseNode:
	var op_type

	func _init(parent, parser, _op_type = null).(parent, parser):
		if _op_type == null :
			op_type = parser.expect_symbol(Operator.op_types()).type
		else:
			op_type = _op_type

	func tree_string(indent_level):
		var info = []
		info.append(tab(indent_level, op_type))
		return info.join('')

	static func op_info(op):
		if not Operator.is_op(op) :
			printerr('%s is not a valid operator' % op.name)

		#determine associativity and operands
		# each operand has
		var TokenType = Constants.TokenType

		match op:
			TokenType.Not, TokenType.UnaryMinus:
				return OperatorInfo.new(Associativity.Right, 30, 1)
			TokenType.Multiply, TokenType.Divide, TokenType.Modulo:
				return OperatorInfo.new(Associativity.Left, 20, 2)
			TokenType.Add, TokenType.Minus:
				return OperatorInfo.new(Associativity.Left, 15, 2)
			TokenType.GreaterThan, TokenType.LessThan, TokenType.GreaterThanOrEqualTo, TokenType.LessThanOrEqualTo:
				return OperatorInfo.new(Associativity.Left, 10, 2)
			TokenType.EqualTo, TokenType.EqualToOrAssign, TokenType.NotEqualTo:
				return OperatorInfo.new(Associativity.Left, 5, 2)
			TokenType.And:
				return OperatorInfo.new(Associativity.Left, 4, 2)
			TokenType.Or:
				return OperatorInfo.new(Associativity.Left, 3, 2)
			TokenType.Xor:
				return OperatorInfo.new(Associativity.Left, 2, 2)
			_:
				printerr('Unknown operator: %s' % op.name)
		return null

	static func is_op(type):
		return type in op_types()

	static func op_types():
		return [
			Constants.TokenType.Not,
			Constants.TokenType.UnaryMinus,

			Constants.TokenType.Add,
			Constants.TokenType.Minus,
			Constants.TokenType.Divide,
			Constants.TokenType.Multiply,
			Constants.TokenType.Modulo,

			Constants.TokenType.EqualToOrAssign,
			Constants.TokenType.EqualTo,
			Constants.TokenType.GreaterThan,
			Constants.TokenType.GreaterThanOrEqualTo,
			Constants.TokenType.LessThan,
			Constants.TokenType.LessThanOrEqualTo,
			Constants.TokenType.NotEqualTo,

			Constants.TokenType.And,
			Constants.TokenType.Or,

			Constants.TokenType.Xor
		]

class OperatorInfo:
	var associativity
	var precedence = -1
	var arguments = -1

	func _init(_associativity, _precedence, _arguments):
		associativity = _associativity
		precedence = _precedence
		arguments = _arguments

class Clause:
	var expression
	var statements = [] #Statement

	func _init(_expression = null, _statements = []):
		expression = _expression
		statements = _statements

	func tree_string(indent_level):
		var info = []

		if expression != null:
			info.append(expression.tree_string(indent_level))
		info.append(tab(indent_level, '{'))

		for statement in statements:
			info.append(statement.tree_string(indent_level + 1))

		info.append(tab(indent_level, '}'))
		return PoolStringArray(info).join('')

	func tab(indent_level, input, newline = true):
		return '%*s| %s%s' % [indent_level * 2, '', input, '' if !newline else '\n']
