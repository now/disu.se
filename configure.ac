AC_PREREQ([2.69])
AC_INIT([disu.se], [1.0.0], [now@disu.se])
AC_CONFIG_SRCDIR([configure.ac])
AC_CONFIG_AUX_DIR([build])
hostname=`hostname`
AC_ARG_WITH([hostname],
  [AS_HELP_STRING([--with-hostname],
     [override default hostname @<:@$hostname@:>@])],
  [hostname=$withwal])
AC_SUBST([hostname])
nginxuser=www-data
AC_ARG_WITH([nginxuser],
  [AS_HELP_STRING([--with-nginxuser],
     [override default nginx user @<:@$nginxuser@:>@])],
  [nginxuser=$withwal])
case $nginxuser in
  ?*) nginxuserdirective="user $nginxuser;" ;;
  *) nginxuserdirective= ;;
esac
AC_SUBST([nginxuserdirective])
port=80
AC_ARG_WITH([port],
  [AS_HELP_STRING([--with-port],
     [override default port @<:@$port@:>@])],
  [port=$withval])
AC_SUBST([port])
sslport=80
AC_ARG_WITH([ssl-port],
  [AS_HELP_STRING([--with-ssl-port],
     [override default SSL port @<:@$sslport@:>@])],
  [sslport=$withval])
AC_SUBST([sslport])
webrootdir='${abs_top_builddir}'
AC_ARG_WITH([webrootdir],
  [AS_HELP_STRING([--with-webrootdir],
     [override default webroot directory @<:@$webrootdir@:>@])],
  [webrootdir=$withval])
AC_SUBST([webrootdir])
AC_CHECK_PROGS([CURL], [curl])
AC_ARG_VAR([CURL], [the cURL command])
AC_PROG_INSTALL
AC_CHECK_PROGS([GEM], [gem])
AC_ARG_VAR([GEM], [the gem command])
AC_CHECK_PROGS([GIT], [git])
AC_ARG_VAR([GIT], [the git command])
AC_CHECK_PROGS([JAVA], [java])
AC_ARG_VAR([JAVA], [the java command])
AC_CHECK_PROGS([NMC], [nmc])
AC_ARG_VAR([NMC], [the nmc command])
AC_CHECK_PROGS([RAKE], [rake])
AC_ARG_VAR([RAKE], [the rake command])
AC_CHECK_PROGS([RSYNC], [rsync])
AC_ARG_VAR([RSYNC], [the rsync command])
AC_PROG_MKDIR_P
AC_CHECK_PROGS([XSLTPROC], [xsltproc])
AC_ARG_VAR([XSLTPROC], [the xsltproc command])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
