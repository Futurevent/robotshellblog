---
title: Fuchsia的APP变革
id: stories&modules
tags:
  - OS
categories:
  - OS
---
相比之前的操作系统，Fuchsia做了很多的变革和特有的功能。Stories和Modules就是其中之一。这两个功能将颠覆之前对智能手机APP的使用方式，带来不一样的使用体验。
<!--more-->
在android或者ios系统上，一个应用要么是打开、要么是关闭。如果你想同时处理多件事，大多数应用通过打开新的选项卡来处理，例如浏览器，可以使用不同的tab来打开不同的网页。
在Fuchsia系统中，应用是由一个个独立的Modules构成的，每个modules可作为独立的视图或者是功能对外提供。这些modules可以多次打开，例如可以打开两个计算器。在此之上，Fuchsia引入了Story的概念。Story由来自不同应用中的一个或者多个modules构成，用来完成一项任务或者一个完整的想法（无论这些modules最初是用来做什么的）。
***
下面是对Story和Module的官方介绍
# Stroies
```
A story is a logical container for composing a set of modules.

Stories and their associated state are stored in the user's Ledger.
```
一个Story是由一系列的modules组合而成的一个逻辑容器。这个逻辑容器的信息（story和和它关联的状态）将存储在[Ledger](https://fuchsia.googlesource.com/fuchsia/+/master/src/ledger/docs/README.md)(Fuchsia的存储系统，存储story及其状态可实现跨设备同步使用此story)内。
```
The modular framework uses the fuchsia.modular.StoryShell interface
to display the UI for stories.
```
## Story的生命周期
```
Stories can be created, deleted, started, and stopped.
Created and deleted refer to the existence of the story in the ledger, whereas started and stopped refer to whether or not the story
and its associated modules are currently running.
```
Story有四个状态：created、deleted、started、stopped，created和deleted表示在ledger中是否存在该story，而started和stopped用来表示此story及其中的module是否正在运行。
# Modules
```
A Module is a component which displays UI and runs as part of a Story.

Multiple modules can be composed into a single story,
and modules can add other modules to the story they are part of. Module's can either embed other modules within their own content,
or they can delegate visual composition to the StoryShell.
```
Module 是Story用来显示UI的一个组件，一个Story可以添加多个module，module也可以添加其它module到它所在的story中，也可以在module内部嵌套其他module。
## Module的生命周期
```
A module's lifecycle is bound to the lifecycle of the story it is part of. In addition, a given module can have multiple running instances in a single story.

When a module starts another module it is given a module controller which it can use to control the lifecycle of the started module.
```
一个模块的生命周期依赖于它所在的story，一个module可以在一个story内部创建多个实例。当一个module创建了另一个module时，会得到被创建module的controller，通过controller即可控制该module的生命周期。
## Module之间的通信机制
```
Modules communicate with other modules via intents and entities, and with agents via FIDL and message queues.
```
Module之间通过传递intent和entities进行通信。
***
Fuchsia中没有像其他系统中那样有最近使用app的概念（Recent Apps）,取而代之的增加了最近使用的story（Recent Stories）。想要组合多个module，可以通过拖拽将不同的story组合在一起，然后根据需要调整view的大小。同时也支持使用一个本地设备上不存在的module，就像“Android Instant App”的改进版。
Story符合人们做事情时分步骤但是连续的思路。而以往的App则时一种分离的做事方式。Story是一种更加连贯的思维方式，不同于App的使用。
