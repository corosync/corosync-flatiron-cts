#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

# bootstrap / init
AC_PREREQ([2.61])

AC_INIT([corosync-testagents], [1.2.7], [openais@lists.osdl.org])
AM_INIT_AUTOMAKE([-Wno-portability])

AC_CONFIG_SRCDIR([cts/agents/cpg_test_agent.c])
AC_CONFIG_HEADER([config.h])

AC_CANONICAL_HOST

AC_LANG([C])

dnl Fix default variables - "prefix" variable if not specified
if test "$prefix" = "NONE"; then
	prefix="/usr"

	dnl Fix "localstatedir" variable if not specified
	if test "$localstatedir" = "\${prefix}/var"; then
		localstatedir="/var"
	fi
	dnl Fix "sysconfdir" variable if not specified
	if test "$sysconfdir" = "\${prefix}/etc"; then
		sysconfdir="/etc"
	fi
	dnl Fix "libdir" variable if not specified
	if test "$libdir" = "\${exec_prefix}/lib"; then
		if test -e /usr/lib64; then
			libdir="/usr/lib64"
		else
			libdir="/usr/lib"
		fi
	fi
fi

# Checks for programs.

# check stolen from gnulib/m4/gnu-make.m4
if ! ${MAKE-make} --version /cannot/make/this >/dev/null 2>&1; then
	AC_MSG_ERROR([you don't seem to have GNU make; it is required])
fi

AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET
AC_PROG_RANLIB
AC_CHECK_PROGS([GROFF], [groff])
AC_CHECK_PROGS([PKGCONFIG], [pkg-config])
AC_CHECK_PROGS([AUGTOOL], [augtool])

# Checks for libraries.
AC_CHECK_LIB([dl], [dlopen])
AC_CHECK_LIB([pthread], [pthread_create])
AC_CHECK_LIB([socket], [socket])
AC_CHECK_LIB([nsl], [t_open])
AC_CHECK_LIB([rt], [sched_getscheduler])

# Checks for header files.
AC_HEADER_STDC
AC_HEADER_SYS_WAIT
AC_CHECK_HEADERS([arpa/inet.h fcntl.h limits.h netdb.h netinet/in.h stdint.h \
		  stdlib.h string.h sys/ioctl.h sys/param.h sys/socket.h \
		  sys/time.h syslog.h unistd.h sys/types.h getopt.h malloc.h \
		  sys/sockio.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_C_INLINE
AC_TYPE_INT16_T
AC_TYPE_INT32_T
AC_TYPE_INT64_T
AC_TYPE_INT8_T
AC_TYPE_SIZE_T
AC_TYPE_SSIZE_T
AC_HEADER_TIME
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T
AC_TYPE_UINT8_T

# Checks for library functions.
AC_FUNC_ERROR_AT_LINE
AC_FUNC_FORK
AC_PROG_GCC_TRADITIONAL
AC_FUNC_MALLOC
AC_FUNC_MEMCMP
AC_FUNC_REALLOC
AC_FUNC_SELECT_ARGTYPES
AC_TYPE_SIGNAL
AC_FUNC_VPRINTF
AC_CHECK_FUNCS([alarm alphasort atexit bzero dup2 endgrent endpwent fcntl \
		getcwd getpeerucred getpeereid gettimeofday inet_ntoa memmove \
		memset mkdir scandir select socket strcasecmp strchr strdup \
		strerror strrchr strspn strstr pthread_spin_lock \
		pthread_spin_unlock pthread_setschedparam \
		sched_get_priority_max sched_setscheduler])

AC_CONFIG_FILES([Makefile
		 cts/Makefile
		 cts/agents/Makefile
		 cts/CTSvars.py])

### Local business

# ===============================================
# Helpers
# ===============================================

## helper for CC stuff
cc_supports_flag() {
	local CFLAGS="$@"
	AC_MSG_CHECKING([whether $CC supports "$@"])
	AC_COMPILE_IFELSE([int main(){return 0;}] ,
			  [RC=0; AC_MSG_RESULT([yes])],
			  [RC=1; AC_MSG_RESULT([no])])
	return $RC
}

## cleanup
AC_MSG_NOTICE(Sanitizing prefix: ${prefix})
case $prefix in
  NONE) prefix=/usr/local;;
esac

# local options
AC_ARG_ENABLE([debug],
	[ --enable-debug          : enable debug build. ],
	[ default="no" ])

AC_ARG_ENABLE([coverage],
	[  --enable-coverage       : coverage analysis of the codebase. ],
	[ default="no" ])

AC_ARG_ENABLE([augeas],
	[  --enable-augeas           : Install the augeas lens for corosync.conf ],,
	[ enable_augeas="no" ])
AM_CONDITIONAL(INSTALL_AUGEAS, test x$enable_augeas = xyes)

AC_ARG_WITH([lcrso-dir],
	[  --with-lcrso-dir=DIR    : corosync lcrso files. ],
	[ LCRSODIR="$withval" ],
	[ LCRSODIR="$libexecdir/lcrso" ])


AC_ARG_WITH([corosyncdir],
	[  --with-corosyncdir=DIR     : path to corosync source directory. ],
	[ CORODIR="$withval" ],
	[ AC_MSG_ERROR([Please provide corosync source dir]) ])

AC_SUBST(CORODIR)

CP=cp
OS_LDL="-ldl"
OS_DYFLAGS="-rdynamic"

AC_SUBST(CP)
# *FLAGS handling goes here

ENV_CFLAGS="$CFLAGS"
ENV_CPPFLAGS="$CPPFLAGS"
ENV_LDFLAGS="$LDFLAGS"

# debug build stuff
if test "x${enable_debug}" = xyes; then
	AC_DEFINE_UNQUOTED([DEBUG], [1], [Compiling Debugging code])
	OPT_CFLAGS="-O0"
	PACKAGE_FEATURES="$PACKAGE_FEATURES debug"
else
	OPT_CFLAGS="-O3"
fi

# gdb flags
if test "x${GCC}" = xyes; then
	GDB_FLAGS="-ggdb3"
else
	GDB_FLAGS="-g"
fi

if test "x${enable_augeas}" = xyes; then
	PACKAGE_FEATURES="$PACKAGE_FEATURES augeas"
fi

# extra warnings
EXTRA_WARNINGS=""

WARNLIST="
	all
	shadow
	missing-prototypes
	missing-declarations
	strict-prototypes
	declaration-after-statement
	pointer-arith
	write-strings
	cast-align
	bad-function-cast
	missing-format-attribute
	format=2
	format-security
	format-nonliteral
	no-long-long
	unsigned-char
	gnu89-inline
	no-strict-aliasing
	"

for j in $WARNLIST; do
	if cc_supports_flag -W$j; then
		EXTRA_WARNINGS="$EXTRA_WARNINGS -W$j";
	fi
done

if test "x${enable_coverage}" = xyes && \
		cc_supports_flag -ftest-coverage && \
		cc_supports_flag -fprofile-arcs ; then
	AC_MSG_NOTICE([Enabling Coverage (enable -O0 by default)])
	OPT_CFLAGS="-O0"
	COVERAGE_CFLAGS="-ftest-coverage -fprofile-arcs"
	COVERAGE_LDFLAGS="-ftest-coverage -fprofile-arcs"
	COVERAGE_LCRSO_EXTRA_LDFLAGS="-rdynamic"
	PACKAGE_FEATURES="$PACKAGE_FEATURES coverage"
else
	COVERAGE_CFLAGS=""
	COVERAGE_LDFLAGS=""
	COVERAGE_LCRSO_EXTRA_LDFLAGS=""
fi


if test "x${enable_fatal_warnings}" = xyes && \
		cc_supports_flag -Werror ; then
	AC_MSG_NOTICE([Enabling Fatal Warnings (-Werror)])
	WERROR_CFLAGS="-Werror"
	PACKAGE_FEATURES="$PACKAGE_FEATURES fatal-warnings"
else
	WERROR_CFLAGS=""
fi

# final build of *FLAGS
CFLAGS="$ENV_CFLAGS $OPT_CFLAGS $GDB_FLAGS $OS_CFLAGS \
	$COVERAGE_CFLAGS $EXTRA_WARNINGS $WERROR_CFLAGS $NSS_CFLAGS"
CPPFLAGS="$ENV_CPPFLAGS $ANSI_CPPFLAGS $OS_CPPFLAGS"
LDFLAGS="$ENV_LDFLAGS $COVERAGE_LDFLAGS $OS_LDFLAGS"

AC_SUBST([LCRSODIR])
AC_SUBST([COVERAGE_LCRSO_EXTRA_LDFLAGS])
AC_SUBST([OS_DYFLAGS])

AC_SUBST([OS_LDL])
AM_CONDITIONAL(AUGTOOL, test -n "${AUGTOOL}")
AC_DEFINE_UNQUOTED([LCRSODIR], "$(eval echo ${LCRSODIR})", [LCRSO directory])

AC_DEFINE_UNQUOTED([PACKAGE_FEATURES], "${PACKAGE_FEATURES}", [corosync built-in features])

AC_OUTPUT

AC_MSG_RESULT([])
AC_MSG_RESULT([$PACKAGE configuration:])
AC_MSG_RESULT([  Version                  = ${VERSION}])
AC_MSG_RESULT([  Prefix                   = ${prefix}])
AC_MSG_RESULT([  Executables              = ${sbindir}])
AC_MSG_RESULT([  Arch-independent files   = ${datadir}])
AC_MSG_RESULT([  System configuration     = ${sysconfdir}])
AC_MSG_RESULT([  corosync config dir      = ${COROSYSCONFDIR}])
AC_MSG_RESULT([  Features                 =${PACKAGE_FEATURES}])
AC_MSG_RESULT([])
AC_MSG_RESULT([  LCRSO                    = ${LCRSODIR}])
AC_MSG_RESULT([  Default optimization     = ${OPT_CFLAGS}])
AC_MSG_RESULT([  Default debug options    = ${GDB_CFLAGS}])
AC_MSG_RESULT([  Extra compiler warnings  = ${EXTRA_WARNING}])
AC_MSG_RESULT([  Env. defined CFLAG       = ${ENV_CFLAGS}])
AC_MSG_RESULT([  Env. defined CPPFLAGS    = ${ENV_CPPFLAGS}])
AC_MSG_RESULT([  Env. defined LDFLAGS     = ${ENV_LDFLAGS}])
AC_MSG_RESULT([  OS   defined CFLAGS      = ${OS_CFLAGS}])
AC_MSG_RESULT([  OS   defined CPPFLAGS    = ${OS_CPPFLAGS}])
AC_MSG_RESULT([  OS   defined LDFLAGS     = ${OS_LDFLAGS}])
AC_MSG_RESULT([  OS   defined LDL         = ${OS_LDL}])
AC_MSG_RESULT([  OS   defined DYFLAGS     = ${OS_DYFLAGS}])
AC_MSG_RESULT([  ANSI defined CPPFLAGS    = ${ANSI_CPPFLAGS}])
AC_MSG_RESULT([  Coverage     CFLAGS      = ${COVERAGE_CFLAGS}])
AC_MSG_RESULT([  Coverage     LDFLAGS     = ${COVERAGE_LDFLAGS}])
AC_MSG_RESULT([  Fatal War.   CFLAGS      = ${WERROR_CFLAGS}])
AC_MSG_RESULT([  Final        CFLAGS      = ${CFLAGS}])
AC_MSG_RESULT([  Final        CPPFLAGS    = ${CPPFLAGS}])
AC_MSG_RESULT([  Final        LDFLAGS     = ${LDFLAGS}])
