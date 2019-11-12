---
title: Component 能力介绍
tags: OS
id: component capabilities
categories: OS
date: 2019-11-12 17:17:26
---

Capabilities 理解为能力、功能，就是赋予一个组件能够连接和读取其他组件提供的能力的权限。
fuchsia 中组件的能力，有三种，分别是：
- Directory 能力
- Service 能力
- Storage 能力

<!--more-->
# Directory 能力
Directory能力允许组件连接到其他组件提供的目录。
## 创建Directory能力
当一个组件想让它的一个目录对其他组件可用时，可以使用以下两种方式之一导出目录的路径：
方法一：使用expose关键字，将目录公开到包含域
```
{
    "expose: [{
        "directory": "/data",
        "from": "self",
    }],
}
```
方法二：使用offer关键字，将目录提供给组件的子目录
```
{
    "offer: [{
        "directory": "/data",
        "from": "self",
        "to": [{
            { "dest": "#child-a" },
            { "dest": "#child-b" },
        }],
    }],
}
```
## 使用Directory能力
如果组件想使用自己所在包含域内的目录，需要使用use关键字来使用目录，组件框架会连接组件到提供该目录的组件，这样组件再运行时就可以访问该目录了。示例如下：
```
{
    "use": [{
        "directory": "/data",
    }],
}
```
## 组件框架提供的Directory能力
组件框架提供了一些预先定义好的Directory能力，在申请使用这些目录时同样使用use关键字，只是需要增加from字段，并且字段值为framework，来表明该目录来自于framework。
```
{
    "use": [{
        "directory": "/hub",
        "from": "framework",
    }],
}
```
## Dierctory的路径别名
在使用关键字expose、offer向外提供目录能力、使用use请求目录能力时，可以使用as 关键字来为目录的引用路径起别名。
在如下的实例中，有A、B、C三个组件如下：
```
A  <- offers directory "/data" from "self" to B as "/intermediary"
|
B  <- offers directory "/intermediary" from "realm" to B as "/intermediary2"
|
C  <- uses directory "/intermediary2" as "/config"
```
写清单文件时，则写为如下形式：
A.cml
```
{
    "offer: [{
        "directory": "/data",
        "from": "self",
        "to": [{
            { "dest": "#B", "as": "/intermediary" },
        }],
    }],
    "children": [{
        "name": "B",
        "url": "fuchsia-pkg://fuchsia.com/B#meta/B.cm",
    }],
}
```
B.cml
```
{
    "offer: [{
        "directory": "/intermediary",
        "from": "self",
        "to": [{
            { "dest": "#C", "as": "/intermediary2" },
        }],
    }],
    "children": [{
        "name": "C",
        "url": "fuchsia-pkg://fuchsia.com/C#meta/C.cm",
    }],
}
```
C.cml
```
{
    "use": [{
        "directory": "/intermediary2",
        "as": "/config",
    }],
}
```
# Service 能力
Service 服务，允许组件通过FIDL定义的接口，调用其他组件或者框架提供的服务。
## Service 能力的创建
当组件expose或者offer一个服务时，会将此服务导出给该组件的父组件
expose的方式
```
{
    "expose": [{
        "service": "/svc/fuchsia.example.ExampleService",
        "from": "self",
    }],
}
```
像其子组件提供服务
```
{
    "offer": [{
        "service": "/svc/fuchsia.example.ExampleService",
        "from": "self",
        "to": [{
            { "dest": "#child-a" },
            { "dest": "#child-b" },
        }],
    }],
}
```
## 使用service能力
可使用use关键字获取在当前组件所在的包含域内的服务。组件框架将根据该定义为组件查找到提供此服务的组件，并在组件间简历通道。
```
{
    "use": [{
        "service": "/svc/fuchsia.example.ExampleService",
    }],
}
```
## 使用组件框架提供的服务
fuchsia的组件框架提供了一些服务，供任意组件调用，使用组件框架提供的服务，使用use关键子申明，并且来源标记为framework即可。
```
{
    "use": [{
        "service": "/svc/fuchsia.sys2.Realm",
        "from": "framework",
    }],
}
```
## service别名
同上directory能力的别名，使用as关键字定义，不再赘述。
# Sotrage 能力
Storage能力和Directory非常相似，但是也有不同。存储功能所提供的目录对于组件来说是唯一，不重叠的，每个组件有自己的区别于其他组件的存储目录。
## Directory 和 Storage的比较
例如，如果组件实例a从其领域得到访问一个目录的能力，然后又将该能力提供给b，则两个组件实例都可以看到同一个目录并与之交互。
```
<a's realm>
    |
    a
    |
    b

a.cml:
{
    "use": [ {"directory": "/example_dir" } ],
    "offer": [
        {
            "directory": "/example_dir",
            "from": "realm",
            "to": [ { "dest": "#b" } ],
        },
    ],
}

b.cml:
{
    "use": [ {"directory": "/example_dir" } ],
}
```
如果组件a在目录 example_dir内创建了一个文件，则b组件是可以看到并且读取该文件的。而如果使用的是storage能力，例如：
```
<a's realm>
    |
    a
    |
    b

a.cml:
{
    "use": [ { "storage": "data", "as": "/example_dir" } ],
    "offer": [
        {
            "storage": "data",
            "from": "realm",
            "to": [ { "dest": "#b" } ],
        },
    ],
}

b.cml:
{
    "use": [ { "storage": "data", "as": "/example_dir" } ],
}
```
则b组件是看不到a组件创建的文件的。b组件看到的example_dir目录和a组件看到的example_dir目录是各自独立的，不重叠的。
直接使用directory能力是应当小心谨慎，因为每个拥有该目录访问能力的组件都可访问该目录。而基于该目录的storage能力，将会为每个访问该storage的组件创建子目录，这样各组件就可以放心使用该目录，而不用担心冲突问题。这也意味着在定义子组件时，使用不同的名字，将会为子组件分配到不同的sotrage的子目录。

## 创建Storage 能力
使用storage关键字可以创建storage能力，storage能力创建后，别的组件可以通过能力名称来引用该能力。创建storage能力时，必须从directory能力创建，组件框架将从该目录为storage能力创建组件唯一的storage能力。
```
{
    "storage": [
        {
            "name": "mystorage",
            "from": "#memfs",
            "path": "/memfs",
        },
    ],
    "offer": [
        {
            "storage": "data",
            "from": "#mystorage",
            "to": [ { "dest": "#storage_user" } ],
        },
    ],
    "children": [
        { "name": "memfs", "url": "fuchsia-pkg://..." },
        { "name": "storage_user", "url": "fuchsia-pkg://...", },
    ],
}
```
上例中，将使用子组件memfs提供的目录/memfs作为storage的目录创建storatge能力，能力的名称为mystorage, 并以mystorage为基础创建了storage能力data提供给了storage_user组件使用。
