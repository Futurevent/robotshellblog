---
title: android之SystemServer的启动
id: BootSystemServer
tags: android
categories: android
---
Android系统中恐怕是没有任何一个进程有SystemServer重要了。Android的大量核心Service都运行在SystemServer上，这些核心的Service笼统的讲几乎能代表整个Android的Framework层。Android区别于Linux的关键又在于Framework层，所以更进一步讲SystemServer几乎又可代表整个Android系统了。
本文主要分析SystemServer的启动过程，分析的方法类似于从一个地方到另外一个地方的旅游，不只是单纯的到达目的地，也会欣赏沿路的风景。
# SystemServer的启动路径图
```flow
st=>start: 设备上电

boot=>operation: BootLoader启动，准备软硬件环境

kernel_init=>operation: kernel初始化：
1. zImage解压缩、
2. kernel的汇编启动阶段、
3. Kernel的C启动阶段(kernel/init/main.c start_kernel())

kernel_process=>operation: 创建kernel三进程：
1. idle(swapper) pid=0
2. init pid=1 由idle 通过 kernel_thread 创建
3. kthreadd pid=2 由idle通过kernel_thread创建负责内核线程的调度管理。

init_start=>start: init过程开始
init_main=>subroutine: /system/core/init/main.cpp 的mian方法
init_first_stage=>subroutine: /system/core/init/first_init_stage.cpp 的 FistStageMain 方法:
1. 设置环境变量创建
2. 创建文件系统：/dev,/proc,/sys,/mnt等。
3. execv 执行如下:/system/bin/init selinux_setup 重新进入main
init_set_selinux=>subroutine: /system/core/init/selinux.cpp中的SetupLinux方法。
execv 执行如下：/system/bin/init second_stage 重新进入main
init_second_stage=>subroutine: /system/core/init/init.cpp 的 SecondStage 方法。
1. 设置init进程的oom_socre_adj 值为-1000
2. 注册信号SIGCHLD子进程死亡的信号处理函数: InstallSignalFdHandler，
此处与下面的属性服务的socket流使用多路复用epoll。
3. 创建属性服务property_service: StartPropertyService
创建Socket并等待连接。
init_initrc=>subroutine: init.rc 文件处理
init_end=>end: init过程结束

e=>end: 系统启动完毕

st->boot->kernel_init->kernel_process->init_start->init_main->init_first_stage->init_set_selinux->init_second_stage->init_initrc->init_end->e
```
