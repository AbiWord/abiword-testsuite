#!/usr/bin/perl
eval `cat regression.conf`;

if ($root eq "")
{
        printf "\$root is unset, please check your regression.conf file\n";
        die;
}

if ($#ARGV+1 != 1)
{
	print "Usage: cleanup.pl <branchname>\n";
	die;
}

$abi_branch = $ARGV[0];
$source_dir = ".src/" . $abi_branch; # TODO: make this configurable

#TODO: it isn't really safe to exec rm -rf :-P
#TODO: run make uninstall first?
`rm -rf $source_dir`;
`rm -rf $root/$prefix`;
