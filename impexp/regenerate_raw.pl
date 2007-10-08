#!/usr/bin/perl
require "../regression.conf";

sub GenRaw {
	my ($abiword_binary, $branch) = @_;
	die unless $abiword_binary;
	die unless $branch;

	# TODO: Move this to regression.conf
	$importDirs = 'abw rtf txt odt doc wpd xml opml';

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
			`$abiword_binary --to=abw --to-name=$fileOutPath $filePath`;
		}
	    }

	@sourceList = ( "abw" );
	# TODO: Move this to regression.conf
	@sinkList = ( "abw", "rtf", "txt", "xml", "html", "odt", "wml" );

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
				`$abiword_binary --to=$sink --to-name=$fileOutPath $filePath`;
			}
		}
	}
}

#
# Main function
#

#
# Setup environment variables
#

#ugly
$ENV{DISPLAY} = ""; # we don't require a display to run
$ENV{LD_LIBRARY_PATH} = "$root/$prefix/lib";
$ENV{PKG_CONFIG_PATH} = "$root/$prefix/lib/pkgconfig";
$ENV{G_SLICE} = "always-malloc";
$ENV{PATH} = "$root/../$prefix/bin:" . $ENV{PATH}; # hack hack hack

foreach my $module_info ( @branches )
{
	my ($abiword_url, $abiword_plugins_url, $abiword_binary) = @$module_info;
	die unless $abiword_url;
	die unless $abiword_plugins_url;
	die unless $abiword_binary;

	$abiword_url =~ m/.*\/(.*)/;
	my $sn = $1;

	# bootstrap the regression test suite
	system("cd .. && ./cleanup.pl $abiword_url");
	system("cd .. && ./bootstrap.pl $abiword_url $abiword_plugins_url");

	&GenRaw($abiword_binary, $sn);
}

1;
