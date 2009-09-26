#!/usr/bin/perl
require "regression.conf";

sub ExecTests
{
	my ($sn, $abiword_binary) = @_;
	die unless $sn;
	die unless $abiword_binary;

	foreach $test ( @tests )
	{
		if ($html)
		{
			# TODO: add branch
			`cd $test; ./regression.pl $sn $abiword_binary >index_$sn.html`;
		}
		else
		{
			`cd $test; ./regression.pl $sn $abiword_binary 2>/dev/null`;
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

#
# Setup environment variables
#

#ugly
$ENV{DISPLAY} = ""; # we don't require a display to run
$ENV{LD_LIBRARY_PATH} = "$root/$prefix/lib";
$ENV{PKG_CONFIG_PATH} = "$root/$prefix/lib/pkgconfig";
$ENV{G_SLICE} = "always-malloc";
$ENV{PATH} = "$root/$prefix/bin:" . $ENV{PATH};

if ($html)
{
	open(STDOUT, ">index.html");
	&HtmlHeader;

	# write out the branch overview index
	foreach my $module_info ( @branches )
	{
		my ($abiword_url, $abiword_binary) = @$module_info;
		die unless $abiword_url;
		die unless $abiword_binary;
		
		$abiword_url =~ m/.*\/(.*)/;
		my $sn = $1;

		print "<h3>Branch: " . $sn . "</h3>\n";

		foreach $test ( @tests )
		{
			print "View report for <a href=\"./$test/index_$sn.html\">$test</a><br>\n";
		}
        }
}

foreach my $module_info ( @branches )
{
	my ($abiword_url, $abiword_binary) = @$module_info;
	die unless $abiword_url;
	die unless $abiword_binary;

	$abiword_url =~ m/.*\/(.*)/;
	my $sn = $1;

	if (!$html)
	{
		print "Branch: " . $sn . "\n";
	}
	
	# bootstrap the regression test suite
	system("./cleanup.pl", $abiword_url);
	system("./bootstrap.pl", $abiword_url);

	# execute the regression test suite
	&ExecTests($sn, $abiword_binary);
}

if ($html) {
	&HtmlFooter;
	close(STDOUT);
}

1;
