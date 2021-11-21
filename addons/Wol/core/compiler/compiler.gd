extends Object
class_name Compiler

const Constants = preload('res://addons/Wol/core/constants.gd')
const Lexer = preload('res://addons/Wol/core/compiler/lexer.gd')
const Program = preload('res://addons/Wol/core/program.gd')
const Parser = preload('res://addons/Wol/core/compiler/parser.gd')

const INVALID_TITLE = '[\\[<>\\]{}\\|:\\s#\\$]'

const NO_ERROR = 0x00
const LEXER_FAILURE = 0x01
const PARSER_FAILURE = 0x02
const INVALID_HEADER = 0x04
const ERR_COMPILATION_FAILED = 0x10

var source = ''
var filename = ''

var _current_node
var _contains_implicit_string_tags = false
var _label_count = 0

var _string_table = {}
var _string_count = 0

func _init(_filename, _source = null):
	filename = _filename

	if not _filename and _source:
		self.source = _source
	else:
		var file = File.new()
		file.open(_filename, File.READ)
		self.source = file.get_as_text()
		file.close()

func compile():
	var header_sep = RegEx.new()
	var header_property = RegEx.new()
	header_sep.compile('---(\r\n|\r|\n)')
	header_property.compile('(?<field>.*): *(?<value>.*)')

	assert(header_sep.search(source), 'No headers found!')
	
	var line_number = 0

	var source_lines = source.split('\n', false)
	for i in range(source_lines.size()):
		source_lines[i] = source_lines[i].strip_edges(false, true)

	var parsed_nodes = []
	
	while line_number < source_lines.size():
		var title = ''
		var body = ''

		# Parse header
		while true:
			var line = source_lines[line_number]
			line_number += 1
			
			if not line.empty():
				var result = header_property.search(line)
				if result != null:
					var field = result.get_string('field')
					var value = result.get_string('value')

					if field == 'title':
						var regex = RegEx.new()
						regex.compile(INVALID_TITLE)
						assert(not regex.search(value), 'Invalid characters in title "%s", correct to "%s"' % [value, regex.sub(value, '', true)])

						title = value
					# TODO: Implement position, color and tags

			if line_number >= source_lines.size() or line == '---':
				break

		line_number += 1

		# past header
		var body_lines = []
		
		while line_number < source_lines.size() and source_lines[line_number] != '===':
			body_lines.append(source_lines[line_number])
			line_number += 1

		line_number += 1

		body = PoolStringArray(body_lines).join('\n')

		var lexer = Lexer.new(filename, title, body)
		var tokens = lexer.tokenize()

		var parser = Parser.new(title, tokens)
		var parser_node = parser.parse_node()

		parser_node.name = title
		# parser_node.tags = title
		parsed_nodes.append(parser_node)

		while line_number < source_lines.size() and source_lines[line_number].empty():
			line_number += 1

	var program = Program.new()

	for node in parsed_nodes:
		compile_node(program, node)

	for key in _string_table:
		program.strings[key] = _string_table[key]

	return program

func compile_node(program, parsed_node):
	assert(not program.nodes.has(parsed_node.name), 'Duplicate node in program: %s' % parsed_node.name)

	var node_compiled = Program.WolNode.new()

	node_compiled.name = parsed_node.name
	node_compiled.tags = parsed_node.tags

	if parsed_node.source != null and not parsed_node.source.empty():
		node_compiled.source_id = register_string(
			parsed_node.source,
			parsed_node.name,
			'line:' + parsed_node.name,
			0,
			[]
		)
	else:
		var start_label = register_label()
		emit(Constants.ByteCode.Label,node_compiled,[Program.Operand.new(start_label)])

		for statement in parsed_node.statements:
			generate_statement(node_compiled, statement)
		
		var dangling_options = false
		for instruction in node_compiled.instructions:
			if instruction.operation == Constants.ByteCode.AddOption:
				dangling_options = true
			if instruction.operation == Constants.ByteCode.ShowOptions:
				dangling_options = false

		if dangling_options:
			emit(Constants.ByteCode.ShowOptions, node_compiled)
			emit(Constants.ByteCode.RunNode, node_compiled)
		else:
			emit(Constants.ByteCode.Stop, node_compiled)

	program.nodes[node_compiled.name] = node_compiled

func register_string(text:String,node_name:String,id:String='',line_number:int=-1,tags:Array=[])->String:
	var line_id_used : String

	var implicit : bool

	if id.empty():
		line_id_used = '%s-%s-%d' % [self.filename,node_name,self._string_count]
		self._string_count+=1

		#use this when we generate implicit tags
		#they are not saved and are generated
		#aka dummy tags that change on each compilation
		_contains_implicit_string_tags = true

		implicit = true
	else :
		line_id_used = id
		implicit = false

	var string_info = Program.Line.new(text,node_name,line_number,filename,implicit,tags)
	#add to string table and return id
	self._string_table[line_id_used] = string_info

	return line_id_used

func register_label(comment:String='')->String:
	_label_count+=1
	return  'L%s%s' %[ _label_count , comment]

func emit(bytecode, node = _current_node, operands = []):
	var instruction = Program.Instruction.new(null)
	instruction.operation = bytecode
	instruction.operands = operands

	if node == null:
		printerr('trying to emit to null node with byte_code: %s' % bytecode)
		return

	node.instructions.append(instruction)

	if bytecode == Constants.ByteCode.Label:
		#add to label table
		node.labels[instruction.operands[0].value] = node.instructions.size()-1


func generate_header():
	pass

func generate_statement(node,statement):

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
			assert(false, 'Illegal statement type [%s]. Could not generate code.' % statement.type)

#compile instructions for custom commands
func generate_custom_command(node,command):
	#print('generating custom command')
	#can evaluate command
	if command.expression != null:
		generate_expression(node,command.expression)
	else:
		var command_string = command.client_command
		if command_string == 'stop':
			emit(Constants.ByteCode.Stop,node)
		else :
			emit(Constants.ByteCode.RunCommand,node,[Program.Operand.new(command_string)])

#compile instructions for linetags and use them
# \#line:number
func generate_line(node,statement,line:String):
	var num : String = register_string(line, node.name, '', statement.line_number, []);
	emit(Constants.ByteCode.RunLine, node, [Program.Operand.new(num)])

func generate_shortcut_group(node,shortcut_group):
	# print('generating shortcutoptopn group')
	var end : String = register_label('group_end')

	var labels : Array = []#String

	var option_count : int = 0

	for option in shortcut_group.options:
		var op_destination : String = register_label('option_%s'%[option_count+1])
		labels.append(op_destination)

		var endof_clause : String = ''

		if option.condition != null :
			endof_clause = register_label('conditional_%s'%option_count)
			generate_expression(node,option.condition)
			emit(Constants.ByteCode.JumpIfFalse, node, [Program.Operand.new(endof_clause)])

		var label_line_id = '' #TODO: Add tag support
		var label_string_id = register_string(
			option.label,
			node.name,
			label_line_id,option.line_number,
			[]
		)
		
		emit(Constants.ByteCode.AddOption,node,[Program.Operand.new(label_string_id),Program.Operand.new(op_destination)])

		if option.condition != null :
			emit(Constants.ByteCode.Label,node,[Program.Operand.new(endof_clause)])
			emit(Constants.ByteCode.Pop,node)

		option_count+=1
	
	emit(Constants.ByteCode.ShowOptions,node)
	emit(Constants.ByteCode.Jump,node)

	option_count = 0

	for option in shortcut_group.options:
		emit(Constants.ByteCode.Label,node,[Program.Operand.new(labels[option_count])])

		if option.node != null :
			generate_block(node,option.node.statements)
		emit(Constants.ByteCode.JumpTo,node,[Program.Operand.new(end)])
		option_count+=1

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

	if option.label == null or option.label.empty():
		#jump to another node
		emit(Constants.ByteCode.RunNode,node,[Program.Operand.new(destination)])
	else :
		var line_iD : String = ''#tags not supported TODO: ADD TAG SUPPORT
		var string_iD = register_string(option.label,node.name,line_iD,option.line_number,[])

		emit(Constants.ByteCode.AddOption,node,[Program.Operand.new(string_iD),Program.Operand.new(destination)])


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
	#expression = value or func call
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
			var id = register_string(value.value.as_string(),
				node.name,'',value.line_number,[])
			emit(Constants.ByteCode.PushString,node,[Program.Operand.new(id)])
		Constants.ValueType.Boolean:
			emit(Constants.ByteCode.PushBool,node,[Program.Operand.new(value.value.as_bool())])
		Constants.ValueType.Variable:
			emit(Constants.ByteCode.PushVariable,node,[Program.Operand.new(value.value.variable)])
		Constants.ValueType.Nullean:
			emit(Constants.ByteCode.PushNull,node)
		_:
			printerr('Unrecognized valuenode type: %s' % value.value.type)

static func print_tokens(tokens:Array=[]):
	var list : PoolStringArray = []
	list.append('\n')
	for token in tokens:
		list.append('%s (%s line %s)\n'%[Constants.token_type_name(token.type),token.value,token.line_number])
	print('TOKENS:')
	print(list.join(''))
