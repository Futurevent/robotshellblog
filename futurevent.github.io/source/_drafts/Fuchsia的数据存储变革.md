---
title: Fuchsia的数据存储变革
tags: OS
id: ledger
categories: OS
---
根据之前的介绍，Fuchsia引入了一个新的概念Story，Story由一系列的app组成用来完成独立的任务。在Fuchsia上，你可以快速的在不同的设备上切换以使用这些创建好的Story，而可以这样做的原因是，Fuchsia将这些Story的信息保存在了你的个人ledger中。
<!--more-->
# 那么，Ledger是什么？
Ledger翻译为中文是账本、分类帐的意思，一个组织或公司用来记录花销收入的账簿。在Fuchsia中，Ledger的含义是分布式存储系统，它位于Fuchsia四层结构的第三层Peridot中。Ledger可以跨设备保存你在应用/模块中的位置，并同步到你的Google账户。
Ledger为每一个用户运行的应用程序提供相互分离的数据存储，然后由Fuchsia的Framework通过组件上下文（component context）向（不同设备的）客户端应用程序提供这些数据。这些数据对模块和用户来说都是私有的，不同的用户互相看不到对方的数据，不同的模块也看不到互相的数据。存储的每一项数据都会在不同的设备间透明的进行同步。而任何数据的使用则都是优先使用离线备份，然后再向云端备份。不同设备是有可能对数据进行并发修改的，而并发修改产生冲突后的冲突解决策略，对每个应用来说则是可配置的。
数据按照key-value的形式进行存储，多个key-value组成的集合，叫做Page。Fuchisa提供了操作Page的API，可对page进行存储、原子读、快照操作，或者使用Observer来监测数据的变化。
# 什么情况下使用Ledger
Ledger为用户存储应用的使用数据，并在用户的不同设备间同步这些数据，当用户重置了设备，用户可以使用这些数据恢复被重置的设备。因为使用Ledger会消耗计算和存储资源，因此如果数据并不需要同步或者持久化，则不要使用Ledger。
# Ledger长啥样
{% asset_img ledger_arch.png Ledger示意图 %}
如图，Ledger由如下部分组成：
## Storge： 用来存取本地数据
数据是使用key-value的形成组合而成的page，对page的操作是原子性的。每一次对page的提交可以进行多个key-value的增删改查。所有page的每一个commit会有0个、1个或2个(merged)parent commit, 所有这些commit会形成一个有向无环图（DAG）。

Storge组件包含
- 每一个page的提交记录
- 保存每个页面状态的不可变存储对象
- 同步元数据，包括每个对象的同步状态

## 和Storge进行交互的组件：
### Local client：通过FIDL向本地运行的应用程序提供数据
运行中的应用程序模块通过调用Local client提供的FIDL API将数据存储到Ledger中。当数据产生冲突时，Storge会通知Local client 冲突产生，Local Client使用App所选择的冲突解决策略解决冲突。
### Cloud sync：在设备间同步Ledger的状态
当有新的commit产生时，Storge会通知Cloud sync，Cloud sync会将Storge中新产生的commit所关联的存储对象推送到云端。而且，Cloud sync也会监视其他设备同步到云端的commit，并将它们下载并插入到Storge中。

Ledger是一个分布式的存储系统，扮演着在不同设备间同步数据的角色。本文对Ledger的简要介绍，希望可以起到帮助理解的作用。
