extends Node

signal values_changed

const Value = preload("res://addons/Wol/core/value.gd")

var variables = {}

func set_value(name, value):
    print('SETTING VALUES %s: %s' % [name, value])
    if !(value is Value):
        variables[name] = Value.new(value)
    else:
        variables[name] = value

    emit_signal('values_changed')

func get_value(name):
    return variables.get(name)

func clear_values():
    variables.clear()
    emit_signal('values_changed')
