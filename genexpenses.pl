#!/usr/bin/perl
# vim:set ts=4 sw=4 ai et smarttab:

# genexpenses.pl -- reads in a list of expenses in CSV, and outputs
# it list in JSON.  (Sorry, Andy, but I got way too tired of adding
# JSON entries by hand...)     -- mct, Thu Nov  8 20:49:58 PST 2012

use strict;
use warnings;
use Data::Dumper;

my @data;

while (my $line = <>) {
    chomp $line;
    $line =~ s/^\s*//;
    $line =~ s/#.*//;
    next unless $line;
    my @f = split /,\s*/, $line;
    die "Line $.: Unexpected number of fields\n"
        unless @f == 3 or @f == 4 or @f == 6;

    my ($timestamp, $amount, $desc, $invoice, $start, $end) = @f;

    my @elements;
    push @elements, qq!"timestamp": $timestamp!;
    push @elements, qq!"expense_amount": $amount!;
    push @elements, qq!"documentation_note": "$desc"!;
    push @elements, qq!"invoice_number": "$invoice"! if $invoice;
    push @elements, qq!"service_start": $start! if $start;
    push @elements, qq!"service_end": $end! if $end;
    push @data, "        {\n" . join(",\n", map { " "x12 . $_ } @elements) . "\n        }";
}


print qq!{\n    "expenses":[\n!;
print join(",\n", @data);
print "\n    ]\n}\n";
