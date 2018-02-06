---
title: Android包管理之App安装前的校验
tags: android
categories: android
date: 2018-02-06 21:32:49
---

# 初识Package Verification
之前在做机器人操作系统的时候有过这样的需求，希望在安装应用的时候判断该应用是否符合机器人系统的操作规范，说白了就是需要扫描一下这个apk，是否符合某些规则。当然，这个需求可以在andoird 安装应用的过程实现。但是查看源码发现了Package Verification，这是一个没有多少文档介绍也没有相应demo的特性。
最近在做车机系统的时候，大家讨论热修复，聊到在海外渠道以及一些海外应用商店平台上，禁止带有热修复功能的应用上架，甚至带有热修复功能的app安装都不会成功。聊到此处想起了Package Verification，料想使用此特性实现的。
早在android J 中就在PackageManagerService源码中加入了此特性。大体思路是，在安装应用前会发送一个需要对此包进行验证的广播，该广播可叫做Verify Request，如果系统中有实现了该广播的Receiver，则该应用被叫做Verifier，则Verifier取得广播中携带的附属信息，包括包的路径等，则通过或是扫描该包或是对比其他信用，总之对要安装的这个应用做出校验，然后调用PowerManager的接口告诉PowerManagerService 本次校验是否通过，通过则继续执行安装过程，否则提示用户安装被拒绝。也可以讲，android通过这样的方式，将android包安装校验这一任务外包给了第三方应用（通常为应用商店等）进行校验。
比如校验不通过会弹出如下的界面(就算没见过这个，也见过类似的吧)：
![package verifier failure](http://ovfro7ddi.bkt.clouddn.com/android-pkgverify.png)

# 使用Package Verification
## Verify 流程如下：
```flow
st=>start: Start
e=>end: end
install=>operation: PackageManagerService 调用到handleStartCopy方法
verifierOk=>condition: 获取系统中存在的Verifier,判断系统中是否存在Verifier。
completeInstall=>operation: PackageManagerService完成安装
requestVerify=>operation: 发出广播ACTION_PACKAGE_NEEDS_VERIFICATION，设置最大验证超时时长
timeout=>condition: 是否超时
verify=>subroutine: Verifier 接收到ACTION_PACKAGE_NEEDS_VERIFICATION广播并检查要安装的应用
verifyResult=>condition: app是否允许安装
verifyAllow=>operation: 调用PackageManager.verifyPendingInstall 参数为本次验证的任务ID，结果为VERIFICATION_ALLOW
verifyReject=>operation: 调用PackageManager.verifyPendingInstall 参数为本次验证的任务ID，结果为VERIFICATION_REJECT
handleVerifyResult=>condition: 判断返回的verify结果
stopInstall=>operation: 终止安装，提醒安装被拒绝

st->install->verifierOk
verifierOk(no)->completeInstall
verifierOk(yes)->requestVerify->verify->verifyResult
verifyResult(no)->verifyReject->handleVerifyResult
verifyResult(yes)->verifyAllow->handleVerifyResult
handleVerifyResult(yes)->completeInstall
handleVerifyResult(no)->stopInstall
stopInstall->e
completeInstall->e
```
其中verifier 检查要安装的应用这个子过程即可实现为一个独立应用，在其中做具体的校验逻辑。
## Verify 过程中使用到的PackageManager API
### [请求对即将安装的包进行验证](#请求)
PackageManagerService 会在应用安装前发送ACTION_PACKAGE_NEEDS_VERIFICATION 广播请求对要安装的包进行验证，它会携带PowerManager.EXTRA_VERIFICATION_ID 待Verifier验证结束后会使用该ID通知PackageManagerService验证结果。
另外几个在API中被hide的附属值为：
- EXTRA_VERIFICATION_URI
- EXTRA_VERIFICATION_INSTALLER_PACKAGE
- EXTRA_VERIFICATION_INSTALL_FLAGS
- EXTRA_VERIFICATION_INSTALLER_UID
- EXTRA_VERIFICATION_PACKAGE_NAME
- EXTRA_VERIFICATION_VERSION_CODE
另外，应用程序也可在自己的manifest中使用标签<package-verifier>来指定Verifier 例如：
```XML
<package-verifier
    android:name="org.mycompany.verifier"
    android:publicKey="Zm9vYmFy..." />
```
这类Verifier被叫做Sufficient Verifiers，配置中的publickey 为 应用安装完成后在/data/system/package.xml 中保存的对应应用的编码。

### Verifier 的实现
Verifier 需要具有权限PACKAGE_VERIFICATION_AGENT，然后实现接受ACTION_PACKAGE_NEEDS_VERIFICATION广播的BroadcastReceiver。待校验结束后调用PackageManager.verifyPendingInstall 返回校验结果，结果常量为：
- PowerManager.VERIFICATION_ALLOW
- PowerManager.VERIFICATION_REJECT
结果返回后会被PackageManagerService处理[响应](#响应)

## Package Verification 机制实现分析。
Package Verification 机制的实现在PackageManagerService中，与应用的安装过程紧紧的结合在一起，但此处不在介绍安装过程。当安装进行到函数startCopy这一步时，在handleStartCopy方法中有如下代码
<span id="请求"/>
```java
if (ret == PackageManager.INSTALL_SUCCEEDED) {
    // TODO: http://b/22976637
    // Apps installed for "all" users use the device owner to verify the app
    UserHandle verifierUser = getUser();
    if (verifierUser == UserHandle.ALL) {
        verifierUser = UserHandle.SYSTEM;
    }

    /*
     * Determine if we have any installed package verifiers. If we
     * do, then we'll defer to them to verify the packages.
     */
    // mRequiredVerifierPackage 和 mOptionalVerifierPackage在
    // PackageManagerService初始化时初始化
    final int requiredUid = mRequiredVerifierPackage == null ? -1
            : getPackageUid(mRequiredVerifierPackage, MATCH_DEBUG_TRIAGED_MISSING,
                    verifierUser.getIdentifier());

    final int optionalUid = mOptionalVerifierPackage == null ? -1
            : getPackageUid(mOptionalVerifierPackage, MATCH_DEBUG_TRIAGED_MISSING,
                    verifierUser.getIdentifier());

    final int installerUid =
            verificationInfo == null ? -1 : verificationInfo.installerUid;
    if (!origin.existing && (requiredUid != -1 || optionalUid != -1)
            && isVerificationEnabled(
                    verifierUser.getIdentifier(), installFlags, installerUid)) {
        // 开始构造请求Verify的广播的Intent
        final Intent verification = new Intent(
                Intent.ACTION_PACKAGE_NEEDS_VERIFICATION);
        verification.addFlags(Intent.FLAG_RECEIVER_FOREGROUND);
        verification.setDataAndType(Uri.fromFile(new File(origin.resolvedPath)),
                PACKAGE_MIME_TYPE);
        verification.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

        // Query all live verifiers based on current user state
        // 把当前所有能做校验的Receiver都找出来。
        final List<ResolveInfo> receivers = queryIntentReceiversInternal(verification,
                PACKAGE_MIME_TYPE, 0, verifierUser.getIdentifier());

        if (DEBUG_VERIFY) {
            Slog.d(TAG, "Found " + receivers.size() + " verifiers for intent "
                    + verification.toString() + " with " + pkgLite.verifiers.length
                    + " optional verifiers");
        }

        // 生成此次的verificationId，用来唯一标识此次校验
        final int verificationId = mPendingVerificationToken++;
        // 添加需要携带给Verifier 的数据
        verification.putExtra(PackageManager.EXTRA_VERIFICATION_ID, verificationId);

        verification.putExtra(PackageManager.EXTRA_VERIFICATION_INSTALLER_PACKAGE,
                installerPackageName);

        verification.putExtra(PackageManager.EXTRA_VERIFICATION_INSTALL_FLAGS,
                installFlags);

        verification.putExtra(PackageManager.EXTRA_VERIFICATION_PACKAGE_NAME,
                pkgLite.packageName);

        verification.putExtra(PackageManager.EXTRA_VERIFICATION_VERSION_CODE,
                pkgLite.versionCode);

        if (verificationInfo != null) {
            if (verificationInfo.originatingUri != null) {
                verification.putExtra(Intent.EXTRA_ORIGINATING_URI,
                        verificationInfo.originatingUri);
            }
            if (verificationInfo.referrer != null) {
                verification.putExtra(Intent.EXTRA_REFERRER,
                        verificationInfo.referrer);
            }
            if (verificationInfo.originatingUid >= 0) {
                verification.putExtra(Intent.EXTRA_ORIGINATING_UID,
                        verificationInfo.originatingUid);
            }
            if (verificationInfo.installerUid >= 0) {
                verification.putExtra(PackageManager.EXTRA_VERIFICATION_INSTALLER_UID,
                        verificationInfo.installerUid);
            }
        }

        // 创建PackageVerificationState 对像用来跟踪校验状态。
        final PackageVerificationState verificationState = new PackageVerificationState(
                requiredUid, args);
        // 把verificationState保存起来，方便以后查找使用。
        mPendingVerification.append(verificationId, verificationState);

        // 获取到sufficientVerifiers，上文提到过，其中pkgLite经过解析manifest而来
        final List<ComponentName> sufficientVerifiers = matchVerifiers(pkgLite,
                receivers, verificationState);
        // 这里应该是android6.0 后添加的，避免在校验的过程中系统进入休眠。
        DeviceIdleController.LocalService idleController = getDeviceIdleController();
        final long idleDuration = getVerificationTimeout();

        /*
         * If any sufficient verifiers were listed in the package
         * manifest, attempt to ask them.
         */
        if (sufficientVerifiers != null) {
            final int N = sufficientVerifiers.size();
            if (N == 0) {
                Slog.i(TAG, "Additional verifiers required, but none installed.");
                ret = PackageManager.INSTALL_FAILED_VERIFICATION_FAILURE;
            } else {
                for (int i = 0; i < N; i++) {
                    final ComponentName verifierComponent = sufficientVerifiers.get(i);
                    // 与doze模式相关，避免休眠
                    idleController.addPowerSaveTempWhitelistApp(Process.myUid(),
                            verifierComponent.getPackageName(), idleDuration,
                            verifierUser.getIdentifier(), false, "package verifier");

                    final Intent sufficientIntent = new Intent(verification);
                    sufficientIntent.setComponent(verifierComponent);
                    // 发送验证请求
                    mContext.sendBroadcastAsUser(sufficientIntent, verifierUser);
                }
            }
        }

        if (mOptionalVerifierPackage != null) {
            final Intent optionalIntent = new Intent(verification);
            optionalIntent.setAction("com.qualcomm.qti.intent.action.PACKAGE_NEEDS_OPTIONAL_VERIFICATION");
            final List<ResolveInfo> optional_receivers = queryIntentReceiversInternal(optionalIntent,
                PACKAGE_MIME_TYPE, 0, verifierUser.getIdentifier());
            final ComponentName optionalVerifierComponent = matchComponentForVerifier(
                mOptionalVerifierPackage, optional_receivers);
            optionalIntent.setComponent(optionalVerifierComponent);
            verificationState.addOptionalVerifier(optionalUid);
            if (mRequiredVerifierPackage != null) {
                mContext.sendBroadcastAsUser(optionalIntent, verifierUser, android.Manifest.permission.PACKAGE_VERIFICATION_AGENT);
            } else {
                mContext.sendOrderedBroadcastAsUser(optionalIntent, verifierUser, android.Manifest.permission.PACKAGE_VERIFICATION_AGENT,
                new BroadcastReceiver() {
                    @Override
                    public void onReceive(Context context, Intent intent) {
                        final Message msg = mHandler.obtainMessage(CHECK_PENDING_VERIFICATION);
                        msg.arg1 = verificationId;
                        mHandler.sendMessageDelayed(msg, getVerificationTimeout());
                    }
                }, null, 0, null, null);
                mArgs = null;
            }
        }

        final ComponentName requiredVerifierComponent = matchComponentForVerifier(
                mRequiredVerifierPackage, receivers);
        if (ret == PackageManager.INSTALL_SUCCEEDED
                && mRequiredVerifierPackage != null) {
            Trace.asyncTraceBegin(
                    TRACE_TAG_PACKAGE_MANAGER, "verification", verificationId);
            /*
             * Send the intent to the required verification agent,
             * but only start the verification timeout after the
             * target BroadcastReceivers have run.
             */
            verification.setComponent(requiredVerifierComponent);
            idleController.addPowerSaveTempWhitelistApp(Process.myUid(),
                    mRequiredVerifierPackage, idleDuration,
                    verifierUser.getIdentifier(), false, "package verifier");
            // 之前基础发送给各种verifier 进行校验，最后发送给required的verifier进行校验
            mContext.sendOrderedBroadcastAsUser(verification, verifierUser,
                    android.Manifest.permission.PACKAGE_VERIFICATION_AGENT,
                    new BroadcastReceiver() {
                        // 此处巧妙，此Receiver做为orderedBroadcast的最后一站，将接收到intent。
                        @Override
                        public void onReceive(Context context, Intent intent) {
                            final Message msg = mHandler
                                    .obtainMessage(CHECK_PENDING_VERIFICATION);
                            msg.arg1 = verificationId;
                            // 延时发送校验结束的消息，即超时时间到后发送校验结束，由于未携带
                            // 校验结果，将被判定为REJECT.
                            mHandler.sendMessageDelayed(msg, getVerificationTimeout());
                        }
                    }, null, 0, null, null);

            /*
             * We don't want the copy to proceed until verification
             * succeeds, so null out this field.
             */
            mArgs = null;
        }
    } else {
        /*
         * No package verification is enabled, so immediately start
         * the remote call to initiate copy using temporary file.
         */
        ret = args.copyApk(mContainerService, true);
    }
}

mRet = ret;
```
以上为发送校验请求，当校验结束后会需要调用verifyPendingInstall 方法通知PackageManagerService 校验结束了，该方法会发送消息PACKAE_VERIFIED给PackageManagerService的PackageHandler.handleMessage 处理，处理流程如下：
<span id="响应"/>
```java
case PACKAGE_VERIFIED: {
    final int verificationId = msg.arg1;

    final PackageVerificationState state =
    // 通过verificationId 取得 校验状态对象，该对象用来跟踪校验过程的状态变化。
    mPendingVerification.get(verificationId);

    if (state == null) {
        Slog.w(TAG, "Invalid verification token " + verificationId + " received");
        break;
    }

    final PackageVerificationResponse response = (PackageVerificationResponse) msg.obj;

    // 更新校验状态，会根据calleruid来判断是那个verifier校验的结果。
    state.setVerifierResponse(response.callerUid, response.code);

    if (state.isVerificationComplete()) {
        mPendingVerification.remove(verificationId);

        final InstallArgs args = state.getInstallArgs();
        final Uri originUri = Uri.fromFile(args.origin.resolvedFile);

        int ret;
        if (state.isInstallAllowed()) {
            ret = PackageManager.INSTALL_FAILED_INTERNAL_ERROR;
            // 校验通过会通知下verifier们校验最终通过了，大家都安心，其实没啥用。
            broadcastPackageVerified(verificationId, originUri,
                    response.code, state.getInstallArgs().getUser());
            try {
                // 继续安装流程
                ret = args.copyApk(mContainerService, true);
            } catch (RemoteException e) {
                Slog.e(TAG, "Could not contact the ContainerService");
            }
        } else {
            // 校验失败，返回安装失败的结果。
            ret = PackageManager.INSTALL_FAILED_VERIFICATION_FAILURE;
        }

        Trace.asyncTraceEnd(
                TRACE_TAG_PACKAGE_MANAGER, "verification", verificationId);

        processPendingInstall(args, ret);
        mHandler.sendEmptyMessage(MCS_UNBIND);
    }

    break;
}
```
整个校验的流程其实挺简单的，实际上就是在应用安装的过程中横插了一杠，发送了请求校验的广播出去，然后停止安装，等着有能力校验的应用校验完成后，根据校验的结果继续完成安装过程。至于校验者应用，官方文档介绍，GooglePlay实现了这一校验功能，据说是会扫描采集安装包的信息到Google的后台按照一些规则计算衡量后判定是否符合安装的要求，这大概就是一些应用海外版不能具有某种“黑科技技术”实现的原因吧，因为人家的机子上都有GooglePlay对这些应用进行检查。
实际上现在国内许多手机厂商都会实现自己的Verifier，例如我使用的华为P9在安装一些应用的时候，华为的应用商店也会进行校验，然后弹出类似文章开头处的界面。

## 参考
### 其他人介绍Package Verifiers的文章
[Android Internals: Package Verifiers](http://irq5.io/2014/12/01/android-internals-package-verifiers/)
### Package安装过程
The following process executes in Package Manager Service.
- Waiting
- Add a package to the queue for the installation process
- Determine the appropriate location of the package installation
- Determine installation Install / Update new
- Copy the apk file to a given directory
- Determine the UID of the app
- Request the installd daemon process
- Create the application directory and set permissions
- Extraction of dex code to the cache directory
- To reflect and packages.list / system / data / packages.xml the latest status
- Broadcast to the system along with the name of the effect of the installation is complete package
- Intent.ACTION_PACKAGE_ADDED: If the new ( Intent.ACTION_PACKAGE_REPLACED): the case of an update

流程如下图：
![package installer](http://ovfro7ddi.bkt.clouddn.com/Package%20Installer.jpg)

### PackageManager 详细介绍：
1. [In Depth: Android Package Manager and Package Installer](https://dzone.com/articles/depth-android-package-manager)
2. [Android パッケージインストール処理のしくみを追う](http://dsas.blog.klab.org/archives/52069323.html#PackageManagerService.FileInstallArgs.doPostInstall)
