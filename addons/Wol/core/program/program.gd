extends Node

var programName : String
var wolStrings : Dictionary = {}
var wolNodes : Dictionary = {}

func get_node_tags(name:String)->Array:
    return wolNodes[name].tags

func get_wol_string(key:String)->String:
    return wolStrings[key]

func get_node_text(name:String)->String:
    var key = wolNodes[name].sourceId
    return get_wol_string(key)

#possible support for line tags
func get_untagged_strings()->Dictionary:
    return {}

func merge(other):
    pass

func include(other):
    pass

func dump(library):
    print("not yet implemented")
    pass
    
