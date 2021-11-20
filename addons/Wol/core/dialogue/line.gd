extends Object

const LineInfo = preload("res://addons/Wol/core/program/yarn_line.gd")

var id : String
var substitutions : Array = []#String
var info : LineInfo

func _init(id: String, info: LineInfo):
    self.id = id
    self.info = info
