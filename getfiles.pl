#!/usr/bin/env perl

# getfiles.pl - Fetch the current configuration file set from midgard, then
# perform any necessary sanitization on them (remove passwords and other
# sensitive or overly-specific information, etc.).
#
# Mark Shroyer
# http://markshroyer.com/

use warnings;
use strict;

### BEGIN CONFIGURATION ###################################################

# DNS hostname of the computer whose configuration files we should copy
use constant HOSTNAME => 'midgard';

# The specific configuration files that we want
use constant FILES => (
                       '/etc/hostname.vr0',
                       '/etc/hostname.pppoe0',
                       '/etc/hostname.vr1',
                       '/etc/myname',
                       '/etc/hosts',
                       '/etc/cvsup-file-ports',
                       '/etc/ntpd.conf',
                       '/etc/pf.conf',
                       '/etc/dhcpd.conf',
                       '/var/named/etc/named.conf',
                       '/etc/fstab',
                      );

### END CONFIGURATION #####################################################

### BEGIN SANITIZATION FUNCTIONS ##########################################

sub sanitize_etc_hostname_pppoe0 {
    local $_ = shift;

    # Redact PPPoE username and password
    s/authname\s+'.+?'/authname 'YOUR_USERNAME'/gom;
    s/authkey\s+'.+?'/authkey 'YOUR_PASSWORD'/gom;

    return $_;
}

sub sanitize_etc_hostname_vr1 {
    local $_ = shift;

    s/[\w\d]+\.net/example\.net/gom;

    return $_;
}

sub sanitize_etc_fstab {
    local $_ = shift;

    # Only keep fstab contents up to the first blank line
    my $i = index $_, "\n\n";
    if ( $i != -1 ) {
        return substr $_, 0, ($i+1);
    } else {
        return $_;
    }
}

sub sanitize_etc_myname {
    local $_ = shift;

    # Use example.net
    s/[\w\d]+\.net/example\.net/go;

    return $_;
}

sub sanitize_etc_hosts {
    local $_ = shift;

    # Exclude commented-out lines
    s/^\s*#[^\n]*\n//gom;

    # Use example.net
    s/[\w\d]+\.net/example\.net/go;

    return $_;
}

sub sanitize_etc_dhcpd_conf {
    local $_ = shift;

    # Use example.net
    s/[\w\d]+\.net/example\.net/go;

    # Don't tell the world our network's MAC addresses
    s/(?:[[:xdigit:]]{2}:){5}[[:xdigit:]]{2}/XX:XX:XX:XX:XX:XX/go;

    # Don't show commented-out lines
    s/^\s*#[^\n]*\n//gom;

    # Don't show our static client configurations
    s/group \{(?:.+host \S+ \{.+\})+.*\}//oms;

    # Get rid of leading and trailing empty lines
    s/^\n+//o;
    s/\n+$/\n/o;

    return $_;
}

sub sanitize_var_named_etc_named_conf {
    local $_ = shift;

    # Use example.net
    s/[\w\d]{3,}\.net/example\.net/go;
    s/db\.net\.[\w\d]{3,}/db\.net\.example/go;

    return $_;
}

sub sanitize_etc_dhclient_script_local {
    local $_ = shift;

    # Cut out the initial comment block for brevity
    s/^(.+?\n)(?:#.*?\n)+/$1/s;

    # Redact TSIG key
    s/^key .*$/key XXXXXXXXXXXX YYYYYYYYYYYYYYYYYYYYYYYY/om;

    return $_;
}

sub sanitize_etc_ddclient_ddclient_conf {
    local $_ = shift;

    # Ignore commented-out lines
    s/^\s*#[^\s\n][^\n]*\n//gom;

    # Purge my username and password from the file
    s/^password=.*$/password=YOUR_PASSWORD/mgo;
    s/^login=.*$/login=YOUR_LOGIN/mgo;

    return $_;
}

sub sanitize_usr_local_etc_raddb_clients_conf {
    local $_ = shift;

    # Ignore comment and whitespace lines
    s/^\s*(?:#.*)?\n//gom;

    # Don't show secret keys
    s/secret = .+/secret = YOUR_SECRET_KEY/go;

    return $_;
}

sub sanitize_usr_local_tspc_bin_gw6c_conf {
    local $_ = shift;

    # Hide comment and whitespace lines for clarity
    s/^\s*(?:#.*)?\n//gom;

    # Obscure username and password
    s/^userid=.*/userid=YOUR_GO6_USERNAME/gom;
    s/^passwd=.*/passwd=YOUR_GO6_PASSWORD/gom;

    return $_;
}

### END SANITIZATION FUNCTIONS ############################################

#
# Null sanitizer: simply returns the file contents in their original form.
#
# Arg #1:   File contents, scalar
# Returns:  File contents, scalar
#
sub sanitize_null {
    local $_ = shift;
    return $_;
}

#
# Converts a filename into an appropriate sanitize_ function name fragment
#
# Arg #1:   Filename, scalar
# Returns:  Sanitize function name fragment, scalar
#
sub get_sanitize_name {
    local $_ = shift;

    s/[^\w\d]/\_/go;
    s/^\_(.+)/$1/;
    return $_;
}

# Search through the namespace to find file sanitization functions (as
# described above).
our %sanitize = ();
foreach(keys %::) {
    $sanitize{$1} = \&$_ if m/^sanitize_([\w\d\_]*)$/o and defined &$_;
}

# Shell into the server and create a tarball with the files that we want;
# copy that tarball to here.
my $tar_command = "tar -czf manual_files.tar.gz";
foreach ( FILES ) { $tar_command .= " $_"; }
if ( HOSTNAME ) {
    system("ssh " . HOSTNAME . " sudo $tar_command");
    system("scp " . HOSTNAME . ":manual_files.tar.gz .");
    system("ssh " . HOSTNAME . " rm -f manual_files.tar.gz");
} else {
    system("sudo $tar_command");
}

# Prepare temporary file workspace
if ( -d 'tempfiles' ) {
    `rm -rf tempfiles`;
}
mkdir 'tempfiles';
`tar -C tempfiles -xzf manual_files.tar.gz`;
unlink 'manual_files.tar.gz';

# Prepare storage directory for extracted files
if ( -d 'src/files' ) {
    `rm -rf src/files`;
}
system("mkdir -p src/files");

foreach my $f ( FILES ) {
    # Quickly create file's directory tree
    system("mkdir -p src/files$f"); rmdir "src/files$f";

    # Sanitize and wite output
    my $sf;
    unless ( $sf = $sanitize{get_sanitize_name($f)} ) {
        # Use the null sanitizer if this file does not have a custom
        # sanitization function defined.
        $sf = \&sanitize_null;
    }
    local (*IN, *OUT);
    open(IN, '<', "tempfiles$f")
        or die "getfiles.pl: Error: Could not open tempfiles$f for input: $!\n";
    open(OUT, '>', "src/files$f")
        or die "getfiles.pl: Error: Could not open src/files$f for output: $!\n";
    my $lines = join( '', readline(IN) );
    my $out = &$sf( $lines );
    my $sec = 0;
    my %sec_handles = ();
    my $sec_out;
    foreach my $line ( split /\n/, $out ) {
        if ( $line =~ m/~~~ GETFILES SEGMENT (\d+) ~~~/ ) {
            $sec = $1;
            if ( $sec > 0 ) {
                unless ( exists $sec_handles{$sec} ) {
                    my $fh;
                    open($fh, '>', "src/files$f.$sec") or die "getfiles.pl: Error: Could not open src/files$f.$sec for output: $!\n";
                    $sec_handles{$sec} = $fh;
                }
                $sec_out = $sec_handles{$sec};
            }
            else {
                $sec_out = undef;
            }
        }
        else {
            print OUT $line . "\n";
            if ( defined $sec_out ) {
                print $sec_out $line . "\n";
            }
        }
    }
    foreach my $sec ( keys %sec_handles ) {
        close $sec_handles{$sec};
    }
    close OUT;
    close IN;
}

# Clean up
`rm -rf tempfiles`;

