#!/usr/bin/perl -w

use strict;
use Test::More;

require_ok('File::Spec');

require Cwd;

my $vms_unix_rpt;

if ($^O eq 'VMS') {
    if (eval 'require VMS::Feature') {
        $vms_unix_rpt = VMS::Feature::current("filename_unix_report");
    } else {
        my $unix_rpt = $ENV{'DECC$FILENAME_UNIX_REPORT'} || '';
        $vms_unix_rpt = $unix_rpt =~ /^[ET1]/i; 
    }
}


my $skip_exception = "Needs VMS::Filespec (and thus VMS)" ;

eval {
   require VMS::Filespec ;
} ;

if ( $@ ) {
   # Not pretty, but it allows testing of things not implemented solely
   # on VMS.  It might be better to change File::Spec::VMS to do this,
   # making it more usable when running on (say) Unix but working with
   # VMS paths.
   eval qq-
      sub File::Spec::VMS::vmsify  { die "$skip_exception" }
      sub File::Spec::VMS::unixify { die "$skip_exception" }
      sub File::Spec::VMS::vmspath { die "$skip_exception" }
   - ;
   $INC{"VMS/Filespec.pm"} = 1 ;
}

foreach (qw(Unix)) {
    require_ok("File::Spec::$_");
    #require("File::Spec::$_");
}

# Each element in this array is a single test. Storing them this way makes
# maintenance easy, and should be OK since perl should be pretty functional
# before these tests are run.

my @tests = (
# [ Function          ,            Expected          ,         Platform ]

[  "Unix->abs2rel('/t1/t2/t3','/t1/t2/t3')",          '.'                  ],
[  "Unix->abs2rel('/t1/t2/t4','/t1/t2/t3')",          '../t4'              ],
[  "Unix->abs2rel('/t1/t2','/t1/t2/t3')",             '..'                 ],
[  "Unix->abs2rel('/t1/t2/t3/t4','/t1/t2/t3')",       't4'                 ],
[  "Unix->abs2rel('/t4/t5/t6','/t1/t2/t3')",          '../../../t4/t5/t6'  ],
#[ "Unix->abs2rel('../t4','/t1/t2/t3')",              '../t4'              ],
[  "Unix->abs2rel('/','/t1/t2/t3')",                  '../../..'           ],
[  "Unix->abs2rel('///','/t1/t2/t3')",                '../../..'           ],
[  "Unix->abs2rel('/.','/t1/t2/t3')",                 '../../..'           ],
[  "Unix->abs2rel('/./','/t1/t2/t3')",                '../../..'           ],
[  "Unix->abs2rel('/t1/t2/t3', '/')",                 't1/t2/t3'           ],
[  "Unix->abs2rel('/t1/t2/t3', '/t1')",               't2/t3'              ],
[  "Unix->abs2rel('t1/t2/t3', 't1')",                 't2/t3'              ],
[  "Unix->abs2rel('t1/t2/t3', 't4')",                 '../t1/t2/t3'        ],
[  "Unix->abs2rel('.', '.')",                         '.'                  ],
[  "Unix->abs2rel('/', '/')",                         '.'                  ],
[  "Unix->abs2rel('../t1', 't2/t3')",                 '../../../t1'        ],
[  "Unix->abs2rel('t1', 't2/../t3')",                 '../t1'              ],
# Tests added for RT 133465
[  "Unix->abs2rel('t1/t5/t6', 't1/t2/t3/t4')",        '../../../t5/t6'     ],
[  "Unix->abs2rel('t1/t5/t6', 't1/t2/t3/../../t4')",  '../t5/t6'           ],
[  "Unix->abs2rel('t1/t5/t6', 't1/t2/t3/t4/..')",     '../../t5/t6'        ],
[  "Unix->abs2rel('t1/t2/t3/../../t4', 't1/t5/t6')",  '../../t2/t3/../../t4'],
[  "Unix->abs2rel('t1/t2/t3/..', 't1/t5/t6')",        '../../t2'           ],
[  "Unix->abs2rel('t1/t2/..', 't1/t2/../../t3')",     '../t1'              ],
#[  "Unix->abs2rel('t1/t2/t3/..', 't1/t2/t3/../../t4')", '../t2'            ], # failing
#[  "Unix->abs2rel('t1/t2/t3/..', 't1/t5/t6')", '../../t2'            ],
#[  "Unix->abs2rel('t1/t2/t3', 't1/t2/t3/../../t4')",  '../t2/t3'           ],
#[  "Unix->abs2rel('t1/t2/t3/../../t4/t5', 't1/t6/t7')",  '../../t4/t5'     ],
#[  "Unix->abs2rel('t1/t2/t3/../../t4/t5', 't1/t6/t7')",  '../../t2/t3/../../t4/t5'     ],
#[  "Unix->abs2rel('t1/t2/t3/../../t4/t5/..', 't1/t6/t7')",  '../../t4/t5/..' ],
#[  "Unix->abs2rel('t1/t2/t3/../../t4/t5/..', 't1/t6/t7')",  '../../t2/t3/../../t4/t5/..' ],

) ;

# Tries a named function with the given args and compares the result against
# an expected result. Works with functions that return scalars or arrays.
for ( @tests ) {
    my ($function, $expected) = @$_;

    $function =~ s#\\#\\\\#g ;
    $function =~ s/^([^\$].*->)/File::Spec::$1/;
    my $got = join ',', eval $function;

 SKIP: {
	if ($@) {
	    skip "skip $function: $skip_exception", 1
		if $@ =~ /^\Q$skip_exception/;
	    is($@, '', $function);
	} else {
	    is($got, $expected, $function);
	}
    }
}

#is +File::Spec::Unix->canonpath(), undef;

done_testing();
