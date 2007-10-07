#!/usr/bin/perl
require "regression.conf";

if ($#ARGV+1 != 1)
{
	print "Usage: cleanup.pl <branch url>\n";
	die;
}

$abiword_url = $ARGV[0];
$abiword_url =~ m/.*\/(.*)/;
$sn = $1;
$source_dir = $root . "/.src/" . $sn;

#TODO: it isn't really safe to exec rm -rf :-P
#TODO: run make uninstall first?
`rm -rf $source_dir`;
`rm -rf $root/$prefix`;
