---
title: 简述Fuchsia内核Zircon之LK
tags: OS
id: zircon_LK
categories: OS
date: 2020-01-08 15:59:02
---

Zircon是Fuchsia的内核部分，[前面的几篇文章](https://www.robotshell.com/2020/01/02/os/zircon2/)简述了Zircon的一些常见的概念。
Ziron是作为[LK](https://github.com/littlekernel/lk)的一个分支产生的，本文主要简述LK与Zircon相关的一些事情。
<!--more-->
# Zircon和LK
Zircon是LK的一个分支，因此内部的很多结构是相同的，同时Zircon对LK进行了扩展。例如Zircon有进程的概念，而LK则没有；不过Zircon的概念是构建在LK的线程、内存结构之上的。
LK（little kernel）是一个适用于嵌入式设备，bootloader等场景的微型操作系统（微内核），提供了线程调度，互斥量和定时器等支持，在嵌入式ARM平台，LK的核心大约15~20KB左右。部分芯片厂商（如高通，MTK）的Android操作系统使用LK作为其bootloader和TEE（Trusted Execution Environment）安全区运行环境。另外，LK也可以作为FreeRTOS、ThreadX等实时操作系统的好的替代。
Zircon的设计目标则与LK有一些不同。Zircon的目标设备是现代化手机和现代个人电脑，即具有快速处理器，任意的外设，不受限数量的RAM，开放式的终端计算设备。
Zircon与LK的一些明显的不同如下：
- Zircon运行于64位系统，LK运行于32位系统。
- Zircon有用户模式，LK没有
- Zircon提供对象句柄的概念，LK没有该概念
- Zircon提供一套能力安全模型，LK认为所有的代码都是被信任的。

# LK体验
根据LK github的描述，大家也可以编译运行下LK，步骤如下：
1、 安装qmeu
```
sudo apt install qemu
sudo apt install qemu-system-arm
```
2、为嵌入式arm安装gcc
```
sudo apt install gcc-arm-none-eabi
```
3、编译运行LK，执行LK源码根目录下的/scripts/do-qemuarm
```
» ./scripts/do-qemuarm
```
编译完成后，会运行qemu，输出如下
```
qemu-system-arm -cpu cortex-a15 -m 512 -smp 1 -machine virt -kernel build-qemu-virt-arm32-test/lk.elf -nographic

welcome to lk/MP

boot args 0x0 0x0 0x0 0x0
INIT: cpu 0, calling hook 0x800276dd (version) at level 0x3ffff, flags 0x1
version:
	arch:     arm
	platform: qemu-virt-arm
	target:   qemu-virt-arm
	project:  qemu-virt-arm32-test
	buildid:  J1873_LOCAL
INIT: cpu 0, calling hook 0x80028af1 (vm_preheap) at level 0x3ffff, flags 0x1
initializing heap
calling constructors
INIT: cpu 0, calling hook 0x80028b39 (vm) at level 0x50000, flags 0x1
initializing mp
initializing threads
initializing timers
initializing ports
creating bootstrap completion thread
top of bootstrap2()
INIT: cpu 0, calling hook 0x800254c1 (pktbuf) at level 0x70000, flags 0x1
pktbuf: creating 256 pktbuf entries of size 1536 (total 393216)
INIT: cpu 0, calling hook 0x800277c9 (virtio) at level 0x70000, flags 0x1
releasing 0 secondary cpus
initializing platform
initializing target
calling apps_init()
starting app inetsrv
starting internet servers
starting app shell
entering main console loop
]
```
最后一行的 ] 为LK的命令提示符，至此可以输入命令help查看LK所携带的命令了
```
] help
command list:
	page_alloc      : page allocator debug commands
	heap            : heap debug commands
	gfx             : gfx commands
	help            : this list
	test            : test the command processor
	history         : command history
	repeat          : repeats command multiple times
	bio             : block io debug commands
	vmm             : virtual memory manager
	vm              : vm commands
	pmm             : physical memory manager
	reboot          : soft reset
	poweroff        : powerdown
	version         : print version
	tcp             : tcp commands
	arp             : arp commands
	mi              : minip commands
	spifs           : commands related to the spifs implementation.
	ls              : dir listing
	cd              : change dir
	pwd             : print working dir
	mkdir           : make dir
	mkfile          : make file
	rm              : remove file
	stat            : stat file
	cat             : cat file
	fs              : fs debug commands
	dw              : display memory in words
	dh              : display memory in halfwords
	db              : display memory in bytes
	mw              : modify word of memory
	mh              : modify halfword of memory
	mb              : modify byte of memory
	fw              : fill range of memory by word
	fh              : fill range of memory by halfword
	fb              : fill range of memory by byte
	mc              : copy a range of memory
	crash           : intentionally crash
	stackstomp      : intentionally overrun the stack
	mtest           : simple memory test
	chain           : chain load another binary
	sleep           : sleep number of seconds
	sleepm          : sleep number of milliseconds
	crc16           : crc16
	crc32           : crc32
	adler32         : adler32
	bench_cksum     : benchmark the checksum routines
	aes_test        : test AES encryption
	aes_bench       : bench AES encryption
	threads         : list kernel threads
	threadstats     : thread level statistics
	threadload      : toggle thread load display
	printf_tests    : test printf
	printf_tests_float: test printf with floating point
	thread_tests    : test the scheduler
	port_tests      : test the ports
	clock_tests     : test clocks
	bench           : miscellaneous benchmarks
	fibo            : threaded fibonacci
	spinner         : create a spinning thread
	cbuf_tests      : test lib/cbuf
	mem_test        : test memory
	float_tests     : floating point test
	cache_tests     : test/bench the cpu cache
	string          : memcpy tests
	dcc             : dcc stuff
```

这样一个微内核LK就在qemu模拟器上运行起来，：）。
