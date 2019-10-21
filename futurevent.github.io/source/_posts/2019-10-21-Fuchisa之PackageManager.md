---
title: Fuchisa之PackageManager
tags: OS
id: pm
categories: OS
date: 2019-10-21 17:29:16
---

上周，在Fuchsia OS上运行了第一个demo——HelloWorld，了解到编译完成后，需要使用fx的命令将编译好的Fuchisa的应用包传送到系统中，从而得到运行。本周简单介绍下Fuchsia Package。
<!--more-->
Fuchsia 系统内的包的管理和控制，通过PackageManager实现。pm 是一个控制台的工具，通过pm可以对包进行相关的操作。

# pm
pm 是package manager的命令行接口，主要提供如下功能：
- 演示和执行pmd(解释见下文)的 api
- 供开发人员使用的包相关的功能
  - 打包
  - 安装包
  - 列出所有的包
  - 移除包
  - 包检验
- 向Amber提供包的摘要信息
pm可以运行在多个操作系统上，但在没有pmd的系统上只支持一部分操作。

# pmd
pmd 是包管理的守护进程，它的职责是：
- 激活包（使包在本地可用）
- 为包提供服务服务包（提供对包的文件系统类型访问）
- 管理包（对不在使用的包进行垃圾回收）
- 枚举系统中的包，列出系统中可用的包。
pmd 只运行在fuchisia上。

# fuchsia包的结构
fuchsia包是为fuchsia系统提供一个或多个程序、组件或服务的一个或多个文件集合。
包由一组元数据定义，这些元数据存储在Fuchsia顶层的目录中，如下：
```
meta/
  package
  contents
```
## metadata
元数据文件包含一组基本的系统、开发人员和用户友好的数据。例如，包括人名、唯一名称、版本、开发人员名称、开发人员公钥和说明。
## contents
内容文件包含整个包中所有文件的严格完整清单。这些名称兼作打包路径和运行时表示路径。这些路径都有一个作为merkle树节点的hash值。merkle树在zircon中有大量的使用，后续专门介绍一下。
