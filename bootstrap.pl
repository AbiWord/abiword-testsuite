#!/usr/bin/perl
eval `cat regression.conf`;

if ($root eq "")
{
        printf "\$root is unset, please check your regression.conf file\n";
        die;
}

if ($#ARGV+1 != 1)
{
	print "Usage: bootstrap.pl <branchname>\n";
	die;
}

$branch = $ARGV[0];
$source_dir = ".src/" . $branch; # TODO: make this configurable


#TODO: handle the login to the cvs server
#...

# TODO: this is ugly
`mkdir -p $source_dir`;
`mkdir -p $prefix`;


#
# Per Branch Build Instructions
#

$abi_log = "$root/abiword_compilation_report_$branch.txt";
$abi_plugin_log = "$root/abiword_plugins_compilation_report_$branch.txt";

if ($branch eq "ABI-2-4-0-STABLE")
{
	# cvs update abiword
	`cd $source_dir &&\
	 cvs -d $cvsroot -z3 co -r $branch abi abidistfiles abiword-plugins &&\
	 cvs -d $cvsroot -z3 co -r wv-1-0-0-STABLE wv`;

	# apply the testsuite specific patches to the tree 
	# (TODO: make this a function)
	foreach $patch ( @patches )
	{
		`cd $source_dir && patch -p0 < $root/patches/$patch-$branch.diff`;
	}

	# build abiword
	# TODO: write the compilation report to a branch specific log file
	`cd $source_dir/abi &&\
	 ./autogen.sh &&\
	 CXXFLAGS="-pg -g" ./configure --prefix=$root/$prefix --enable-gnome\
	 make 2>$abi_log && make install`;
 
	# build required abiword plugins
	`cd $source_dir/abiword-plugins &&\
	 ./nextgen.sh &&\
	 CXXFLAGS="-pg -g" ./configure --prefix=$root/$prefix &&\
	 make 2>$abi_plugin_log && make install`;
} 
elsif ($branch eq "HEAD")
{
	# cvs update abiword
	`cd $source_dir &&\
	 cvs -d $cvsroot -z3 co -r $branch abi abidistfiles abiword-plugins &&\
	 cvs -d $cvsroot -z3 co wv`;

	# apply the testsuite specific patches to the tree
	foreach $patch ( @patches )
	{
		`cd $source_dir && patch -p0 < $root/patches/$patch-$branch.diff`;
	}

	# build wv
	`cd $source_dir/wv &&\
	 ./autogen.sh &&\
	 CXXFLAGS="-pg -g" ./configure --prefix=$root/$prefix \
	 make && make install >/dev/null 2>/dev/null`;

	# build abiword
	# TODO: write the compilation report to a branch specific log file
	`cd $source_dir/abi &&\
	 ./autogen.sh &&\
	 CXXFLAGS="-pg -g" ./configure --prefix=$root/$prefix --enable-gnome\
	 make 2>$abi_log && make install`;
 
	# build required abiword plugins
	`cd $source_dir/abiword-plugins &&\
	 ./nextgen.sh &&\
	 CXXFLAGS="-pg -g" ./configure --prefix=$root/$prefix &&\
	 make 2>$abi_plugin_log && make install`;
}
