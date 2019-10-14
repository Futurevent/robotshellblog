---
title: 'Fuchisa运行Hello,World'
tags: OS
id: HelloWorld
categories: OS
date: 2019-10-14 16:16:38
---

之前的几篇一直都在介绍Fuchsia的一些概念，本文将在Fuchsia上运行我们的第一个应用，通过该示例可以快速了解到Fuchsia的components是如何编译、运行及测试的。Hello Fuchsia，Hello World。
<!--more-->
# 文件说明
代码所在位置为fuchsia根目录/examples/hello_world，先来看下目录结构：
{% asset_img project.png 工程目录 %}
Fuchsia的示例代码同时提供了c++ 和 rust 语言的示例，所以有两个语言的子目录 /cpp 和 /rust。这两个目录之外，一个是README.md文件，其中描述了该示例如何编译运行等一些说明。另一个文件就比较重要了，是BUILD.gn。
fuchsia 使用 GN 编译，GN是一款构建系统，用于编译大规模代码生成ninjia文件。BUILD.gn 内容如下：
```
group("hello_world") {
  testonly = true
  deps = [
    ":tests",
    "cpp",
    "rust",
  ]
}

group("tests") {
  testonly = true
  data_deps = [
    "cpp:tests",
    "rust:tests",
  ]
}
```
在这个文件中使用group定义了一个target，名字为“hello_world”，group可以包含其他的依赖，此处包含了cpp 和 rust，使用该target将同时构建cpp和rust版的hello world程序。
每一个依赖的子路径下，都有自己的BUILD.gn文件用来定义要构建出的包，同时每一个依赖的子路径下也包含一个meta目录，该目录中定义的.cmx 文件为包的清单文件。cpp目录下的Build.gn文件内容如下所示：
```
import("//build/package.gni")

//定义目标cpp，该目标被上级的BUILD.gn所依赖
group("cpp") {
  deps = [
    ":hello_world_cpp",
  ]
}

//定义可执行的目标/bin/hello_world_cpp
executable("bin") {
  output_name = "hello_world_cpp"

  //包含的源文件
  sources = [
    "hello_world.cc",
  ]
}

//定义fuchisa包：hello_world_cpp
package("hello_world_cpp") {
  //依赖上面定义的executable bin
  deps = [
    ":bin",
  ]

  binaries = [
    {
      name = "hello_world_cpp"
    },
  ]

  //包含清单文件
  meta = [
    {
      path = rebase_path("meta/hello_world_cpp.cmx")
      dest = "hello_world_cpp.cmx"
    },
  ]
}
```
cpp/meta 目录下的 hello_world_cpp.cmx 内容如下，它是一个json格式的文件，它用来描述在Fuchsia系统中应用如何作为组件进行运行。
```
{
    "program": {
        "binary": "bin/hello_world_cpp"
    },
    "sandbox": {
        "services": [
            "fuchsia.logger.LogSink"
        ]
    }
}
```
# build
首先需要将hello_world包含进build，命令如下：
```
fx set ... --with //examples/hello_world
```
此命令将包hello_world包含进fuchsia的universe中。对于应用包包含的位置可参考文章[Fuchsia的fx命令](https://www.robotshell.com/2019/09/29/os/fx/)后半部分的介绍。universe空间的含义为universe 中的包是附加可选包，这些包可以按需下载运行。它们不会运行打包到Paving image中。
然后可以构建，命令如下：
```
fx build
```
# 运行
由于hello world包放到了universe中，所以需要一个更新服务给fuchsia系统安装包，所以启动服务
```
» fx serve
+ exec /home/[username]/code/fuchsia/out/default/host_x64/bootserver --board_name pc --boot /home/[username]/code/fuchsia/out/default/fuchsia.zbi --bootloader /home/[username]/code/fuchsia/out/default/fuchsia.esp.blk --fvm /home/[username]/code/fuchsia/out/default/obj/build/images/fvm.sparse.blk --zircona /home/[username]/code/fuchsia/out/default/fuchsia.zbi --zirconr /home/[username]/code/fuchsia/out/default/zedboot.zbi --authorized-keys /home/[username]/code/fuchsia/.ssh/authorized_keys
2019-10-14 14:49:09 [bootserver] Board name set to [pc]
2019-10-14 14:49:09 [bootserver] listening on [::]:33331
2019-10-14 14:49:09 [serve-updates] Discovery...
```
服务启动后，会停止在Discovery，等待发现设备，我们使用qemu模拟器，所以运行模拟器
```
fx run -N -u scripts/start-dhcp-server.sh  -g
```
fuchsia启动完成后，会看到qemu模拟器中启动四个终端并显示$符号。这时，serve的终端显示有设备上线了，显示如下：
```
2019-10-14 15:14:44 [serve-updates] Device up
2019-10-14 15:14:44 [serve-updates] Registering devhost as update source
2019-10-14 15:14:59 [serve-updates] Ready to push packages!
```

此时准备工作就准备好了，开始向fuchis推送hello_world并运行。
hello_world 的cpp版源文件为hello_world.cc，在此就可以进行其他熟悉的cpp开发了。
```
#include <iostream>

int main() {
  std::cout << "Hello, Fuchsia!\n";
  return 0;
}
```
开始运行编译好的hello_world
```
» fx shell run fuchsia-pkg://fuchsia.com/hello_world_cpp#meta/hello_world_cpp.cmx
Hello, Fuchsia!
```
运行正确，输出期望的结果。此时也可以在模拟器fuchsia的终端下，或者使用fx shell登录到fuchsia的终端下，使用run命令运行。run命令运行时，也可以使用组件的名称替代URI运行，前提是该名称对应唯一的组件，如下所示：
```
» fx shell run hello_world_cpp
fuchsia-pkg://fuchsia.com/hello_world_cpp_tests#meta/hello_world_cpp_unittests.cmx
fuchsia-pkg://fuchsia.com/hello_world_cpp#meta/hello_world_cpp.cmx
Error: "hello_world_cpp" matched multiple components.
```
因为包含字符串hello_world_cpp的组件还有测试程序，所以没能唯一匹配一个组件从而得到运行。

若要查看一个字符串所对应的组件可以使用locate命令，它将列出所有名称中包含关键字的Fuchsia Package URI，示例如下：
```
» fx shell locate hello
fuchsia-pkg://fuchsia.com/hello_world_cpp_tests#meta/hello_world_cpp_unittests.cmx
fuchsia-pkg://fuchsia.com/hello_world_rust_tests#meta/hello_world_rust_bin_test.cmx
fuchsia-pkg://fuchsia.com/hello_world_cpp#meta/hello_world_cpp.cmx
fuchsia-pkg://fuchsia.com/hello_world_rust#meta/hello_world_rust.cmx
Error: "hello" matched more than one component. Try `locate --list` instead.
```

最后，在fuchsia终端下，可以查看下一个包安装到系统中的目录结构，包被放在如下目录中：
```
/pkgfs/packages/hello_world_cpp/0
|--bin
  |--hello_world_cpp
|--lib
  |--ld.so.1
  |--libc++.so.2
  |--libc++abi.so.1
  |--libfdio.so
  |--libunwind.so.1
|--meta
  |--contents
  |--hello_world_cpp.cmx
  |--pacakge
```

另外补充下，fuchsia的源码使用clion IDE 进行查看非常方便。可以在fuchsia根目录运行
```
fx compdb
```
生成compile_commands.json文件。然后安装IDE Clion，启动后，选择fuchsia根目录导入项目，然后经过漫长的等待，就可以使用ide来查看代码了。

如上内容，如有谬误，请君留言，感激不进。
