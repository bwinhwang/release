#!/bin/env perl

#if setsee version < LINSEE_BTS_3.4.0_64 insert:
#
#BEGIN {
#unshift @INC, "/home/dems11q1/perl-5.8.7/lib/5.8.7";
#require "MIME/Lite.pm";
#import MIME::Lite;
#unshift @INC;
#}

####!/home/dems11q1/perl-5.8.7/bin/perl -w
###!/usr/local/bin/perl -w
#
# Author:		Joachim Bauernberger <joachim.bauernberger.ext@nsn.com>
#
# Date:			Thu May 29 12:02:59 CEST 2008
#
# Description:	Send a mail (now with or without an attachment)
#				   send_message.pl -help gives you a list of options.
#
# Changes:      07-Dec-2009		Hans-Uwe Zeisler		Changes to use it for sending a mail without attachment 
#

use MIME::Lite;
use Net::SMTP;
use Getopt::Long;

my $me = `basename $0`;
chomp $me;

my $from_address = "";
my $to_address = "";
my $cc_address = "";

my $subject = "";
my $message_body = "";
my $reply_to="";
my $body;

my $file_zip  = "";
my $file_txt  = "";
my $file_html = "";
my $filename1;
my $filename2;
my $filename3;
my $usage = 0;

sub usage()
{
   print "\n\nUSAGE:\n";
   print "$me --from=sender\@nsn.com\n";
   print "      		--to=recepient\@nsn.com\n";
   print "      		--cc=receipient\@nsn.com (optional)\n";
   print "      		--subject=\"test\"\n";
   print "      		--body=\"this is a test\" (or pathname to a file which contains the message body)\n";
   print "              --reply_to=recipient\@nsn.com\n";
   print "      		--zip_attach=/tmp/file.tar.gz (optional)\n";
   print "              --txt_attach=/tmp/file.txt (optional)\n";
   print "              --html_attach=/tmp/file.html (optional)\n";
   exit 1;
}

GetOptions (
   "from=s"        => \$from_address,    	# sender
   "to=s"          => \$to_address,   	    # recipient
   "cc:s"          => \$cc_address,   	    # cc (optional)
   "subject=s"     => \$subject, 	        # subject line
   "body=s"        => \$message_body, 	    # either a string or the name of a file containing the contents as text
   "reply_to:s"    => \$reply_to,           # reply adress (optional)
   "zip_attach:s"  => \$file_zip,           # path to a zip file (optional)
   "txt_attach:s"  => \$file_txt,           # path to a txt file (optional)
   "html_attach:s" => \$file_html,          # path to a html file (optional)
   "help!"         => \$usage) or usage();
	
if ($from_address eq "") { print "$me: parameter 'from' missing\n"; usage(); }
if ($to_address eq "")   { print "$me: parameter 'to' missing\n"; usage(); }
if ($subject eq "")      { print "$me: parameter 'subject' missing"; usage(); }
if ($message_body eq "") { print "$me: parameter 'body' missing"; usage(); }
if ($reply_to eq "" )    { $reply_to = $from_address; }

# Check if $message_body is a string or a valid path to a file 
$body = $message_body;
if (( $message_body !~ " " ) && ( $message_body !~ "\n" )) {
   if (-r $message_body) {
      open FILE, "<$message_body" || die "Unable to open $message_body for reading: $!";
      $body = do { local $/; <FILE> };
   }
}

# smtp server
my $mail_host = 'mail.emea.nsn-intra.net';

print "Sending to: $to_address\n";
print "Sending cc: $cc_address\n";
print "Subject is: $subject\n";

### Create the multipart container
my $msg = MIME::Lite->new (
   From => "$from_address",
   To => "$to_address",
   Cc => "$cc_address",
   Subject => "$subject",
   'Reply-to' => "$reply_to",
   Type =>'multipart/mixed'
) or die "Error creating multipart container: $!\n";

### Add the text message part
$msg->attach (
   Type => 'TEXT',
   Data => $body
) or die "Error adding the text message part: $!\n";

### Add the ZIP file if readable
if ( -r $file_zip) {
   $filename1 = `basename $file_zip`;
   chomp $filename1;
   $msg->attach (
   Type => 'application/zip',
   Path => $file_zip,
   Filename => $filename1,
   Disposition => 'attachment'
   ) or die "Error adding $file_zip: $!\n";
}

### Add the HTML file if readable
if ( -r $file_html) {
   $filename2 = `basename $file_html`;
   chomp $filename2;
   $msg->attach (
   Type => 'text/html',
   Path => $file_html,
   Filename => $filename2,
   Disposition => 'attachment'
   ) or die "Error adding $file_html: $!\n";
}

### Add the TXT file if readable
if ( -r $file_txt) {
   $filename3 = `basename $file_txt`;
   chomp $filename3;
   $msg->attach (
   Type => 'text/plane',
   Path => $file_txt,
   Filename => $filename3,
   Disposition => 'attachment'
   ) or die "Error adding $file_txt: $!\n";
}

### Send the Message
MIME::Lite->send('smtp', $mail_host, Timeout=>60);
$msg->send; 

#EOF
