#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use YAML qw//;

my $dataset_file = dirname(__FILE__) . '/../dataset.yaml';
my $java_file = dirname(__FILE__) . '/../perl/lib/Woothee/DataSet.pm';

open(my $dfh, '-|', 'env', 'LANG=C', 'date');
my $generated_timestamp = <$dfh>;
chomp $generated_timestamp;
close($dfh);
open(my $ufh, '-|', 'env', 'LANG=C', 'whoami');
my $generated_username = <$ufh>;
chomp $generated_username;
close($ufh);
my @defs = (<<"EOI"
    # GENERATED from dataset.yaml at $generated_timestamp by $generated_username
    my \$obj;
EOI
        );

my $dataset_entries = YAML::LoadFile($dataset_file);
foreach my $dataset (@$dataset_entries) {
    my $label = $dataset->{label};
    my $name = $dataset->{name};
    my $type = $dataset->{type};
    my $def = <<"EOD";
    \$obj = {label => '$label', name => '$name', type => '$type'};
EOD
    if ($type eq 'browser') {
        my $vendor = $dataset->{vendor};
        $def .= <<"EOD";
    \$obj->{vendor} = '$vendor';
EOD
    }
    elsif ($type eq 'os') {
        my $category = $dataset->{category};
        $def .= <<"EOD";
    \$obj->{category} = '$category';
EOD
    }
    elsif ($type eq 'full') {
        my $vendor = $dataset->{vendor} || '';
        my $category = $dataset->{category};
        $def .= <<"EOD";
    \$obj->{category} = '$category';
    \$obj->{vendor} = '$vendor';
EOD
        if ($dataset->{os}) {
            my $os = $dataset->{os};
            $def .= <<"EOD";
    \$obj->{os} = '$os';
EOD
        }
    }
    else {
        die "invalid type: " . $dataset->{type};
    }
    $def .= <<"EOD";
    \$DATASET->{'$label'} = \$obj;
EOD
    push @defs, $def;
}

open(my $fh, ">", $java_file);
while (my $line = <DATA>) {
    if ($line =~ /^___GENERATED_STATIC_INITIALIZER___/) {
        print $fh join('', @defs);
    }
    else {
        print $fh $line;
    }
}
close($fh);

exit 0;

__DATA__
package Woothee::DataSet;

use strict;
use warnings;
use Carp;

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(get const);
}

my $CONST = {
    KEY_LABEL => "label",
    KEY_NAME => "name",
    KEY_TYPE => "type",
    KEY_CATEGORY => "category",
    KEY_OS => "os",
    KEY_VENDOR => "vendor",
    KEY_VERSION => "version",

    TYPE_BROWSER => "browser",
    TYPE_OS => "os",
    TYPE_FULL => "full",

    CATEGORY_PC => "pc",
    CATEGORY_SMARTPHONE => "smartphone",
    CATEGORY_MOBILEPHONE => "mobilephone",
    CATEGORY_CRAWLER => "crawler",
    CATEGORY_APPLIANCE => "appliance",
    CATEGORY_MISC => "misc",

    ATTRIBUTE_NAME => "name",
    ATTRIBUTE_CATEGORY => "category",
    ATTRIBUTE_OS => "os",
    ATTRIBUTE_VENDOR => "vendor",
    ATTRIBUTE_VERSION => "version",

    VALUE_UNKNOWN => "UNKNOWN",
};

sub const {
    my ($klass, $const_name) = @_;
    $const_name = $klass unless $const_name;
    $CONST->{$const_name};
}

my $DATASET = {};
{
___GENERATED_STATIC_INITIALIZER___
}

sub get {
    my ($klass, $label) = @_;
    $label = $klass unless $label;
    $DATASET->{$label};
}

1;
