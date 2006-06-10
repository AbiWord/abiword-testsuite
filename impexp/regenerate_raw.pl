#!/usr/bin/perl
eval `cat ../regression.conf`;
$abicommand = "../$prefix/bin/abiword";

sub GenRaw {
	my ($branch) = @_;

	# TODO: Move this to regression.conf
	$importDirs = 'abw rtf txt odt doc wpd';

	@subDirList = split(/\s+/, $importDirs);

	foreach $subDir ( @subDirList )
	{
		# remove all diff files, since they are possible outdated now
		$diffs = $subDir . "/" . $branch . '/*.raw.*';
		`rm -f $diffs`;
    
		$regrInput = $subDir . '/regression.in';
	        $FL = `cat $regrInput`;

		@fileList = split(/\n/, $FL);
	        foreach $file ( @fileList )
		{
			$filePath = $subDir  . '/' . $file;
			$fileOutPath = $subDir  . '/' . "raw-" . $branch . "/" . $file . ".imp.raw.abw";
			`$abicommand --to=$fileOutPath $filePath`;
		}
	    }

	@sourceList = ( "abw" );
	# TODO: Move this to regression.conf
	@sinkList = ( "abw", "rtf", "txt", "xml", "html");

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
				$fileOutPath = $source  . '/' . "raw-" . $branch . "/" . $file . ".exp.raw." .$sink;
				`$abicommand --to=$fileOutPath $filePath`;
			}
		}
	}
}

# Main function

my $branch;
foreach $branch ( @branches )
{
	`cd .. ; ./cleanup.pl $branch ; ./bootstrap.pl $branch`;
	&GenRaw($branch);
}

1;
