extends Object
class_name Compiler

const Constants = preload('res://addons/Wol/core/constants.gd')
const Lexer = preload('res://addons/Wol/core/compiler/lexer.gd')
const Program = preload('res://addons/Wol/core/program.gd')

#patterns
const INVALIDTITLENAME = '[\\[<>\\]{}\\|:\\s#\\$]'

#ERROR Codes
const NO_ERROR = 0x00
const LEXER_FAILURE = 0x01
const PARSER_FAILURE = 0x02
const INVALID_HEADER = 0x04
const DUPLICATE_NODES_IN_PROGRAM = 0x08
const ERR_COMPILATION_FAILED = 0x10

var _errors : int
var _lastError : int

#-----Class vars
var _currentNode : Program.WolNode
var _rawText : bool
var _fileName : String
var _containsImplicitStringTags : bool
var _labelCount : int = 0

#<String, Program.Line>
var _stringTable : Dictionary = {}
var _stringCount : int = 0
#<int, Constants.TokenType>
var _tokens : Dictionary = {}

static func compile_string(source: String, filename: String):
	var Parser = load('res://addons/Wol/core/compiler/parser.gd')
	var Compiler = load('res://addons/Wol/core/compiler/compiler.gd')

	var compiler = Compiler.new()
	compiler._fileName = filename

	#--------------Nodes
	var headerSep : RegEx = RegEx.new()
	headerSep.compile('---(\r\n|\r|\n)')
	var headerProperty : RegEx = RegEx.new()
	headerProperty.compile('(?<field>.*): *(?<value>.*)')

	assert(not not headerSep.search(source), 'No headers found')
	
	var lineNumber: int = 0
	
	var sourceLines : Array = source.split('\n',false)
	for i in range(sourceLines.size()):
		sourceLines[i] = sourceLines[i].strip_edges(false,true)

	var parsedNodes : Array = []
	
	while lineNumber < sourceLines.size():
		
		var title : String
		var body : String

		#get title
		while true:
			var line : String = sourceLines[lineNumber]
			lineNumber+=1
			
			if !line.empty():
				var result = headerProperty.search(line)
				if result != null :
					var field : String = result.get_string('field')
					var value : String = result.get_string('value')

					if field == 'title':
						title = value

			if(lineNumber >= sourceLines.size() || sourceLines[lineNumber] == '---'):
				break

		
		lineNumber+=1

		#past header
		var bodyLines : PoolStringArray = []
		
		while lineNumber < sourceLines.size() && sourceLines[lineNumber]!='===':
			bodyLines.append(sourceLines[lineNumber])
			lineNumber+=1

		lineNumber+=1

		body = bodyLines.join('\n')
		var lexer = Lexer.new()

		var tokens : Array = lexer.tokenize(body)
		var parser = Parser.new(tokens)

		var parserNode = parser.parse_node()

		parserNode.name = title
		parsedNodes.append(parserNode)
		while lineNumber < sourceLines.size() && sourceLines[lineNumber].empty():
			lineNumber+=1

	#--- End parsing nodes---

	var program = Program.new()

	#compile nodes
	for node in parsedNodes:
		compiler.compile_node(program, node)

	for key in compiler._stringTable:
		program.strings[key] = compiler._stringTable[key]

	return program

func compile_node(program, parsedNode):
	if program.nodes.has(parsedNode.name):
		emit_error(DUPLICATE_NODES_IN_PROGRAM)
		printerr('Duplicate node in program: %s' % parsedNode.name)
	else:
		var nodeCompiled = Program.WolNode.new()

		nodeCompiled.name = parsedNode.name
		nodeCompiled.tags = parsedNode.tags

		#raw text
		if parsedNode.source != null && !parsedNode.source.empty():
			nodeCompiled.sourceId = register_string(parsedNode.source,parsedNode.name,
			'line:'+parsedNode.name, 0, [])
		else:
			#compile node
			var startLabel : String = register_label()
			emit(Constants.ByteCode.Label,nodeCompiled,[Program.Operand.new(startLabel)])

			for statement in parsedNode.statements:
				generate_statement(nodeCompiled,statement)

			
			#add options
			#todo: add parser flag

			var danglingOptions = false
			for instruction in nodeCompiled.instructions :
				if instruction.operation == Constants.ByteCode.AddOption:
					danglingOptions = true
				if instruction.operation == Constants.ByteCode.ShowOptions:
					danglingOptions = false

			if danglingOptions:
				emit(Constants.ByteCode.ShowOptions, nodeCompiled)
				emit(Constants.ByteCode.RunNode, nodeCompiled)
			else:
				emit(Constants.ByteCode.Stop, nodeCompiled)

			
		program.nodes[nodeCompiled.name] = nodeCompiled

func register_string(text:String,nodeName:String,id:String='',lineNumber:int=-1,tags:Array=[])->String:
	var lineIdUsed : String

	var implicit : bool

	if id.empty():
		lineIdUsed = '%s-%s-%d' % [self._fileName,nodeName,self._stringCount]
		self._stringCount+=1

		#use this when we generate implicit tags
		#they are not saved and are generated
		#aka dummy tags that change on each compilation
		_containsImplicitStringTags = true

		implicit = true
	else :
		lineIdUsed = id
		implicit = false

	var stringInfo = Program.Line.new(text,nodeName,lineNumber,_fileName,implicit,tags)
	#add to string table and return id
	self._stringTable[lineIdUsed] = stringInfo

	return lineIdUsed

func register_label(comment:String='')->String:
	_labelCount+=1
	return  'L%s%s' %[ _labelCount , comment]

func emit(bytecode, node = _currentNode, operands = []):
	var instruction = Program.Instruction.new(null)
	instruction.operation = bytecode
	instruction.operands = operands

	if node == null:
		printerr('trying to emit to null node with byteCode: %s' % bytecode)
		return

	node.instructions.append(instruction)

	if bytecode == Constants.ByteCode.Label:
		#add to label table
		node.labels[instruction.operands[0].value] = node.instructions.size()-1


func get_string_tokens()->Array:
	return []

#compile header
func generate_header():
	pass

#compile instructions for statements
#this will walk through all child branches
#of the parse tree
func generate_statement(node,statement):
	# print('generating statement')
	match statement.type:
		Constants.StatementTypes.CustomCommand:
			generate_custom_command(node,statement.custom_command)
		Constants.StatementTypes.ShortcutOptionGroup:
			generate_shortcut_group(node,statement.shortcut_option_group)
		Constants.StatementTypes.Block:
			generate_block(node,statement.block.statements)
		Constants.StatementTypes.IfStatement:
			generate_if(node,statement.if_statement)
		Constants.StatementTypes.OptionStatement:
			generate_option(node,statement.option_statement)
		Constants.StatementTypes.AssignmentStatement:
			generate_assignment(node,statement.assignment)
		Constants.StatementTypes.Line:
			generate_line(node,statement,statement.line)
		_:
			emit_error(ERR_COMPILATION_FAILED)
			printerr('illegal statement type [%s]- could not generate code' % statement.type)

#compile instructions for custom commands
func generate_custom_command(node,command):
	#print('generating custom command')
	#can evaluate command
	if command.expression != null:
		generate_expression(node,command.expression)
	else:
		var commandString = command.client_command
		if commandString == 'stop':
			emit(Constants.ByteCode.Stop,node)
		else :
			emit(Constants.ByteCode.RunCommand,node,[Program.Operand.new(commandString)])

#compile instructions for linetags and use them
# \#line:number
func generate_line(node,statement,line:String):
	var num : String = register_string(line, node.name, '', statement.lineNumber, []);
	emit(Constants.ByteCode.RunLine, node, [Program.Operand.new(num)])

func generate_shortcut_group(node,shortcutGroup):
	# print('generating shortcutoptopn group')
	var end : String = register_label('group_end')

	var labels : Array = []#String

	var optionCount : int = 0

	for option in shortcutGroup.options:
		var opDestination : String = register_label('option_%s'%[optionCount+1])
		labels.append(opDestination)

		var endofClause : String = ''

		if option.condition != null :
			endofClause = register_label('conditional_%s'%optionCount)
			generate_expression(node,option.condition)
			emit(Constants.ByteCode.JumpIfFalse,node,[Program.Operand.new(endofClause)])

		var labelLineId : String  = ''#no tag TODO: ADD TAG SUPPORT
		var labelStringId : String = register_string(option.label,node.nodeName,
			labelLineId,option.lineNumber,[])
		
		emit(Constants.ByteCode.AddOption,node,[Program.Operand.new(labelStringId),Program.Operand.new(opDestination)])

		if option.condition != null :
			emit(Constants.ByteCode.Label,node,[Program.Operand.new(endofClause)])
			emit(Constants.ByteCode.Pop,node)

		optionCount+=1
	
	emit(Constants.ByteCode.ShowOptions,node)
	emit(Constants.ByteCode.Jump,node)

	optionCount = 0

	for option in shortcutGroup.options:
		emit(Constants.ByteCode.Label,node,[Program.Operand.new(labels[optionCount])])

		if option.node != null :
			generate_block(node,option.node.statements)
		emit(Constants.ByteCode.JumpTo,node,[Program.Operand.new(end)])
		optionCount+=1

	#end of option group
	emit(Constants.ByteCode.Label,node,[Program.Operand.new(end)])
	#clean up
	emit(Constants.ByteCode.Pop,node)



#compile instructions for block
#blocks are just groups of statements
func generate_block(node,statements:Array=[]):
	# print('generating block')
	if !statements.empty():
		for statement in statements:
			generate_statement(node,statement)
	

#compile if branching instructions
func generate_if(node,if_statement):
	# print('generating if')
	#jump to label @ end of every clause
	var endif : String = register_label('endif')

	for clause in if_statement.clauses:
		var end_clause : String = register_label('skip_clause')

		if clause.expression!=null:	
			generate_expression(node,clause.expression)
			emit(Constants.ByteCode.JumpIfFalse,node,[Program.Operand.new(end_clause)])
		
		generate_block(node,clause.statements)
		emit(Constants.ByteCode.JumpTo,node,[Program.Operand.new(endif)])

		if clause.expression!=null:
			emit(Constants.ByteCode.Label,node,[Program.Operand.new(end_clause)])

		if clause.expression!=null:
			emit(Constants.ByteCode.Pop)

		
	emit(Constants.ByteCode.Label,node,[Program.Operand.new(endif)])


#compile instructions for options
func generate_option(node,option):
	# print('generating option')
	var destination : String = option.destination

	if option.label == null || option.label.empty():
		#jump to another node
		emit(Constants.ByteCode.RunNode,node,[Program.Operand.new(destination)])
	else :
		var lineID : String = ''#tags not supported TODO: ADD TAG SUPPORT
		var stringID = register_string(option.label,node.nodeName,lineID,option.lineNumber,[])

		emit(Constants.ByteCode.AddOption,node,[Program.Operand.new(stringID),Program.Operand.new(destination)])


#compile instructions for assigning values
func generate_assignment(node,assignment):
	# print('generating assign')
	#assignment
	if assignment.operation == Constants.TokenType.EqualToOrAssign:
		#evaluate the expression to a value for the stack
		generate_expression(node,assignment.value)
	else :
		#this is combined op
		#get value of var
		emit(Constants.ByteCode.PushVariable,node,[assignment.destination])

		#evaluate the expression and push value to stack
		generate_expression(node,assignment.value)

		#stack contains oldvalue and result

		match assignment.operation:
			Constants.TokenType.AddAssign:
				emit(Constants.ByteCode.CallFunc,node,
					[Program.Operand.new(Constants.token_type_name(Constants.TokenType.Add))])
			Constants.TokenType.MinusAssign:
				emit(Constants.ByteCode.CallFunc,node,
					[Program.Operand.new(Constants.token_type_name(Constants.TokenType.Minus))])
			Constants.TokenType.MultiplyAssign:
				emit(Constants.ByteCode.CallFunc,node,
					[Program.Operand.new(Constants.token_type_name(Constants.TokenType.MultiplyAssign))])
			Constants.TokenType.DivideAssign:
				emit(Constants.ByteCode.CallFunc,node,
					[Program.Operand.new(Constants.token_type_name(Constants.TokenType.DivideAssign))])
			_:
				printerr('Unable to generate assignment')

	#stack contains destination value
	#store the top of the stack in variable
	emit(Constants.ByteCode.StoreVariable,node,[Program.Operand.new(assignment.destination)])

	#clean stack
	emit(Constants.ByteCode.Pop,node)


#compile expression instructions
func generate_expression(node,expression):
	# print('generating expression')
	#expression = value || func call
	match expression.type:
		Constants.ExpressionType.Value:
			generate_value(node,expression.value)
		Constants.ExpressionType.FunctionCall:
			#eval all parameters
			for param in expression.params:
				generate_expression(node,param)
			
			#put the num of of params to stack
			emit(Constants.ByteCode.PushNumber,node,[Program.Operand.new(expression.params.size())])

			#call function
			emit(Constants.ByteCode.CallFunc,node,[Program.Operand.new(expression.function)])
		_:
			printerr('no expression')

#compile value instructions
func generate_value(node,value):
	# print('generating value')
	#push value to stack
	match value.value.type:
		Constants.ValueType.Number:
			emit(Constants.ByteCode.PushNumber,node,[Program.Operand.new(value.value.as_number())])
		Constants.ValueType.Str:
			var id : String = register_string(value.value.as_string(),
				node.nodeName,'',value.lineNumber,[])
			emit(Constants.ByteCode.PushString,node,[Program.Operand.new(id)])
		Constants.ValueType.Boolean:
			emit(Constants.ByteCode.PushBool,node,[Program.Operand.new(value.value.as_bool())])
		Constants.ValueType.Variable:
			emit(Constants.ByteCode.PushVariable,node,[Program.Operand.new(value.value.variable)])
		Constants.ValueType.Nullean:
			emit(Constants.ByteCode.PushNull,node)
		_:
			printerr('Unrecognized valuenode type: %s' % value.value.type)


#get the error flags
func get_errors()->int:
	return _errors

#get the last error code reported
func get_last_error()->int:
	return _lastError

func clear_errors()->void:
	_errors = NO_ERROR
	_lastError = NO_ERROR

func emit_error(error : int)->void:
	_lastError = error
	_errors |= _lastError

static func print_tokens(tokens:Array=[]):
	var list : PoolStringArray = []
	list.append('\n')
	for token in tokens:
		list.append('%s (%s line %s)\n'%[Constants.token_type_name(token.type),token.value,token.lineNumber])
	print('TOKENS:')
	print(list.join(''))
