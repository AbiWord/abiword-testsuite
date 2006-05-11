#!/usr/bin/perl
eval `cat ../regression.conf`;
$abicommand = "../$prefix/bin/abiword";

sub GenRaw {

	$importDirs = 'abw rtf txt odt doc wpd';

	@subDirList = split(/\s+/, $importDirs);

	foreach $subDir ( @subDirList )
	{
		# remove all diff files, since they are possible outdated now
		$diffs = $subDir . '/*.diff';
		`rm -f $diffs`;
    
		$regrInput = $subDir . '/regression.in';
	        $FL = `cat $regrInput`;

		@fileList = split(/\n/, $FL);
	        foreach $file ( @fileList )
		{
		    $filePath = $subDir  . '/' . $file;
		    `export DISPLAY=; $abicommand --to=$filePath.imp.raw.abw $filePath`;
		}
	    }

	@sourceList = ( "abw" );
	@sinkList = ( "abw", "rtf", "txt");

	my $source;
	my $sink;

	foreach $source ( @sourceList )
	{
	    foreach $sink ( @sinkList )
	    {
		    $regrInput = $source . '/regression.in';
		    $FL = `cat $regrInput`;

		    @fileList = split(/\n/, $FL);
		    foreach $file ( @fileList )
		    {
			    $filePath = $source . '/' . $file;
			    `export DISPLAY=; $abicommand --to=$filePath.exp.raw.$sink $filePath`;
		    }
	    }
	}
}

# Main function
&GenRaw;

1;
