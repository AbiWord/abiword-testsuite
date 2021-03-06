#!/usr/bin/perl
#use strict;
use File::Spec::Functions qw(rel2abs);
use File::Basename;
require "regression.conf";

# check args
if ($#ARGV+1 != 1 && $#ARGV+1 != 2)
{
	print "Usage: bootstrap.pl <abiword svn url> [<abiword plugins svn url>]\n";
	die;
}

# setup variables
$abiword_url = $ARGV[0];
$abiword_url =~ m/.*\/(.*)/;
$sn = $1;
$source_dir = $root . "/.src/" . $sn;

# remap stdout
open(STDOUT, ">$root/logs/bootstrap_$sn.log");
open(STDERR, ">>$root/logs/bootstrap_$sn.log");

# setup directories
# TODO: this is ugly
`mkdir -p $source_dir`;
`mkdir -p $prefix`;

#
# per-branch build instructions
#

$abi_log = "$root/logs/abiword_compilation_report_$sn.txt";
$abi_plugin_log = "$root/logs/abiword_plugins_compilation_report_$sn.txt";

if ($sn eq "trunk")
{
	# cvs update abiword
	`cd $source_dir && svn co $abiword_url abiword`;

	# apply the testsuite specific patches to the tree
	foreach $patch ( @patches )
	{
		`cd $source_dir && patch -p0 < $root/patches/$patch-$sn.diff`;
	}

	# build abiword
	my $abiword_cmd = "cd $source_dir/abiword && CXXFLAGS=\"-pg -g\" ./autogen.sh --prefix=$root/$prefix --enable-plugins && make $make_flags 2>$abi_log && make install";
	open(ABIWORD_CMD,  "$abiword_cmd |");
	while (<ABIWORD_CMD>)
	{
	    print $_;
	}
	close(ABIWORD_CMD);
}

# flush/close the logfile
close(STDOUT);
