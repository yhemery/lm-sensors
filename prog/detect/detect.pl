#!/usr/bin/perl

#
#    detect.pl - Detect PCI bus and chips
#    Copyright (c) 1998, 1999  Frodo Looijaard <frodol@dds.nl>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

# TODO: Better handling of chips with several addresses

# A Perl wizard really ought to look upon this; the PCI and I2C stuff should
# each be put in a separate file, using modules and packages. That is beyond
# me.

use strict;

#########################
# CONSTANT DECLARATIONS #
#########################

use vars qw(@pci_adapters @chip_ids @undetectable_adapters);

@undetectable_adapters = ( "bit-lp", "bit-velle" );

# This is the list of SMBus or I2C adapters we recognize by their PCI
# signature. This is an easy and fast way to determine which SMBus or I2C
# adapters should be present.
# Each entry must have a vindid (Vendor ID), devid (Device ID), func (PCI
# Function) and procid (string as appears in /proc/pci; see linux/driver/pci,
# either pci.c or oldproc.c). If no driver is written yet, omit the 
# driver (Driver Name) field. The match (Match Description) field should
# contain a function which returns zero if its two parameter matches
# the text as it would appear in /proc/bus/i2c.
@pci_adapters = ( 
     { 
       vendid => 0x8086,
       devid  => 0x7113,
       func => 3,
       procid => "Intel 82371AB PIIX4 ACPI",
       driver => "i2c-piix4",
       match => sub { $_[0] =~ /^SMBus PIIX4 adapter at [0-9,a-f]{4}/ },
     } , 
     { 
       vendid => 0x1106,
       devid  => 0x3040,
       func => 3,
       procid => "VIA Technologies VT 82C586B Apollo ACPI",
       driver => "i2c-via",
       match => sub { $_[0] =~ /^VIA i2c/ },
     } ,
     {
       vendid => 0x1039,
       devid  => 0x0008,
       func => 0,
       procid => "Silicon Integrated Systems 85C503",
       match => sub { 0 },
     } ,
     {
       vendid => 0x10b9,
       devid => 0x7101,
       funcid => 0,
       procid => "Acer Labs M7101",
       driver => "i2c-ali15x3",
       match => sub { $_[0] =~ /^SMBus ALI15X3 adapter at [0-9,a-f]{4}/ },
     }
);

use subs qw(lm78_detect lm78_isa_detect lm78_alias_detect lm75_detect 
            lm80_detect w83781d_detect w83781d_alias_detect
            w83781d_isa_detect gl518sm_detect gl520sm_detect adm9240_detect 
            adm1021_detect sis5595_isa_detect eeprom_detect);

# This is a list of all recognized chips. 
# Each entry must have the following fields:
#  name: The full chip name
#  driver (optional): The driver name (without .o extension). Omit if none is
#      written yet.
#  i2c_addrs (optional): For I2C chips, the range of valid I2C addresses to
#      probe.
#  i2c_detect (optional): For I2C chips, the function to call to detect
#      this chip. The function should take two parameters: an open file
#      descriptor to access the bus, and the I2C address to probe.
#  isa_addrs (optional): For ISA chips, the range of valid port addresses to
#      probe.
#  isa_detect (optional): For ISA chips, the function to call to detect
#      this chip. The function should take one parameter: the ISA address
#      to probe.
#  alias_detect (optional): For chips which can be both on the ISA and the
#      I2C bus, a function which detectes whether two entries are the same.
#      The function should take three parameters: The ISA address, the
#      I2C bus number, and the I2C address.
@chip_ids = (
     {
       name => "National Semiconductors LM78",
       driver => "lm78",
       i2c_addrs => [0x00..0x7f], 
       i2c_detect => sub { lm78_detect 0, @_},
       isa_addrs => [0x290],
       isa_detect => sub { lm78_isa_detect 0, @_ },
       alias_detect => sub { lm78_alias_detect 0, @_ },
     } ,
     {
       name => "National Semiconductors LM78-J",
       driver => "lm78",
       i2c_addrs => [0x00..0x7f],
       i2c_detect => sub { lm78_detect 1, @_ },
       isa_addrs => [0x290],
       isa_detect => sub { lm78_isa_detect 1, @_ },
       alias_detect => sub { lm78_alias_detect 1, @_ },
     } ,
     {
       name => "National Semiconductors LM79",
       driver => "lm78",
       i2c_addrs => [0x00..0x7f],
       i2c_detect => sub { lm78_detect 2, @_ },
       isa_addrs => [0x290],
       isa_detect => sub { lm78_isa_detect 2, @_ },
       alias_detect => sub { lm78_alias_detect 2, @_ },
     } ,
     {
       name => "National Semiconductors LM75",
       driver => "lm75",
       i2c_addrs => [0x48..0x4f],
       i2c_detect => sub { lm75_detect @_},
     } ,
     {
       name => "National Semiconductors LM80",
       driver => "lm80",
       i2c_addrs => [0x28..0x2f],
       i2c_detect => sub { lm80_detect @_} ,
     },
     {
       name => "Winbond W83781D",
       driver => "w83781d",
       i2c_addrs => [0x00..0x7f], 
       i2c_detect => sub { w83781d_detect 0, @_},
       isa_addrs => [0x290],
       isa_detect => sub { w83781d_isa_detect 0, @_ },
       alias_detect => sub { w83781d_alias_detect 0, @_ },
     } ,
     {
       name => "Winbond W83782D",
       driver => "w83781d",
       i2c_addrs => [0x00..0x7f], 
       i2c_detect => sub { w83781d_detect 1, @_},
       isa_addrs => [0x290],
       isa_detect => sub { w83781d_isa_detect 1, @_ },
       alias_detect => sub { w83781d_alias_detect 1, @_ },
     } ,
     {
       name => "Winbond W83783S",
       driver => "w83781d",
       i2c_addrs => [0x00..0x7f], 
       i2c_detect => sub { w83781d_detect 2, @_},
       isa_addrs => [0x290],
       isa_detect => sub { w83781d_isa_detect 2, @_ },
       alias_detect => sub { w83781d_alias_detect 2, @_ },
     } ,
     {
       name => "Genesys Logic GL518SM Revision 0x00",
       driver => "gl518sm",
       i2c_addrs => [0x4c, 0x4d],
       i2c_detect => sub { gl518sm_detect 0, @_} ,
     },
     {
       name => "Genesys Logic GL518SM Revision 0x80",
       driver => "gl518sm",
       i2c_addrs => [0x4c, 0x4d],
       i2c_detect => sub { gl518sm_detect 1, @_} ,
     },
     {
       name => "Genesys Logic GL520SM",
       i2c_addrs => [0x4c, 0x4d],
       i2c_detect => sub { gl520sm_detect @_} ,
     },
     {
       name => "Analog Devices ADM9240",
       driver => "adm9240",
       i2c_addrs => [0x2c..0x2f],
       i2c_detect => sub { adm9240_detect @_ }
     },
     {
       name => "Analog Devices ADM1021",
       driver => "adm1021",
       i2c_addrs => [0x18..0x1b,0x29..0x2b,0x4c..0x4e],
       i2c_detect => sub { adm1021_detect 0, @_ },
     },
     {
       name => "Maxim MAX1617",
       driver => "adm1021",
       i2c_addrs => [0x18..0x1b,0x29..0x2b,0x4c..0x4e],
       i2c_detect => sub { adm1021_detect 1, @_ },
     },
     {
       name => "Silicon Integrated Systems SIS5595",
       driver => "sis5595",
       isa_addrs => [ 0 ],
       isa_detect => sub { sis5595_isa_detect @_ },
     },
     {
       name => "Serial EEPROM (PC-100 DIMM)",
       driver => "eeprom",
       i2c_addrs => [0x50..0x57],
       i2c_detect => sub { eeprom_detect @_ },
     }
);


#######################
# AUXILIARY FUNCTIONS #
#######################

sub swap_bytes
{
  return (($_[0] & 0xff00) >> 8) + (($_[0] & 0x00ff) << 8)
}

# $_[0] is the sought value
# @_[1..] is the list to seek in
# Returns: 0 on failure, 1 if found.
sub contains
{
  my $sought = shift;
  foreach (@_) {
    return 1 if $sought eq $_;
  }
  return 0;
}

sub parse_not_to_scan
{
  my ($min,$max,$to_parse) = @_;
  my @ranges = split /\s*,\s*/, $to_parse;
  my @res = ();
  my $range;
  foreach $range (@ranges) {
    my ($start,$end) = split /\s*-s*/, $range;
    $start = oct $start if $start =~ /^0/;
    if (defined $end) {
      $end = oct $end if $end =~ /^0/;
      $start = $min if $start < $min;
      $end = $max if $end > $max;
      push @res, ($start+0..$end+0);
    } else {
      push @res, $start+0 if $start >= $min and $start <= $max;
    }
  }
  return sort { $a <=> $b } @res;
}

# @_[0]: Reference to list 1
# @_[1]: Reference to list 2
# Result: 0 if they have no elements in common, 1 if they have
# Elements must be numeric.
sub any_list_match
{
  my ($list1,$list2) = @_;
  my ($el1,$el2);
  foreach $el1 (@$list1) {
    foreach $el2 (@$list2) {
      return 1 if $el1 == $el2;
    }
  }
  return 0;
}

###################
# I/O port access #
###################

sub initialize_ioports
{
  sysopen IOPORTS, "/dev/port", 2;
}

# $_[0]: port to read
# Returns: -1 on failure, read value on success.
sub inb
{
  my ($res,$nrchars);
  sysseek IOPORTS, $_[0], 0 or return -1;
  $nrchars = sysread IOPORTS, $res, 1;
  return -1 if not defined $nrchars or $nrchars != 1;
  $res = unpack "C",$res ;
  return $res;
}

# $_[0]: port to write
# $_[1]: value to write
# Returns: -1 on failure, 0 on success.
sub outb
{
  my $towrite = pack "C", $_[1];
  sysseek IOPORTS, $_[0], 0 or return -1;
  my $nrchars = syswrite IOPORTS, $towrite, 1;
  return -1 if not defined $nrchars or $nrchars != 1;
  return 0;
}

# $_[0]: Address register
# $_[1]: Data register
# $_[2]: Register to read
# Returns: read value
sub isa_read_byte
{
  outb $_[0],$_[2];
  return inb $_[1];
}

# $_[0]: Address register
# $_[1]: Data register
# $_[2]: Register to write
# $_[3}: Value to write
# Returns: nothing
sub isa_write_byte
{
  outb $_[0],$_[2];
  outb $_[1],$_[3];
}

###########
# MODULES #
###########

use vars qw(@modules_list);

sub initialize_modules_list
{
  open INPUTFILE, "/proc/modules" or die "Can't access /proc/modules!";
  while (<INPUTFILE>) {
    push @modules_list, /^(\S*)/ ;
  }
  close INPUTFILE;
}

##############
# PCI ACCESS #
##############

use vars qw(@pci_list);

# This function returns a list of hashes. Each hash has some PCI information 
# (more than we will ever need, probably). The most important
# fields are 'bus', 'slot', 'func' (they uniquely identify a PCI device in 
# a computer) and 'vendid','devid' (they uniquely identify a type of device).
# /proc/bus/pci/devices is only available on late 2.1 and 2.2 kernels.
sub read_proc_dev_pci
{
  my ($dfn,$vend,@pci_list);
  open INPUTFILE, "/proc/bus/pci/devices" or return;
  while (<INPUTFILE>) {
    my $record = {};
    ($dfn,$vend,$record->{irq},$record->{base_addr0},$record->{base_addr1},
          $record->{base_addr2},$record->{base_addr3},$record->{base_addr4},
          $record->{base_addr5},$record->{rom_base_addr}) = 
          map { oct "0x$_" } split;
    $record->{bus} = $dfn >> 8;
    $record->{slot} = ($dfn & 0xf8) >> 3;
    $record->{func} = $dfn & 0x07;
    $record->{vendid} = $vend >> 16;
    $record->{devid} = $vend & 0xffff;
  push @pci_list,$record;
  }
  close INPUTFILE or return;
  return @pci_list;
}

# This function returns a list of hashes. Each hash has some PCI 
# information. The important fields here are 'bus', 'slot', 'func' (they
# uniquely identify a PCI device in a computer) and 'desc' (a functional
# description of the PCI device). If this is an 'unknown device', the
# vendid and devid fields are set instead.
sub read_proc_pci
{
  my @pci_list;
  open INPUTFILE, "/proc/pci" or return;
  while (<INPUTFILE>) {
    my $record = {};
    if (($record->{bus},$record->{slot},$record->{func}) = 
        /^\s*Bus\s*(\S)+\s*,\s*device\s*(\S+)\s*,\s*function\s*(\S+)\s*:\s*$/) {
      my $desc = <INPUTFILE>;
      unless (($desc =~ /Unknown device/) and
              (($record->{vendid},$record->{devid}) = 
                         /^\s*Vendor id=(\S+)\.\s*Device id=(\S+)\.$/)) {
        $record->{desc} = $desc;
      }
      push @pci_list,$record;
    }
  }
  close INPUTFILE or return;
  return @pci_list;
}

sub initialize_proc_pci
{
  @pci_list = read_proc_dev_pci;
  @pci_list = read_proc_pci     if not defined @pci_list;
  die "Can't access either /proc/bus/pci/ or /proc/pci!" 
                                    if not defined @pci_list;
}

#####################
# ADAPTER DETECTION #
#####################

sub all_available_adapters
{
  my @res = ();
  my ($module,$adapter);
  MODULES:
  foreach $module (@modules_list) {
    foreach $adapter (@pci_adapters) {
      if (exists $adapter->{driver} and $module eq $adapter->{driver}) {
        push @res, $module;
        next MODULES;
      }
    }
  }
  return @res;
}

sub adapter_pci_detection
{
  my ($device,$try,@res);
  print "Probing for PCI bus adapters...\n";

  foreach $device (@pci_list) {
    foreach $try (@pci_adapters) {
      if ((defined($device->{vendid}) and 
           $try->{vendid} == $device->{vendid} and
           $try->{devid} == $device->{devid} and
           $try->{func} == $device->{func}) or
          (! defined($device->{vendid}) and
           $device->{desc} =~ /$try->{procid}/ and
           $try->{func} == $device->{func})) {
        printf "Use driver `%s' for device %02x:%02x.%x: %s\n",
               $try->{driver}?$try->{driver}:"<To Be Written>",
               $device->{bus},$device->{slot},$device->{func},$try->{procid};
        push @res,$try->{driver};
      }
    }
  }
  if (! defined @res) {
    print ("Sorry, no PCI bus adapters found.\n");
  } else {
    printf ("Probe succesfully concluded.\n");
  }
  return @res;
}

# $_[0]: Adapter description as found in /proc/bus/i2c
# $_[1]: Algorithm description as found in /proc/bus/i2c
sub find_adapter_driver
{
  my $adapter;
  for $adapter (@pci_adapters) {
    return $adapter->{driver} if &{$adapter->{match}} ($_[0],$_[1]);
  }
  return "?????";
}

#############################
# I2C AND SMBUS /DEV ACCESS #
#############################

# This should really go into a separate module/package.

# To do: support i2c-level access (through sysread/syswrite, probably).
# I can't test this at all (PIIX4 does not support this), so I have not
# included it.

use vars qw($IOCTL_I2C_RETRIES $IOCTL_I2C_TIMEOUT $IOCTL_I2C_UDELAY 
            $IOCTL_I2C_MDELAY $IOCTL_I2C_SLAVE $IOCTL_I2C_TENBIT 
            $IOCTL_I2C_SMBUS);

# These are copied from <linux/i2c.h> and <linux/smbus.h>

# For bit-adapters:
$IOCTL_I2C_RETRIES = 0x0701;
$IOCTL_I2C_TIMEOUT = 0x0702;
$IOCTL_I2C_UDELAY = 0x0705;
$IOCTL_I2C_MDELAY = 0x0706;

# General ones:
$IOCTL_I2C_SLAVE = 0x0703;
$IOCTL_I2C_TENBIT = 0x0704;
$IOCTL_I2C_SMBUS = 0x0720;


use vars qw($SMBUS_READ $SMBUS_WRITE $SMBUS_QUICK $SMBUS_BYTE $SMBUS_BYTE_DATA 
            $SMBUS_WORD_DATA $SMBUS_PROC_CALL $SMBUS_BLOCK_DATA);

# These are copied from <linux/smbus.h>

$SMBUS_READ = 1;
$SMBUS_WRITE = 0;
$SMBUS_QUICK = 0;
$SMBUS_BYTE = 1;
$SMBUS_BYTE_DATA  = 2;
$SMBUS_WORD_DATA  = 3;
$SMBUS_PROC_CALL = 4;
$SMBUS_BLOCK_DATA = 5;

# Select the device to communicate with through its address.
# $_[0]: Reference to an opened filehandle
# $_[1]: Address to select
# Returns: 0 on failure, 1 on success.
sub i2c_set_slave_addr
{
  my ($file,$addr) = @_;
  ioctl $file, $IOCTL_I2C_SLAVE, $addr or return 0;
  return 1;
}

# i2c_smbus_access is based upon the corresponding C function (see 
# <linux/i2c-dev.h>). You should not need to call this directly.
# Exact calling conventions are intricate; read i2c-dev.c if you really need
# to know.
# $_[0]: Reference to an opened filehandle
# $_[1]: $SMBUS_READ for reading, $SMBUS_WRITE for writing
# $_[2]: Command (usually register number)
# $_[3]: Transaction kind ($SMBUS_BYTE, $SMBUS_BYTE_DATA, etc.)
# $_[4]: Reference to an array used for input/output of data
# Returns: 0 on failure, 1 on success.
# Note that we need to get back to Integer boundaries through the 'x2'
# in the pack. This is very compiler-dependent; I wish there was some other 
# way to do this.
sub i2c_smbus_access
{
  my ($file,$read_write,$command,$size,$data) = @_;
  my $data_array = pack "C32", @$data;
  my $ioctl_data = pack "C2x2Ip", ($read_write,$command,$size,$data_array);
  ioctl $file, $IOCTL_I2C_SMBUS, $ioctl_data or return 0;
  $_[4] = [ unpack "C32",$data_array ];
  return 1;
}

# $_[0]: Reference to an opened filehandle
# $_[1]: Either 0 or 1
# Returns: -1 on failure, the 0 on success.
sub i2c_smbus_write_quick
{
  my ($file,$value) = @_;
  my $data = [];
  i2c_smbus_access $file, $value, 0, $SMBUS_QUICK, $data 
         or return -1;
  return 0;
}

# $_[0]: Reference to an opened filehandle
# Returns: -1 on failure, the read byte on success.
sub i2c_smbus_read_byte
{
  my ($file) = @_;
  my $data = [];
  i2c_smbus_access $file, $SMBUS_READ, 0, $SMBUS_BYTE, $data 
         or return -1;
  return $$data[0];
}

# $_[0]: Reference to an opened filehandle
# $_[1]: Byte to write
# Returns: -1 on failure, 0 on success.
sub i2c_smbus_write_byte
{
  my ($file,$command) = @_;
  my $data = [$command];
  i2c_smbus_access $file, $SMBUS_WRITE, 0, $SMBUS_BYTE, $data 
         or return -1;
  return 0;
}

# $_[0]: Reference to an opened filehandle
# $_[1]: Command byte (usually register number)
# Returns: -1 on failure, the read byte on success.
sub i2c_smbus_read_byte_data
{
  my ($file,$command) = @_;
  my $data = [];
  i2c_smbus_access $file, $SMBUS_READ, $command, $SMBUS_BYTE_DATA, $data 
         or return -1;
  return $$data[0];
}
  
# $_[0]: Reference to an opened filehandle
# $_[1]: Command byte (usually register number)
# $_[2]: Byte to write
# Returns: -1 on failure, 0 on success.
sub i2c_smbus_write_byte_data
{
  my ($file,$command,$value) = @_;
  my $data = [$value];
  i2c_smbus_access $file, $SMBUS_WRITE, $command, $SMBUS_BYTE_DATA, $data 
         or return -1;
  return 0;
}

# $_[0]: Reference to an opened filehandle
# $_[1]: Command byte (usually register number)
# Returns: -1 on failure, the read word on success.
# Note: some devices use the wrong endiannes; use swap_bytes to correct for 
# this.
sub i2c_smbus_read_word_data
{
  my ($file,$command) = @_;
  my $data = [];
  i2c_smbus_access $file, $SMBUS_READ, $command, $SMBUS_WORD_DATA, $data 
         or return -1;
  return $$data[0] + 256 * $$data[1];
}

# $_[0]: Reference to an opened filehandle
# $_[1]: Command byte (usually register number)
# $_[2]: Byte to write
# Returns: -1 on failure, 0 on success.
# Note: some devices use the wrong endiannes; use swap_bytes to correct for 
# this.
sub i2c_smbus_write_word_data
{
  my ($file,$command,$value) = @_;
  my $data = [$value & 0xff, $value >> 8];
  i2c_smbus_access $file, $SMBUS_WRITE, $command, $SMBUS_WORD_DATA, $data 
         or return -1;
  return 0;
}

# $_[0]: Reference to an opened filehandle
# $_[1]: Command byte (usually register number)
# $_[2]: Word to write
# Returns: -1 on failure, read word on success.
# Note: some devices use the wrong endiannes; use swap_bytes to correct for 
# this.
sub i2c_smbus_process_call
{
  my ($file,$command,$value) = @_;
  my $data = [$value & 0xff, $value >> 8];
  i2c_smbus_access $file, $SMBUS_WRITE, $command, $SMBUS_PROC_CALL, $data 
         or return -1;
  return $$data[0] + 256 * $$data[1];
}

# $_[0]: Reference to an opened filehandle
# $_[1]: Command byte (usually register number)
# Returns: Undefined on failure, a list of read bytes on success
# Note: some devices use the wrong endiannes; use swap_bytes to correct for 
# this.
sub i2c_smbus_read_block_data
{
  my ($file,$command) = @_;
  my $data = [];
  i2c_smbus_access $file, $SMBUS_READ, $command, $SMBUS_BLOCK_DATA, $data 
         or return;
  shift @$data;
  return @$data;
}

# $_[0]: Reference to an opened filehandle
# $_[1]: Command byte (usually register number)
# @_[2..]: List of values to write
# Returns: -1 on failure, 0 on success.
# Note: some devices use the wrong endiannes; use swap_bytes to correct for 
# this.
sub i2c_smbus_write_block_data
{
  my ($file,$command,@data) = @_;
  i2c_smbus_access $file, $SMBUS_WRITE, $command, $SMBUS_BLOCK_DATA, \@data 
         or return;
  return 0;
}

####################
# ADAPTER SCANNING #
####################

use vars qw(@chips_detected);

# We will build a complicated structure @chips_detected here, being:
# A list of
#  references to hashes
#    with field 'driver', being a string with the driver name for this chip;
#    with field 'detected'
#      being a reference to a list of
#        references to hashes of type 'detect_data';
#    with field 'misdetected'
#      being a reference to a list of
#        references to hashes of type 'detect_data'

# Type detect_data:
# A hash
#   with field 'i2c_adap' containing an adapter string as appearing
#        in /proc/bus/i2c (if this is an I2C detection)
#  with field 'i2c_algo' containing an algorithm string as appearing
#       in /proc/bus/i2c (if this is an I2C detection)
#  with field 'i2c_devnr', contianing the /dev/i2c-* number of this
#       adapter (if this is an I2C detection)
#  with field 'i2c_driver', containing the driver name for this adapter
#       (if this is an I2C detection)
#  with field 'i2c_addr', containing the I2C address of the detection;
#       (if this is an I2C detection)
#  with field 'i2c_sub_addrs', containing a reference to a list of
#       other I2C addresses (if this is an I2C detection)
#  with field 'isa_addr' containing the ISA address this chip is on 
#       (if this is an ISA detection)
#  with field 'conf', containing the confidence level of this detection
#  with field 'chipname', containing the chip name

# This adds a detection to the above structure. We do no alias detection
# here; so you should do ISA detections *after* all I2C detections.
# Not all possibilities of i2c_addr and i2c_sub_addrs are exhausted.
# In all normal cases, it should be all right.
# $_[0]: chip driver
# $_[1]: reference to data hash
# Returns: Nothing
sub add_i2c_to_chips_detected
{
  my ($chipdriver,$datahash) = @_;
  my ($i,$new_detected_ref,$new_misdetected_ref,$detected_ref,$misdetected_ref,
      $main_entry,$detected_entry,$put_in_detected,@hash_addrs,@entry_addrs);

  # First determine where the hash has to be added.
  for ($i = 0; $i < @chips_detected; $i++) {
    last if ($chips_detected[$i]->{driver} eq $chipdriver);
  }
  if ($i == @chips_detected) {
    push @chips_detected, { driver => $chipdriver,
                            detected => [],
                            misdetected => [] };
  }
  $new_detected_ref = $chips_detected[$i]->{detected};
  $new_misdetected_ref = $chips_detected[$i]->{misdetected};

  # Find out whether our new entry should go into the detected or the
  # misdetected list. We only compare main i2c_addr here; so we can have
  # the unlikely case that we replace a subsidiary i2c_addr with a higher
  # confidence value. Too bad.
  $put_in_detected = 1;
  FIND_LOOP:
  foreach $main_entry (@chips_detected) {
    foreach $detected_entry (@{$main_entry->{detected}}) {
      if ($detected_entry->{i2c_devnr} == $datahash->{i2c_devnr} and
          $detected_entry->{i2c_addr} == $datahash->{i2c_addr}) {
        if ($detected_entry->{conf} >= $datahash->{conf}) {
          $put_in_detected = 0;
        }
        last FIND_LOOP;
      }
    }
  }

  if ($put_in_detected) {
    # Here, we move all entries from detected to misdetected which
    # match at least in one main or sub address. This may not be the
    # best idea to do, as it may remove detections without replacing
    # them with second-best ones. Too bad.
    @hash_addrs = ($datahash->{i2c_addr});
    push @hash_addrs, @{$datahash->{i2c_sub_addrs}} 
         if exists $datahash->{i2c_sub_addrs};
    foreach $main_entry (@chips_detected) {
      $detected_ref = $main_entry->{detected};
      $misdetected_ref = $main_entry->{misdetected};
      for ($i = @$detected_ref-1; $i >=0; $i--) {
        @entry_addrs = ($detected_ref->[$i]->{i2c_addr});
        push @entry_addrs, @{$detected_ref->[$i]->{i2c_sub_addrs}}
             if exists $detected_ref->[$i]->{i2c_sub_addrs};
        if (any_list_match \@entry_addrs, \@hash_addrs) {
          push @$misdetected_ref,$detected_ref->[$i];
          splice @$detected_ref, $i, 1;
        }
      }
    }

    # Now add the new entry to detected
    push @$new_detected_ref, $datahash;
  } else {
    # No hard work here 
    push @$new_misdetected_ref, $datahash;
  }
}

# This adds a detection to the above structure. We also do alias detection
# here; so you should do ISA detections *after* all I2C detections.
# $_[0]: alias detection function
# $_[1]: chip driver
# $_[2]: reference to data hash
# Returns: Nothing
sub add_isa_to_chips_detected
{
  my ($alias_detect,$chipdriver,$datahash) = @_;
  my ($i,$new_detected_ref,$new_misdetected_ref,$detected_ref,$misdetected_ref,
      $main_entry);

  # First determine where the hash has to be added.
  for ($i = 0; $i < @chips_detected; $i++) {
    last if ($chips_detected[$i]->{driver} eq $chipdriver);
  }
  if ($i == @chips_detected) {
    push @chips_detected, { driver => $chipdriver,
                            detected => [],
                            misdetected => [] };
  }
  $new_detected_ref = $chips_detected[$i]->{detected};
  $new_misdetected_ref = $chips_detected[$i]->{misdetected};

  # Now, we are looking for aliases. An alias can only be the same chiptype.
  # If an alias is found in the misdetected list, we add the new information
  # and terminate this function. If it is found in the detected list, we
  # still have to check whether another chip has claimed this ISA address.
  # So we remove the old entry from the detected list and put it in datahash.

  # Misdetected alias detection:
  for ($i = 0; $i < @$new_misdetected_ref; $i++) {
    if (exists $new_misdetected_ref->[$i]->{i2c_addr} and
        not exists $new_misdetected_ref->[$i]->{isa_addr} and
        defined $alias_detect and
        $new_misdetected_ref->[$i]->{chipname} eq $datahash->{chipname}) {
      open FILE,"/dev/i2c-$new_misdetected_ref->[$i]->{devnr}" or
           print("Can't open ",
                 "/dev/i2c-$new_misdetected_ref->[$i]->{devnr}?!?\n"),
           next;
      i2c_set_slave_addr \*FILE,$new_misdetected_ref->[$i]->{address} or
           print("Can't set I2C address for ",
                 "/dev/i2c-$new_misdetected_ref->[$i]->{devnr}?!?\n"),
           next;
      if (&$alias_detect ($datahash->{isa_addr},\*FILE,
                          $new_misdetected_ref->[$i]->{i2c_addr})) {
        $new_misdetected_ref->[$i]->{isa_addr} = $datahash->{isa_addr};
        close FILE;
        return;
      }
      close FILE;
    }
  }

  # Detected alias detection:
  for ($i = 0; $i < @$new_detected_ref; $i++) {
    if (exists $new_detected_ref->[$i]->{i2c_addr} and
        not exists $new_detected_ref->[$i]->{isa_addr} and
        defined $alias_detect and
        $new_detected_ref->[$i]->{chipname} eq $datahash->{chipname}) {
      open FILE,"/dev/i2c-$new_detected_ref->[$i]->{devnr}" or
           print("Can't open ",
                 "/dev/i2c-$new_detected_ref->[$i]->{devnr}?!?\n"),
           next;
      i2c_set_slave_addr \*FILE,$new_detected_ref->[$i]->{address} or
           print("Can't set I2C address for ",
                 "/dev/i2c-$new_detected_ref->[$i]->{devnr}?!?\n"),
           next;
      if (&$alias_detect ($datahash->{isa_addr},\*FILE,
                          $new_detected_ref->[$i]->{i2c_addr})) {
        $new_detected_ref->[$i]->{isa_addr} = $datahash->{isa_addr};
        ($datahash) = splice (@$new_detected_ref, $i, 1);
        close FILE;
        last;
      }
      close FILE;
    }
  }


  # Find out whether our new entry should go into the detected or the
  # misdetected list. We only compare main isa_addr here, of course.
  foreach $main_entry (@chips_detected) {
    $detected_ref = $main_entry->{detected};
    $misdetected_ref = $main_entry->{misdetected};
    for ($i = 0; $i < @{$main_entry->{detected}}; $i++) {
      if (exists $detected_ref->[$i]->{isa_addr} and
          $detected_ref->[$i]->{isa_addr} == $datahash->{isa_addr}) {
        if ($detected_ref->[$i]->{conf} >= $datahash->{conf}) {
          push @$new_misdetected_ref, $datahash;
        } else {
          push @$misdetected_ref,$detected_ref->[$i];
          splice @$detected_ref, $i,1;
          push @$new_detected_ref, $datahash;
        }
        return;
      }
    }
  }

  # Nor found? OK, put it in the detected list
  push @$new_detected_ref, $datahash;
}

# $_[0]: The number of the adapter to scan
# $_[1]: The name of the adapter, as appearing in /proc/bus/i2c
# $_[2]: The name of the algorithm, as appearing in /proc/bus/i2c
# $_[3]: The driver of the adapter
sub scan_adapter
{
  my ( $adapter_nr,$adapter_name,$algorithm_name,$adapter_driver, 
       $not_to_scan) = @_;
  my ($chip, $addr, $conf,@chips,$new_hash,$other_addr);

  # As we modify it, we need a copy
  my @not_to_scan = @$not_to_scan;

  open FILE,"/dev/i2c-$adapter_nr" or 
       (print "Can't open /dev/i2c-$adapter_nr ($!)\n"), return;

  # Now scan each address in turn
  foreach $addr (0..0x7f) {
    # As the not_to_scan list is sorted, we can check it fast
    if (@not_to_scan and $not_to_scan[0] == $addr) {
      shift @not_to_scan;
      next;
    }

    i2c_set_slave_addr(\*FILE,$addr) or print("Can't set address to $_?!?\n"), 
                                     next;

    next unless i2c_smbus_read_byte(\*FILE) >= 0;
    printf "Client found at address 0x%02x\n",$addr;

    foreach $chip (@chip_ids) {
      if (exists $$chip{i2c_addrs} and contains $addr, @{$$chip{i2c_addrs}}) {
        print "Probing for `$$chip{name}'... ";
        if (($conf,@chips) = &{$$chip{i2c_detect}} (\*FILE ,$addr)) {
          print "Success!\n",
                "    (confidence $conf, driver `$$chip{driver}'";
          if (@chips) {
            print ", other addresses:";
            @chips = sort @chips;
            foreach $other_addr (sort @chips) {
              printf(" %02x",$other_addr);
            }
          }
          printf "\n";
          $new_hash = { conf => $conf,
                        i2c_addr => $addr,
                        chipname =>  $$chip{name},
                        i2c_adap => $adapter_name,
                        i2c_algo => $algorithm_name,
                        i2c_driver => $adapter_driver,
                        i2c_devnr => $adapter_nr,
                      };
          $new_hash->{i2c_sub_addrs} = \@chips if (@chips);
          add_i2c_to_chips_detected $$chip{driver}, $new_hash;
        } else {
          print "Failed!\n";
        }
      }
    }
  }
}

sub scan_isa_bus
{
  my ($chip,$addr,$conf);
  foreach $chip (@chip_ids) {
    next if not exists $$chip{isa_addrs} or not exists $$chip{isa_detect};
    print "Probing for `$$chip{name}'\n";
    foreach $addr (@{$$chip{isa_addrs}}) {
      if ($addr) {
        printf "  Trying address 0x%04x... ", $addr;
      } else {
        print "  Trying general detect... ";
      }
      $conf = &{$$chip{isa_detect}} ($addr);
      print("Failed!\n"), next if not defined $conf;
      print "Success!\n";
      printf "    (confidence %d, driver `%s')\n", $conf, $$chip{driver};
      add_isa_to_chips_detected $$chip{alias_detect},$$chip{driver}, 
                                { conf => $conf,
                                  isa_addr => $addr,
                                  chipname =>  $$chip{name},
                                };
    }
  }
}


##################
# CHIP DETECTION #
##################

# Each function returns a confidence value. The higher this value, the more
# sure we are about this chip. A Winbond W83781D, for example, will be
# detected as a LM78 too; but as the Winbond detection has a higher confidence 
# factor, you should identify it as a Winbond.

# Each function returns a list. The first element is the confidence value;
# Each element after it is an SMBus address. In this way, we can detect 
# chips with several SMBus addresses. The SMBus address for which the
# function was called is never returned.

# If there are devices which get confused if they are only read from, then
# this program will surely confuse them. But we guarantee never to write to
# any of these devices.


# $_[0]: Chip to detect (0 = LM78, 1 = LM78-J, 2 = LM79)
# $_[1]: A reference to the file descriptor to access this chip.
#        We may assume an i2c_set_slave_addr was already done.
# $_[2]: Address
# Returns: undef if not detected, (7) if detected.
# Registers used:
#   0x40: Configuration
#   0x48: Full I2C Address
#   0x49: Device ID
# Note that this function is always called through a closure, so the
# arguments are shifted by one place.
sub lm78_detect
{
  my $reg;
  my ($chip,$file,$addr) = @_;
  return unless i2c_smbus_read_byte_data($file,0x48) == $addr;
  return unless (i2c_smbus_read_byte_data($file,0x40) & 0x80) == 0x00;
  $reg = i2c_smbus_read_byte_data($file,0x49);
  return unless ($chip == 0 and $reg == 0x00) or
                    ($chip == 1 and $reg == 0x40) or
                    ($chip == 2 and ($reg & 0xfe) == 0xc0);
  return (7);
}

# $_[0]: Chip to detect (0 = LM78, 1 = LM78-J, 2 = LM79)
# $_[1]: Address
# Returns: undef if not detected, (7) if detected.
# Note: Only address 0x290 is scanned at this moment.
sub lm78_isa_detect
{
  my ($chip,$addr) = @_ ;
  my $val = inb ($addr + 1);
  return if inb ($addr + 2) != $val or inb ($addr + 3) != $val or 
            inb ($addr + 7) != $val;
  my $readproc = sub { isa_read_byte $addr + 5, $addr + 6, @_ };
  return unless (&$readproc(0x40) & 0x80) == 0x00;
  my $reg = &$readproc(0x49);
  return unless ($chip == 0 and $reg == 0x00) or
                ($chip == 1 and $reg == 0x40) or
                ($chip == 2 and ($reg & 0xfe) == 0xc0);
  return 7;
}


# $_[0]: Chip to detect (0 = LM78, 1 = LM78-J, 2 = LM79)
# $_[1]: ISA address
# $_[2]: I2C file handle
# $_[3]: I2C address
sub lm78_alias_detect
{
  my ($chip,$isa_addr,$file,$i2c_addr) = @_;
  my $i;
  my $readproc = sub { isa_read_byte $isa_addr + 5, $isa_addr + 6, @_ };
  return 0 unless &$readproc(0x48) == $i2c_addr;
  for ($i = 0x2b; $i <= 0x3d; $i ++) {
    return 0 unless &$readproc($i) == i2c_smbus_read_byte_data($file,$i);
  }
  return 1;
}

# $_[0]: A reference to the file descriptor to access this chip.
#        We may assume an i2c_set_slave_addr was already done.
# $_[1]: Address
# Returns: undef if not detected, (3) if detected.
# Registers used:
#   0x01: Configuration
#   0x02: Hysteris
#   0x03: Overtemperature Shutdown
# Detection really sucks! It is only based on the fact that the LM75 has only
# four registers. Any other chip in the valid address range with only four
# registers will be detected too.
# Note that register $00 may change, so we can't use the modulo trick on it.
sub lm75_detect
{
  my $i;
  my ($file,$addr) = @_;
  my $conf = i2c_smbus_read_byte_data($file,0x01);
  my $hyst = i2c_smbus_read_word_data($file,0x02);
  my $os = i2c_smbus_read_word_data($file,0x03);
  for ($i = 0x00; $i <= 0xF; $i += 1) {
    return if i2c_smbus_read_byte_data($file,($i * 0x10) + 0x01) != $conf;
    return if i2c_smbus_read_word_data($file,($i * 0x10) + 0x02) != $hyst;
    return if i2c_smbus_read_word_data($file,($i * 0x10) + 0x03) != $os;
  }
  return (3);
}
  

# $_[0]: A reference to the file descriptor to access this chip.
#        We may assume an i2c_set_slave_addr was already done.
# $_[1]: Address
# Returns: undef if not detected, (3) if detected.
# Registers used:
# Registers used:
#   0x02: Interrupt state register
# How to detect this beast? 
sub lm80_detect
{
  my $i;
  my ($file,$addr) = @_;
  return if (i2c_smbus_read_byte_data($file,$0x02) & 0xc0) != 0;
  for ($i = 0x2a; $i <= 0x3d; $i++) {
    my $reg = i2c_smbus_read_byte_data($file,$i);
    return if i2c_smbus_read_byte_data($file,$i+0x40) != $reg;
    return if i2c_smbus_read_byte_data($file,$i+0x80) != $reg;
    return if i2c_smbus_read_byte_data($file,$i+0xc0) != $reg;
  }
  return (3);
}
  
# $_[0]: Chip to detect (0 = W83781D, 1 = W83782D, 3 = W83783S)
# $_[1]: A reference to the file descriptor to access this chip.
#        We may assume an i2c_set_slave_addr was already done.
# $_[2]: Address
# Returns: undef if not detected, (8,addr1,addr2) if detected, but only
#          if the LM75 chip emulation is enabled.
# Registers used:
#   0x48: Full I2C Address
#   0x4a: I2C addresses of emulated LM75 chips
#   0x4e: Vendor ID byte selection, and bank selection
#   0x4f: Vendor ID
#   0x58: Device ID (only when in bank 0); both 0x10 and 0x11 is seen for
#         W83781D though Winbond documents 0x10 only.
# Note: Fails if the W8378xD is not in bank 0!
# Note: Detection overrules a previous LM78 detection
sub w83781d_detect
{
  my ($reg1,$reg2,@res);
  my ($chip,$file,$addr) = @_;
  return unless i2c_smbus_read_byte_data($file,0x48) == $addr;
  $reg1 = i2c_smbus_read_byte_data($file,0x4e);
  $reg2 = i2c_smbus_read_byte_data($file,0x4f);
  return unless (($reg1 & 0x80) == 0x00 and $reg2 == 0xa3) or 
                (($reg1 & 0x80) == 0x80 and $reg2 == 0x5c);
  return unless ($reg1 & 0x07) == 0x00;
  $reg1 = i2c_smbus_read_byte_data($file,0x58);
  return if $chip == 0 and  ($reg1 & 0xfe) != 0x10;
  return if $chip == 1 and  $reg1 != 0x30;
  return if $chip == 2 and  $reg1 != 0x40;
  $reg1 = i2c_smbus_read_byte_data($file,0x4a);
  @res = (8);
  push @res, ($reg1 & 0x07) + 0x48 unless $reg1 & 0x08;
  push @res, (($reg1 & 0x80) >> 4) + 0x48 unless $reg1 & 0x80;
  return @res;
}

# $_[0]: Chip to detect (0 = W83781D, 1 = W83782D, 3 = W83783S)
# $_[1]: ISA address
# $_[2]: I2C file handle
# $_[3]: I2C address
sub w83781d_alias_detect
{
  my ($chip,$isa_addr,$file,$i2c_addr) = @_;
  my $i;
  my $readproc = sub { isa_read_byte $isa_addr + 5, $isa_addr + 6, @_ };
  return 0 unless &$readproc(0x48) == $i2c_addr;
  for ($i = 0x2b; $i <= 0x3d; $i ++) {
    return 0 unless &$readproc($i) == i2c_smbus_read_byte_data($file,$i);
  }
  return 1;
}

# $_[0]: Chip to detect (0 = W83781D, 1 = W83782D, 3 = W83783S)
# $_[1]: Address
# Returns: undef if not detected, (8) if detected.
sub w83781d_isa_detect
{
  my ($chip,$addr) = @_ ;
  my ($reg1,$reg2);
  my $val = inb ($addr + 1);
  return if inb ($addr + 2) != $val or inb ($addr + 3) != $val or 
            inb ($addr + 7) != $val;
  my $read_proc = sub { isa_read_byte $addr + 5, $addr + 6, @_ };
  $reg1 = &$read_proc(0x4e);
  $reg2 = &$read_proc(0x4f);
  return unless (($reg1 & 0x80) == 0x00 and $reg2 == 0xa3) or 
                (($reg1 & 0x80) == 0x80 and $reg2 == 0x5c);
  return unless ($reg1 & 0x07) == 0x00;
  $reg1 = &$read_proc(0x58);
  return if $chip == 0 and  ($reg1 & 0xfe) != 0x10;
  return if $chip == 1 and  $reg1 != 0x30;
  return if $chip == 2 and  $reg1 != 0x40;
  return 8;
}

# $_[0]: Chip to detect (0 = Revision 0x00, 1 = Revision 0x80)
# $_[1]: A reference to the file descriptor to access this chip.
#        We may assume an i2c_set_slave_addr was already done.
# $_[2]: Address
# Returns: undef if not detected, (6) if detected.
# Registers used:
#   0x00: Device ID
#   0x01: Revision ID
#   0x03: Configuration 
# Mediocre detection
sub gl518sm_detect
{
  my $reg;
  my ($chip,$file,$addr) = @_;
  return unless i2c_smbus_read_byte_data($file,0x00) == 0x80;
  return unless (i2c_smbus_read_byte_data($file,0x03) & 0x80) == 0x00;
  $reg = i2c_smbus_read_byte_data($file,0x01);
  return unless ($chip == 0 and $reg == 0x00) or
                ($chip == 1 and $reg == 0x80);
  return (6);
}

# $_[0]: A reference to the file descriptor to access this chip.
#        We may assume an i2c_set_slave_addr was already done.
# $_[1]: Address
# Returns: undef if not detected, (5) if detected.
# Registers used:
#   0x00: Device ID
#   0x01: Revision ID
#   0x03: Configuration 
# Mediocre detection
sub gl520sm_detect
{
  my ($file,$addr) = @_;
  return unless i2c_smbus_read_byte_data($file,0x00) == 0x20;
  return unless (i2c_smbus_read_byte_data($file,0x03) & 0x80) == 0x00;
  # The line below must be better checked before I dare to use it.
  # return unless i2c_smbus_read_byte_data($file,0x01) == 0x00;
  return (5);
}

# $_[0]: A reference to the file descriptor to access this chip.
#        We may assume an i2c_set_slave_addr was already done.
# $_[1]: Address
# Returns: undef if not detected, (5) if detected.
# Registers used:
#   0x3e: Company ID
#   0x40: Configuration
#   0x48: Full I2C Address
# Note: Detection overrules a previous LM78 detection
sub adm9240_detect
{
  my ($file,$addr) = @_;
  return unless i2c_smbus_read_byte_data($file,0x3e) == 0x23;
  return unless (i2c_smbus_read_byte_data($file,0x40) & 0x80) == 0x00;
  return unless i2c_smbus_read_byte_data($file,0x48) == $addr;
  
  return (8);
}

# $_[0]: Chip to detect (0 = ADM1021, 1 = MAX1617)
# $_[1]: A reference to the file descriptor to access this chip.
#        We may assume an i2c_set_slave_addr was already done.
# $_[2]: Address
# Returns: undef if not detected, (6) or (3) if detected.
# Registers used:
#   0xfe: Company ID
#   0x02: Status
# Note: Especially the Maxim has very bad detection; we give it a low 
# confidence value.
sub adm1021_detect
{
  my $reg;
  my ($chip, $file,$addr) = @_;
  return if $chip == 0 and i2c_smbus_read_byte_data($file,0xfe) != 0x41;
  # The remaining things are flaky at best. Perhaps something can be done
  # with the fact that some registers are unreadable?
  return if (i2c_smbus_read_byte_data($file,0x02) & 0x03) != 0;
  if ($chip == 0) {
    return (6);
  } else {
    return (3);
  }
}

# $_[0]: Address
# Returns: undef if not detected, (9) if detected.
# Note: It is already 99% certain this chip exists if we find the PCI
# entry. The exact address is encoded in PCI space.
sub sis5595_isa_detect
{
  my ($addr) = @_;
  my ($adapter,$try);
  my $found = 0;
  foreach $try (@pci_adapters) {
    if ($try->{procid} eq "Silicon Integrated Systems 85C503") {
      $found = 1;
      last;
    }
  }
  return if not $found;

  $found = 0;
  foreach $adapter (@pci_list) {
    if ((defined($try->{vendid}) and 
         $try->{vendid} == $adapter->{vendid} and
         $try->{devid} == $adapter->{devid} and
         $try->{func} == $adapter->{func}) or
        (! defined($adapter->{vendid}) and
         $adapter->{desc} =~ /$try->{procid}/ and
         $try->{func} == $adapter->{func})) {
      $found = 1;
      last;
    }
  }
  return if not $found;

  return (9);
}

################
# MAIN PROGRAM #
################

# $_[0]: reference to a list of chip hashes
sub print_chips_report 
{
  my ($listref) = @_;
  my $data;
  
  foreach $data (@$listref) {
    my $is_i2c = exists $data->{i2c_addr};
    my $is_isa = exists $data->{isa_addr};
    print "  * ";
    if ($is_i2c) {
      printf "Bus `%s' (%s)\n", $data->{i2c_adap}, $data->{i2c_algo};
      printf "    Busdriver `%s', I2C address 0x%02x", 
             $data->{i2c_driver}, $data->{i2c_addr};
      if (exists $data->{i2c_sub_addrs}) {
        print " (and";
        my $sub_addr;
        foreach $sub_addr (@{$data->{i2c_sub_addrs}}) {
          printf " 0x%02x",$sub_addr;
        }
        print ")"
      }
      print "\n";
    }
    if ($is_isa) {
      print "    " if  $is_i2c;
      if ($data->{isa_addr}) {
        printf "ISA bus address 0x%04x (Busdriver `i2c-isa')\n", 
               $data->{isa_addr};
      } else {
        printf "ISA bus, undetermined address (Busdriver `i2c-isa')\n"
      }
    }
    printf "    Chip `%s' (confidence: %d)\n",
           $data->{chipname},  $data->{conf};
  }
}

# $_[0]: A reference to the file descriptor to access this chip.
#        We may assume an i2c_set_slave_addr was already done.
# $_[1]: Address
# Returns: undef if not detected, (5) if detected.
# Registers used:
#   0x00-0x63: PC-100 Data and Checksum
sub eeprom_detect
{
  my ($file,$addr) = @_;
  # Check the checksum for validity (only works for PC-100 DIMMs)
  my $checksum = 0;
  for (my $i = 0; $i <= 62; $i = $i + 1) {
    $checksum = $checksum + i2c_smbus_read_byte_data($file,$i);
  }
  $checksum=$checksum & 255;
  if (i2c_smbus_read_byte_data($file,63) == $checksum) {
  	return (8);
  }
  # Even if checksum test fails, it still may be an eeprom
  return (1);
}

################
# MAIN PROGRAM #
################

sub main
{
  my (@adapters,$res,$did_adapter_detection,$detect_others,$adapter);

  initialize_proc_pci;
  initialize_modules_list;

  print " This program will help you to determine which I2C/SMBus modules you ",
        "need to\n",
        " load to use lm_sensors most effectively.\n";
  print " You need to have done a `make install', issued a `depmod -a' and ",
        "made sure\n",
        " `/etc/conf.modules' (or `/etc/modules.conf') contains the ",
        "appropriate\n",
        " module path before you can use some functions of this utility. ",
        "Read\n",
        " doc/modules for more information.\n";
  print " Also, you need to be `root', or at least have access to the ",
        "/dev/i2c-* files\n",
        " for some things. You can use prog/mkdev/mkdev.sh to create these ",
        "/dev files\n",
        " if you do not have them already.\n\n";

  print " We can start with probing for (PCI) I2C or SMBus adapters.\n";
  print " You do not need any special privileges for this.\n";
  print " Do you want to probe now? (YES/no): ";
  @adapters = adapter_pci_detection 
                        if ($did_adapter_detection = not <STDIN> =~ /\s*[Nn]/);

  print "\n";

  if (not $did_adapter_detection) {
    print " As you skipped adapter detection, we will only scan already ",
          "loaded adapter\n",
          " modules. You can still be prompted for non-detectable adapters.\n",
          " Do you want to? (yes/NO): ";
    $detect_others = <STDIN> =~ /^\s*[Yy]/;
  } elsif ($> != 0) {
    print " As you are not root, we can't load adapter modules. We will only ",
          "scan\n",
          " already loaded adapters.\n";
    $detect_others = 0;
  } else {
    print " We will now try to load each adapter module in turn.\n";
    foreach $adapter (@adapters) {
      if (contains $adapter, @modules_list) {
        print "Module `$adapter' already loaded.\n";
      } else {
        print "Load `$adapter'? (YES/no): ";
        unless (<STDIN> =~ /^\s*[Nn]/) {
          if (system ("modprobe", $adapter)) {
            print "Loading failed ($!)... skipping.\n";
          } else {
            print "Module loaded succesfully.\n";
          }
        }
      }
    }
    print " Do you now want to be prompted for non-detectable adapters? ",
          "(yes/NO): ";
    $detect_others = <STDIN> =~ /^\s*[Yy]/ ;
  }

  if ($detect_others) {
    foreach $adapter (@undetectable_adapters) {
      print "Load `$adapter'? (YES/no): ";
      unless (<STDIN> =~ /^\s*[Nn]/) {
        if (system ("modprobe", $adapter)) {
          print "Loading failed ($!)... skipping.\n";
        } else {
          print "Module loaded succesfully.\n";
        }
      }
    }
  }

  print " To continue, we need modules `i2c-proc' and `i2c-dev' to be ",
        "loaded.\n";
  if (contains "i2c-proc", @modules_list) {
    print "i2c-proc is already loaded.\n";
  } else {
    if ($> != 0) {
      print " i2c-proc is not loaded, and you are not root. I can't ",
            "continue.\n";
      exit;
    } else {
      print " i2c-proc is not loaded. May I load it now? (YES/no): ";
      if (<STDIN> =~ /^\s*[Nn]/) {
        print " Sorry, in that case I can't continue.\n";
        exit;
      } elsif (system "modprobe","i2c-proc") {
        print " Loading failed ($!), aborting.\n";
        exit;
      } else {
        print " Module loaded succesfully.\n";
      }
    }
  }
  if (contains "i2c-dev", @modules_list) {
    print "i2c-dev is already loaded.\n";
  } else {
    if ($> != 0) {
      print " i2c-dev is not loaded. As you are not root, we will just hope ",
            "you edited\n",
            " `/etc/conf.modules' (or `/etc/modules.conf') for automatic ",
            "loading of\n",
            " this module. If not, you won't be able to open any /dev/i2c-* ",
            "file.\n";
    } else {
      print " i2c-dev is not loaded. Do you want to load it now? (YES/no): ";
      if (<STDIN> =~ /^\s*[Nn]/) {
        print " Well, you will know best. We will just hope you edited ",
              "`/etc/conf.modules'\n",
              " (or `/etc/modules.conf') for automatic loading of this ",
              "module. If not,",
              " you won't be able to open any /dev/i2c-* file.\n";
      } elsif (system "modprobe","i2c-dev") {
        print " Loading failed ($!), aborting.\n";
        exit;
      } else {
        print " Module loaded succesfully.\n";
      }
    }
  }

  print "\n We are now going to do the adapter probings. Some adapters may ",
        "hang halfway\n",
        " through; we can't really help that. Also, some chips will be double ",
        "detected;\n",
        " choose the one with the highest confidence value in that case.\n",
        " If you found that the adapter hung after probing a certain address, ",
        "you can\n",
        " specify that address to remain unprobed.\n";

  my ($inp,@not_to_scan,$inp2);
  open INPUTFILE,"/proc/bus/i2c" or die "Couldn't open /proc/bus/i2c?!?";
  while (<INPUTFILE>) {
    print "\n";
    my ($dev_nr,$adap,$algo) = /^i2c-(\S+)\s+\S+\s+(.*?)\s*\t\s*(.*?)\s+$/;
    print "Next adapter: $adap ($algo)\n";
    print "Do you want to scan it? (YES/no/selectively): ";
    
    $inp = <STDIN>;
    @not_to_scan=();
    if ($inp =~ /^\s*[Ss]/) {
      print "Please enter one or more addresses not to scan. Separate them ",
            "with comma's.\n",
            "You can specify a range by using dashes. Addresses may be ",
            "decimal (like 54)\n",
            "or hexadecimal (like 0x33).\n",
            "Addresses: ";
      $inp2 = <STDIN>;
      chop $inp2;
      @not_to_scan = parse_not_to_scan 0,0x7f,$inp2;
    }
    scan_adapter $dev_nr, $adap, $algo, find_adapter_driver($adap,$algo),
                 \@not_to_scan   unless $inp =~ /^\s*[Nn]/;
  }

  print "\n Some chips are also accessible through the ISA bus. ISA probes ",
        "are\n",
        " typically a bit more dangerous, as we have to write to I/O ports ",
        "to do\n",
        " this. ";
  if ($> != 0) {
    print "As you are not root, we shall skip this step.\n";
  } else {
    print " Do you want to scan the ISA bus? (YES/no): ";
    if (not <STDIN> =~ /^\s*[Nn]/) {
      initialize_ioports or die "Sorry, can't access /dev/port ($!)?!?";
      scan_isa_bus;
    }
  }

  print "\n Now follows a summary of the probes I have just done.\n";
  my ($chip,$data);
  foreach $chip (@chips_detected) {
    print "\nDriver `$$chip{driver}' ";
    if (@{$$chip{detected}}) {
      if (@{$$chip{misdetected}}) {
        print "(should be inserted but causes problems):\n";
      } else {
        print "(should be inserted):\n";
      }
    } else {
      if (@{$$chip{misdetected}}) {
        print "(may not be inserted):\n";
      } else {
        print "(should not be inserted, but is harmless):\n";
      }
    }
    if (@{$$chip{detected}}) {
      print "  Detects correctly:\n";
      print_chips_report $chip->{detected};
    }
    if (@{$$chip{misdetected}}) {
      print "  Misdetects:\n";
      print_chips_report $chip->{misdetected};
    }
  }
}

main;
