#!/usr/bin/perl
require "../regression.conf";

sub DisplayCell
{
	my ($bgColor, $text) = @_;

	print "<td style='background-color: #$bgColor;'>$text</td>\n";
}

sub ExecUnitTest 
{
	my ($sn) = @_;

	# reporting; just reuse the compilation reports from the bootstrap process
	$abi_log = "../logs/abiword_compilation_report_$sn.txt";
	$abi_plugin_log = "../logs/abiword_plugins_compilation_report_$sn.txt";

	$abiword_compilation_report = `cat $abi_log`;
	$abiword_plugins_compilation_report = `cat $abi_plugin_log`;
	if ($html)
	{
		print "<b>Summary</b><br>\n";
		print "<table>\n";
		print "<tr>\n";
		print "<td>AbiWord</td>\n";
		if ($abiword_compilation_report)
		{
			DisplayCell($fail_colour, "failed <a href=\"$abi_log\">log</a>");
		}
		else
		{
			DisplayCell($pass_colour, "success");
		}
		print "</tr>\n";
		print "<tr>\n";
		print "<td>AbiWord Plugins</td>\n";
		if ($abiword__plugins_compilation_report)
		{
			DisplayCell($fail_colour, "failed <a href=\"$abi_plugin_log\">log</a>");
		}
		else
		{
			DisplayCell($pass_colour, "success");
		}
		print "</tr>\n";
		print "</table>\n";
	}
	else
	{
		print "\nSummary\n";
		if ($abiword_compilation_report)
		{
			print "AbiWord: failed\n";
		}
		else
		{
			print "AbiWord: success\n";
		}
		if ($abiword_plugins_compilation_report)
		{
			print "AbiWord Plugins: failed\n";
		}
		else
		{
			print "AbiWord Plugins: success\n";
		}
	}
}

sub HtmlHeader {
	print "<html>\n<head>\n</head>\n<body>\n";
	print "<h2>AbiWord TestSuite: Compilation Warning Test Results</h2>\n";
}

sub HtmlFooter {
	print "</body>\n</html>\n";
}

# Main function
$#ARGV+1 == 2 || die "Usage: regression.pl <branchname> <abiword binary name>\n";

if ($html)
{
	&HtmlHeader;
}

my $sn = $ARGV[0];
die unless $sn;
&ExecUnitTest($sn);

if ($html)
{
	&HtmlFooter;
}
