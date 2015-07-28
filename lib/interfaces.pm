#!/usr/bin/perl -w

use strict;
use warnings;
use rlib ('/lib');
use config;
use modules;

# Root Verzeichnis setzen
my $rootdir = rootdir();
# Konfigurationsdatei einlesen
my $cfg = devicescfg();

##### Interface OWFS #####
sub owfs {
	#Root auslesen
	my $bus_root = OW::get('');
	my @bus_root = split /,/, $bus_root;
	chop @bus_root;
	my $no = ("alarm|simultaneous|structure|statistics|system|settings|uncached|bus.0");
	my @devices = grep {! /$no/} @bus_root;

	#my $ip = $cfg->val( 'bmsr', 'ip' );
	#my $port = $cfg->val( 'bmsr', 'port' );
	#my $client = RPC::XML::Client->new("$ip:$port");

	foreach(@devices){
        	my @datapoints = split /,/, OW::get($_);
                	if(grep {$_ eq "temperature"}@datapoints) {
                        	my $temperature = OW::get("$_/temperature10");
                        	sql_setvalue('owfs', $_, 'temperature', $temperature);
				#my $req = RPC::XML::request->new('event',RPC::XML::string->new('owfs'),RPC::XML::string->new($_),RPC::XML::string->new('temperature'),RPC::XML::double->new($temperature));
                        	#$client->send_request($req);
			}
	}
}

##### Interface USV #####
sub usv {
   	my @data= `apcaccess`;
   	my $dp = ("^BATTV|^TIMELEFT|^LOADPCT|^ITEMP|^BCHARGE|^LINEV|^LINEFREQ");
	my @use = grep { /$dp/} @data;

	#my $ip = $cfg->val( 'bmsr', 'ip' );
   	#my $port = $cfg->val( 'bmsr', 'port' );
	#my $client = RPC::XML::Client->new("$ip:$port");

		foreach(@use) {		 
			my ($dp,$value)=split(/:[ ]*(\d+\.*\d+).*/);
			sql_setvalue('usv', 'APC Smart UPS 1500', $dp, $value);
			#my $req = RPC::XML::request->new('event',RPC::XML::string->new('usv'),RPC::XML::string->new('APC Smart UPS 1500'),RPC::XML::string->new($dp),RPC::XML::double->new($value));
                        #$client->send_request($req);
		} 
}

##### Interface rx100s5 Server #####
sub server {
	my @data= `sensors`;
	my $dp = ("^Core 0|^Core 1");
   	my @use = grep { /$dp/} @data;
	
	#my $ip = $cfg->val( 'bmsr', 'ip' );
   	#my $port = $cfg->val( 'bmsr', 'port' );
   	#my $client = RPC::XML::Client->new("$ip:$port");

		foreach(@use) {
			my ($address,$value)=split(/[:° ][C ][+\s\/]+/);
			sql_setvalue('rx100s5', $address, 'temperature', $value);
			#my $req = RPC::XML::request->new('event',RPC::XML::string->new('rx100s5'),RPC::XML::string->new($address),RPC::XML::string->new('temperature'),RPC::XML::double->new($value));
        		#$client->send_request($req);
		}
}

##### Interface Viessmann Vitronic 150KB1 <-> Vcontrol #####
sub vcontrol {
	#my $bmsr_ip = $cfg->val( 'bmsr', 'ip' );
   	#my $bmsr_port = $cfg->val( 'bmsr', 'port' );
   	#my $client = RPC::XML::Client->new("$bmsr_ip:$bmsr_port");

	my @dp = ("getTempKist","getTempKsoll","getTempKOffset","getTempWWsoll","getBrennerStarts","getBrennerStufe","getBrennerStunden1","getStatusStoerung","getBetriebArt");

		foreach(@dp) {
			RESTART:
                        my $value = xmlrpc_getvalue('vcontrol','',$_);
                        if ($value == "128.5") { goto RESTART;} 
			sql_setvalue('vcontrol', 'Vitronic 150KB1', $_, $value);
			#my $req = RPC::XML::request->new('event',RPC::XML::string->new('vcontrol'),RPC::XML::string->new('Vitronic 150KB1'),RPC::XML::string->new($_),RPC::XML::double->new($value));
                	#$client->send_request($req);
		}
}

##### Interface Homematic CCU anmelden #####
sub ccu_start {
	my $bmsr_ip = $cfg->val( 'bmsr', 'ip' );
   	my $bmsr_port = $cfg->val( 'bmsr', 'port' );
	
	# Homematic Wired RS485 Anmeldung
	my $wired_ip = $cfg->val( 'wired', 'ip' );
   	my $wired_port = $cfg->val( 'wired', 'port' );
	my $wired = RPC::XML::Client->new("$wired_ip:$wired_port");
	$wired->simple_request('init',"$bmsr_ip:$bmsr_port",'wired');
		
	# Homematic BidCos Anmeldung
	my $bidcos_ip = $cfg->val( 'bidcos', 'ip' );
   	my $bidcos_port = $cfg->val( 'bidcos', 'port' );
	my $rfd = RPC::XML::Client->new("$bidcos_ip:$bidcos_port");
	$rfd->simple_request('init',"$bmsr_ip:$bmsr_port",'bidcos');
	
	# Homematic System Anmeldung
	my $system_ip = $cfg->val( 'system', 'ip' );
   	my $system_port = $cfg->val( 'system', 'port' );
	my $sys = RPC::XML::Client->new("$system_ip:$system_port");
	$sys->simple_request('init',"$bmsr_ip:$bmsr_port",'system');
}

##### Interface Homematic CCU abmelden #####
sub ccu_stop {
	my $bmsr_ip = $cfg->val( 'bmsr', 'ip' );
   	my $bmsr_port = $cfg->val( 'bmsr', 'port' );
   
	# Homematic Wired RS485 Abmeldung
	my $wired_ip = $cfg->val( 'wired', 'ip' );
   	my $wired_port = $cfg->val( 'wired', 'port' );
	my $wired = RPC::XML::Client->new("$wired_ip:$wired_port");
	$wired->simple_request('init',"$bmsr_ip:$bmsr_port",'');
	
	# Homematic BidCos Abmeldung
	my $bidcos_ip = $cfg->val( 'bidcos', 'ip' );
   	my $bidcos_port = $cfg->val( 'bidcos', 'port' );
	my $rfd = RPC::XML::Client->new("$bidcos_ip:$bidcos_port");
	$rfd->simple_request('init',"$bmsr_ip:$bmsr_port",'');
	
	# Homematic System Abmeldung
	my $system_ip = $cfg->val( 'system', 'ip' );
   	my $system_port = $cfg->val( 'system', 'port' );
	my $sys = RPC::XML::Client->new("$system_ip:$system_port");
	$sys->simple_request('init',"$bmsr_ip:$bmsr_port",'');
}

##### XML::RPC Server #####
sub server_start {
	system("$rootdir/bmsr_server&");
}
sub server_stop {
        my $pid = `ps -ef | grep bmsr_server | grep -v grep | awk '{print \$2}'`;
        system("kill -9 $pid");
}

##### Vorlaufsolltemperatur #####
sub vs_start {
	system("$rootdir/uhc/uhc2_vs&");
}
sub vs_stop {
        my $pid = `ps -ef | grep uhc2_vs | grep -v grep | awk '{print \$2}'`;
        system("kill -9 $pid");
}

##### Zirkulationspumpe #####
sub zp_start {
        system("$rootdir/uhc/uhc2_zp&");
}
sub zp_stop {
        my $pid = `ps -ef | grep uhc2_zp | grep -v grep | awk '{print \$2}'`;
        system("kill -9 $pid");
}

##### Brauchwasserpumpe #####
sub bw_start {
        system("$rootdir/uhc/uhc2_bw&");
}
sub bw_stop {
        my $pid = `ps -ef | grep uhc2_bw | grep -v grep | awk '{print \$2}'`;
        system("kill -9 $pid");
}

##### Mischer Heizkreis 1 #####
sub hk1_start {
        system("$rootdir/uhc/uhc2_hk1&");
}
sub hk1_stop {
        my $pid = `ps -ef | grep uhc2_hk1 | grep -v grep | awk '{print \$2}'`;
        system("kill -9 $pid");
}

##### Mischer Heizkreis 2 #####
sub hk2_start {
        system("$rootdir/uhc/uhc2_hk2&");
}
sub hk2_stop {
        my $pid = `ps -ef | grep uhc2_hk2 | grep -v grep | awk '{print \$2}'`;
        system("kill -9 $pid");
}

##### Ladepumpe #####
sub lp_start {
        system("$rootdir/uhc/uhc2_lp&");
}
sub lp_stop {
        my $pid = `ps -ef | grep uhc2_lp | grep -v grep | awk '{print \$2}'`;
        system("kill -9 $pid");
}
1;
