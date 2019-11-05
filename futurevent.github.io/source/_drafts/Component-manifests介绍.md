---
title: Component manifests介绍
tags: OS
id: component manifest
categories: OS
---
清单文件是用来描述组件的一个描述文件，扩展名为.cmx。通常位于工程的meta目录下。描述一个组件通常包含如下几部分：
- 关于如何运行组件的信息
- 子组件实例和组件集合的描述
- 描述如何在组件之间使用、发布和提供功能的路由规则。
- 自由形式的数据（“facets”）被组件框架忽略，但可以由第三方解释（类似android清单文件中的meta-data 数据）。

<!--more-->
# 组件清单文件和组件声明
这里由几个比较容易混淆的概念 component manifest、component manifest source 和 component declarations。
## component manifest
组件清单，组件清单是对组件描述的编码实现，可以理解为组件描述通过对清单文件的编译而来。通常作为包的一部分随包一起发布，它和组件是一一对应的关系。扩展名为.cm是一个json文件。带有清单文件信息的的fuchsia-pkg URL用来唯一标识一个包里的组件。
## component manifest source
组件清单文件的源文件。组件清单源文件使用CML(component manifest language)语言编写。后缀名为.cml，也是json格式的文件。使用cmc工具可将清单源文件编译为清单文件。
cmc 为清单源文件编译工具，在fuchsia编译后会生成，生成的位置为：./out/default/host_x64/cmc
使用方法如下：
```
» ./out/default/host_x64/cmc help                                                                       zhaojie@zhaojie-PC


USAGE:
    cmc [OPTIONS] <SUBCOMMAND>

FLAGS:
    -h, --help       Prints help information
    -V, --version    Prints version information

OPTIONS:
    -s, --stamp <stamp>    Stamp this file on success

SUBCOMMANDS:
    compile     compile a CML file
    format      format a json file
    help        Prints this message or the help of the given subcommand(s)
    merge       merge the listed cmx files
    validate    validate that one or more cmx files are valid
```
## component declarations
清单文件会转换为ComponentDecl table对象，这是FIDL语言定义的一个数据结构。该数据结构在fuchsia的组件框架中代表一个具体的组件，在运行时，组件框架的api读取该数据向其他组件提供该组件的能力。

# 涉及到的一些概念
先看一个两段清单文件的内容，有个大致的认识。示例如下：
```
// Component manifest for the `echo_client` example program, which sends a message to the Echo
// service.
{
    "program": {
        "binary": "bin/echo_client",
        "args": ["Hippos", "rule!"],
    },
    "use": [
        {
            "legacy_service": "/svc/fidl.examples.routing.echo.Echo",
        },
    ],
}
```
和
```
// Component manifest for the `echo_server` example program, which hosts the Echo service used
// by `echo_client`.
{
    "program": {
        "binary": "bin/echo_server",
    },
    "expose": [
        {
            "legacy_service": "/svc/fidl.examples.routing.echo.Echo",
            "from": "self",
        },
        {
            "directory": "/hub",
            "from": "framework",
        },
    ],
}
```
## 运行时
字段【program】用来描述组件是如何运行的。对于包含elf格式的二进制可执行文件的组件，该字段的值为指向包中二进制文件的路径，同时可选的也可以携带传递给该二进制文件的参数。如何一个组件中不包含可执行文件，此字段可以省略。
## 能力路由
组件清单中提供相应的语法用来描述能力是如何在组件之间进行路由的。
如下的几类能力可在组件间进行传递路由：
- service：一种文件系统服务节点，通过该节点可以打开和使用服务提供者提供的服务。类似服务的客户端代理。
- directory：文件系统中的目录
- storge：与使用它的组件相隔离的文件系统目录。

使用下面几个关键字可对能力的路由进行定义：
- use

当一个组件使用某种能力时，该能力将被引入到组件的命名空间内，组件可以使用任意赋予给它的能力。

- offer

一个组件可以将它的能力提供给它的子组件或者组件集合使用，获得该能力的组件也可以将能力再次提供出去。

- expose

组件可以使用该关键字将自己的组件暴露出去，这样该组件的父组件就可以将该能力提供给该组件在同一颗树上的其他组件节点。

# 清单文件的语法
清单文件由各段组成
## program
program 段由组件将执行的可执行文件决定，如果组件不包含可执行文件，该段可省略。
如果组件使用elf runner执行，则program段包含两个属性：
- binary: 与包关联的可执行文件的路径，
- args(可选)：二进制文件执行的参数字符串数组。

```
"program": {
    "binary": "bin/hippo",
    "args": [ "Hello", "hippos!" ],
},
```
## children
children 段用来定义子组件实例，是一个描述子组件的数组。childer包含如下属性：
- name: 子组件实例的名字
- url： 子组件实例的URL
- startup: 组件实例的启动方式
  - lazy(默认)：只有当由其他组件绑定它时它才启动
  - eager：父组件启动即启动子组件

```
"children": [
    {
        "name": "logger",
        "url": "fuchsia-pkg://fuchsia.com/logger#logger.cm",
    },
    {
        "name": "pkg_cache",
        "url": "fuchsia-pkg://fuchsia.com/pkg_cache#meta/pkg_cache.cm",
        "startup": "eager",
    },
],
```
## use
use 段用来描述组件将使用哪些能力，use的内容是包含如下属性的对象数组。
- 能力的定义：关键字分别为service/directory/storage
- as: 类似能力路径的别名

```
"use": [
    {
        "service": "/svc/fuchsia.logger.LogSink",
    },
    {
        "directory": "/data/themes",
        "as": "/themes",
    },
    {
        "storage": "data",
        "as": "/my_data",
    },
],
```
## expose
expose 用于定义组件暴露的能力，属性如下：
- 能力定义
- from：用来说明能力的来源，取值如下：
  - self：当前组件
  - #<child-name>：子组件实例的引用
- as

```
"expose": [
    {
        "directory": "/data/themes",
        "from": "self",
    },
    {
        "service": "/svc/pkg_cache",
        "from": "#pkg_cache",
        "as": "/svc/fuchsia.pkg.PackageCache",
    },
],
```
## offer
offer 用来定义该组件为子组件提供能力的描述，属性：
- 能力的定义
- from 能力的来源，取值为：
  - self 当前组件
  - realm 组件所在域
  - #<child-name> 子组件实例的名字
  - #<storage-name> 一个storage定义的引用
- to 被赋予能力的目标组件
```
"offer": [
    {
        "service": "/svc/fuchsia.logger.LogSink",
        "from": "#logger",
        "to": [ "#fshost", "#pkg_cache" ],
    },
    {
        "directory": "/data/blobfs",
        "from": "self",
        "to": [ "#pkg_cache" ],
        "as": "/blobfs",
    },
    {
        "directory": "/data",
        "from": "realm",
        "to": [ "#fshost" ],
    },
    {
        "storage": "meta",
        "from": "realm",
        "to": [ "#logger" ],
    },
],
```

## facets
facets 段中可定义第三方自行解析的json格式的内容，用于自定义组件的属性。

总体来讲，组件清单就是用来描述组件的基本构成，运行方式，以及能力获取提供的文件。在组件框架中用来代表一个组件。fuchsia的组件清单文件是一种类似于乐高积木的组合方式，提供的描述组件组合的方式并不多，但是这种方式，更强的限制了组件能力调用的权限。本文只是形式上对清单文件进行了描述，深层次的理解，还得后续深入。
