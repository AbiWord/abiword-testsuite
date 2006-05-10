#!/usr/bin/perl
eval `cat ../regression.conf`;
$abicommand = "../$prefix/bin/abiword";

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

	`sed -i -e 's/\<version.*\>/\<!-- version tag removed --\>/g' $f.pruned`; 
	`sed -i -e 's/\<history.*\>/\<!-- history tag removed --\>/g' $f.pruned`;
	`sed -i -e 's/\<\\/history.*\>/\\<!-- \\/history tag removed --\\>/g' $f.pruned`;
}

sub DiffTest
{
	my ($command, $command2, $file, $extension, $exp_extension) = @_;
	my $result = "pass";
	my $comment = "";
	
	my $errPath = $file . ".$extension.err.txt";
	my $rawPath;
	if ($exp_extension)
	{
	    $rawPath = "$file.exp.$extension.$exp_extension";
	}
	else
	{
	    $rawPath = "$file.imp.$extension.abw";
	}
	my $diffPath = "$rawPath.diff.txt";
	my $newRawPath;
	if ($exp_extension)
	{
	    $newRawPath = "$file.exp.$extension.new.$exp_extension";
	}
	else
	{
	    $newRawPath = "$rawPath.new.abw";
	}
	
	# generate a new raw output to compare with
	`$command $file`;
	if ($command2)
	{
		`mv $newRawPath $newRawPath.tmp`;
		`$command2 $newRawPath.tmp >& $newRawPath`;
		`rm $newRawPath.tmp`;
	}
	
	# HACK: check if there is a raw file with _some_ contents. If not, we assume to have been segfaulted
	my $err = "";
	my $diff = "";
	$newRaw=`cat $newRawPath`;
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
	my ($filePath, $destPath) = @_;
	
	my $vgCommand = "valgrind";
	my $vgVersionOutput = `valgrind --version`;
	if ($vgVersionOutput =~ /\-2.1/ || 
	$vgVersionOutput =~ /\-3.0/ ||
	$vgVersionOutput =~ /\-3.1/)
	{ 
		$vgCommand = "valgrind --tool=memcheck";
	}

	$vgPath = $filePath . '.vg.txt';
	$valgrind = 0;
	`export DISPLAY=; $vgCommand --num-callers=16 --leak-check=full $abicommand --to=$destPath $filePath >& $vgPath`;
	open VG, "$vgPath";
	my $vg_output;
	while (<VG>)
	{
		if (/^\=\=/) {
			$vgOutput .= $_;
			if (/definitely lost: [1-9]/ ||
			/ERROR SUMMARY: [1-9]/ ||
			/Invalid read of/) {
				$valgrind = 1;
			}
		}
	}
	close VG;
	
	`rm -f $vgPath`;
	`rm -f $destPath`;
	if ($valgrind)
	{
		open VG, ">$vgPath";
		print VG $vgOutput;
		close VG;
		$vgFailures++;
	}
	$vgOutput = "";
	
	if ($html) {
		($valgrind eq 0 ? DisplayCell($pass_colour, "passed") : DisplayCell($fail_colour, "failed <a href='$vgPath'>log<a>"));
	} else {
		print "! $file valgrind: " . ($valgrind eq "0" ? "pass" : "fail") . "\n";
	}
}

sub ImportRegTest 
{
	my $rawDiffFailures = 0;
	my $vgFailures = 0;
	
	my @docFormatList = ( "abw", "doc", "rtf", "txt", "wpd" );
	
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
			print "<td style='background-color: rgb(204, 204, 255);'><b>Valgrind Test</b></td>\n";
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
			my $filePath = $docFormat  . '/' . $file;
			
			if ($html)
			{
				print "<tr>\n";
				print "<td><a href='" . $filePath . "'>" . $file . "<\/a></td>\n";
			}
	
			# /////////////////////
			# DIFF REGRESSION TESTS
			# /////////////////////
		
			if (DiffTest("export DISPLAY=; $abicommand --to=$filePath.imp.raw.abw.new.abw", 0, $filePath, "raw", 0) eq "fail") {
				$rawDiffFailures++;
			}
			
			# ////////////////////////
			# VALGRIND REGRESSION TEST
			# ////////////////////////
			
			if ($do_vg)
			{
				ValgrindTest($filePath, "abw.tmp.vg");
			}
			else
			{
				if ($html)
				{
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
			
			`gprof $abicommand gmon.out > $filePath.gmon.txt`;
			DisplayCell("white", "<a href=' $filePath.gmon.txt'>profile<\/a>");
			
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
	my $rawDiffFailures = 0;
	my $vgFailures = 0;
	
	my @sourceList = ( "abw" );
	my @sinkList = ( "abw", "rtf", "txt");
	
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
				print "<td style='background-color: rgb(204, 204, 255);'><b>Valgrind Test</b></td>\n";
				print "<td style='background-color: rgb(204, 204, 255);'><b>Time/Profile</b></td>\n";
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
				my $sourcePath = $source  . '/' . $file;
				
				if ($html)
				{
					print "<tr>\n";
					print "<td><a href='" . $sourcePath . "'>" . $file . "<\/a></td>\n";
				}
		
				# /////////////////////
				# DIFF REGRESSION TESTS
				# /////////////////////
			
				if (DiffTest("export DISPLAY=; $abicommand --to=$sourcePath.exp.raw.new.$sink", 0, $sourcePath, "raw", $sink) eq "fail") {
					$rawDiffFailures++;
				}
				
				# ////////////////////////
				# VALGRIND REGRESSION TEST
				# ////////////////////////
				
				if ($do_vg)
				{
					ValgrindTest($sourcePath, $sourcePath . "vg" . $sink);
				}
				else
				{
					if ($html)
					{
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

				`gprof $abicommand gmon.out > $sourcePath.$sink.gmon.txt`;
				DisplayCell("white", "00:00:00 <a href=' $sourcePath.$sink.gmon.txt'>prof<\/a>");
				
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

# Main function
if ($html)
{
	&HtmlHeader;
}

&ImportRegTest;
if ($html)
{
	print "<br/>\n<br/>\n";
}
&ExportRegTest;

if ($html)
{
	&HtmlFooter;
}
