#!/usr/bin/perl
eval `cat ../regression.conf`;

sub DisplayCell
{
	my ($bgColor, $text) = @_;

	print "<td style='background-color: #$bgColor;'>$text</td>\n";
}

sub _DiffPruneAWML
{
	my ($f) = @_;

	`cp -f $f $f.pruned`;

	# apply a set of filters to remove the lines that screw up the diff test

	`sed -i -e 's/^\<version.*\>/\<!-- version tag removed --\>/g' $f.pruned`; 
	`sed -i -e 's/^\<history.*\>/\<!-- history tag removed --\>/g' $f.pruned`;
	`sed -i -e 's/^\\s*\<title\>.*abw.exp.raw.*html.*\<\\/title\>/\<!-- title tag removed --\>/g' $f.pruned`;
	`sed -i -e 's/^\<\\/history.*\>/\<!-- \\/history tag removed --\>/g' $f.pruned`;
	`sed -i -e 's/listid=".*"/\<!-- listid removed --\\>/g' $f.pruned`;
	`sed -i -e 's/table-sdh:[a-zA-Z0-9]*/\<!-- table-sdh removed --\>/g' $f.pruned`;
	`sed -i -e 's/shplid[0-9]*/\<!-- shplid removed --\>/g' $f.pruned`;
	`sed -i -e 's/version=".*"/\<!-- version removed --\>/g' $f.pruned`;
	`sed -i -e 's/fileref=".*" /\<!-- fileref removed --\>/g' $f.pruned`;
	`sed -i -e 's/raw.*.html_files/\<!-- html_files directory filtered --\>/g' $f.pruned`;
}

sub DiffTest
{
	my ($branch_dir, $basedir, $file, $exp_extension) = @_;

	my $result = "pass";
	my $comment = "";

	# setup a lot of directories	
	my $errPath = $basedir . '/' . $branch_dir . '/' . $file . ".raw.err.txt";
	
	my $rawPath;
	my $newRawPath;
	if ($exp_extension)
	{
		$rawPath = $basedir . '/' . $branch_dir . '/' . $file . ".exp.raw.$exp_extension";
		$newRawPath = $basedir . '/' . $branch_dir . '/' . $file . ".exp.raw.new.$exp_extension";
	}
	else
	{
		$rawPath = $basedir . '/' . $branch_dir . '/' . $file . ".imp.raw.abw";
		$newRawPath = $rawPath . ".new.abw";
	}

	my $diffPath = "$rawPath.diff.txt";
	
	# generate a new raw output to compare with
	`abiword --to=$newRawPath $basedir/$file`;
	
	# HACK: check if there is a raw file with _some_ contents. If not, we assume to have been segfaulted
	my $err = "";
	my $diff = "";
	$newRaw = `cat $newRawPath`;
	if ($newRaw eq "")
	{
		$err = "No output file: possible segmentation fault!";
		`echo $err > $errPath`;
	}
	
	if ($err ne "")
	{
		$result = "fail";
	}
	else
	{
		# remove the generated (empty) error file
		`rm -f $errPath`;
		
		# diff the stored raw data with the newly generated raw data
		&_DiffPruneAWML($rawPath);
		&_DiffPruneAWML($newRawPath);
		`diff -u $rawPath.pruned $newRawPath.pruned 1>$diffPath 2>$diffPath`;
		$diff=`cat $diffPath`;
		
		if ($diff ne "")
		{
			$result = "changed";
		}
		else
		{
			`rm -f $diffPath`;
		}
	}
	
	# remove the generated raw file
	`rm -f $newRawPath`;
	
	# DISPLAYING RESULTS
	if ($html)
	{
		my $bgColor;
		if ($diff eq "" && $err eq "")
		{
			$bgColor = $pass_colour;
		}
		elsif ($err ne "")
		{
			$bgColor = $fail_colour;
		}
		else
		{
			$bgColor = $warn_colour;
		}
		
		if ($err ne "" || $diff ne "")
		{
			$comment = " <a href='" . ($err ne "" ? $errPath : $diffPath) . "'>" . ($err ne "" ? "error" : "diff") . "<a>";
		}
		
		DisplayCell($bgColor, $result . $comment);
	}
	else
	{
		if ($err ne "" || $diff ne "") {
		$comment = ($err ne "" ? "(error: " : "(diff: ") . ($err ne "" ? $errPath : $diffPath) . ")";
		}
		print "! $file diff (using $command): $result $comment\n";
	}
	
	return $result;
}

sub ValgrindTest
{
	my ($branch, $basedir, $file, $exp_extension) = @_;
	
	$filePath = $basedir . '/' . $file;
	my $destPath;
	my $vgPath; 
	if ($exp_extension)
	{
		$destPath = "/tmp/abiword-testsuite/valgrind.tmp." . $exp_extension;
		$vgPath = $basedir . '/raw-' . $branch . '/' . $file . '.' . $exp_extension . '.vg.txt';
	}
	else
	{
		$destPath = "/tmp/abiword-testsuite/valgrind.tmp.abw";
		$vgPath = $basedir . '/raw-' . $branch . '/' . $file . '.vg.txt';
	}


	my $vgCommand = "valgrind";
	my $vgVersionOutput = `valgrind --version`;
	if ($vgVersionOutput =~ /\-2.1/ || 
	$vgVersionOutput =~ /\-3.0/ ||
	$vgVersionOutput =~ /\-3.1/)
	{ 
		$vgCommand = "valgrind --tool=memcheck";
	}

	$valgrind_error = 0;
	$valgrind_leak = 0;
	`$vgCommand $vg_options abiword --to=$destPath $filePath >& $vgPath`;
	open VG, "$vgPath";
	my $vg_output;
	while (<VG>)
	{
		if (/^\=\=/) {
			$vgOutput .= $_;
			if (/ERROR SUMMARY: [1-9]/ ||
			    /Invalid read of/) {
				$valgrind_error = 1;
			}
			if (/definitely lost: [1-9]/) {
				$valgrind_leak = 1;
			}
		}
	}
	close VG;
	
	`rm -f $vgPath`;
	`rm -f $destPath`;
	if ($valgrind_error || $valgrind_leak)
	{
		open VG, ">$vgPath";
		print VG $vgOutput;
		close VG;
		$vgFailures++;
	}
	$vgOutput = "";
	
	if ($html)
	{
		($valgrind_error eq 0 ? DisplayCell($pass_colour, "passed") : DisplayCell($fail_colour, "failed <a href='$vgPath'>log<a>"));
		($valgrind_leak eq 0 ? DisplayCell($pass_colour, "passed") : DisplayCell($fail_colour, "failed <a href='$vgPath'>log<a>"));
	}
	else
	{
		print "! $file valgrind errors: " . ($valgrind_error eq "0" ? "pass" : "fail") . "\n";
		print "! $file valgrind leaks: " . ($valgrind_leak eq "0" ? "pass" : "fail") . "\n";
	}
}

sub ImportRegTest 
{
	my ($branch) = @_;

	my $rawDiffFailures = 0;
	my $vgFailures = 0;
	
	my @docFormatList = ( "abw", "doc", "rtf", "odt", "txt", "wpd", "xml", "wml", "opml" );
	
	if ($html)
	{
		print "<b>Test 1: Document Import</b><br/><br/>\n";
	}	
	
	my $docFormat;
	foreach $docFormat ( @docFormatList )
	{
		if ($html)
		{
			print "<i>Regression testing document import of " . $docFormat . " documents</i><br>\n";
			print "<table>\n";
			print "<tr>\n";
			print "<td style='background-color: rgb(204, 204, 255);' width='200px'><b>File</b></td>\n";
			print "<td style='background-color: rgb(204, 204, 255);'><b>Raw Diff Test</b></td>\n";
			print "<td style='background-color: rgb(204, 204, 255);' colspan=\"2\"><b>Valgrind Test [errors | leaks]</b></td>\n";
			print "<td style='background-color: rgb(204, 204, 255);'><b>Profile</b></td>\n";
			print "</tr>\n";
		}
		else
		{
			print "Regression testing document import of " . $docFormat . " documents\n";
		}
		
		my $regrInput = $docFormat . '/regression.in';
		
		my @fileList = split(/\n/, `cat $regrInput`);
		foreach $file ( @fileList )
		{
			if ($file =~ /^\s*#/ )
			{
				next;
			}
				
			my $filePath = $docFormat  . '/' . $file;
			
			if ($html)
			{
				print "<tr>\n";
				print "<td><a href='" . $filePath . "'>" . $file . "<\/a></td>\n";
			}
	
			# /////////////////////
			# DIFF REGRESSION TESTS
			# /////////////////////
		
			if ($do_diff)
			{
				if (DiffTest("raw-" . $branch, $docFormat, $file, 0) eq "fail")
				{
					$rawDiffFailures++;
				}
			}
			else
			{
				if ($html)
				{
					DisplayCell($skip_colour, "skipped");
				}
				else
				{					
					print "! $file raw diff: skipped\n";
				}
			}
			
			# ////////////////////////
			# VALGRIND REGRESSION TEST
			# ////////////////////////
			
			if ($do_vg)
			{
				ValgrindTest($branch, $docFormat, $file, 0);
			}
			else
			{
				if ($html)
				{
					DisplayCell($skip_colour, "skipped");
					DisplayCell($skip_colour, "skipped");
				}
				else
				{					
					print "! $file valgrind: skipped\n";
				}
			}
			
			# ////////////////////////
			# PROFILE
			# ////////////////////////			
			
			if ($do_gprof)
			{
				$gprofOutPath = $docFormat  . '/raw-' . $branch . '/' . $file . '.gmon.txt';
				$actual_abiword = `which abiword`;
				`gprof $actual_abiword gmon.out > $gprofOutPath`;
				DisplayCell("white", "<a href='$gprofOutPath'>profile<\/a>");
			}
			else
			{
				if ($html)
				{
					DisplayCell($skip_colour, "skipped");
				}
				else
				{					
					print "! $file gprof: skipped\n";
				}
			}
			
			if ($html)
			{
				print "</tr>\n";
			}				
		}

		if ($html)
		{
			print "</table><br>\n";
		}	
	}
    
	if ($html)
	{
		print "<b>Summary</b><br>\n";
		print "Regression test found " . $rawDiffFailures . " raw diff failure(s)<br>\n";
		if ($do_vg)
		{
			print "Regression test found " . $vgFailures . " valgrind failure(s)<br>\n";
		}
		else
		{
			print "Valgrind test skipped<br>\n";
		}
	
	}
	else
	{
		print "\nSummary\n";
		print "Regression test found " . $rawDiffFailures . " raw diff failure(s)\n";
		if ($do_vg)
		{
			print "Regression test found " . $vgFailures . " valgrind failure(s)\n";
		}
		else
		{
			print "Valgrind test skipped\n";
		}
	}
}

sub ExportRegTest 
{
	my ($branch) = @_;

	my $rawDiffFailures = 0;
	my $vgFailures = 0;
	
	my @sourceList = ( "abw" );
	my @sinkList = ( "abw", "rtf", "txt", "xml", "html", "odt");
	
	my $source;
	my $sink;
	
	if ($html)
	{
		print "<b>Test 2: Document Export</b><br/><br/>\n";
	}

	foreach $source ( @sourceList )
	{
		foreach $sink ( @sinkList )
		{
			if ($html)
			{
				print "<i>Regression testing document export of .".$source." to .".$sink."</i><br>\n";
				print "<table>\n";
				print "<tr>\n";
				print "<td style='background-color: rgb(204, 204, 255);' width='200px'><b>File</b></td>\n";
				print "<td style='background-color: rgb(204, 204, 255);'><b>Raw Diff Test</b></td>\n";
				print "<td style='background-color: rgb(204, 204, 255);' colspan=\"2\"><b>Valgrind Test [errors | leaks]</b></td>\n";
				print "<td style='background-color: rgb(204, 204, 255);'><b>Profile</b></td>\n";
				print "</tr>\n";
			}
			else
			{
				print "Regression testing document export of .".$source." to .".$sink."\n";
			}
			
			my $regrInput = $source . '/regression.in';
			
			my @fileList = split(/\n/, `cat $regrInput`);
			foreach $file ( @fileList )
			{
				if ($file =~ /^\s*#/ )
				{
					next;
				}
				my $sourcePath = $source  . '/' . $file;
				
				if ($html)
				{
					print "<tr>\n";
					print "<td><a href='" . $sourcePath . "'>" . $file . "<\/a></td>\n";
				}
		
				# /////////////////////
				# DIFF REGRESSION TESTS
				# /////////////////////
	
				if ($do_diff)
				{		
					if (DiffTest("raw-" . $branch, $source, $file, $sink) eq "fail")
					{
						$rawDiffFailures++;
					}
				}
				else
				{
					if ($html)
					{
						DisplayCell($skip_colour, "skipped");
					}
					else
					{					
						print "! $file raw diff: skipped\n";
					}
				}
				
				# ////////////////////////
				# VALGRIND REGRESSION TEST
				# ////////////////////////
				
				if ($do_vg)
				{
					ValgrindTest($branch, $source, $file, $sink);
				}
				else
				{
					if ($html)
					{
						DisplayCell($skip_colour, "skipped");
						DisplayCell($skip_colour, "skipped");						
					}
					else
					{					
						print "! $file valgrind: skipped\n";
					}
				}
			
				# ////////////////////////
				# PROFILE
				# ////////////////////////			

				if ($do_gprof)
				{
                                	$gprofOutPath = $source  . '/raw-' . $branch . '/' . $file . '.' . $sink . '.gmon.txt';
					$actual_abiword = `which abiword`;
	                                `gprof $actual_abiword gmon.out > $gprofOutPath`;
        	                        DisplayCell("white", "<a href='$gprofOutPath'>profile<\/a>");

					if ($html)
					{
						print "</tr>\n";
					}
				}
				else
				{
					if ($html)
					{
						DisplayCell($skip_colour, "skipped");
					}
					else
					{					
						print "! $file gprof: skipped\n";
					}
				}
			}
	
			if ($html)
			{
				print "</table><br>\n";
			}	
		}
	}
    
	if ($html)
	{
		print "<b>Summary</b><br>\n";
		print "Regression test found " . $rawDiffFailures . " raw diff failure(s)<br>\n";
		if ($do_vg)
		{
			print "Regression test found " . $vgFailures . " valgrind failure(s)<br>\n";
		}
		else
		{
			print "Valgrind test skipped<br>\n";
		}
	
	}
	else
	{
		print "\nSummary\n";
		print "Regression test found " . $rawDiffFailures . " raw diff failure(s)\n";
		if ($do_vg)
		{
			print "Regression test found " . $vgFailures . " valgrind failure(s)\n";
		}
		else
		{
			print "Valgrind test skipped\n";
		}
	}
}

sub HtmlHeader {
	print "<html>\n<head>\n</head>\n<body>\n";
	print "<h2>AbiWord TestSuite: Import / Export Results</h2>\n";
}

sub HtmlFooter {
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

if ($#ARGV+1 != 1)
{
	print "Usage: bootstrap.pl <branchname>\n";
	die;
}

$branch = $ARGV[0];

if ($html)
{
	&HtmlHeader;
}

&ImportRegTest($branch);
if ($html)
{
	print "<br/>\n<br/>\n";
}
&ExportRegTest($branch);

if ($html)
{
	&HtmlFooter;
}
