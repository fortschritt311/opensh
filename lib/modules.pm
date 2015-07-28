#!/usr/bin/perl -w

use strict;
use warnings;
use Config::IniFiles;
use RPC::XML;
use RPC::XML::Client;
use DBI;
use Time::Format qw(%time);
use rlib ('/lib');
use config;

# Konfigurationsdatei einlesen
my $cfg = devicescfg();

# Datenbankanbindung
sub datenbank {

	# Verbindung zu MySQL Datenbank herstellen
	my $database = $cfg->val( 'db', 'database' );
	my $host = $cfg->val( 'db', 'host' );
	my $port = $cfg->val( 'db', 'port' );
	my $user = $cfg->val( 'db', 'user' );
	my $pw = $cfg->val( 'db', 'pw' );
	my $dsn = "dbi:mysql:$database:$host:$port";
	my $dbh = DBI->connect($dsn,$user,$pw);{ RaiseError => 1} or die $dbh->errstr();
	return ($database, $dbh);
}

# Timestamp erzeugen
sub timestamp {

        my ($sec,$min,$hour,$mday,$mon,$year)=localtime;
        my $timestamp = sprintf ( "%04d-%02d-%02d %02d:%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec);
        return $timestamp;
}

# SQL : Wert auslesen
sub sql_getvalue {
   	my ($interface, $address, $dp) = @_;

	# Verbindung zur MySQL-Datenbank herstellen
	my $dbh = datenbank();

        my $value_search = $dbh->prepare("SELECT `Value` FROM `device_$interface` WHERE `Address` = '$address' AND `Datapoint` = '$dp'");
        $value_search->execute();
        my $value = $value_search->fetchrow_array();
	return $value;
}

# SQL : Wert setzen und loggen
sub sql_setvalue {
	my ($interface, $address, $dp, $value) = @_;       

	#Verbindung zur Datenbank herstellen
        my ($database, $dbh) = datenbank();

	# Timestamp erzeugen
        my $timestamp = timestamp();

        # Werte in device_log Tabelle begrenzen, Werte die älter als $interval Minuten werden gelöscht
        my $interval = $cfg->val( 'log', 'interval' );
	$dbh->do("DELETE FROM `$database`.`device_".$interface."_log` WHERE `Address` = '$address' AND `Datapoint` = '$dp' AND `LastUpdate` < NOW() - INTERVAL $interval MINUTE");
	
	# Werte in device_log Tablle setzen
        $dbh->do("INSERT INTO `$database`.`device_".$interface."_log` (Interface,Address,DataPoint,Value,LastUpdate ) 
                  VALUES ('$interface','$address','$dp','$value','$timestamp')");

	# Werte in device Tabelle suchen
        my $current = $dbh->prepare("SELECT * FROM `device_$interface` WHERE `Address` = '$address' AND `Datapoint` = '$dp'");
        $current->execute();
        my $currentstate = $current->fetchrow_hashref();
        # Werte in device Tabelle aktualisieren
        if ($currentstate) {
        my $update = $dbh->prepare("UPDATE `device_$interface` SET `Value` = '$value', `LastUpdate`= '$timestamp' WHERE `Address` = '$address' AND `Datapoint` = '$dp'");
        $update->execute();
        } else {
        $dbh->do("INSERT INTO `$database`.`device_$interface` (Interface,Address,DataPoint,Value,LastUpdate ) 
                  VALUES ('$interface','$address','$dp','$value','$timestamp')");
        }
}

# RPC::XML Werte lesen und setzen
# Bsp: xmlrpc_setvalue('wired','JEQ123456','LEVEL','0.56');
sub xmlrpc_getvalue {
	my ($interface, $address, $dp) = @_; 
	# RS485 
	if ($interface eq 'wired') {
	 my $wired_ip = $cfg->val( 'wired', 'ip' );
   	 my $wired_port = $cfg->val( 'wired', 'port' );
	 my $client = RPC::XML::Client->new("$wired_ip:$wired_port");
	 $client->simple_request('getValue', $address, $dp);
	}
	# BidCos
   	if ($interface eq 'bidcos') {
   	 my $bidcos_ip = $cfg->val( 'bidcos', 'ip' );
   	 my $bidcos_port = $cfg->val( 'bidcos', 'port' );
         my $client = RPC::XML::Client->new("$bidcos_ip:$bidcos_port");
         $client->simple_request('getValue', $address, $dp);
        }
	# Vcontrol
	if ($interface eq 'vcontrol') {
	 my $vcontrol_ip = $cfg->val( 'vcontrol', 'ip' );
   	 my $vcontrol_port = $cfg->val( 'vcontrol', 'port' );
         my $client = RPC::XML::Client->new("$vcontrol_ip:$vcontrol_port");
         $client->simple_request('getValue', $dp);
        }
}
sub xmlrpc_setvalue {
	my ($interface, $address, $dp, $value) = @_;
   	# RS485 
   	if ($interface eq 'wired') {
         my $wired_ip = $cfg->val( 'wired', 'ip' );
   	 my $wired_port = $cfg->val( 'wired', 'port' );
	 my $client = RPC::XML::Client->new("$wired_ip:$wired_port");
         $client->simple_request('setValue', $address, $dp, $value);
        }
   	# BidCos
   	if ($interface eq 'bidcos') {
   	 my $bidcos_ip = $cfg->val( 'bidcos', 'ip' );
   	 my $bidcos_port = $cfg->val( 'bidcos', 'port' );
         my $client = RPC::XML::Client->new("$bidcos_ip:$bidcos_port");
         $client->simple_request('setValue', $address, $dp, $value);                
        }
   	# Vcontrol
   	if ($interface eq 'vcontrol') {
         my $vcontrol_ip = $cfg->val( 'vcontrol', 'ip' );
   	 my $vcontrol_port = $cfg->val( 'vcontrol', 'port' );
         my $client = RPC::XML::Client->new("$vcontrol_ip:$vcontrol_port");
         $client->simple_request('setValue', $dp, $value);
        }
}
1;
