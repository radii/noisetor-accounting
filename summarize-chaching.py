#!/usr/bin/env python

import getopt, json, re, os, sys

from time import strftime, localtime

verbose = 0

def headline(s):
    '''print s followed by a line of matching dashes'''
    print s
    print re.sub('[^ ]', '-', s)

def print_summary(ytd_json, oneoff_json, expenses):
    '''print formatted summary of Noisetor financials, given chaching
    JSON for YTD donations and additional JSON for one-off donations.
    '''
    global verbose
    donations = ytd_json['donations'] + oneoff_json['donations']

    total_gross = 0.0
    total_net = 0.0
    month_gross = {}

    header = 'Date        gross    net fee%'
    #        '2011-11-11 100.00  98.00  2%'
    format = '%10s %6.2f %6.2f %2d%%'
    if verbose >= 1:
        headline(header)
    for d in donations:
        (t, g, n) = (d['timestamp'], d['payment_gross'], d['payment_net'])
        tm = localtime(t)
        datestr = strftime('%Y-%m-%d', tm)
        k = (tm.tm_year, tm.tm_mon)
        month_gross[k] = month_gross.get(k, 0) + g
        f = g - n
        f = 100.0 * f / g 
        if verbose >= 1:
            print format % (datestr, g, n, f)
        total_gross += g
        total_net += n

    headline('Month                Total')
    for (y, m) in sorted(month_gross.keys()):
        name = 'January February March April May June July August September October November December'.split(' ')[m-1]
        print "%-18s %7.2f" % ("%s %d" % (name, y), month_gross[(y, m)])

    f = total_gross - total_net
    f = 100.0 * f / total_gross
    print "Total: %.2f (net %.2f, %.2f%% fees)" % (total_gross, total_net, f)

    income = total_gross * .92

    print "net of 8%% to Noisebridge, total is %.2f" % income

    costs = 0
    for e in expenses['expenses']:
        costs += e['expense_amount']

    print "Spent %.2f on servers leaving %.2f in the bank" % (costs, income - costs)

url = 'http://cha-ching.noisebridge.net/v1/donations/list/all/json/noisetor'

def usage():
    print '''Usage: %s [-v] [-e expenses] [-a oneoff] [-f jsonfile] [-u url] [-o file]
    -v: be more verbose (show each donation individually)
    -a: additional donations given in file <oneoff>
    -e: Expenses given in <expenses> in JSON format
    -f: read JSON from <jsonfile> rather than fetching URL
    -u: fetch JSON from <url> rather than %s
    -o: output to <file> rather than stdout
    ''' % (sys.argv[0], url)
    sys.exit(1)

def main():
    global url, verbose
    opts = 'a:e:f:o:u:v'
    jsonfile = None
    out = sys.stdout
    oneoff = None
    expenses = None
    try:
        (opts, args) = getopt.getopt(sys.argv[1:], opts)
    except getopt.GetoptError, e:
        print e
        usage()
    for (o, v) in opts:
        if o == '-a':
            oneoff = v
        elif o == '-e':
            expenses = v
        elif o == '-f':
            jsonfile = v
        elif o == '-o':
            out = open(v, 'w')
        elif o == '-u':
            url = v
        elif o == '-v':
            verbose += 1
        else:
            usage()
    if jsonfile:
        s = open(jsonfile).read()
    else:
        s = os.popen('curl -s %s' % url, 'r').read()
    j = json.loads(s)

    if oneoff:
        s = open(oneoff).read()
        oneoff = json.loads(s)
    if expenses:
        s = open(expenses).read()
        expenses = json.loads(s)
    print_summary(j, oneoff or {}, expenses or {})

if __name__ == '__main__':
    main()
