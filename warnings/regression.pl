#!/usr/bin/perl
eval `cat ../regression.conf`;

use Cwd;

sub DisplayCell
{
	my ($bgColor, $text) = @_;

	print "<td style='background-color: #$bgColor;'>$text</td>\n";
}

sub ExecUnitTest 
{
	$ROOT=getcwd;

	#TODO: login

	#TODO: move to config
	#TODO: don't ditch the tree every time
	`rm -rf .src && mkdir -p .src`;
	`rm -rf .local && mkdir -p .local`;

	# cvs update abiword (HEAD)
	`cd .src &&\
	 cvs -d $cvsroot -z3 co -r $abi_branch abi abidistfiles abiword-plugins &&\
	 cvs -d $cvsroot -z3 co -r wv-1-0-0-STABLE wv`;

	# build abiword
	`cd .src/abi &&\
	 ./autogen.sh &&\
	 CXXFLAGS="-pg -g" ./configure --prefix=$ROOT/.local --enable-gnome\
	 make 2>../../abiword_compilation_report.txt`;

	# build required abiword plugins
	`cd .src/abiword-plugins &&\
	 ./nextgen.sh &&\
	 CXXFLAGS="-pg -g" ./configure --prefix=$ROOT/.local &&\
	 make 2>../../abiword_plugins_compilation_report.txt`;


	# reporting
	my $abiword_compilation_report = `cat .src/abi/abiword_compilation_report.txt`;
	my $abiword_plugins_compilation_report = `cat .src/abiword-plugins/abiword_plugins_compilation_report.txt`;
	if ($html)
	{
		print "<b>Summary</b><br>\n";
		print "<table>\n";
		print "<tr>\n";
		print "<td>AbiWord</td>\n";
		if ($abiword_compilation_report)
		{
			DisplayCell($fail_colour, "failed <a href=\"abiword_compilation_report.txt\">log</a>");
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
			DisplayCell($fail_colour, "failed <a href=\"abiword_plugins_compilation_report.txt\">log</a>");
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
if ($html)
{
	&HtmlHeader;
}

&ExecUnitTest;

if ($html)
{
	&HtmlFooter;
}
