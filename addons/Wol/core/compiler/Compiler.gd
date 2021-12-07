extends Object

signal error(message, line_number, column)

const Constants = preload('res://addons/Wol/core/Constants.gd')
const Lexer = preload('res://addons/Wol/core/compiler/Lexer.gd')
const Program = preload('res://addons/Wol/core/Program.gd')
const Parser = preload('res://addons/Wol/core/compiler/Parser.gd')

const INVALID_TITLE = '[\\[<>\\]{}\\|:\\s#\\$]'

var source = ''
var filename = ''

var current_node
var has_implicit_string_tags = false
var soft_assert = false

var string_count = 0
var string_table = {}
var label_count = 0

func _init(_filename, _source = null, _soft_assert = false):
	filename = _filename
	soft_assert = _soft_assert

	if not _filename and _source:
		self.source = _source
	else:
		var file = File.new()
		file.open(_filename, File.READ)
		self.source = file.get_as_text()
		file.close()

	var source_lines = source.split('\n')
	for i in range(source_lines.size()):
		source_lines[i] = source_lines[i].strip_edges(false, true)

	source = source_lines.join('\n')

func get_headers(offset = 0):
	var header_property = RegEx.new()
	var header_sep = RegEx.new()

	header_sep.compile('---(\r\n|\r|\n)')
	header_property.compile('(?<field>.*): *(?<value>.*)')

	self.assert(header_sep.search(source), 'No headers found!')

	var title = ''
	var position = Vector2.ZERO

	var source_lines = source.split('\n')
	var line_number = offset
	while line_number < source_lines.size():
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
					self.assert(not regex.search(value), 'Invalid characters in title "%s", correct to "%s"' % [value, regex.sub(value, '', true)])

					title = value

				if field == 'position':
					var regex = RegEx.new()
					regex.compile('^position:.*,.*\\d$')
					self.assert(regex.search(line), 'Couldn\'t parse position property in the headers, got "%s" instead in node "%s"' % [value, title])

					position = Vector2(int(value.split(',')[0].strip_edges()), int(value.split(',')[1].strip_edges()))

				# TODO: Implement color and tags

		if line == '---':
			break

	return {
		'title': title,
		'position': position
	}

func get_body(offset = 0):
	var body_lines = []
	
	var source_lines = source.split('\n')
	var recording = false
	var line_number = offset

	while line_number < source_lines.size() and source_lines[line_number] != '===':
		if recording:
			body_lines.append(source_lines[line_number])

		recording = recording or source_lines[line_number] == '---'
		line_number += 1

	line_number += 1

	return PoolStringArray(body_lines).join('\n')

func get_nodes():
	var nodes = []
	var line_number = 0
	var source_lines = source.split('\n')
	while line_number < source_lines.size():
		var headers = get_headers(line_number)
		var body = get_body(line_number)
		headers.body = body

		nodes.append(headers)

		# Add +2 to the final line to skip the === from that node
		line_number = Array(source_lines).find_last(body.split('\n')[-1]) + 2

		while line_number < source_lines.size() and source_lines[line_number].empty():
			line_number += 1
	
	return nodes

func assert(statement, message, line_number = -1, column = -1, _absolute_line_number = -1):
	if not soft_assert:
		assert(statement, '"%s" on line %d column %d' % [message, line_number, column])
	elif not statement:
		emit_signal('error', message, line_number, column)

	return not statement

func compile():
	var parsed_nodes = []
	for node in get_nodes():
		var lexer = Lexer.new(self, filename, node.title, node.body)
		var tokens = lexer.tokenize()

		# In case of lexer error
		if not tokens:
			return

		var parser = Parser.new(self, node.title, tokens)
		var parser_node = parser.parse_node()

		parser_node.name = node.title
		parsed_nodes.append(parser_node)

	var program = Program.new()
	program.filename = filename

	for node in parsed_nodes:
		compile_node(program, node)

	for key in string_table:
		program.strings[key] = string_table[key]

	return program

func compile_node(program, parsed_node):
	self.assert(not program.nodes.has(parsed_node.name), 'Duplicate node in program: %s' % parsed_node.name)

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
		emit(Constants.ByteCode.Label, node_compiled, [Program.Operand.new(start_label)])

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

func register_string(text, node_name, id = '', line_number = -1, tags = []):
	var line_id_used = ''
	var implicit = false

	if id.empty():
		line_id_used = '%s-%s-%d' % [filename, node_name, string_count]
		string_count += 1

		#use this when we generate implicit tags
		#they are not saved and are generated
		#aka dummy tags that change on each compilation
		has_implicit_string_tags = true

		implicit = true
	else :
		line_id_used = id
		implicit = false

	var string_info = Program.Line.new(text, node_name, line_number, filename, implicit, tags)
	string_table[line_id_used] = string_info

	return line_id_used

func register_label(comment = ''):
	label_count += 1
	return 'Label%s%s' % [label_count, comment]

func emit(bytecode, node = current_node, operands = []):
	var instruction = Program.Instruction.new(null)
	instruction.operation = bytecode
	instruction.operands = operands

	if node == null:
		printerr('Trying to emit to null node with byte_code: %s' % bytecode)
		return

	node.instructions.append(instruction)

	if bytecode == Constants.ByteCode.Label:
		node.labels[instruction.operands[0].value] = node.instructions.size() - 1

func generate_statement(node, statement):
	match statement.type:
		Constants.StatementTypes.CustomCommand:
			generate_custom_command(node, statement.custom_command)

		Constants.StatementTypes.ShortcutOptionGroup:
			generate_shortcut_group(node, statement.shortcut_option_group)

		Constants.StatementTypes.Block:
			generate_block(node, statement.block.statements)

		Constants.StatementTypes.IfStatement:
			generate_if(node, statement.if_statement)

		Constants.StatementTypes.OptionStatement:
			generate_option(node, statement.option_statement)

		Constants.StatementTypes.AssignmentStatement:
			generate_assignment(node, statement.assignment)

		Constants.StatementTypes.Line:
			generate_line(node, statement)
		_:
			self.assert(false, statement.line_number, 'Illegal statement type [%s]. Could not generate code.' % statement.type)

func generate_custom_command(node, command):
	# TODO: See if the first tree of this statement is being used
	if command.expression != null:
		generate_expression(node, command.expression)
	else:
		var command_string = command.client_command
		if command_string == 'stop':
			emit(Constants.ByteCode.Stop, node)
		else :
			emit(Constants.ByteCode.RunCommand, node, [Program.Operand.new(command_string)])

func generate_line(node, statement):
	# TODO: Implement proper line numbers (global and local)
	var line = statement.line
	var expression_count = line.substitutions.size()

	while not line.substitutions.empty():
		var inline_expression = line.substitutions.pop_back()
		generate_expression(node, inline_expression.expression)
	
	var num = register_string(line.line_text, node.name, line.line_id, statement.line_number, line.tags);
	emit(Constants.ByteCode.RunLine, node,[Program.Operand.new(num), Program.Operand.new(expression_count)])

func generate_shortcut_group(node, shortcut_group):
	var end = register_label('group_end')
	var labels = []
	var option_count = 0
	
	for option in shortcut_group.options:
		var endof_clause = ''
		var op_destination = register_label('option_%s' % [option_count + 1])

		labels.append(op_destination)

		if option.condition != null:
			endof_clause = register_label('conditional_%s' % option_count)
			generate_expression(node, option.condition)
			emit(Constants.ByteCode.JumpIfFalse, node, [Program.Operand.new(endof_clause)])

		var label_line_id = '' #TODO: Add tag support
		var label_string_id = register_string(
			option.label,
			node.name,
			label_line_id,
			option.line_number,
			[]
		)
		
		emit(Constants.ByteCode.AddOption, node, [Program.Operand.new(label_string_id), Program.Operand.new(op_destination)])

		if option.condition != null:
			emit(Constants.ByteCode.Label, node, [Program.Operand.new(endof_clause)])
			emit(Constants.ByteCode.Pop, node)

		option_count += 1
	
	emit(Constants.ByteCode.ShowOptions, node)
	emit(Constants.ByteCode.Jump, node)

	option_count = 0

	for option in shortcut_group.options:
		emit(Constants.ByteCode.Label, node, [Program.Operand.new(labels[option_count])])

		if option.node != null:
			generate_block(node, option.node.statements)
		emit(Constants.ByteCode.JumpTo, node, [Program.Operand.new(end)])
		option_count += 1

	emit(Constants.ByteCode.Label, node, [Program.Operand.new(end)])
	emit(Constants.ByteCode.Pop, node)

func generate_block(node, statements = []):
	if not statements.empty():
		for statement in statements:
			generate_statement(node, statement)
	

func generate_if(node, if_statement):
	var endif = register_label('endif')

	for clause in if_statement.clauses:
		var end_clause = register_label('skip_clause')

		if clause.expression != null:	
			generate_expression(node, clause.expression)
			emit(Constants.ByteCode.JumpIfFalse, node, [Program.Operand.new(end_clause)])
		
		generate_block(node, clause.statements)
		emit(Constants.ByteCode.JumpTo, node, [Program.Operand.new(endif)])

		if clause.expression != null:
			emit(Constants.ByteCode.Label, node, [Program.Operand.new(end_clause)])

		if clause.expression != null:
			emit(Constants.ByteCode.Pop)
		
	emit(Constants.ByteCode.Label, node, [Program.Operand.new(endif)])

func generate_option(node, option):
	var destination = option.destination

	if option.label == null or option.label.empty():
		emit(Constants.ByteCode.RunNode, node, [Program.Operand.new(destination)])
	else :
		var line_id = '' #TODO: ADD TAG SUPPORT
		var string_id = register_string(option.label, node.name, line_id, option.line_number, [])

		emit(Constants.ByteCode.AddOption, node, [Program.Operand.new(string_id), Program.Operand.new(destination)])

func generate_assignment(node, assignment):
	if assignment.operation == Constants.TokenType.EqualToOrAssign:
		generate_expression(node, assignment.value)
	else :
		emit(Constants.ByteCode.PushVariable, node, [assignment.destination])
		generate_expression(node, assignment.value)

		match assignment.operation:
			Constants.TokenType.AddAssign:
				emit(
					Constants.ByteCode.CallFunc,
					node,
					[Program.Operand.new(Constants.token_type_name(Constants.TokenType.Add))]
				)
			Constants.TokenType.MinusAssign:
				emit(
					Constants.ByteCode.CallFunc,
					node,
					[Program.Operand.new(Constants.token_type_name(Constants.TokenType.Minus))]
				)
			Constants.TokenType.MultiplyAssign:
				emit(
					Constants.ByteCode.CallFunc,
					node,
					[Program.Operand.new(Constants.token_type_name(Constants.TokenType.MultiplyAssign))]
				)
			Constants.TokenType.DivideAssign:
				emit(
					Constants.ByteCode.CallFunc,
					node,
					[Program.Operand.new(Constants.token_type_name(Constants.TokenType.DivideAssign))]
				)
			_:
				printerr('Unable to generate assignment')

	emit(Constants.ByteCode.StoreVariable, node, [Program.Operand.new(assignment.destination)])
	emit(Constants.ByteCode.Pop, node)

func generate_expression(node, expression):
	if self.assert(expression != null, 'Wrong expression (perhaps unterminated command block ">>"?)'):
		return false

	match expression.type:
		Constants.ExpressionType.Value:
			generate_value(node, expression.value)
		Constants.ExpressionType.FunctionCall:
			for parameter in expression.parameters:
				generate_expression(node, parameter)
			
			emit(Constants.ByteCode.PushNumber, node, [Program.Operand.new(expression.parameters.size())])
			emit(Constants.ByteCode.CallFunc, node, [Program.Operand.new(expression.function)])
		_:
			printerr('No expression.')

func generate_value(node, value):
	match value.value.type:
		Constants.ValueType.Number:
			emit(
				Constants.ByteCode.PushNumber,
				node,
				[Program.Operand.new(value.value.as_number())]
			)
		Constants.ValueType.Str:
			var id = register_string(
				value.value.as_string(),
				node.name,
				'',
				value.line_number,
				[]
			)
			emit(
				Constants.ByteCode.PushString,
				node,
				[Program.Operand.new(id)]
			)
		Constants.ValueType.Boolean:
			emit(
				Constants.ByteCode.PushBool,
				node,
				[Program.Operand.new(value.value.as_bool())]
			)
		Constants.ValueType.Variable:
			emit(
				Constants.ByteCode.PushVariable,
				node,
				[Program.Operand.new(value.value.variable)]
			)
		Constants.ValueType.Nullean:
			emit(Constants.ByteCode.PushNull, node)
		_:
			printerr('Unrecognized valuenode type: %s' % value.value.type)
