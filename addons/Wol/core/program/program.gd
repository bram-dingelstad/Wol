extends Node

var programName = ''
var wolStrings = {}
var wolNodes = {}

func get_node_tags(name):
    return wolNodes[name].tags

#possible support for line tags
func get_untagged_strings()->Dictionary:
    return {}

func merge(other):
    pass

func include(other):
    pass

func dump(library):
    pass

