#!/usr/bin/perl

use warnings;
use strict;

use Expect;


my $host = shift;
my $name = shift;
my $exp = Expect->new;
$exp = Expect->spawn("ssh $host");
$exp->expect(2,
             [ qr/connecting/ => sub { my $exp = shift;
                                $exp->send("yes\n");
                                exp_continue;} ],
             [ qr/password/i => sub { my $exp = shift;
                                $exp->send("Mko09ijn\n");} ],
             );
$exp->send("id $name\n") if ($exp->expect(undef,'$'));
$exp->send("exit\n") if ($exp->expect(undef,'$'));
$exp->soft_close();
