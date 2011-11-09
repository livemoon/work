#!/usr/bin/perl

#use warnings;
#use strict;


# get user info
while (($name, $pass, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire) = getpwent()) {
        if ($shell !~ /false|nologin/ && $dir !~ /var|bin|usr/) {
            print "$name\n";
            system "sudo su - $name -c \"crontab -l\"";
        }
}
