#!/usr/bin/perl
eval `cat regression.conf`;

sub ExecTests
{
	my ($branch) = @_;

	foreach $test ( @tests )
	{
		if ($html)
		{
			# TODO: add branch
			`cd $test; ./regression.pl $branch >index_$branch.html`;
		}
		else
		{
			`cd $test; ./regression.pl $branch 2>/dev/null`;
		}
	}
}

sub HtmlHeader
{
	print "<html>\n<head>\n</head>\n<body>\n";
	print "<h2>AbiWord TestSuite</h2>\n";
}

sub HtmlFooter
{
	$now = gmtime;	
	print "<br/>\n";
	print "Generated at $now GMT\n";
	print "</body>\n</html>\n";
}

#
# Main function
#

if ($root eq "")
{
	printf "\$root is unset, please check your regression.conf file\n";
	die;
}

if ($html)
{
	open(STDOUT, ">index.html");
	&HtmlHeader;

	# write out the branch overview index
	my $branch;
	foreach $branch ( @branches )
	{
		print "<h3>Branch: " . $branch . "</h3>\n";

		foreach $test ( @tests )
		{
			print "View report for <a href=\"./$test/index_$branch.html\">$test</a><br>\n";
		}
        }
}

# start a virtual X server
`Xvfb $DISPLAY & disown`;

my $branch;
foreach $branch ( @branches )
{
	if (!$html)
	{
		print "Branch: " . $branch . "\n";
	}
	
	# bootstrap the regression test suite
	system './cleanup.pl', $branch;
	system './bootstrap.pl', $branch;

	# execute the regression test suite
	&ExecTests($branch);
}

if ($html) {
	&HtmlFooter;
	close(STDOUT);
}

# Stop the virtual X server (TODO: should only kill the one we started)
`killall Xvfb`;

1;
