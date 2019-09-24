---
title: Linux-安装和使用Cisco AnyConnect Client
id: anyconnect
tags:
  - 工具
categories:
  - 工具
date: 2018-01-07 13:12:39
---

以前使用的vpn到期了，而且最近查的挺严，原先的好多vpn都用不了了，在同事的推荐下使用[__矩阵研究所__
](https://edgevpn.com/)自己搭建的shadowsocks翻墙上网，他提供了windows、ios、android各平台的客户端，唯独未提供linux的客户端。不过他还好支持anyconnect，所以在linux还是可以配置anyconnect client 进行使用的。配置过程记录如下，供以后参考。
<!--more-->
#  安装Cisco AnyConnect Client
1. 安装依赖包
```bash
$ sudo apt-get update
$ sudo apt-get install lib32z1 lib32ncurses5
```
2. 从[UCI OIT Cisco Anyconnect/Linux instruction page](https://uci.service-now.com/kb_view.do?sysparm_article=KB0010201)下载Cisco AnyConnect Client
根据linux 是32位还是64位选择适合自己的版本，查看系统版本号可使用如下命令：
```bash
$ uname -a
Linux xxxx-XPS-8910 4.13.0-21-generic #24-Ubuntu SMP Mon Dec 18 17:29:16 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux
```
3. 将下载好的压缩包解压到你想保存的路径下
```bash
$ tar -xzvf anyconnect-predeploy-linux-64-4.3.05017-k9.tar.gz
anyconnect-4.3.05017/
anyconnect-4.3.05017/vpn/
anyconnect-4.3.05017/vpn/vpn_install.sh
anyconnect-4.3.05017/vpn/vpnagentd
anyconnect-4.3.05017/vpn/vpnagentd_init
anyconnect-4.3.05017/vpn/vpn_uninstall.sh
anyconnect-4.3.05017/vpn/anyconnect_uninstall.sh
anyconnect-4.3.05017/vpn/libacciscossl.so
anyconnect-4.3.05017/vpn/libacciscocrypto.so
anyconnect-4.3.05017/vpn/libaccurl.so.4.3.0
anyconnect-4.3.05017/vpn/vpnui
anyconnect-4.3.05017/vpn/cisco-anyconnect.desktop
anyconnect-4.3.05017/vpn/cisco-anyconnect.menu
anyconnect-4.3.05017/vpn/cisco-anyconnect.directory
anyconnect-4.3.05017/vpn/libvpnagentutilities.so
anyconnect-4.3.05017/vpn/libvpncommon.so
anyconnect-4.3.05017/vpn/libvpncommoncrypt.so
anyconnect-4.3.05017/vpn/libvpnapi.so
anyconnect-4.3.05017/vpn/libvpnipsec.so
anyconnect-4.3.05017/vpn/vpn
anyconnect-4.3.05017/vpn/acinstallhelper
anyconnect-4.3.05017/vpn/pixmaps/
anyconnect-4.3.05017/vpn/pixmaps/company-logo.png
anyconnect-4.3.05017/vpn/pixmaps/cvc-about.png
anyconnect-4.3.05017/vpn/pixmaps/cvc-configure.png
anyconnect-4.3.05017/vpn/pixmaps/cvc-connect.png
anyconnect-4.3.05017/vpn/pixmaps/cvc-disconnect.png
anyconnect-4.3.05017/vpn/pixmaps/cvc-info.png
anyconnect-4.3.05017/vpn/pixmaps/systray_connected.png
anyconnect-4.3.05017/vpn/pixmaps/systray_disconnecting.png
anyconnect-4.3.05017/vpn/pixmaps/systray_notconnected.png
anyconnect-4.3.05017/vpn/pixmaps/systray_quarantined.png
anyconnect-4.3.05017/vpn/pixmaps/systray_reconnecting.png
anyconnect-4.3.05017/vpn/pixmaps/vpnui48.png
anyconnect-4.3.05017/vpn/pixmaps/downloader-arrow.png
anyconnect-4.3.05017/vpn/manifesttool
anyconnect-4.3.05017/vpn/ACManifestVPN.xml
anyconnect-4.3.05017/vpn/vpndownloader
anyconnect-4.3.05017/vpn/vpndownloader-cli
anyconnect-4.3.05017/vpn/update.txt
anyconnect-4.3.05017/vpn/OpenSource.html
anyconnect-4.3.05017/vpn/AnyConnectProfile.xsd
anyconnect-4.3.05017/vpn/AnyConnectLocalPolicy.xsd
anyconnect-4.3.05017/vpn/libacfeedback.so
anyconnect-4.3.05017/vpn/license.txt
anyconnect-4.3.05017/vpn/VeriSignClass3PublicPrimaryCertificationAuthority-G5.pem
anyconnect-4.3.05017/dart/
anyconnect-4.3.05017/dart/dart_install.sh
anyconnect-4.3.05017/dart/AMPEnabler.xml
anyconnect-4.3.05017/dart/AnyConnectConfig.xml
anyconnect-4.3.05017/dart/BaseConfig.xml
anyconnect-4.3.05017/dart/ConfigXMLSchema.xsd
anyconnect-4.3.05017/dart/DARTGUI.glade
anyconnect-4.3.05017/dart/ISEPosture.xml
anyconnect-4.3.05017/dart/NetworkVisibility.xml
anyconnect-4.3.05017/dart/Posture.xml
anyconnect-4.3.05017/dart/RequestXMLSchema.xsd
anyconnect-4.3.05017/dart/Umbrella.xml
anyconnect-4.3.05017/dart/cisco-anyconnect-dart.desktop
anyconnect-4.3.05017/dart/cisco-anyconnect-dart.directory
anyconnect-4.3.05017/dart/cisco-anyconnect-dart.menu
anyconnect-4.3.05017/dart/ciscoLogo.png
anyconnect-4.3.05017/dart/dartCustom.png
anyconnect-4.3.05017/dart/dartTypical.png
anyconnect-4.3.05017/dart/dart_uninstall.sh
anyconnect-4.3.05017/dart/dartcli
anyconnect-4.3.05017/dart/dartcli.symbols
anyconnect-4.3.05017/dart/dartui
anyconnect-4.3.05017/dart/dartui.symbols
anyconnect-4.3.05017/dart/license.txt
anyconnect-4.3.05017/dart/manifesttool
anyconnect-4.3.05017/dart/ACManifestDART.xml
anyconnect-4.3.05017/posture/
anyconnect-4.3.05017/posture/ciscod
anyconnect-4.3.05017/posture/cscan
anyconnect-4.3.05017/posture/ciscod_init
anyconnect-4.3.05017/posture/cstub
anyconnect-4.3.05017/posture/posture_install.sh
anyconnect-4.3.05017/posture/posture_uninstall.sh
anyconnect-4.3.05017/posture/libcsd.so
anyconnect-4.3.05017/posture/libhostscan.so
anyconnect-4.3.05017/posture/libinspector.so
anyconnect-4.3.05017/posture/license.txt
anyconnect-4.3.05017/posture/tables.dat
anyconnect-4.3.05017/posture/ACManifestPOS.xml
anyconnect-4.3.05017/posture/libaccurl.so.4.3.0
anyconnect-4.3.05017/posture/libacciscocrypto.so
anyconnect-4.3.05017/posture/libacciscossl.so
```
进入解压目录下确认文件是否完整：
```bash
$ cd anyconnect-4.3.05017/vpn/
$ ls -lh
total 12M
-rwxr-xr-x 1 XXXX XXXX  14K 12月 10  2016 acinstallhelper
-rw-r--r-- 1 XXXX XXXX  262 12月 10  2016 ACManifestVPN.xml
-rw-r--r-- 1 XXXX XXXX 6.6K 12月 10  2016 AnyConnectLocalPolicy.xsd
-rw-r--r-- 1 XXXX XXXX  83K 12月 10  2016 AnyConnectProfile.xsd
-rwxr-xr-x 1 XXXX XXXX  502 12月 10  2016 anyconnect_uninstall.sh
-rw-r--r-- 1 XXXX XXXX  279 12月 10  2016 cisco-anyconnect.desktop
-rw-r--r-- 1 XXXX XXXX  164 12月 10  2016 cisco-anyconnect.directory
-rw-r--r-- 1 XXXX XXXX  603 12月 10  2016 cisco-anyconnect.menu
-rwxr-xr-x 1 XXXX XXXX 2.6M 12月 10  2016 libacciscocrypto.so
-rwxr-xr-x 1 XXXX XXXX 436K 12月 10  2016 libacciscossl.so
-rwxr-xr-x 1 XXXX XXXX 232K 12月 10  2016 libaccurl.so.4.3.0
-rwxr-xr-x 1 XXXX XXXX 168K 12月 10  2016 libacfeedback.so
-rwxr-xr-x 1 XXXX XXXX 888K 12月 10  2016 libvpnagentutilities.so
-rwxr-xr-x 1 XXXX XXXX 1.6M 12月 10  2016 libvpnapi.so
-rwxr-xr-x 1 XXXX XXXX 530K 12月 10  2016 libvpncommoncrypt.so
-rwxr-xr-x 1 XXXX XXXX 1.7M 12月 10  2016 libvpncommon.so
-rwxr-xr-x 1 XXXX XXXX 1.1M 12月 10  2016 libvpnipsec.so
-rw-r--r-- 1 XXXX XXXX  13K 12月 10  2016 license.txt
-rwxr-xr-x 1 XXXX XXXX 480K 12月 10  2016 manifesttool
-rw-r--r-- 1 XXXX XXXX  68K 12月 10  2016 OpenSource.html
drwxr-xr-x 2 XXXX XXXX 4.0K 12月 10  2016 pixmaps
-rw-r--r-- 1 XXXX XXXX   10 12月 10  2016 update.txt
-rw-r--r-- 1 XXXX XXXX 1.8K 12月 10  2016 VeriSignClass3PublicPrimaryCertificationAuthority-G5.pem
-rwxr-xr-x 1 XXXX XXXX  65K 12月 10  2016 vpn
-rwxr-xr-x 1 XXXX XXXX 724K 12月 10  2016 vpnagentd
-rw-r--r-- 1 XXXX XXXX 2.1K 12月 10  2016 vpnagentd_init
-rwxr-xr-x 1 XXXX XXXX 424K 12月 10  2016 vpndownloader
-rwxr-xr-x 1 XXXX XXXX 396K 12月 10  2016 vpndownloader-cli
-rwxr-xr-x 1 XXXX XXXX  24K 12月 10  2016 vpn_install.sh
-rwxr-xr-x 1 XXXX XXXX 176K 12月 10  2016 vpnui
-rwxr-xr-x 1 XXXX XXXX 8.4K 12月 10  2016 vpn_uninstall.sh
```
4. 安装
```bash
$ sudo ./vpn_install.sh
```
遇到提示直接y就可以了
5. 重新载入 systemd，扫描新的或有变动的单元
```bash
sudo systemctl daemon-reload
```
6. 这是vpnagented进程应该已经启动了，可使用如下方式进行检查：
```bash
$ ps auxw | grep vpnagentd | grep -v grep
root      7677  0.1  0.0 259808 12720 ?        Sl   11:24   0:00 /opt/cisco/anyconnect/bin/vpnagentd
```
7. 同时安装过程中设置了开机启动，时候安装开机启动检查方式如下：
```bash
$ find /etc/rc?.d -type l -name "*vpnagentd*"
/etc/rc2.d/K25vpnagentd
/etc/rc2.d/S85vpnagentd
/etc/rc3.d/K25vpnagentd
/etc/rc3.d/S85vpnagentd
/etc/rc4.d/K25vpnagentd
/etc/rc4.d/S85vpnagentd
/etc/rc5.d/K25vpnagentd
/etc/rc5.d/S85vpnagentd
```
## 使用Cisco AnyConnect UI Client 翻墙
1. 为方便以后使用添加命令别名
```bash
$ alias vpn='/opt/cisco/anyconnect/bin/vpn'
$ alias vpnui='/opt/cisco/anyconnect/bin/vpnui'
```
或者
```bash
$ cat >> ~/.bash_aliases
alias vpn='/opt/cisco/anyconnect/bin/vpn'
alias vpnui='/opt/cisco/anyconnect/bin/vpnui'
^D
$ _
```
2. 使用vpnui 配置anyconnect
```bash
$ vpnui
```
在弹出的界面中输入要连接的服务器，点击右侧的设置图标，弹出如下界面
{% asset_img anyconnct2.png %}
{% asset_img anyconnet1.png %}
点击 按钮【Connect Anyway】 之后按照提示依次输入从矩阵研究所获得的AnyConnect 账号和密码即可连接成功。

## 使用Csico AnyConnect Command Client 翻墙

1. To start the client from a command-line prompt in a terminal window, using the alias you made above:
```bash
$ vpn
```
2. At the VPN> prompt, type connect vpn.uci.edu and press Enter. (If you get an error message about an untrusted server or certificate, you can fix that following the instructions from Robert in the section NOTE 1 - Connect-error, below.) Otherwise, you should now see:
```bash
VPN> connect vpn.uci.edu
   >> Please enter your UCInetID and password.
   0) Default-WebVPN
   1) Merage
   2) MerageFull
   3) UCI
   4) UCIFull
```
If you do not see this, but get a connect error instead, please see NOTE 1 - Connect Error below.
3. Ignore the message about entering your UCInetID and password, for now.
4. Choose one of the choices by number and press return -- usually UCI or UCIFull. (See the differences in the Tunnels below.) For instance, for UCI, press 3 and hit Enter.
5. Enter your UCInetID and password in the Username and Password boxes and press return.
6. At the accept? [y/n]: prompt, type y and press Enter. You may get several notices the first time about the downloader performing update checks. At the end you should see a >> state: Connected message and a new VPN> prompt. You are now connected.
7. Either leave the VPN> prompt open or if you want your terminal back just type quit at the VPN> prompt (the connection will remain active).
