<p align="center">
<img style="height: 120px; object-fit: cover" src="https://user-images.githubusercontent.com/3514405/143497096-e5d98c85-1f1b-4d8a-9a63-ee439d4c616d.png" /> 
<p align="center" style="font-style: italic"> The friendly tool for writing game dialogue, in and for Godot</p>
<p align="center" style="font-style: italic"> <a href="README.md#Getting-Started">Getting Started</a> | <a href="README.md#Documentation">Documentation</a> | <a href="README.md#Tutorial">Tutorial</a> | <a href="https://wol-editor.bram.dingelstad.works">Web Editor</a> | <a href="https://twitter.com/bram_dingelstad">Follow me 🐦!</a> </p>
</p> 

---

**Wol** is a tool for creating interactive dialogue for games. Its based on [YarnSpinner](https://yarnspinner.dev/) and it's [Yarn language](https://yarnspinner.dev/docs/syntax/). (**_currently under heavy development, very unstable, do not use for production_**)

Write your conversations in *Yarn*, a simple programming language that's designed to be easy for writers to learn, while also powerful enough to handle whatever you need. 

Yarn's similar in style to [Twine](http://twinery.org), so if you already know that, you'll be right at home! If you don't, that's cool - Yarn's syntax is extremely minimal, and there's not much there to learn. 

Wol is actively maintained by [Bram Dingelstad](https://bram.dingelstad.works), if you need a programmer or designer for your next (Godot) project, you can [hire him!](https://hire.bram.dingelstad.works)

## Getting Started

This repo contains the code for the Wol nodes & Yarn compiler. 
If you want to use it in a game engine other than Godot, you should get the appropriate package for your game engine.
Check out [YarnSpinner-Unity](https://github.com/YarnSpinnerTool/YarnSpinner-Unity) for a Unity version of this project.

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
  - [ ] Auto generation for `#line:` suffixes
- [ ] Support for [format functions](https://yarnspinner.dev/docs/syntax/#format-functions).
- [ ] ~Support~ Fix for conditional options.
- [ ] In-editor dialogue editor with preview.
  - [x] Lines connecting different nodes if they refer to eachother.
  - [x] Error hints when doing something wrong.
  - [x] Basic saving, opening and saving-as.
- [ ] Remove all `printerr` in favor of (soft) `assert`s.
- [x] Fully extend the documentation of this project.
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

# Tutorial

Welcome to Wol! In this tutorial, you’ll learn how to use Wol in a Godot project to create interactive dialogue.

We’ll start by downloading and installing Wol. We’ll then take a look at the core concepts that power Wol / Yarn, and write some dialogue. 
After that, we’ll explore some of the more advanced features of Wol & Yarn.

## Introducing Wol

Wol & Yarn (Spinner) are tools for writing interactive dialogue in games - that is, conversations that the player can have with characters in the game. 
Yarn Spinner does this by letting you write your dialogue in a programming language called Yarn.

Yarn is designed to be as minimal as possible.
For example, the following is valid Yarn code:

```yarn
Gregg: I think I might be sick.
Mae: True friendship: Letting your friend make you sick.
Gregg: True bros.
Mae: True bros.
```

Wol will take each line, one at a time, and deliver them to the game.
It’s entirely up to the game to decide what to do with the lines; for example, the game that these lines are from, 
Night in the Woods, displays them in speech bubbles, one character at a time, and waits for the user to press a button before showing the next one.


## Quick Start

We’ll begin by playing the example game that comes with Wol. It’s very short - about 2 minutes long. After that we'll make some small changes!

1. Create a new empty Godot project.
2. Download and install Wol. Go to the [Getting started section](#README.md#Getting-Started), and follow the directions there.
3. Open the example scene (`res://ExampleDialogue/ExampleScene.tscn`).
4. Play the game. Use the left and right arrow keys to move, and the enter key to talk to characters.

We’re now ready to start looking under the hood, to see how Wol & Yarn power this game.

### The Wol Editor

Wol & Yarn Spinner stores its dialogue in .yarn (or .wol) files. These are plain text files, which means you can edit them in any plain text editor (Visual Studio Code is a good option, and Secret Labs offers a syntax highlighting extension to make it nice to use!)

You can also use the Wol Editor, which is a tool in the Godot editor for working with Yarn code. This editor is useful because it lets you view the structure of your dialogue in a very visual way. (This is not completed yet however)

### Reading Yarn

In this section of the tutorial, we’re going to open the file Sally.yarn, and look at what it’s doing.

#### Open Sally.yarn in your editor of choice.

Wol & Yarn groups all of its dialogue into nodes. Nodes contain everything: your lines of dialogue, the choices you show to the player, and the commands that you send to the game. The Sally.yarn file contains four of them: Sally, Sally.Watch, Sally.Exit, and Sally.Sorry. The example game is set up so that when you walk up to Sally and press the spacebar, the game will start running the Sally node.

#### Go to the Sally node.

Let’s take a look at what that node contains. Here’s the entire text of it:

```yarn
<<if visited("Sally") is false>>
    Player: Hey, Sally. #line:794945
    Sally: Oh! Hi. #line:2dc39b
    Sally: You snuck up on me. #line:34de2f
    Sally: Don't do that. #line:dcc2bc
<<else>>
    Player: Hey. #line:a8e70c
    Sally: Hi. #line:305cde
<<endif>>

<<if not visited("Sally.Watch")>>
    [[Anything exciting happen on your watch?|Sally.Watch]] #line:5d7a7c
<<endif>>

<<if $sally_warning and not visited("Sally.Sorry")>>
    [[Sorry about the console.|Sally.Sorry]] #line:0a7e39
<<endif>>
[[See you later.|Sally.Exit]] #line:0facf7
```

Take a second now to look at this code, and get a feel for its structure.

### Lines and Logic

We’ll now take a closer look at each part of this code, and explain what’s going on.

```yarn
<<if visited("Sally") is false>>
    Player: Hey, Sally. #line:794945
    Sally: Oh! Hi. #line:2dc39b
    Sally: You snuck up on me. #line:34de2f
    Sally: Don't do that. #line:dcc2bc
<<else>>
    Player: Hey. #line:a8e70c
    Sally: Hi. #line:305cde
<<endif>>
```

The first line of code in this node checks to see if Wol has already run this node. `visited` is a function that 
is built into Wol. It returns true if the node you specify has been run before. 
You’ll notice that this line is wrapped in `<<` and `>>` symbols. This tells Wol that it’s control code, and not meant to be shown to the player.

If they haven’t run the `Sally` node yet, it means that this is the first time that we’ve spoken to `Sally` in this game. As a result, we run lines in which Sally and the player character meet. Otherwise, we instead run some shorter lines.
Each line in Wol is just a run of text, which is sent directly to the game. It’s up to the game to decide how it wants to display it; in the example game, it’s shown at the top of the screen.

At the end of each line, you’ll see a `#line:` tag. This tag lets Wol identify lines across multiple translations, and is optional if you aren’t translating your game into other languages. Wol can automatically generate them for you (not supported yet however).

#### Options

Here’s the next part of the code.

```yarn
<<if not visited("Sally.Watch")>>
    [[Anything exciting happen on your watch?|Sally.Watch]] #line:5d7a7c
<<endif>>

<<if $sally_warning and not visited("Sally.Sorry")>>
    [[Sorry about the console.|Sally.Sorry]] #line:0a7e39
<<endif>>
```

In the next part of the code, we do a check, and if it passes, we add an option. Options are things that the player can select; in this game, they’re things the player can say, but like lines, it’s up to the game to decide what to do with them. Options are shown to the player when the end of a node is reached.

The first couple of lines here test to see whether the player has run the node `Sally.Watch`. If they haven’t, then the code adds a new option. Options are wrapped with `[[` and `]]`. The text before the `|` is shown to the player, and the text after is the name of the node that will be run if the player chooses the option. Like lines, options can have line tags for localisation.

If the player has run the `Sally.Watch` node before, this code won’t be run, which means that the option to run it again won’t appear.

The rest of this part does a similar thing as the first: it does a check, and adds another option if the check passes. In this case, it checks to see if the variable `$sally_warning` is `true`, and if the player has not yet run the `Sally.Sorry` node. `$sally_warning` is set in a different node - it’s in the node Ship, which is stored in the file `Ship.yarn`.

```yarn
[[See you later.|Sally.Exit]] #line:0facf7
```

The very last line of the node adds an option, which takes the player to the Sally.Exit line. Because this option isn’t inside an if statement, it’s always added.

When Wol hits the end of the node, all of the options that have been accumulated so far will be shown to the player. Wol will then wait for the player to make a selection, and then start running the node that they selected.

And that’s how the node works!

### Writing Some Dialogue

Let’s write some dialogue! We’ll add a couple of lines to the Ship.

> Open the file Ship.yarn. It contains a single node, called Ship - go to it.

This code uses couple of features that we didn’t see in Sally: commands, and variables.

#### Commands

Commands are messages that Wol sends to your game, but aren’t intended to be shown to the player. Commands let you control things in your scene, like moving the camera around, or instructing a character to move to another point.

Because every game is different, Wol leaves the task of defining most commands to you. Wol defines two built-in commands: wait, which pauses the dialogue for a certain number of seconds, and stop, which ends the dialogue immediately.

The example game defines its own command, `setsprite`, which is used to change the sprite that the Ship character’s face is displaying. You can see this in action in the file `Ship.yarn`:

```yarn
Player: How's space?
Ship: Oh, man.
<<setsprite ShipFace happy>>
Ship: It's HUGE!
<<setsprite ShipFace neutral>>
```

<!-- TODO: make tutorial about setting up commands
You can learn how to define your own custom commands in Working With Commands. -->

#### Variables

Variables are how you store information about what the player has done in the game. We saw variables in use in the `Sally` node, where the variable `$sally_warning` was used to control whether some content was shown or not. This variable is set in here, in the `Ship` node - it represents whether or not the player has heard Sally’s warning about the console from the Ship.

Variables in Wol start with a `$`, and can store text, numbers, booleans (`true` or `false` values), or `null`. If you try and access a variable that hasn’t been set, you’ll get the value `null`, which represents “no value”.
Adding Some Content

#### Add some new dialogue. Add the following text to the end of the node:

```
Ship: Anything else I can help with?

-> No, thanks.
    Ship: Aw, ok!
-> I'm good.
    Ship: Let me know!

Ship: Bye!
```

#### Shortcut Options

The `->` items that we just added are called shortcut options. Shortcut options let you put choices in your node without having to create new nodes, which you link to through the `[[Option]]` syntax. They exist in-line with the rest of your node.

To use a shortcut option, you write a `->`, followed by the text that you want to display. Then, on the next lines, indent the code a few spaces (it doesn’t matter how many, as long as you’re consistent.) The indented lines will run if the option they’re attached to is selected. Shortcut options can be nested, which means you can put a group of shortcut options inside another. You can put any kind of code inside a shortcut option’s lines.

Because shortcut options don’t require you to create new nodes, they’re really good for situations where you want to offer the player some kind of choice that doesn’t significantly change the flow of the story.

Save the file, and go back to the game. Play the game again, and talk to the Ship. At the end of the conversation, you’ll see new dialogue.

### Where Next

The example game is set up so that when you talk to Sally, the node Sally is run, and when you talk to the Ship, the node Ship is run. With this in mind, change the story so that after you get told off by Sally, she asks you to go and fix a problem with the Ship.

You can also read the [Syntax Reference](https://yarnspinner.dev/docs/syntax/) for Yarn.

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

* line ( [Line](README.md#Line) line ) 

  Emitted when a [Line](README.md#Line) is emitted from the dialogue. `line` holds relevant information.

* options ( [`Array`](https://docs.godotengine.org/en/stable/classes/class_array.html) options ) 

  Emitted when the dialogue runs into a set of options. Is emitted with an [`Array`](https://docs.godotengine.org/en/stable/classes/class_array.html) of [Option](README.md#Option)s.
 
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
The [Line](README.md#Line) object is _the_ object that you're gonna be interacting with the most. This object holds all of the information of the actual lines of dialogue. The most important property is `text`, but it has some additional properties you can make use of for debugging or holding of metadata (no support for that yet however).

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
The [Option](README.md#Option) object is anoter object that you're gonna be interacting with a lot. This object holds the information of a choice in your dialogue. 
It has a reference to a [Line](README.md#Line) with it's `line` property so you can show the appropriate text to your player!

### Properties
| Type                                                                                      | Property      |
|-------------------------------------------------------------------------------------------|---------------|
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html#class-int)            | id            | 
| [Line](README.md#Line)                                                                    | line          |
| [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string)  | destination   |

### Property Descriptions

* [int](https://docs.godotengine.org/en/stable/classes/class_int.html#class-int) id 

  A unique identifier that you can use to communicate your option choice with `select_option ( id )`.

* [Line](README.md#Line) line 

  A line of dialogue that's been processed by Wol. See [Line](README.md#Line) for more details.

* [String](https://docs.godotengine.org/en/lastest/classes/class_string.html#class-string) destination

  The node that you will jump to when this option is selected. (Only relevant for jump questions, not inline ones).
 

