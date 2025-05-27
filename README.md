# Some kexec-tools static prebuilts (linked with glibc)

## Context/Motivation:
Allow using kexec in a busybox based ramdisk (or any other small one).

## Objectives:
Do the same things in the e2fsprogs repo / videos for dosfstools.
- (cross-)Build dosfstools from source code - STATICALLY
- Discuss some annoying configuration issues with autotools
- Discussing common (g)libc issues when you try to just build with your distro tools and autotools
- (cross)-chroot for testing - and discussing what warnings should worry you or what
- reasoning why this entire presentation is a bad practice and you should use build systems and not build things yourself ;-)

## Why does this repo exist?
- I gave a kexec/kdump talk, and mentioned it can be used anywhere. This is an example.
- Can be used for embedded systems where the kernel supports kexec and the vendor did not provide the tools in userspace

## More info about the why and demonstration of the how (i.e. how to build the resulting binaries)
Will not be as elaborate as with the previous tools. If a *short* version is uploaded, it will be provided.
The following videos in Youtube give very detailed information
- [The practical Kexec/Kdump talk](https://www.youtube.com/watch?v=U-DKdswpVT4&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=80) - This is an **Excellent** introduction to kdump and kexec. It was unfortunately given in Hebrew due to the audience request, but you can use captions in English, it works reasonably well).
- [arm64 kexec/kdump on PscgBuildOS/pscg_busybox](https://www.youtube.com/watch?v=GKWMN53PxjM&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=82)
- [Mixtures of our built kexec and Ubuntu file system running (i.e.: PscgDebOS and PscgBusyboxOS, including upstream Ubuntu kernel from my host)](https://www.youtube.com/watch?v=4ljjbzHWKIo&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=83&pp=gAQBiAQB)

## Notes about other toolchains:
Note the significant size difference when building with *musl* cf. when building with *glibc*. I only tested it for x86_64.
As I am unaware of an easily publicly available package for installing musl, I am not providing the instructions to do it, but basically you just
use the relevant tuple in the script (e.g. `x86_64-linux-musl`). I am writing it explicitly because this is a quite significant difference.
You may of course experiment with other toolchains.

```
ron@ronmsi:~/dev/pscgdebos-external-projects-build/kexec-tools-static-builds$ du -sh x86_64-linux-musl-install/usr/local/sbin/*
220K	x86_64-linux-musl-install/usr/local/sbin/kexec
48K	x86_64-linux-musl-install/usr/local/sbin/vmcore-dmesg

ron@ronmsi:~/dev/pscgdebos-external-projects-build/kexec-tools-static-builds$ du -sh x86_64-linux-gnu-install/usr/local/sbin/*
1.3M	x86_64-linux-gnu-install/usr/local/sbin/kexec
748K	x86_64-linux-gnu-install/usr/local/sbin/vmcore-dmesg
ron@ronmsi:~/dev/pscgdebos-external-projects-build/kexec-tools-static-builds$ 
```

## Building
You can speficy the `TUPLES` and `MORE_TUPLES` variables to specify your build tuples, or otherwise modify the code. You can provide `dontfetch` to avoid cloning the tool from git if you already built it at least once.
```bash
./build-kexec-tools.sh
```

## Build status
Known to build properly:
```
x86_64-linux-gnu aarch64-linux-gnu riscv64-linux-gnu arm-linux-gnueabi arm-linux-gnueabihf i686-linux-gnu loongarch64-linux-gnu
m68k-linux-gnu mips64-linux-gnuabi64 mips64el-linux-gnuabi64 mips-linux-gnu mipsel-linux-gnu powerpc64-linux-gnu powerpc64le-linux-gnu sh4-linux-gnu s390x-linux-gnu
```

Known to not build properly:
```
alpha-linux-gnu, arc-linux-gnu, powerpc-linux-gnu, sparc64-linux-gnu
```
