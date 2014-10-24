#!/usr/bin/perl -w

use strict;
use warnings;

##### Interface OWFS #####
sub owfs {
#Root auslesen
my $bus_root = OW::get('');
my @bus_root = split /,/, $bus_root;
chop @bus_root;
my $no = ("alarm|simultaneous|structure|statistics|system|settings|uncached|bus.0");
my @devices = grep {! /$no/} @bus_root;

my $client = RPC::XML::Client->new('http://localhost:5544');

foreach(@devices){
        my @datapoints = split /,/, OW::get($_);
                if(grep {$_ eq "temperature"}@datapoints) {
                        my $temperature = OW::get("$_/temperature10");
#                       $tempsensors{$_} = $temperature;
                        my $req = RPC::XML::request->new('event',RPC::XML::string->new('owfs'),RPC::XML::string->new($_),RPC::XML::string->new('temperature'),RPC::XML::double->new($temperature));
                        $client->send_request($req);

                }
}
}

##### Interface Homematic CCU anmelden #####
sub ccu_start {
# Homematic Wired RS485 Anmeldung
my $wired = RPC::XML::Client->new('http://192.168.123.119:2000');
$wired->simple_request('init','http://192.168.123.117:5544','wired');

# Homematic BidCos Anmeldung
my $rfd = RPC::XML::Client->new("http://192.168.123.119:2001");
$rfd->simple_request("init","http://192.168.123.117:5544",'bidcos');

# Homematic System Anmeldung
my $sys = RPC::XML::Client->new('http://192.168.123.119:2002');
$sys->simple_request('init','http://192.168.123.117:5544','system');
}

##### Interface Homematic CCU abmelden #####
sub ccu_stop {
# Homematic Wired RS485 Anmeldung
my $wired = RPC::XML::Client->new('http://192.168.123.119:2000');
$wired->simple_request('init','http://192.168.123.117:5544','');

# Homematic BidCos Anmeldung
my $rfd = RPC::XML::Client->new("http://192.168.123.119:2001");
$rfd->simple_request("init","http://192.168.123.117:5544",'');

# Homematic System Anmeldung
my $sys = RPC::XML::Client->new('http://192.168.123.119:2002');
$sys->simple_request('init','http://192.168.123.117:5544','');
}

##### XML::RPC Server starten #####
sub server_start {
system('/opt/uhc2/uhc2_server&');
}

##### XML::RPC Server beenden #####
sub server_stop {
        my $pid = `ps -ef | grep uhc2_server | grep -v grep | awk '{print \$2}'`;
        system("kill -9 $pid");
}

1;
