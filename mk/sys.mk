# $Id: sys.mk,v 1.23 2010/06/14 16:23:46 sjg Exp $
#
#	@(#) Copyright (c) 2003-2009, Simon J. Gerraty
#
#	This file is provided in the hope that it will
#	be of use.  There is absolutely NO WARRANTY.
#	Permission to copy, redistribute or otherwise
#	use this file is hereby granted provided that 
#	the above copyright notice and this notice are
#	left intact. 
#      
#	Please send copies of changes and bug-fixes to:
#	sjg@crufty.net
#

# Avoid putting anything platform specific in here.

# sometimes we want to turn on debugging in just one or two places
# if .CURDIR is matched by any entry in DEBUG_MAKE_SYS_DIRS we
# will apply DEBUG_MAKE_FLAGS now.
# if an entry in DEBUG_MAKE_DIRS matches, we apply after sys.mk
# eg.  DEBUG_MAKE_FLAGS=-dv DEBUG_MAKE_SYS_DIRS="*lib/sjg"
.if ${.MAKE.LEVEL:U1} > 0 && empty(DEBUG_MAKE_FLAGS)
.if ${DEBUG_MAKE_SYS_DIRS:Uno:@x@${.CURDIR:M$x}@} != ""
.MAKEFLAGS: ${DEBUG_MAKE_FLAGS}
.endif
.endif

# if this is an ancient version of bmake
MAKE_VERSION ?= 0
.if ${MAKE_VERSION:M*make-*}
# turn it into what we want - just the date
MAKE_VERSION := ${MAKE_VERSION:[1]:C,.*-,,}
.endif

# some useful modifiers

# A useful trick for testing multiple :M's against something
# :L says to use the variable's name as its value - ie. literal
# got = ${clean* destroy:${M_ListToMatch:S,V,.TARGETS,}}
M_ListToMatch = L:@m@$${V:M$$m}@
# match against our initial targets (see above)
M_L_TARGETS = ${M_ListToMatch:S,V,_TARGETS,}

# turn a list into a set of :N modifiers
# NskipFoo = ${Foo:${M_ListToSkip}}
M_ListToSkip= O:u:ts::S,:,:N,g:S,^,N,

# type should be a builtin in any sh since about 1980,
# AUTOCONF := ${autoconf:L:${M_whence}}
M_whence = @x@(type $$x 2> /dev/null; echo) | sed 's,^[^/][^/]*,,;q';@:sh

# convert a path to a valid shell variable
M_P2V = tu:C,[./-],_,g

# convert path to absolute
.if ${MAKE_VERSION:U0} > 20100408
M_tA = tA
.else
M_tA = C,.*,('cd' & \&\& 'pwd') 2> /dev/null || echo &,:sh
.endif

# this is handy for forcing a space into something.
AnEmptyVar=

# absoulte path to what we are reading.
_PARSEDIR = ${.PARSEDIR:${M_tA}}

# we expect a recent bmake
.if !defined(_TARGETS)
# some things we do only once
_TARGETS := ${.TARGETS}
.-include <sys.env.mk>
.endif

# we need HOST_TARGET etc below.
.include <host-target.mk>

# find the OS specifics
.if defined(SYS_OS_MK)
.include <${SYS_OS_MK}>
.else
_sys_mk =
.for x in ${HOST_OSTYPE} ${HOST_TARGET} ${HOST_OS} ${MACHINE} Generic
.if empty(_sys_mk)
.-include <sys/$x.mk>
_sys_mk := ${.MAKE.MAKEFILES:M*/$x.mk}
.if !empty(_sys_mk)
_sys_mk := sys/${_sys_mk:T}
.endif
.endif
.if empty(_sys_mk)
# might be an old style
.-include <$x.sys.mk>
_sys_mk := ${.MAKE.MAKEFILES:M*/$x.sys.mk:T}
.endif
.endfor

SYS_OS_MK := ${_sys_mk}
.export SYS_OS_MK
.endif

# allow customization without editing.
.-include <local.sys.mk>

.ifndef ROOT_GROUP
ROOT_GROUP != sed -n /:0:/s/:.*//p /etc/group
.export ROOT_GROUP
.endif

unix ?= We run ${_HOST_OSNAME}.

# A race condition in mkdir, means that it can bail if another
# process made a dir that mkdir expected to.
# We repeat the mkdir -p a number of times to try and work around this.
# We stop looping as soon as the dir exists.
# If we get to the end of the loop, a plain mkdir will issue an error.
Mkdirs= Mkdirs() { \
	for d in $$*; do \
		for i in 1 2 3 4 5 6; do \
			mkdir -p $$d; \
			test -d $$d && return 0; \
		done; \
		mkdir $$d || exit $$?; \
	done; }

# this often helps with debugging
.SUFFIXES:      .cpp-out

.c.cpp-out:
	@${COMPILE.c:N-c} -E ${.IMPSRC} | grep -v '^[ 	]*$$'

.cc.cpp-out:
	@${COMPILE.cc:N-c} -E ${.IMPSRC} | grep -v '^[ 	]*$$'


# sometimes we want to turn on debugging in just one or two places
# if .CURDIR is matched by any entry in DEBUG_MAKE_DIRS we
# will apply DEBUG_MAKE_FLAGS
# eg.  DEBUG_MAKE_FLAGS=-dv DEBUG_MAKE_DIRS="*lib/sjg"
.if ${.MAKE.LEVEL:U1} > 0 && empty(DEBUG_MAKE_FLAGS)
.if ${DEBUG_MAKE_DIRS:Uno:@x@${.CURDIR:M$x}@} != ""
.MAKEFLAGS: ${DEBUG_MAKE_FLAGS}
.endif
.endif
