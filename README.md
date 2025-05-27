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
Short explanations in youtube:
- <future placeholder>

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
