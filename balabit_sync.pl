#!/usr/bin/perl
use strict;
#use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use JSON;
use HTTP::Status;
use File::Copy;
use File::Path;
#use Data::Dumper;
use XML::LibXML;
use Getopt::Std;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

my $username      = "admin";
my $prod_password = 'vendor_noisy$oasis';
#my $uat_password  = "qVNRn2mMUcv";
my $uat_password  = 'vendor_noisy$oasis';
my $dr_password   = 'vendor_noisy$oasis';
my $overwrite     = 1;
our $dbg          = 0;
my $unpackDirBase = "/home/scbsync";
my $unpackDir     = "";
my $day           = "";
my $mon           = "";
my $year          = "";
my %options       = ();
my %env           = (
  'prod_host'     => '',
  'uat_host'      => '',
  'dr_host'       => '',
  'prod_password' => '',
  'dr_password'   => '',
  'uat_password'  => '', );
#my ($refid_d);
#my ($refid_d);

getopts("ds:e:", \%options);

if ((!defined $options{d} && !defined $options{s}) || (defined $options{d} && defined $options{s}) || (defined $options{d} && $options{e} !~ m/^uat$|^dr$|^prod$/i)) {
  usage();
}

sub usage
{
  print "Usage: $0 -d|-s -e [prod|dr|uat]\n";
  print "     -d                           show diff\n";
  print "     -s [source, destination]     perform sync between the\n";
  print "                                  environments, i.e. prod, dr or uat.\n";
  print "     -e                           set environment to use\n";
  print "\n";
  exit(1);
}

sub unpackConfig
{
  if ($_[0] =~ /prod/) {
    $unpackDir = $unpackDirBase."/.__tar";
  } elsif ($_[0] =~ /dr/) {
    $unpackDir = $unpackDirBase."/.__drtar";
  }

  die "Unpack directory variable is not set." unless length($unpackDir) > 0;
  #print "Unpacking export.tgz into ".$unpackDir."\n";
  mkdir($unpackDir);
  chdir($unpackDir);
  system("tar xzpf ../export.tgz ./xml/scb.xml > /dev/null 2>&1");
  #chdir("/home/scbsync");
}

sub compareProdWithDrXML
{
  my %pconnections  = (); # PROD hash of connections
  my %dconnections  = (); # DR hash of connections
  my @dchildnodes   = ();
  my @pchildnodes   = ();

  if ($options{e} =~ m/^prod$/i) {
    if (! -e "/home/scbsync/drscb/scb.xml$day$mon$year") {
      #print "DR scb.xml for ".$day.".".$mon.".".$year." in /home/scbsync/drscb doesn't exist\n";
      chdir("/home/scbsync");
      export_config($env{"dr_host"}, $username, $env{"dr_password"});
      unpackConfig("dr");
      chdir("/home/scbsync");
      unlink('export.tgz');
      copy("$unpackDir/xml/scb.xml", "/home/scbsync/drscb/scb.xml$day$mon$year") or die "Couldn't copy scb.xml";
      rmtree($unpackDir);
    }

    my $pparser = new XML::LibXML;
    my $pstruct =$pparser->parse_file("/home/scbsync/$options{e}scb/scb.xml$day$mon$year");

    foreach my $pel ($pstruct->findnodes('/config/scb/pol_connections/connections')) {
      if ($pel->getAttribute('proto') =~ /ssh/ && $pel->hasChildNodes()) {
        @pchildnodes = $pel->nonBlankChildNodes();
      }
    }

    my $dparser = new XML::LibXML;
    my $dstruct =$dparser->parse_file("/home/scbsync/drscb/scb.xml$day$mon$year");

    foreach my $del ($dstruct->findnodes('/config/scb/pol_connections/connections')) {
      if ($del->getAttribute('proto') =~ /ssh/ && $del->hasChildNodes()) {
        @dchildnodes = $del->nonBlankChildNodes();
      }
    }

    if ($#pchildnodes != $#dchildnodes) {
      print "XML comparison between PROD and DR failed. Number of connections in PROD and DR doesn't match.\n";

    } else {
      for (my $i = 0; $i < $#pchildnodes; $i++) {
        $pconnections{$pchildnodes[$i]->getAttribute('name')} = $pchildnodes[$i]->getAttribute('enabled');
        $dconnections{$dchildnodes[$i]->getAttribute('name')} = $dchildnodes[$i]->getAttribute('enabled');
      }

      %pconnections = sort %pconnections;
      %dconnections = sort %dconnections;

      if (!(%pconnections ~~ %dconnections)) {
        print "XML comparison between PROD and DR failed. Set of SCB connections in PROD and DR is different.\n";

      } else {
        foreach my $key (keys %pconnections) {
          if ($pconnections{$key} != $dconnections{$key}) {
            print "XML comparison between PROD and DR failed (key phase). Set of enabled SCB connections in PORD and DR is different.\n";
            last;
          }
        }
      }

    }

  }

}

my $cookie_jar = HTTP::Cookies->new(file => "$ENV{'HOME'}/.xcb_cookies.dat", autosave => 1 );
my $ua = LWP::UserAgent->new;
$ua->cookie_jar($cookie_jar);

chdir("/home/scbsync");

require "scb_func.pl";

# Generating a diff
if (defined $options{d}) {
  ($day, $mon, $year) = (localtime(time))[3, 4, 5];
  $mon++;

  if ($mon < 10) {
    $mon = "0".$mon;
  }

  if ($day < 10) {
    $day = "0".$day;
  }

  $year+=1900;
  my $now = time();
  my $yesterday = $now - 86400;
  my ($yday, $ymon, $yyear) = (localtime($yesterday))[3, 4, 5];
  $ymon++;

  if ($ymon < 10) {
    $ymon = "0".$ymon;
  }

  if ($yday < 10) {
    $yday = "0".$yday;
  }
  $yyear+=1900;

  export_config($env{$options{e}."_host"}, $username, $env{$options{e}."_password"});
  copy('export.tgz',$ENV{'HOME'}."/backup/".$env{$options{e}."_host"}."_".join('-',$day,$mon,$year).".tgz") or die "Couldn't copy Balabit export.tgz to backup\n";
  unpackConfig ($options{e});
  unlink('export.tgz');

  unless (chdir("/home/scbsync/".$options{e}."scb")) {
    mkdir ("/home/scbsync/".$options{e}."scb");
    chdir("/home/scbsync/".$options{e}."scb");
  }

  my $output = "";
  copy("$unpackDir/xml/scb.xml", "/home/scbsync/".$options{e}."scb/scb.xml$day$mon$year") or die "Couldn't copy scb.xml";
  if (-e "/home/scbsync/$options{e}scb/scb.xml$yday$ymon$yyear") {
    $output = qx(/usr/bin/diff -u /home/scbsync/$options{e}scb/scb.xml$day$mon$year /home/scbsync/$options{e}scb/scb.xml$yday$ymon$yyear);
  } else {
    print "No configuration file for the previous day is found. Exiting.\n";
    exit (1);
    }
  print $output."\n";


  #
  # If we are dumping PROD then double check that DR config has the same number of connections,
  # they are enabled and their names match
  #
  compareProdWithDrXML();

  rmtree($unpackDir);

  # Delete all dumps
  system("find /home/scbsync/prodscb/ -type f -mtime +7 -exec rm '{}' ';' &>/dev/null");
  system("find /home/scbsync/drscb/ -type f -mtime +7 -exec rm '{}' ';' &>/dev/null");
}

# Syncing config
if (defined($options{s}) && $options{s} =~ m/(^uat|^prod|^dr),\s*(prod|uat|dr)$/i) {
  my $source = $1;
  my $dest   = $2;
  die "Trying to sync from ".$source." to ".$dest."\n" unless $source !~ /$dest/i;

  my $dest_cfg = $dest."_cfg.tgz";

  print "Syncing from ".$source." to ".$dest."\n";
  export_config($env{$source."_host"}, $username, $env{$source."_password"});
  unpackConfig($source);

  my $rules = "/home/scbsync/scb_".$dest.".rules";
  my $scbxml = $unpackDir."/xml/scb.xml";

  system("sed -f $rules -i $scbxml");
  debug(4, "Changing tar content");
  chmod 0644, "$unpackDir/xml/scb.xml";
  chdir("$unpackDir");
  system("gunzip ../export.tgz");
  system("tar -uf ../export.tar ./xml/scb.xml --numeric-owner --owner 33 --group 33 > /dev/null 2>&1");
  system("gzip ../export.tar");
  chdir("..");
  copy("export.tar.gz", $dest_cfg) or die "Couldn't copy export.tar.gz to $dest_cfg";
  system("rm -rf $unpackDir && rm export.tar.gz");

  debug(2, '\nLogging in to $env{$dest."_host"} as $username');
  print "Logging in to ".$env{$dest."_host"}." as $username";
  my $post = "https://".$env{$dest."_host"}."/index.php?_backend=Auth";
  my $req_login = HTTP::Request->new(POST => $post);
  $req_login->content_type('application/x-www-form-urlencoded');
  my $login = "login=Login&login_name=".$username."&login_password=".$env{$dest."_password"};
  $req_login->content($login);

  my $res_login = $ua->request($req_login);
  if ($res_login->code >= 400) {
    print(STDERR "ERROR\n". Dumper($res_login));
  }

  debug(2, 'Fething reference ID from $env{$dest."_host"}');
  my $get = "https://".$env{$dest."_host"}."/index.php?_backend=BasicSystem";
  my $req_basicsys = HTTP::Request->new(GET => $get);
  my $res_basicsys = $ua->request($req_basicsys);
  if ($res_basicsys->code >= 400) {
    print(STDERR "ERROR\n". Dumper($res_basicsys));
  }

  my $content = $res_basicsys->content();
  my ($refid) = $content =~ /id="reference_id" value="([0-9a-f]+)"/;
  debug(4, "Reference id: $refid");
  debug(2, "Uploading new config, step 1");
  $post = "https://".$env{$dest."_host"}."/index.php?_fileupload_marker=true&_backend=BasicSystem";
  my $res = $ua->request(POST $post,
    Content_Type => 'multipart/form-data',
    Content => [ file => [$dest_cfg, "scb.config"], file_upload => 1, result_handler => 'configUpload', reference_id => $refid ] );
  if ($res->code >= 400) {
    print(STDERR "ERROR\n". Dumper($res));
  }

  my ($fname) = $res->content =~ /"result":"(.*?)"/;

  debug(2, "Uploading new config $fname, " . $res->code . ", step 2");
  $post = "https://".$env{$dest."_host"}."/index.php?_backend=Import&_ajax_html=upload_config";
  my $req = HTTP::Request->new(POST => $post);
  $req->content_type('application/x-www-form-urlencoded');
  $req->content("configfile=$fname&dec_key=&_reference_id=$refid");
  my $res = $ua->request($req);
  if ($res->code >= 400) {
    print(STDERR "ERROR\n". Dumper($res));
  }

  debug(2, "Uploading new config " . $res->code . ", step 3");
  $post = "https://".$env{$dest."_host"}."/index.php?_backend=Import&_ajax_cmd=apply_config";
  my $req = HTTP::Request->new(POST => $post);
  $req->content_type('application/x-www-form-urlencoded');
  $req->content("_reference_id=$refid");
  my $res = $ua->request($req);
  if ($res->code >= 400) {
    print(STDERR "ERROR\n". Dumper($res));
  }

  debug(2, "Logging out from $env{$dest.'_host'}");
  $get = "https://".$env{$dest."_host"}."/index.php?_backend=Auth&logout=1";
  my $req_logout = HTTP::Request->new(GET => $get);
  my $req_logout = $ua->request($req_logout);
  if ($req_logout->code >= 400) {
    print(STDERR "ERROR\n". Dumper($req_logout));
    exit(1);
  }

}

