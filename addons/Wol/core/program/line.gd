extends Object
class_name WolLine

var text = ''
var nodeName = ''
var lineNumber = -1
var fileName = ''
var implicit = false
var meta = []

func _init(text, nodeName, lineNumber, fileName, implicit, meta):
	self.text = text
	self.nodeName = nodeName
	self.fileName = fileName
	self.implicit = implicit
	self.meta = meta
