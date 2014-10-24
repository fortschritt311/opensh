#!/usr/bin/perl -w

use strict;
use warnings;
use Config::IniFiles;
use File::Cache;
use RPC::XML;
use RPC::XML::Client;

# Timestamp erzeugen
sub timestamp {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    my $timestamp = sprintf ( "%04d-%02d-%02d %02d:%02d:%02d",
                                   $year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $timestamp;
}


# Wärmebedarf Heizkreis 1
sub waermebedarf_hk1 {

# Konfigurationsdatei einlesen
my $cfg = Config::IniFiles->new( -file => "/opt/uhc2/uhc2.ini" );

# Verbindung mit CCU herstellen
my $bidcos = RPC::XML::Client->new($cfg->val( 'main', 'bidcos' ));
my $wired = RPC::XML::Client->new($cfg->val( 'main', 'wired' ));

# Öffnungszustand der Ventilantriebe auslesen
my $va_flur = $bidcos->simple_request('getValue','HEQ0113870:1' , 'VALVE_STATE');
my $va_kz = $bidcos->simple_request('getValue','KEQ1041117:4' , 'VALVE_STATE');
my $va_kz2 = $bidcos->simple_request('getValue','KEQ1040364:4' , 'VALVE_STATE');

# Betriebszustand und Betriebsmeldung der Heizkreispumpe auslesen
my $pumpe_hk1_extoff = $wired->simple_request('getValue', $cfg->val( 'hk1' , 'pumpe_hk1_extoff' ), 'STATE');
my $pumpe_hk1_ssm = $wired->simple_request('getValue', $cfg->val( 'hk1' , 'pumpe_hk1_ssm' ), 'STATE');
print "Pumpe Hk1 $pumpe_hk1_extoff\n";

# Wärmebedarf berechnen
my $wb = ($va_flur + $va_kz + $va_kz2);

# Heizkreispumpe nach Bedarf schalten
if (($wb <= 20) && ($pumpe_hk1_extoff == 1)) {
$wired->simple_request('setValue', $cfg->val( 'hk1','pumpe_hk1_extoff'),'STATE', 'false');
}
if (($wb >= 30) && ($pumpe_hk1_extoff == 0) && ($pumpe_hk1_ssm == 0)) {
$wired->simple_request('setValue', $cfg->val( 'hk1','pumpe_hk1_extoff'),'STATE', 'true');
}
}

sub vorlauf_hk1 {

}

1;
