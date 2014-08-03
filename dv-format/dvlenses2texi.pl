#!/usr/bin/env perl
use utf8;

## Copyright (C) 2014 David Pinto <david.pinto@bioch.ox.ac.uk>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.

## A script to convert SoftWoRx's dvlenses.tab file into the Texinfo table
## displayed in our DV file format specs.
##
## Either accepts a file name as last argument, or reads from STDIN.

use strict;
use warnings;
use 5.010;

my $pipe;
if (@ARGV) {
  my $path = pop @ARGV;
  open($pipe, "<", $path)
    or die "Could not open '$path' for reading: $!";
} else {
  $pipe = \*STDIN;
}

my $comment    = sub { $_[0] =~ m/^\s*#/ };
my $empty_line = sub { $_[0] =~ m/^\s*$/ };

my @lenses;
while (my $line = <$pipe>) {
  next if &$comment($line) || &$empty_line($line);

  my %lens;
  until (&$empty_line($line)) { # empty line marks the end of this lens
    next if &$comment($line);   # ignore comments
    chomp $line;
    warn ("No key and value on line '$line'")
      unless $line =~ m/^(id|name|magn|na|fl|wd|type|pn|api#)\s*=\s*(.*)$/;
    ## Looking at the file being parsed, it seems that it is an empty that
    ## delimits each lens information. However, it also says that empty
    ## lines are ignored so maybe each lens it's the specification of a
    ## new ID. If so, this is very broken and needs fixing.
    die ("Found two ID values in the same block, fix the script.")
      if (lc($1) eq "id" && defined ($lens{id}));
    $lens{$1} = $2;
    last unless (defined ($line = <$pipe>));
  }

  push (@lenses, \%lens);
}

@lenses = sort {$a->{id} <=> $b->{id}} @lenses;

say <<'END';
@c This file is generated automatically using our dvlenses2texi.pl script.
@c But because the text file with the lenses information is not easily
@c made available, it is still worth to commit this file, and keep it under
@c version control.
@c
@c DO NOT EDIT THIS FILE --- IT IS GENERATED AUTOMATICALLY.
END

foreach my $l(@lenses) {

  ## Their file format has some limitations which are worked around by manual
  ## comments.  We have no other way than to hard-code these here.
  if (defined $l->{wd}) {
    if ($l->{wd} =~ m/approximate range=6.4-7.6/) {
      $l->{wd} = "6.4--7.6";
    }
  }
  if (scalar grep {$_ == $l->{id}} qw(10400 10401 10404)) {
    $l->{fl} = '@math{\approx 4.04}';
  }

  ## The magnification value looks better followed by an "X".  Also, remove
  ## the fractional part if it not required
  if (defined $l->{magn}) {
    my $m = $l->{magn};
    $m = int ($m) if int ($m) == $m;
    $m .= " X";
    $l->{magn} = $m;
  }

  say '@item ' . $l->{id};
  say '@tab ' . ($l->{name}    // "");
  say '@tab ' . ($l->{magn}    // "");
  say '@tab ' . ($l->{fl}      // "");
  say '@tab ' . ($l->{wd}      // "");
  say '@tab ' . ($l->{type}    // "");
#  say '@tab ' . ($l->{pn}      // "");
#  say '@tab ' . ($l->{'api#'}  // "");
  say "";
}
