########################################
# This job add user and add his public 
# key into $HOME/.ssh dir
# Give sudo pri to him
########################################

#!/usr/bin/perl

use warnings;
use strict;

use Expect;


my $host = shift;
my $name = shift;
my $sudo;
my $keyfile = shift;
open my $FH, '<', $keyfile or die "Cannot open file\n";
my $key = <$FH>;
chomp $key;
my $exp = Expect->new;
$exp = Expect->spawn("ssh $host");
$exp->expect(5,
             [ qr/connecting/ => sub { my $exp = shift;
                                $exp->send("yes\n");
                                exp_continue;} ],
             [ qr/password/i => sub { my $exp = shift;
                                $exp->send("Mko09ijn\n");} ],
             );
$exp->send("uname -a\n") if ($exp->expect(undef,'$'));
my $read = $exp->before();
$sudo="wheel\n" if $read =~ /el/;
$sudo="admin\n" if $read =~ /Ubuntu/;
chomp $sudo;
$exp->send("sudo useradd -G $sudo -m -k /etc/skel -s /bin/bash $name\n") if ($exp->expect(undef,'$'));
$exp->send("sudo su - $name -c \"mkdir ~/.ssh\"\n") if ($exp->expect(undef,'$'));
$exp->send("sudo su - $name -c \"echo $key > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys\"\n") if ($exp->expect(undef,'$'));
$exp->send("exit\n") if ($exp->expect(undef,'$'));
$exp->soft_close();
