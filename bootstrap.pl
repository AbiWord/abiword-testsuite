#!/usr/bin/perl
eval `cat regression.conf`;

use Cwd;

$CVSROOT=":pserver:anoncvs\@anoncvs.abisource.com:/cvsroot";
$ROOT=getcwd;
$ABI_BRANCH="ABI-2-4-0-STABLE";

#TODO: login

#TODO: move to config
`mkdir -p .src`;
`mkdir -p $prefix`;

# cvs update abiword (HEAD)
`cd .src &&\
 cvs -d $CVSROOT -z3 co -r $ABI_BRANCH abi abidistfiles abiword-plugins &&\
 cvs -d $CVSROOT -z3 co -r wv-1-0-0-STABLE wv`;

# build abiword
`cd .src/abi &&\
 ./autogen.sh &&\
 CXXFLAGS="-pg -g" ./configure --prefix=$ROOT/$prefix --enable-gnome\
 make && make install 2>compilation_report.out`;
 
# build required abiword plugins
`cd .src/abiword-plugins &&\
 ./nextgen.sh &&\
 CXXFLAGS="-pg -g" ./configure --prefix=$ROOT/$prefix --disable-all --enable-wordperfect --enable-OpenDocument &&\
 make && make install`;
 

