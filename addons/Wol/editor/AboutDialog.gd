extends WindowDialog

func _ready():
	$RichTextLabel.connect('meta_clicked', self, '_on_url_click')

func _on_url_click(url):
	OS.shell_open(url)
