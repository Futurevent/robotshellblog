---
title: Linux 版本控制工具之Ｒａｂｂｉｔｖｃｓ
tags:
  - 工具
categories:
  - 工具
date: 2017-11-04 12:08:10
---


新公司的文档管理居然使用ｓｖｎ，不知道适合原因．很久不用有一些忘却了.之前在ｗｉｎ下用的是TortoiseSVN，在ｕｂｕｎｔｕ下，与之及其相似的是ｒａｂｂｉｔｖｃｓ．
[官网地址](http://rabbitvcs.org/)
<!--more-->
下面是来自官方打介绍

## 特性介绍

### Nautilus
Seamlessly integrates into Nautilus workflow
![Nautilus](http://rabbitvcs.org/images/screenshots/nautilus-git-showcase.png)

### Gedit
Provides menus for accessing version control tools
![Gedit](http://rabbitvcs.org/images/screenshots/gedit-git-showcase.png)

### Thunar
Seamlessly integrates into Thunar workflow
![Thunar](http://rabbitvcs.org/images/screenshots/thunar-git-showcase.png)

### Command Line Interface
An easy to use tool to launch our dialogs
![Command Line Interface](http://rabbitvcs.org/images/screenshots/command-line-showcase.png)

### Subversion
Supports most Subversion functionality
![Subversion](http://rabbitvcs.org/images/screenshots/nautilus-svn-showcase.png)

### Git
Supports most Git functionality
![Git](http://rabbitvcs.org/images/screenshots/git-log-showcase.png)

### Fully Internationalized
Partial-to-full support for 26 languages!
![Fully Internationalized](http://rabbitvcs.org/images/screenshots/i18n-showcase.png)

## Ubuntu安装方法

```bash
### 添加源
$ sudo add-apt-repository ppa:rabbitvcs/ppa
### 导入key
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 34EF4A35
### 更新源
$ sudo apt-get update
### 安装依赖
$ sudo apt-get install python-nautilus python-configobj python-gtk2 python-glade2 python-svn python-dbus python-dulwich subversion meld
### 安装ＲabbitVCS
$ sudo apt-get install rabbitvcs-cli  rabbitvcs-core rabbitvcs-gedit rabbitvcs-nautilus3
### 如安装失败使用　rabbitvcs-nautilus3 替换为　rabbitvcs-nautilus
```

## 使用方法
