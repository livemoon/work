#!/usr/bin/perl

use warnings;
use strict;

use Expect;

my $host = "127.0.0.1";
my $exp = Expect->new;
$exp = Expect->spawn("ssh $host");
$exp->expect(2,
             [ qr/connecting/ => sub { my $exp = shift;
                                $exp->send("yes\n");
                                exp_continue;} ],
             );
$exp->send("uptime\n") if ($exp->expect(undef,'$'));
$exp->send("exit\n") if ($exp->expect(undef,'$'));
$exp->soft_close();
