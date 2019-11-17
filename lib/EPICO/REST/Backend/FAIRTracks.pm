#!/usr/bin/perl

# EPICO REST API FAIRTracks backend
# José María Fernández (jose.m.fernandez@bsc.es)
# LGPL 2.1 or later license

use v5.12;
use strict;
use warnings 'all';

package EPICO::REST::Backend::FAIRTracks;

use version;

our $VERSION = version->declare('v0.0.2');

use base qw(EPICO::REST::Backend);

use boolean qw();

use Carp;

use File::Basename;
use File::Spec;

use Log::Log4perl;

# This is the empty constructor
sub new($$) {
	my($self)=shift;
	my($class)=ref($self) || $self;
	
	$self = $class->SUPER::new(@_)  unless(ref($self));
	
	my $LOG = Log::Log4perl->get_logger(__PACKAGE__);
	
	$self->{LOG} = $LOG;
	
	my $ini = $self->{ini};
	
	# Now, let's get the parameters
	my $iniFile = $self->{iniFile};
	
	return $self;
}

# It returns the data model used for FAIRTracks
sub getModelFromDomain() {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

# It returns the controlled vocabularies
sub getAvailableCVs() {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

# It returns a single controlled vocabularies
sub getCV($) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getCVterms($;\@) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getFilteredCVterms(\@) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getCVsFromColumn($$$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getCVtermsFromColumn($$$;\@) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}


sub getAssemblies($;$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}


sub getSampleTrackingData($;$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getDonors($;$$$$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getSpecimens($;$$$$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getSamples($;$$$$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}


sub getExperiments($;$$$$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}


sub getAnalysisMetadata($;$$$$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getGeneExpressionFromCompoundAnalysisIds($\@;\&) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getRegulatoryRegionsFromCompoundAnalysisIds($\@;\&) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getDataFromCoords($$$$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getDataStreamFromCoords($$$$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub fetchDataStream(\%) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getGenomicLayout($$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getDataCountFromCoords($$$$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub getDataStatsFromCoords($$$$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub queryFeatures($$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

sub suggestFeatures($$) {
	Carp::croak((caller(0))[3]. 'is an unimplemented method!');
}

1;
__END__

=encoding utf8

=head1 NAME

EPICO::REST::Backend::FAIRTracks - FAIRTracks backend class for EPICO REST API

=head1 SYNOPSIS

=for markdown ```perl

    use EPICO::REST::Backend::FAIRTracks;

=for markdown ```
    
=head1 DESCRIPTION

EPICO::REST::Backend::FAIRTracks is the FAIRTracks backend, built for
the ELIXIR Implementation Study "FAIRification of Genomic Data Tracks".

=head1 RATIONALE

Instead of having a monolithic API, EPICO REST API was designed thinking
both on different instances of the same implementation, as well as pluggable
instances for other external sources.

=head1 METHODS

I<(to be documented)>

=head1 INSTALLATION

Latest release of this package is available in the L<BSC INB DarkPAN|https://gitlab.bsc.es/inb/darkpan/>. You
can install it just using C<cpanm>:

=for markdown ```bash

  cpanm --mirror-only --mirror https://gitlab.bsc.es/inb/darkpan/raw/master/ --mirror https://cpan.metacpan.org/ EPICO::REST::Backend::FAIRTracks

=for markdown ```

=head1 AUTHOR

José M. Fernández L<https://github.com/jmfernandez>

=head1 COPYRIGHT

The library has been funded by ELIXIR Implementation Study
"FAIRification of Genomic Data Tracks".

Copyright 2019- José M. Fernández & Barcelona Supercomputing Center (BSC)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the LGPL 2.1 terms.

=head1 SEE ALSO

=cut