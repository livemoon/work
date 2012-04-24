#!/usr/bin/perl

use warnings;
use strict;

use Net::Ping;


my $file = "lb.txt";
my $ip;
my $host1;
my $host2;

sub get_info() {

    open my $FH, '<', $file or die "Cannot open $file\n";

    while(<$FH>) {
        $ip = $1 if /ip;(.*)/;
        $host1 = $1 if /host\d;(.*);(master)/;
        $host2 = $1 if /host\d;(.*);(none)/;
    }
    close($FH);
}

sub check_ping() {
    my $p = Net::Ping->new("icmp");
    if ($p->ping($ip, 5)) {
        $p->close();
	return 1
    }
    else {
        $p->close();
        return 0;
    }
}


sub change() {
    print "change $ip from $host1 to $host2\n";
    $ENV{'NOVA_USERNAME'} = "eric";
    $ENV{'NOVA_API_KEY'} = "123456";
    $ENV{'NOVA_PROJECT_ID'} = "test";
    $ENV{'NOVA_URL'} = "http://127.0.0.1:5000/v2.0/";
    $ENV{'NOVA_VERSION'} = "1.1";
    $ENV{'NOVA_AUTH_STRATEGY'} = "keystone";
    print "remove $ip from $host1\n";
    system("nova remove-floating-ip $host1 $ip") && die "Cannot Disassociate IP $ip";
   # system("echo $ip") && die "Cannot Disassociate IP $ip";
    sleep(2);
    my $i = 5;
    while($i) {
	print "add $ip on $host2\n";
        last unless (&check_ping() || system("nova", "add-floating-ip", $host2, $ip));
       # last unless (!&check_ping() || system("nova", "list"));
    } 
    continue {
	$i--;
    }
    if ($i) {
        &update();
    }
    else {
	print "TIMEOUT\n";
    }
    print "Waiting for 60 seconds\n";
    sleep(60);        
}

my $filebak = "lb.txt.bak";
sub update() {
    open my $IN, '<', $file or die "Cannot open $file\n";
    open my $OUT, '>', $filebak or die "Cannot create $filebak\n";

    while(<$IN>) {
	s/master/none/ || s/none/master/;
	print $OUT $_;
    }
    close($IN);
    close($OUT);

    rename($filebak, $file) or die "Can't rename, The new file is $filebak\n" ; 
}

    

my $i = 100;
while($i) {
    &get_info();
    my $result = check_ping();
    if ($result) {
	print "$ip is running on $host1\n";
    }
    else {
	&change();
    }
    $i--;
    sleep(5);
}
