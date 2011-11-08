cat -n /proc/net/dev | grep eth | awk 'BEGIN {print "nic\t","receive\t","transmit\t","ALL\t"}END{print $2"\t",$3"\t",$11"\t",($3+$11)*8/(1024*1024)"MB"}'
