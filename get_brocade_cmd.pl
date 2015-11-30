#!/usr/bin/perl
use POSIX qw(strftime);
use Net::OpenSSH;
use warnings;
use strict;
use threads;
use Config;
 
$Config{useithreads} or die('Recompile Perl with threads to run this program.');
 
my $user = "";
my $pass = "";
my @cmd = ("switchshow", "fabricshow", "cfgshow");
my $cmd = join("; ",@cmd);
my @switch_list = ("switch1", "switch2", "switch3");
 
my @thrs;

#
# A directory where all output will be stored
#
my $workdir = "path_to_a_directory";
 
my $time = time;
my $today = strftime "%d-%m-%Y", localtime($time);
my $yesterday = strftime "%d-%m-%Y", localtime($time-86400);
 
mkdir "$workdir/$today";
chdir $workdir;
 
sub get_cmd_output
{
  my $switch = $_[0];
  my @stdout;
  print "Opening a connection to ".$switch." ... \n";
  my $ssh = Net::OpenSSH->new($switch, user=>$user, password=>$pass);
  $ssh->error and die "Couldn't establish SSH connection: ". $ssh->error;
  @stdout = $ssh->capture($cmd);
  $ssh->error and die "remote command failed: " . $ssh->error;
  open FH, ">$today/$switch" or die "unable to open file";
  $| = 1;
  print FH join("",@stdout)."\n";
  close FH;
  
  if (-e "./$yesterday/$switch") {
    my $output = qx(/usr/bin/diff -u ./$yesterday/$switch ./$today/$switch);
    print  $output
  } else {
    print "No $switch data found for the previous date - $yesterday\n";
  }
}
 
foreach (@switch_list) {
  my $switch = $_;
  my $thr = threads->create(\&get_cmd_output, $switch);
  push @thrs, $thr;
}
$_->join() for @thrs;