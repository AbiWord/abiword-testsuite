#!/usr/bin/perl
eval `cat regression.conf`;

# list of directories containing test sets
my @subDirList = ( "impexp", "warning" );

sub ExecTests
{
    foreach $subDir ( @subDirList ) {
	if ($html) {
	    print "View report for <a href=\"./$subDir/index.html\">$subDir</a><br>\n";
	}

	if ($html) {
    	    `cd $subDir; ./regression.pl >index.html`;
	}
	else {
    	    `cd $subDir; ./regression.pl 2>/dev/null`;
	}
	
	print $output;
    }
}

sub HtmlHeader {
    print "<html>\n<head>\n</head>\n<body>\n";
    print "<h2>AbiWord TestSuite</h2>\n";
}

sub HtmlFooter {
    print "</body>\n</html>\n";
}

#
# Main function
#
if ($html) {
    open(STDOUT, ">index.html");
    &HtmlHeader;
}

# bootstrap the regression test suite
`./bootstrap.pl`;

# execute the tests
&ExecTests;

if ($html) {
    &HtmlFooter;
}

1;
