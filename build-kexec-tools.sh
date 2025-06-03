#!/bin/bash
#
# An example of how to create kexec-tools statically for different architectures
#
# Used to accompany The PSCG's training/Ron Munitz's talks
#
: ${TUPLES="x86_64-linux-gnu aarch64-linux-gnu riscv64-linux-gnu arm-linux-gnueabi arm-linux-gnueabihf i686-linux-gnu loongarch64-linux-gnu"}
# Note: as per the time of writing the following architectures are not supported by kexec:
#       alpha, arc, powerpc, sparc64 .
# 	Leaving them just in case they get support in the future and you use them
: ${MORE_TUPLES="alpha-linux-gnu arc-linux-gnu m68k-linux-gnu mips64-linux-gnuabi64 mips64el-linux-gnuabi64 mips-linux-gnu mipsel-linux-gnu powerpc-linux-gnu powerpc64-linux-gnu powerpc64le-linux-gnu sh4-linux-gnu sparc64-linux-gnu s390x-linux-gnu"}
: ${SRC_PROJECT=$(readlink -f ./kexec-tools)}

# riscv64: important: the latest tag as per the time of writing it, v2.0.31" DOES NOT SUPPORT building for riscv64.
# the last time this was updated, master was at commit 8322826fa7b04a5c0f023eda78d69dd1413a1412 
# it is not explicitly mentioned, because it could be rebased
: ${GIT_REF=master}
: ${USE_MULTILIB_FOR_32BIT_X86=false}	# if true - use -m32. This conflicts with all cross-compilers. A better alternative for 2025 is to use native toolchain distro, i686-linux-gnu-...

# ./configure vs. make:
# Could use --prefix in configure, but it's working with another folder, and we don't really want the entire set of tools here.
# In addition the install-strip target does not seem to be implemented, and even with --prefix it tries to do some udev stuff which is wrong
# so there is no point in it
#
# Instead, in this particular case,  # make -j16 DESTDIR=... install-strip does the job, without the --prefix in configure.
# It does suffer from the same errors, but at least you don't need to go thorugh an additional stripping phase
# We present two versions for you to experiment with. The one with the find could be more accurate, as some of the executables are
# shell script, so obviously they are not to be stripped.
#
# More notes (the project started as a copying of the e2fsprogs and dosfstools repos I made, do it may apply to them as well) (the lines above are ontouched copying of them)
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# I built on an Ubuntu 25.04, as where I built the previous versions of dosfstool and e2fsprogs  on an earlier version. Since I only care about the binaries,
# I don't put too much work into it, and I didn not check what is the build status of the other projects.  What I noticed for now, in this project is:
# - i386-...- toolchain is not available, but rather i686 (It is very possible that for the other projects I built on non x86_64 host and/or installed my own toolchains
# - make install-strip target does not work here. Maybe it applies for the rest as well
#     
#
# More configure and make flags - kexec-tools specific:
# ----------------------------------------------
#
# Building statically with the default flags results in an zstd linkage error. 
#    "/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/14/../../../x86_64-linux-gnu/libzstd.a(zstd_decompress.o): in function ZSTD_isFrame': (.text+0x1430): multiple definition of ZSTD_isFrame';"
# Therefore, zstd is not allowed in this version (could resolve it, it doesn't really matter so won't do it. If you see it you are willing to fix it and submit the patch)
#
# install-strip does not work. I didn't look into the makefiles. Didn't bother more
: ${MORE_CONFIGURE_FLAGS=" --without-zstd "}

#
# $1: build directory
#
build_without_installing() (
	mkdir $1
	cd $1
	$SRC_PROJECT/configure LDFLAGS=-static  --host=${CROSS_COMPILE%-} $MORE_CONFIGURE_FLAGS || exit 1
	make -j$(nproc)
	find . -executable -not -type d | xargs ${CROSS_COMPILE}strip -s
)


#
# $1: build directory
# $2: install directory
#
build_with_installing() (
	set -euo pipefail # will only apply to this subshell. Prints were added - if nothing is being done - it might be because the folder exists and you will see it in the arch logs
	installdir=$(readlink -f $2)
	mkdir $1 # You must create the build and install directories. make will not do that for you
	cd $1
	echo -e "\x1b[34mConfiguring $tuple\x1b[0m"
	$SRC_PROJECT/configure LDFLAGS=--static  --host=${CROSS_COMPILE%-} $MORE_CONFIGURE_FLAGS || { echo -e "\x1b[31mFailed to configure for $installdir\x1b[0m" ; exit 1 ; }
	echo -e "\x1b[34mBuilding and installing $tuple\x1b[0m ($PWD)"
	echo "make -j$(nproc) DESTDIR=$installdir install"
	make -j$(nproc) DESTDIR=$installdir install || { echo -e "\x1b[31mFailed to build/install for $installdir\x1b[0m" ; exit 1 ; }
	echo -e "\x1b[34mStripping $tuple\x1b[0m ($PWD)"
	find $installdir -executable -not -type d | xargs ${CROSS_COMPILE}strip -s || { echo -e "\x1b[31mFailed to strip for $installdir\x1b[0m" ; exit 1 ; }
	echo -e "\x1b[32m$tuple - Done!\x1b[0m ($PWD)"
)


# This example builds for several tuples
# The function above can be used from outside a script, assuming that the CROSS_COMPILE variable is set
# It may however need more configuration if you do not build for gnulibc
build_for_several_tuples() {
	local failing_tuples=""
        for tuple in $TUPLES $MORE_TUPLES ; do
		echo -e "\x1b[35mConfiguring and building $tuple\x1b[0m"
		export CROSS_COMPILE=${tuple}- # we'll later strip it but CROSS_COMPILE is super standard, and autotools is "a little less standard"
		build_with_installing $tuple-build $tuple-install 2> err.$tuple || failing_tuples="$failing_tuples $tuple"
	done

	if [ -z "$failing_tuples" ] ; then
		echo -e "\x1b[32mDone\x1b[0m"
	else
		echo -e "\x1b[33mDone\x1b[0m You can see errors in $(for x in $failing_tuples ; do echo err.$x ; done)"
	fi
}

#
# Build 32 bit x86 on x86_64 hosts. This is not cross compilation, but rather requires some make flags and the installation of multilib
#
build_and_install_32bitx86_on_x86_64() {
	export CROSS_COMPILE=""
	local tuple=i386-linux-gnu # pretty much arbitrary
	local builddir=$PWD/$tuple-build
	local installdir=$PWD/$tuple-install
	mkdir $builddir
	cd $builddir || exit 1
	$SRC_PROJECT/configure LDFLAGS="--static -m32" CFLAGS=-m32 $MORE_CONFIGURE_FLAGS || exit 1
	make -j$(nproc) DESTDIR=$installdir install 2>err.$tuple

}

fetch() (
	[ "$1" = "dontfetch" ] && return
	git clone git://git.kernel.org/pub/scm/utils/kernel/kexec/kexec-tools.git -b $GIT_REF || exit 1
	cd kexec-tools && ./bootstrap
)

main() {
	fetch $@ || exit 1
	build_for_several_tuples
	if [ "$(uname -m)" = "x86_64" ] ; then
		if [ "$USE_MULTILIB_FOR_32BIT_X86" = "true" ] ; then
			build_and_install_32bitx86_on_x86_64
		fi
	fi
}

main $@
