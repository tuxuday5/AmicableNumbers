package CmdLineArgs;
use Moose;
#use Getopt::Long qw(:config ignore_case_always auto_abbrev);
with 'MooseX::Getopt';

has 'Amicable' => (
  'is' => 'ro',
  'isa' => 'Int',
  'required' => 1,
  'traits' => ['MooseX::Getopt::Meta::Attribute::Trait'],
  'cmd_aliases' => [qw/a amicable/],
);

has 'Threads' => (
  'is' => 'ro',
  'isa' => 'Int',
  'required' => 0,
  'default' => 1,
  'traits' => ['MooseX::Getopt::Meta::Attribute::Trait'],
  'cmd_aliases' => [qw/t threads/],
);

1;
