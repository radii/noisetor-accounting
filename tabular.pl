#!/usr/bin/perl
# vim:set ts=4 sw=4 ai et smarttab:

use JSON;
use POSIX;

use strict;
use warnings;

@ARGV = qw(expenses.json noisetor.json oneoff.json)
    unless @ARGV;

my @transactions;
my $balance = 0;
my $colo_end_date = 0;

sub display_header {
    print "
        <html>
        <head>
            <title>Noisetor Finances</title>
        </head>
        <body>

        <table bgcolor=ffffff cellpadding=4>
        <tr bgcolor=00ff00 valign=bottom>
            <td bgcolor=dddddd>Date
            <td bgcolor=dddddd>Item
                &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
                &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
                &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
            <td bgcolor=dddddd>Income
            <td bgcolor=dddddd>PayPal Fees
            <td bgcolor=dddddd align=center>Noisebridge<br>5% Donation
            <td bgcolor=dddddd>Expense
            <td bgcolor=dddddd>Balance\n";
}

sub display {
    my ($time, $desc, $income, $expense, $paypal_fees, $noisebrige_fee) = @_;
    my $date = POSIX::strftime "%Y-%m-%d", localtime $time;

    if ($income) {
        $balance += $income - $paypal_fees - $noisebrige_fee;
    }
    if ($expense) {
        $balance -= $expense;
    }

    my $displaybalance = $balance;

    for my $i ($income, $expense, $paypal_fees, $noisebrige_fee, $displaybalance) {
        if (defined $i) {
            $i = sprintf "%.02f", $i;
        }
        else {
            $i = "&nbsp;";
        }
    }

    printf "
        <tr bgcolor=00ff00>
            <td align=left  bgcolor=00ff00>$date
            <td align=left  bgcolor=00ff00>$desc
            <td align=right bgcolor=00ff00>$income
            <td align=right bgcolor=00ff00>$paypal_fees
            <td align=right bgcolor=00ff00>$noisebrige_fee
            <td align=right bgcolor=00ff00>$expense
            <td align=right bgcolor=00ff00>$displaybalance\n";
}


for my $file (@ARGV) {
    local $/;
    open my $fd, $file or die "open: $file: $!";
    my $hash = decode_json <$fd>;

    for my $type (qw(expenses donations)) {
        if ($hash->{$type}) {
            for my $i (@{ $hash->{$type} }) {
                $i->{type} = $type;
                push @transactions, $i;
            }
        }
    }
}

@transactions = sort { $a->{timestamp} <=> $b->{timestamp} } @transactions;

display_header;

for my $i (@transactions) {

    if ($i->{type} eq "donations") {

        # paypal
        if ($i->{txn_type}) {

            if ($i->{recurring}) {
                display $i->{timestamp},
                        "PayPal Subscription",
                        $i->{payment_gross},
                        undef,
                        $i->{payment_fee},
                        int($i->{payment_gross} * 100 * .05)/100;
            }
            else {
                display $i->{timestamp},
                        "PayPal",
                        $i->{payment_gross},
                        undef,
                        $i->{payment_fee},
                        int($i->{payment_gross} * 100 * .05)/100;
            }
        }

        # one-off
        else {
                die "payment_fee != 0" unless $i->{payment_fee} == 0;
                die "payment_net != payment_gross" unless $i->{payment_net} == $i->{payment_gross};

                display $i->{timestamp},
                        $i->{documentation_note},
                        $i->{payment_gross},
                        undef,
                        0,
                        int($i->{payment_gross} * 100 * .05)/100;
        }
    }

    if ($i->{type} eq "expenses") {

        if ($i->{documentation_note} eq "Colo Payment"
            && defined $i->{service_end}
            && $i->{service_end} > $colo_end_date)
        {
            $colo_end_date = $i->{service_end};
        }

        if ($i->{service_start} and $i->{service_end}) {
            my $start = POSIX::strftime("%b %e", localtime $i->{service_start});
            my $end = POSIX::strftime("%b %e", localtime $i->{service_end});
            $i->{documentation_note} .= " ($start - $end)";
        }

        display $i->{timestamp},
                $i->{documentation_note},
                undef,
                $i->{expense_amount},
                undef,
                undef;
    }
}

print "
    </table>
    <ul>
    \n";

if ($colo_end_date) {
    my $monthly_fee = 787;
    my $months = int($balance / $monthly_fee);

    print "<li>Colo service has been paid through ",
        POSIX::strftime("%b %e, %Y", localtime $colo_end_date), "\n";

    if ($months == 0) {
        printf "<li>An additional %0.2f needs to be raised to pay for another month of service\n", $monthly_fee - $balance;
    }
    else {
        print "<li>There are enough funds to pay for an additional $months months of colo\n";
    }
}

print "<li>This information was updated at ", scalar localtime, "\n";

print "
    </ul>
    </body>
    </html>\n";
