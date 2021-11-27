<p align="center">
<img style="height: 120px; object-fit: cover" src="https://user-images.githubusercontent.com/3514405/143497096-e5d98c85-1f1b-4d8a-9a63-ee439d4c616d.png" /> 
<p align="center" style="font-style: italic"> The friendly tool for writing game dialogue, in and for Godot</p>
<p align="center" style="font-style: italic"> <a href="README.md#Getting-Started">Getting Started</a> | <a href="README.md#Documentation">Documentation</a> | <a href="README.md#Tutorial">Tutorial</a> | <a href="https://twitter.com/bram_dingelstad">Follow me 🐦!</a> </p>
</p> 

---

**Wol** is a tool for creating interactive dialogue for games. Its based on [YarnSpinner](https://yarnspinner.dev/) and it's [Yarn language](https://yarnspinner.dev/docs/syntax/). 

Write your conversations in *Yarn*, a simple programming language that's designed to be easy for writers to learn, while also powerful enough to handle whatever you need. 

Yarn's similar in style to [Twine](http://twinery.org), so if you already know that, you'll be right at home! If you don't, that's cool - Yarn's syntax is extremely minimal, and there's not much there to learn. 

Wol is actively maintained by [Bram Dingelstad](https://bram.dingelstad.works), if you need a programmer or designer for your next (Godot) project, you can [hire him!](https://hire.bram.dingelstad.works)

## Getting Started

This repo contains the source code for the Wol compiler. If you want to use it in a game engine other than Godot, you should get the appropriate package for your game engine. Check out [YarnSpinner-Unity](https://github.com/YarnSpinnerTool/YarnSpinner-Unity) for a Unity version of this project.

### Download from AssetLib
Unfortunately, this option isn't available yet. Stay tuned!

### Clone this repository / [download the zip](https://github.com/bram-dingelstad/Wol/archive/refs/heads/main.zip)

1. Extract the repository in a folder of your choice.
2. Import the project in Godot.
3. Run the scene to get a taste of Wol!
4. Move the addons folder to your Godot project.
5. Enable the plugin in your Project Settings.
6. Setup the Wol node using the [documentation](README.md#Documentation) or [tutorial](README.md#Tutorial)!

## Roadmap

There are few things that need to be ironed out to be 100% feature compatible with the original YarnSpinner.

- [ ] Integration with Godot's translation/localization system.
- [ ] Full support for [format functions](https://yarnspinner.dev/docs/syntax/#format-functions).
- [ ] In-editor dialogue editor with preview.
- [ ] Fully extend the documentation of this project.
  - [x] Document the `Option` object.
  - [x] Write the method descriptions for the `Wol` node.
  - [ ] Write a basic "Hello World"-esque tutorial.
  - [ ] Provide helpful anchors in the documentation.
- [x] Porting to usable signals in Godot.
- [x] Providing helpful errors when failing to compile.
- [x] Having a working repository with example code.

### On request

If for whatever reason a lot of people want more documentation or certain features, here's some additional stuff I'll do: 
 
- [ ] Write a more advanced "Custom `Wol` Node" tutorial.
- [ ] Perhaps write a little bit about the internals 🤷 (?).

## Getting Help

There are several places to get help with Wol, and stay up to date with what's happening.

* [Follow me on Twitter](https://twitter.com/bram_dingelstad) or [@ me](https://twitter.com/intent/tweet?text=Hey%20@bram_dingelstad,%20I%20need%20help%20using%20%23Wol%21)!
* Open an issue on [Github](https://github.com/bram-dingelstad/Wol/issues)!
* Email bram [at] dingelstad.works for more indepth questions or inqueries for consultancy. You can also email me to [hire me](https://hire.bram.dingelstad.works) for all your Godot needs!

## License

Wol is available under the [MIT License](LICENSE.md). This means that you can use it in any commercial or noncommercial project. The only requirement is that you need to include attribution in your game's docs. A credit would be very, very nice, too, but isn't required. If you'd like to know more about what this license lets you do, tldrlegal.com have a [very nice write up about the MIT license](https://tldrlegal.com/license/mit-license) that you might find useful.

## Made by Bram Dingelstad, kyperbelt & Secret Lab

Yarn Spinner was originally created by [Secret Lab](http://secretlab.com.au), an Australian game dev studio. [Say hi to them for me!](https://twitter.com/thesecretlab)!

Started on Godot by [kyperbelt](https://github.com/kyperbelt/GDYarn) (thank you so much for the initial work!) and completed by Bram Dingelstad. [Say hi to me as well!](https://bram.dingelstad.works/)


## Help Me Make Wol & Secret Lab's Yarn Spinner!

Wol & Yarn Spinner needs your help to be as awesome as it can be! You don't have to be a coder to help out - we'd love to have your help in improving this or YarnSpinner's [documentation](https://yarnspinner.dev/docs/tutorial), in spreading the word, and in finding bugs.

* Yarn Spinner's development is powered by our wonderful Patreon supporters. [Become a patron](https://patreon.com/secretlab), and help us make Yarn Spinner be amazing.
* The [issues page](https://github.com/bram-dingelstad/Wol/issues) contains a list of things we'd love your help in improving.
* Join Secret Lab's discussion on Slack by joining the [narrative game development](http://lab.to/narrativegamedev) channel.
* Follow [Bram Dingelstad](https://twitter.com/bram_dingelstad) & [Yarn Spinner](http://twitter.com/YarnSpinnerTool).

# Documentation

## `Wol` 
_Inherits from [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)_

Node for all interaction with Wol.

### Description
Godot's Nodes as building blocks work really well. That's why this plugin gives you access to a simple node that does all the heavy lifting for you.
It has several properties that you can change either in-editor or using GDScript (or any other compatible language) and signals you can use to listen to events coming from your dialogue.

### Properties
| Type                                                                                           | Property          | Default value |
|------------------------------------------------------------------------------------------------|-------------------|---------------|
| [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string)       | path              | `''`          |
| [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string)       | starting_node     | `'Start'`     |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html)                         | auto_start        | `false`       |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html)                         | auto_show_options | `false`       |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html)                         | auto_substitute   | `true`        |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html)             | variable_storage  | `{}`          |

### Methods
| Return value         | Method name                                                                                                                |
|----------------------|----------------------------------------------------------------------------------------------------------------------------|
| void                 | start ( [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) starting_node = 'Start' ) |
| void                 | pause ( )                                                                                                                  |
| void                 | resume ( )                                                                                                                 |
| void                 | select_option ( [int](https://docs.godotengine.org/en/stable/classes/class_int.html#class-int) id )                        |

### Signals

* started ( ) 

  Emitted when the dialogue is started.

* finished ( ) 

  Emitted when the dialogue is came to a stop, either through running out of dialogue or by using the `<<stop>>` command.

* node_started ( [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) node ) 

  Emitted when a dialogue node is started. Has the node name as a parameter so you can see which node was started.

* node_finished ( [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) node ) 

  Emitted when a dialogue node is started. Has the node name as a parameter so you can see which node was started.

* line ( `Line` line ) 

  Emitted when a `Line` is emitted from the dialogue. `line` holds relevant information.

* options ( [`Array`](https://docs.godotengine.org/en/stable/classes/class_array.html) options ) 

  Emitted when the dialogue runs into a set of options. Is emitted with an [`Array`](https://docs.godotengine.org/en/stable/classes/class_array.html) of `Option`s.
 
* command ( [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) command ) 

  Emitted when the dialogue executes a command. Use this signal to provide interactivity with your game world.

### Property Descriptions
* [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) path 
  
  |Default|`''`|
  |-------|----|

  The path to your `.yarn` or `.wol` file. Must be a valid `Yarn` file otherwise the compiler will throw an error.

* [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) starting_node 

  |Default|`'Start'`|
  |-------|---------|

  The node that is the starting point of the dialogue. Will automatically be the default for the `start()` function as well. The string should be a valid name for a Yarn node and be available in the file or an error will be thrown. You can always start from a different node by calling `start('OtherStartingNode')` for instance.

* [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) auto_start 

  |Default|`false`|
  |-------|-------|

  If enabled, will automatically start the dialogue using the `starting_node` as the entrypoint.

* [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) auto_show_options

  |Default|`false`|
  |-------|-------|

  If enabled, will automatically show you options when they're available, rather than waiting for the player to resume to the line that has options.

* [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) auto_substitude

  |Default|`false`|
  |-------|-------|

  If enabled, will automatically substitute format functions and inline expressions for you. It's recommended to leave enabled, but if you want to manually do this for whatever reason, you can turn it off.

* [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) variable_storage 

  |Default|`{}`|
  |-------|----|

  A [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) that holds all of the variables of your of your dialogue. 
  All of the entries of this dictionary are accesible in your dialogue with a `$` prefix. (e.g `a_variable` would be `$a_variable`). 
  If you set a variable from within your dialogue, this dictionary will also be updated.

  In the future there'll be a signal added for when the `variable_storage` is updated.

### Method Descriptions

* start ( [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) starting_node = 'Start') 

  Starts the dialogue at the `starting_node` (defaults to the value of `self.starting_node` which is `Start`)
  When the dialogue comes to a full stop through reaching the end or reaching a `<<stop>` command, you need to explicitly call this function instead of `resume ( )`.

* pause ( )

  Pauses the dialogue until `resume ( )` is called.

* resume ( )

  Resumes the dialogue. Won't work when the dialogue comes to a full stop by reaching the end or reaching a `<<stop>>` command. You need to call `start ( starting_node )` instead.

* select_option ( [int](https://docs.godotengine.org/en/stable/classes/class_int.html#class-int) id )

  When getting an option from the `options` signal, use this function to let Wol node which option you want to select.
  Use `Option.id` for the `id` parameter.

## `Line` 
_Inherits from [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)_

An object holding all information related to a line in your dialogue.

### Description
The `Line` object is _the_ object that you're gonna be interacting with the most. This object holds all of the information of the actual lines of dialogue. The most important property is `text`, but it has some additional properties you can make use of for debugging or holding of metadata (no support for that yet however).

### Properties
| Type                                                                                      | Property      |
|-------------------------------------------------------------------------------------------|---------------|
| [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string)  | text          |
| [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string)  | node_name     | 
| [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string)  | file_name     |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html)                  | substitutions |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html)                  | meta          |

### Property Descriptions
* [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) text 

  A line of dialogue that's been processed by Wol. You can use this to set a [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) in a text bubble above your character, add to a [RichTextLabel](https://docs.godotengine.org/en/stable/classes/class_richtextlabel.html#class-richtextlabel) for more dynamic stuff (Wol fully supports bbcode). Look at this repository's `Dialogue.tscn` and `Dialogue.gd` for some inspiration ;)

* [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) node_name

  The name of the dialogue node this piece of dialogue came from.

* [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) file_name

  The filename of the file where this piece of dialogue came from.

* [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) substitutions

  An [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) of [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string)s that the result of Wol proccessing statements. Use this array if you disabled `auto_substitutions` and want to manually substitute your dialogue.
  
* [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) meta

  Currently unimplemented.

## `Option` 
_Inherits from [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)_

An object holding information of an option in your dialogue.

### Description
The `Option` object is anoter object that you're gonna be interacting with a lot. This object holds the information of a choice in your dialogue. 
It has a reference to a `Line` with it's `line` property so you can show the appropriate text to your player!

### Properties
| Type                                                                                      | Property      |
|-------------------------------------------------------------------------------------------|---------------|
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html#class-int)            | id            | 
| `Line`                                                                                    | line          |
| [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string)  | destination   |

### Property Descriptions

* [int](https://docs.godotengine.org/en/stable/classes/class_int.html#class-int) id 

  A unique identifier that you can use to communicate your option choice with `select_option ( id )`.

* `Line` line 

  A line of dialogue that's been processed by Wol. See `Line` for more details.

* [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) destination

  The node that you will jump to when this option is selected. (Only relevant for jump questions, not inline ones).
 

# Tutorial

_The tutorial is currently under construction, stay tuned!_
