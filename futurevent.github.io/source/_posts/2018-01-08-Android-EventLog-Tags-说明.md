---
title: Android-EventLog-Tags 说明
tags:
  - android
categories:
  - android
date: 2018-01-08 23:35:54
---

# 简介
Event Log, 官方的解释为
>System diagnostic event record. System diagnostic events are used to record certain system-level events (such as garbage collection, activity manager state, system watchdogs, and other low level activity), which may be automatically collected and analyzed during system development.
>This is not the main "logcat" debugging log (Log)! These diagnostic events are for system integrators, not application authors.
>Events use integer tag codes corresponding to /system/etc/event-log-tags. They carry a payload of one or more int, long, or String values. The event-log-tags file defines the payload contents for each type code.

大概意思是说，是系统诊断事件的记录。这些事件都是系统级别事件，例如垃圾回收，ActivityManager的状态，系统看门够以及一些其他的事件。这些事件在系统开发的过程中会被自动的采集和分析。这些事件不是main debug调试log，它是给系统开发集成商看的，不是给应用开发者看的。
<!-- more -->
但是，话虽这么说，event log 同样对于应用开发者有很大的帮助，例如可以看activity manager相关的tag去了解自己应用activity，service，broadcast等的相关情况，也可以通过分析dvm_lock_sample tag来判断程序中的锁持有或等待情况。
# EventLog 打印
```bash
$ adb logcat -v threadtime -b events
01-01 08:00:00.340   289   289 I auditd  : type=2000 audit(0.0:1): initialized
01-01 08:46:59.550   289   289 I auditd  : type=1403 audit(0.0:2): policy loaded auid=4294967295 ses=4294967295
01-01 08:46:59.560   289   289 I auditd  : type=1404 audit(0.0:3): enforcing=1 old_enforcing=0 auid=4294967295 ses=4294967295
10-05 00:00:00.920   362   362 I boot_progress_start: 7003
02-08 23:06:39.045   362   362 I boot_progress_preload_start: 9173
02-08 23:06:42.121   362   362 I boot_progress_preload_end: 12248
02-08 23:06:42.342   925   925 I boot_progress_system_run: 12469
02-08 23:06:42.815   925   925 I boot_progress_pms_start: 12943
02-08 23:06:43.043   925   925 I boot_progress_pms_system_scan_start: 13171
02-08 23:06:45.124   925   925 I boot_progress_pms_data_scan_start: 15251
02-08 23:06:45.929   350  1003 I dc_mm   : time=1486566405000;i=1;e=play;v=video/avc,720,1280,0
02-08 23:06:56.918   350  1004 I dc_mm   : time=1486566416000;i=1;e=play;v=video/avc,720,1280,0
02-08 23:07:01.606   925   925 I boot_progress_pms_scan_end: 31734
02-08 23:07:01.665   925   925 I boot_progress_pms_ready: 31792
02-08 23:07:01.842   925   941 I battery_status: [2,2,1,2,Li-ion]
02-08 23:07:01.842   925   941 I battery_level: [30,3903,371]
01-07 20:01:21.759   925  1518 I force_gc: Binder
01-07 20:01:22.215   925  1422 I am_proc_start: [0,5225,10089,com.songshu.gallery:sspush,service,com.songshu.gallery/.SSPushService]
```
如上是一段开机阶段的event log，分析可知:
event log 文件格式为：__timestamp PID TID log-level log-tag tag-values__
可将其分为两部分：
第一部分，__timestamp PID TID__ 这部分就是时间，进程ID 和线程ID相对简单，没什么好说的。
第二部分，__log-tag tag-values__ 这部分是event log的主要部分，需要重点说下。
# Event Log Tag 的说明：
Android 源码目录/system/core/logcat/event.logtags 文件中有对event log tags的说明，源码注释如下：
```bash
# The entries in this file map a sparse set of log tag numbers to tag names.
# This is installed on the device, in /system/etc, and parsed by logcat.
#
```
在设备的/system/etc 目录下 可以找到所有event log tags的定义文件event-log-tags，每一个tag都有对应的tag number 和 tag name，例如：

>20003 dvm_lock_sample (process|3),(main|1|5),(thread|3),(time|1|3),(file|3),(line|1|5),(ownerfile|3),(ownerline|1|5),(sample_percent|1|6)

```bash
# Tag numbers are decimal integers, from 0 to 2^31.  (Let's leave the
# negative values alone for now.)
#
```
tag number 是 0 到 2^31 的十进制整数
```bash
# Tag names are one or more ASCII letters and numbers or underscores, i.e.
# "[A-Z][a-z][0-9]_".  Do not include spaces or punctuation (the former
# impacts log readability, the latter makes regex searches more annoying).
#
# Tag numbers and names are separated by whitespace.  Blank lines and lines
# starting with '#' are ignored.
```
```bash
# Optionally, after the tag names can be put a description for the value(s)
# of the tag. Description are in the format
#    (<name>|data type[|data unit])
# Multiple values are separated by commas.
#
```
tag values 的每一个value 格式为：__(<name>|data type[|data unit])__
```bash
# The data type is a number from the following values:
# 1: int
# 2: long
# 3: string
# 4: list
# 5: float
#
```
data 的类型如上
```bash
# The data unit is a number taken from the following list:
# 1: Number of objects
# 2: Number of bytes
# 3: Number of milliseconds
# 4: Number of allocations
# 5: Id
# 6: Percent
# Default value for data of type int/long is 2 (bytes).
```
data 的单位如上列表。

分析event log，举例如下，例如上文中log有这么一行：
```bash
02-08 23:07:01.842   925   941 I battery_level: [30,3903,371]
```
分析如下：
时间： _02-08 23:07:01.842_
进程ID： _925_
线程ID： _941_
log level: _I_
log tag: _battery_level_
log values: _[30,3903,371]_
查找设备上的event-log-tags文件，找到battery_level的说明如下:
>2722 battery_level (level|1|6),(voltage|1|1),(temperature|1|1)

分析values含义
__(level|1|6)__: 30 电量是30%
__(voltage|1|1)__: 3903 电压是3903
__(temperature|1|1)__: 371 温度是371

# 常用Event Log Tags的说明
## ActivityManager
|Num|	TagName	|格式	|功能
|-|-|-|-|
|30001|	am_finish_activity|	User,Token,TaskID,ComponentName,Reason||
|30002|	am_task_to_front	|User,Task||
|30003|	am_new_intent|	User,Token,TaskID,ComponentName,Action,MIMEType,URI,Flags||
|30004|	am_create_task|	User ,Task ID||
|30005|	am_create_activity|	User ,Token ,TaskID ,ComponentName,Action,MIMEType,URI,Flags||
|30006|	am_restart_activity|	User ,Token ,TaskID,ComponentName||
|30007|	am_resume_activity|	User ,Token ,TaskID,ComponentName||
|30008|	am_anr|	User ,pid ,Package Name,Flags ,reason|	ANR|
|30009|	am_activity_launch_time|	User ,Token ,ComponentName,time||
|30010|	am_proc_bound|	User ,PID ,ProcessName||
|30011|	am_proc_died|	User ,PID ,ProcessName||
|30012|	am_failed_to_pause|	User ,Token ,Wanting to pause,Currently pausing	 ||
|30013|	am_pause_activit|y	User ,Token ,ComponentName	 ||
|30014|	am_proc_start|	User ,PID ,UID ,ProcessName,Type,Component	 ||
|30015|	am_proc_bad|	User ,UID ,ProcessName	 ||
|30016|	am_proc_good|	User ,UID ,ProcessName	 ||
|30017|	am_low_memory|	NumProcesses	Lru||
|30018|	am_destroy_activity|	User ,Token ,TaskID,ComponentName,Reason	 ||
|30019|	am_relaunch_resume_activity|	User ,Token ,TaskID,ComponentName	 ||
|30020|	am_relaunch_activity|	User ,Token ,TaskID,ComponentName	 ||
|30021|	am_on_paused_called|	User ,ComponentName	 ||
|30022|	am_on_resume_called|	User ,ComponentName	 ||
|30023|	am_kill|	User ,PID ,ProcessName,OomAdj ,Reason|	杀进程|
|30024|	am_broadcast_discard_filter|	User ,Broadcast ,Action,ReceiverNumber,BroadcastFilter	 ||
|30025|	am_broadcast_discard_app|	User ,Broadcast ,Action,ReceiverNumber,App	 ||
|30030|	am_create_service|	User ,ServiceRecord ,Name,UID ,PID	 ||
|30031|	am_destroy_service|	User ,ServiceRecord ,PID	 ||
|30032|	am_process_crashed_too_much|	User ,Name,PID	 ||
|30033|	am_drop_process|	PID	 ||
|30034|	am_service_crashed_too_much|	User ,Crash Count,ComponentName,PID	 ||
|30035|	am_schedule_service_restart|	User ,ComponentName,Time	 ||
|30036|	am_provider_lost_process|	User ,Package Name,UID ,Name	 ||
|30037|	am_process_start_timeout|	User ,PID ,UID ,ProcessName	timeout||
|30039|	am_crash|	User ,PID ,ProcessName,Flags ,Exception,Message,File,Line|	Crash|
|30040|	am_wtf|	User ,PID ,ProcessName,Flags ,Tag,Message|	Wtf|
|30041|	am_switch_user|	id	 ||
|30042|	am_activity_fully_drawn_time|	User ,Token ,ComponentName,time	 ||
|30043|	am_focused_activity|	User ,ComponentName	 ||
|30044|	am_home_stack_moved|	User ,To Front ,Top Stack Id ,Focused Stack Id ,Reason	 ||
|30045|	am_pre_boot|	User ,Package	 ||
|30046|	am_meminfo|	Cached,Free,Zram,Kernel,Native|	内存|
|30047|	am_pss|	Pid, UID, ProcessName, Pss, Uss|	进程|
### 下面列举tag可能使用的部分场景：

am_low_memory：位于AMS.killAllBackgroundProcesses或者AMS.appDiedLocked，记录当前Lru进程队列长度。
am_pss：位于AMS.recordPssSampleLocked(
am_meminfo：位于AMS.dumpApplicationMemoryUsage
am_proc_start:位于AMS.startProcessLocked，启动进程
am_proc_bound:位于AMS.attachApplicationLocked
am_kill: 位于ProcessRecord.kill，杀掉进程
am_anr: 位于AMS.appNotResponding
am_crash:位于AMS.handleApplicationCrashInner
am_wtf:位于AMS.handleApplicationWtf
am_activity_launch_time：位于ActivityRecord.reportLaunchTimeLocked()，后面两个参数分别是thisTime和 totalTime.
am_activity_fully_drawn_time:位于ActivityRecord.reportFullyDrawnLocked, 后面两个参数分别是thisTime和 totalTime
am_broadcast_discard_filter:位于BroadcastQueue.logBroadcastReceiverDiscardLocked
am_broadcast_discard_app:位于BroadcastQueue.logBroadcastReceiverDiscardLocked
### Activity生命周期相关的方法:

am_on_resume_called: 位于AT.performResumeActivity
am_on_paused_called: 位于AT.performPauseActivity, performDestroyActivity
am_resume_activity: 位于AS.resumeTopActivityInnerLocked
am_pause_activity: 位于AS.startPausingLocked
am_finish_activity: 位于AS.finishActivityLocked, removeHistoryRecordsForAppLocked
am_destroy_activity: 位于AS.destroyActivityLocked
am_focused_activity: 位于AMS.setFocusedActivityLocked, clearFocusedActivity
am_restart_activity: 位于ASS.realStartActivityLocked
am_create_activity: 位于ASS.startActivityUncheckedLocked
am_new_intent: 位于ASS.startActivityUncheckedLocked
am_task_to_front: 位于AS.moveTaskToFrontLocked
## Power
|Num|	TagName|	格式|	功能
|-|-|-|-
|2722|	battery_level|	level, voltage, temperature||
|2723|	battery_status|	status,health,present,plugged,technology	 ||
|2730|	battery_discharge|	duration, minLevel,maxLevel	 ||
|2724|	power_sleep_requested|	wakeLocksCleared|	唤醒锁数量|
|2725|	power_screen_broadcast_send|	wakelockCount	 ||
|2726|	power_screen_broadcast_done|	on, broadcastDuration, wakelockCount	 ||
|2727|	power_screen_broadcast_stop|	which,wakelockCount|	系统还没进入ready状态|
|2728|	power_screen_state|	offOrOn, becauseOfUser, totalTouchDownTime, touchCycles	 ||
|2729|	power_partial_wake_state|	releasedorAcquired, tag	 ||
### 部分含义：

battery_level: [19,3660,352] //剩余电量19%, 电池电压3.66v, 电池温度35.2℃
power_screen_state: [0,3,0,0] // 灭屏状态(0), 屏幕超时(3). 当然还有其他设备管理策略(1),其他理由都为用户行为(2)
power_screen_state: [1,0,0,0] // 亮屏状态(1)
### 下面列举tag可能使用的部分场景：

power_sleep_requested: 位于PMS.goToSleepNoUpdateLocked
power_screen_state:位于Notifer.handleEarlyInteractiveChange, handleLateInteractiveChange

# 附录
最后附上从设备的/system/etc 下获取到[event-log-tags](http://ovfro7ddi.bkt.clouddn.com/event-log-tags)文件.
