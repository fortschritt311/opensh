#!/usr/bin/perl -w

use strict;
use warnings;

# Rootverzeichnis setzen
sub rootdir {
	my $dir;
	$dir = '/opt/opensh';
	return $dir;
}

# devices.ini einlesen
sub devicescfg {
	my $rootdir = rootdir();
	my $cfgfile = "$rootdir/config/devices.ini";
	my $cfg = Config::IniFiles->new( -file => $cfgfile );
	return $cfg;
}

# uhc.ini einlesen
sub uhccfg {
        my $rootdir = rootdir();
        my $cfgfile = "$rootdir/config/uhc.ini";
        my $cfg = Config::IniFiles->new( -file => $cfgfile );
        return $cfg;
}
1;
