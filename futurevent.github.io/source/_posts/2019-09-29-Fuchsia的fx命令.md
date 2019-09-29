---
title: Fuchsia的fx命令
tags: OS
id: fx
categories: OS
date: 2019-09-29 15:08:04
---

之前在介绍fuchsia的编译（fuchsia的编译参考文章：[Fuchsia的运行初体验](https://www.robotshell.com/2019/09/22/os/build/)）的时候提到配置fuchsia的编译产品，以及编译fuchsia系统都会使用到fx命令。
fx对于Fuchsia的重要性，大概等于编译命令+adb 对于Android的重要性。而且fx有非常多的自命令，本文仅参考官方文档[fx workflows](https://fuchsia.dev/fuchsia-src/development/workflows/fx),对部分fx的自命令进行简单介绍。
<!--more-->
fx 是一个入口命令，通过它开发着可以使用大量的开发过程中将使用到的工具脚本。查看fx支持的子命令可以使用fx help。如果使用bash或者zsh作为shell的话，还可以通过执行脚本scripts/fx-env.h将fx的自动补全功能包含进当前shell中。下面为fx help列出的fx子命令
```bash
» fx help               
usage: fx [--dir BUILD_DIR] [-d DEVICE_NAME] [-i] [-x] COMMAND [...]

Run Fuchsia development commands. Must be run with either a current working
directory that is contained in a Platform Source Tree or the FUCHSIA_DIR
environment variable set to the root of a Platform Source Tree.

commands:
add-update-source           register dev host as target's update source
aemu                        start fuchsia in aemu
args                        `gn args` the FUCHSIA_BUILD_DIR
blobstats                   compute some blobfs statistics from the build
bugreport                   Obtain and parse a bugreport from a connected target.
build                       Run Ninja to build Fuchsia
build-push                  build Fuchsia and push to device
catapult_converter
cgpt
check-deps                  checks dependency graph in areas
clang-tidy                  runs clang-tidy on specified files
clean                       `gn clean` the ZIRCON_BUILDROOT and FUCHSIA_BUILD_DIR
clean-build                 clean the build directory and then perform a full build
compdb                      generate a compilation database for the current build configuration
cp                          copy a file to/from a target device
cpuperf_print
dart-remote-test            runs a single remote test target through //scripts/run-dart-action.py
dart-tunnel                 forward local ports to Dart VMs on the device.
debug                       run the debug agent on target and connect to it with zxdb
delta                       compare all built Fuchsia packages with a prior package snapshot
dockyard_host
doctor                      run various checks to determine the health of a Fuchsia checkout
exec                        read the current build config, then exec
exec-host-tests             
far
fidlcat                     run fidlcat on given target.
fidldoc
fidlgen
fidlgen_dart
fidlgen_llcpp
fidlmerge
flash                       
flutter-attach              attach to a running flutter module to enable hot reload and debugging
format-code                 runs source formatters on modified files
futility
fuzz                        run a fuzz test on target a device
gce                         Google Compute Engine commands
gen                         `gn gen` the Zircon and Fuchsia build directories.
gen-cargo
get-build-dir               print the current fuchsia build directory
get-device                  print the current selected device name
get-device-addr             print the Fuchsia IPv6 address of the current selected device
gidl
gn
ninja
cipd
jiri
insntrace_print
iquery                      generate a report with component exposed data
kazoo
lint                        runs source linters on modified files
list-boards                 list boards available for building
list-packages               list packages are built
list-products               list products available for building
list-usb-disks              list attached usb disks
log                         listen for kernel logs.
make-efi
make-fuchsia-vol            build a fuchsia persistent disk
make-integration-patch      Creates a CL in an integration repository suitable for testing other CLs
metrics                     manage collection of metrics in fx tools
mkzedboot                   make a zedboot USB key
multi                       Run an `fx` command across multiple build directories.
netaddr                     get the address of a running fuchsia system
netboot                     run bootserver for netbooting
netls                       list running fuchsia systems on the local network
net-run                     run Fuchsia on QEMU in background and runs SSH command after netstack runs
ninjatrace2json             Collect Ninja trace information for analysis in chrome://tracing
ota                         do a system OTA
pave                        run bootserver for paving
pave-zedboot                run bootserver for paving zedboot
pending-commits             view commits not yet published to global integration
pm
push-package                push packages to a device
qemu-cipd-ensure            Generate CIPD files to download the current QEMU package.
reboot                      reboot a target fuchsia system
remote_module_resolver
run                         start fuchsia in qemu with a FVM disk
run-bash-test               runs tests using bash_test_framework.sh
run-dart-action             Run Dart actions (analysis, test, target-test)
run-e2e-tests               run e2e tests
run-host-tests              build and run tests on host
run-netboot                 start fuchsia in qemu via netboot
run-recovery                start Fuchsia System Recovery in qem
run-test                    build a test package and run on target.
run-test-component          build a test package and run on target.
rustdoc
rustfmt
save-package-stats          take a snapshot of all built Fuchsia packages
scp                         invoke scp with the build ssh config
screenshot                  takes a screenshot and copies it to the host
serial                      attach to a serial console
serve                       start `pave` and `serve-updates` in a single command
serve-updates               start the update server and attach to a running fuchsia device
set                         set up a build directory
set-build-dir               set the default build directory used by other fx commands
set-clock                   set the clock on target using host clock
set-device                  set the default device to interact with
set-petal                   configure jiri to manage a specific petal
set-relay                   
setup-macos                 register Zircon tools at MacOS Application Firewall
setup-usb-ethernet          Setup udev rules for USB CDC ethernet
sftp                        invoke sftp with the build ssh config
shell                       start a remote interactive shell in the target device
sniff                       
ssh                         invoke ssh with the keys from $FUCHSIA_BUILD_DIR/ssh-keys
status                      print relevant information about the developer setup
symbolize                   symbolize backtraces and program locations provided as input on stdin
syslog                      listen for logs
trace2json
traceutil
traceutil-generate-tally
unset-device                unset the default device to interact with
update                      do a full update of a target system
update-rustc-crate-map
update-rustc-third-party    updates rustc_library and rustc_binary third_party dependencies
use                         re-use a previous build directory set up by `fx set`
vendor                      forward commands to vendor/*/scripts/devshell
verify-build-packages       verify the structure of the build package directory in a layer
wait                        wait for a shell to become available
whereiscl
zxdb

Global fx options: fx [OPTION]  ...
  --dir=BUILD_DIR       Path to the build directory to use when running COMMAND.
  -d=DEVICE_NAME        Target a specific device. DEVICE_NAME may be a Fuchsia
                        device name. Note: "fx set-device" can be used to set a
                        default DEVICE_NAME for a BUILD_DIR.
  -i                    Iterative mode.  Repeat the command whenever a file is
                        modified under your Fuchsia directory, not including
                        out/.
  -x                    Print commands and their arguments as they are executed.

optional shell extensions:
  fx-go
  fx-update-path
  fx-set-prompt

To use these shell extensions, first source fx-env.sh into your shell:

  $ source scripts/fx-env.sh
```
# 生成build配置的命令
Fuchsia的编译需要做如下几个选择：
1. 你想编译什么产品？
2. 你想编译什么平台？
3. 你想要包含哪些额外的包？

有了以上的选择，就可以使用fx set配置build了，例如：
```
$ fx set workstation.x64 --with //bundles:tests
```
将此次build设置为运行于x64平台的workstation产品，且将测试程序包也一同进行了编译。这个命令将配置存储在args.gn文件中（该文件默认在out/default/目录下)，然后可以使用命令
```
fx args
```
对该文件进行编辑，编辑关闭文件后，会重新生成配置文件。
这里引入了三个新的概念叫 base、cache、universe。要理解这三个概念需要先理解下另一个概念 __Paving images__ ，后文会对其详细介绍，此处可简单理解为是一种刷机方式的刷机包。build配置就是用来决定对哪些依赖进行编译，哪些编译结果文件会被包含到哪个产物中。base、cache、universe就是在这个概念上的三个空间（范围）。
- base
添加入base的包会被打包进Paviing Image中，他们会和OTA升级包一起升级。在base中的包在运行时不可以被去除-它们决定了一个配置的最小的镜像大小。
- cache
在cache中的包会被打井Paving Image中，但是它们不包含在OTA升级包中。它们也可以在运行时由于资源限制导致被去除，例如磁盘空间不足。cache中的包可以在任意可升级的时间进行独立升级。这些包是可选的，但是为了体验在满足条件的情况下打包进Paving image中，方便用户开箱即使用。
- universe
universe 中的包是附加可选包，这些包可以按需下载运行。它们不会运行打包到Paving image中。
配置平台架构和产品的时候，会将预定义好的一系列包放到如上三种包空间内。平台架构配置会将一些关键的启动驱动放到base中，将一些通用的外围设备的驱动放到cache中，将一些与硬件平台交互用的开发调试用的工具包放到universe中。产品的配置会根据所配置的产品的功能选择一些包分别放入base、cache、universe中。例如，如果编译speaker产品，将增加很多音频多媒体的包到base中，如果编译workstation产品，将会增加一些图形界面、多媒体的包到base中。

## 关键的产品介绍
使用命令
```
fx list-products
```
查看支持的产品，此处介绍其中的三个。
- bringup
最小功能集的镜像，足够精简。通常用来netboot。它通常用来工作在一些低端设备上，只包含zircon内核和平台特有的驱动，因为缺少必要的网络组件，所以一般情况下也不能进行在线升级。
- core
允许安装附加功能（universe中的包）的最小的镜像包。是许多高端产品使用镜像的基础功能包，以进行OTA升级。
- workstation
通用开发环境的基础镜像，包含UI、Media和许多高级别的附加功能。适合爱好者把玩探索。

## 关键的bundles介绍
和产品一样，还有更多的捆绑包，如下几个是最重要的
- tools
包含一系列的开发工具。这些工具包含命令行的组件启动工具、配置和测试网络的工具、http请求工具、程序调试工具、调整音量的工具得。在产品core配置上，bundles:tools 会默认配置到universe空间中。
- tests
测试程序集合。可以在设备上运行run-test-componet运行，或者使用fx run-test运行。
- kitchen_sink
将导致其他所有的目标一同编译。它将消耗host机子的20G存储空间，在设备上也将占用2G的存储空间。

# 执行build
```
fx build
```
通常情况下执行build，运行上面的命令就够了。fuchsia的build采用增量编译，仅对修改的部分进行重复编译。
还有一些其他的编译命令，这边也简单介绍下：
```
fx clean //清除所有生成的产品
fx clean-build  //先清除再编译
fx gen //重复fx set执行时的gn gen过程。进行细粒度参数更改（例如直接编辑args.gn）的用户可以运行fx gen来重新配置其build。
```
# 刷写设备
```
fx flash
```
通常用于arm64架构的设备，用来将zedboot刷入设备，为praving做准备。
```
fx mkzedboot
```
通常用于x64架构的设备，用来制作zedboot的USB引导盘，为praving做准备。
## zedboot 是啥
zedboot是zircon的一个特殊配置，它包含简单的网络栈、一个简单的设备广播和发现协议、一个可将fuchsia写入磁盘的套件等。在arm64的设备上进入zedboot，需开机上电时按住特定的按键，然后使设备进入fastboot flashing模式，这时候在主机上执行fx flash；在x64的设备上，首先需要使用fx mkzedboot制作usb引导盘，然后制作好后，将usb设备插入目标设备，目标设备修改BIOS的引导顺序为从USB启动。（期间若要查看可用的usb设备，可使用命令fx list-usb-disks）
## paving是啥
paving与其他操作系统的flashing非常相似。具体的讲，Paving使用定好要的一组fuchsia协议和规范将组件传输到目标系统，该目标系统将被写入目标设备的各个分区中。flashing只是将原始数据写入磁盘，而paving增加对了对分区的操作。
## netbooting是啥
netboot是fuchisa的一种特殊引导方式，fuchsia可以通过fx flash或者fx mkzedboot制作的usb引导设备使设备进入zedboot状态，然后可以使用fx netboot命令将要启动的组件直接交给zedboot进行引导，这种方式并未修改目标设备上的系统，而仅仅是从ram进行了启动。
# 其他开发中用到的命令
## 打印log
```
fx syslog
```
用来从各级程序获取log，包含内核、驱动及应用程序的log，因为该命令依赖与网络栈的使用，所以运行zedboot和bringup的设备无法使用该命令获取到日志。
```
fx log
```
获取zircon内核log
## 主从设备间传递文件
```
# 从编译主机复制文件到目标设备
$ fx cp book.txt /tmp/book.txt
# 从目标设备中复制文件到编译主机
$ fx cp --to-host /tmp/poem.txt poem.txt
```
## 编译多个目标
```
可以使用 --dir为要编译的目标指定存放目录，这样可以在多个编译目标间进行切换
$ fx --dir out/workstation set workstation.x64
$ fx build
为编译的目标设置名字
$ fx set-device <workstation-node-name>

$ fx --dir out/core set core.arm64
$ fx build
$ fx set-device <core-node-name>

# Start a server for the workstation:
$ fx --dir=out/workstation serve
# Set the default build-dir and target device to the arm64 core, and
# connect to a shell on that device:
$ fx use out/core
$ fx shell
```
