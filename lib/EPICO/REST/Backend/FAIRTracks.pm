#!/usr/bin/perl

# EPICO REST API FAIRTracks backend
# José María Fernández (jose.m.fernandez@bsc.es)
# LGPL 2.1 or later license

use v5.12;
use strict;
use warnings 'all';

package EPICO::REST::Backend::FAIRTracks;

use version;

our $VERSION = version->declare('v0.0.3');

use base qw(EPICO::REST::Backend);

use boolean qw();

use Carp;

use File::Basename;
use File::Spec;

use Log::Log4perl;
use Log::Log4perl::Level;

use LWP::UserAgent ();

use JSON::MaybeXS qw();

use Scalar::Util qw();

# Documentation obtained from https://app.swaggerhub.com/apis-docs/dtitov/TrackFind/1.0.0

use constant {
	TRACKFIND_DEFAULT_BASE_URL	=>	'https://trackfind-dev.gtrack.no/api/v1/',
	TRACKFIND_SECTION	=>	'fairtracks',
	TRACKFIND_BASE_URL_PARAMETER	=>	'base-url',
	ALIVE_TIME_PARAMETER	=>	'ttl',
	DEFAULT_TTL	=>	5*60,	# 5 minutes
};

# This is the empty constructor
sub new($$) {
	my($self)=shift;
	my($class)=ref($self) || $self;
	
	$self = $class->SUPER::new(@_)  unless(ref($self));
	
	unless(Log::Log4perl->initialized()) {
		Log::Log4perl->easy_init({'level' => $Log::Log4perl::DEBUG});
	}
	
	my $LOG = Log::Log4perl->get_logger(__PACKAGE__);
	
	$self->{LOG} = $LOG;
	
	my $ini = $self->{'ini'};
	
	# Now, let's get the parameters
	my $iniFile = $self->{iniFile};
	
	# This parameter is needed to build all the queries to be sent to TrackFind API
	my $apiBaseURL = URI->new($ini->val(TRACKFIND_SECTION,TRACKFIND_BASE_URL_PARAMETER,TRACKFIND_DEFAULT_BASE_URL));
	$self->{'apiBaseURL'} = $apiBaseURL;
	
	my $ttl = URI->new($ini->val(TRACKFIND_SECTION,ALIVE_TIME_PARAMETER,DEFAULT_TTL));
	$self->{'aliveTime'} = $ttl;
	
	$self->{'TF_CACHE'} = {};
	
	$self->{'AS_CACHE'} = {};
	
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


sub _getCached($) {
	my $self = shift;
	
	Carp::croak((caller(0))[3].' is an instance method!')  unless(ref($self));
	
	my($key) = @_;
	
	my $retval = undef;
	my $expiration = undef;
	
	# Checking whether there is a cache miss
	if(exists($self->{'TF_CACHE'}{$key})) {
		($retval,$expiration) = @{$self->{'TF_CACHE'}{$key}};
		
		my $currentTime = time;
		if($currentTime > $expiration) {
			$self->{LOG}->error("WTF?!?!?!");
			delete $self->{'TF_CACHE'}{$key};
			
			$retval = undef;
			$expiration = undef;
		}
	}
	
	return wantarray ? ($retval,$expiration) : $retval;
}

sub _setCached($$;$) {
	my $self = shift;
	
	Carp::croak((caller(0))[3].' is an instance method!')  unless(ref($self));
	
	my($key,$newval,$ttl) = @_;
	
	$ttl = $self->{'aliveTime'}  unless(defined($ttl));
	my $expiration = time + $ttl;
	$self->{'TF_CACHE'}{$key} = [$newval,$expiration];
	
	return wantarray ? ($newval,$expiration) : $expiration;
}

sub _getUA() {
	my $self = shift;
	
	Carp::croak((caller(0))[3].' is an instance method!')  unless(ref($self));
	
	return LWP::UserAgent->new();
}

sub _getCachedRepositories() {
	my $self = shift;
	
	Carp::croak((caller(0))[3].' is an instance method!')  unless(ref($self));
	
	my($cachedRepos,$expiration) = $self->_getCached('repos');
	unless(defined($expiration)) {
		my $ua = $self->_getUA();
		my $url = URI->new('repositories')->abs($self->{'apiBaseURL'});
		
		my $res = $ua->get($url->as_string());
		if($res->is_success()) {
			my $j = JSON::MaybeXS::JSON()->new()->utf8(1);
			eval {
				$cachedRepos = $j->decode($res->decoded_content());
			};
			
			if($@) {
				$self->{LOG}->error("Went wrong ".(caller(0))[3].": $@");
			}
			
			# Last, storage
			$expiration = $self->_setCached('repos',$cachedRepos);
		} else {
			$self->{LOG}->error("Fetch from $url went wrong ".(caller(0))[3].": ".$res->status_line);
		}
	}
	
	return wantarray ? ($cachedRepos,$expiration) : $cachedRepos;
}

sub _getCachedHubs() {
	my $self = shift;
	
	Carp::croak((caller(0))[3].' is an instance method!')  unless(ref($self));
	
	my($cachedHubs,$expiration) = $self->_getCached('hubs');
	unless(defined($expiration)) {
		# We need the repos to query the associated hubs
		my $cachedRepos = $self->_getCachedRepositories();
		if(defined($cachedRepos)) {
			my @hubs = ();
			my $ua = $self->_getUA();
			my $baseHubsUrl = URI->new('hubs/')->abs($self->{'apiBaseURL'});
			my $j = JSON::MaybeXS::JSON()->new()->utf8(1);
			
			# And gathering the hubs from each repo, one by one
			foreach my $repo (@{$cachedRepos}) {
				my $url = URI->new($repo)->abs($baseHubsUrl);
				my $res = $ua->get($url->as_string());
				if($res->is_success()) {
					eval {
						my $p_hubs = $j->decode($res->decoded_content());
						if(ref($p_hubs) eq 'ARRAY') {
							foreach my $hub (@{$p_hubs}) {
								push(@hubs,{'repo' => $repo, 'hub' => $hub});
							}
						}
					};
					
					if($@) {
						$self->{LOG}->error("Went wrong ".(caller(0))[3].": $@");
					}
				} else {
					$self->{LOG}->error("Fetch from $url went wrong ".(caller(0))[3].": ".$res->status_line);
				}
			}
			
			# Last, storage
			$cachedHubs = \@hubs;
			$expiration = $self->_setCached('hubs',$cachedHubs);
		}
	}
	
	return wantarray ? ($cachedHubs,$expiration) : $cachedHubs;
}

sub _getMetamodelEndpoint($$) {
	my $self = shift;
	
	Carp::croak((caller(0))[3].' is an instance method!')  unless(ref($self));
	
	my($repo,$hub) = @_;
	
	my $baseMetamodelUrl = URI->new('metamodel/')->abs($self->{'apiBaseURL'});
	my $url = URI->new($hub)->abs(URI->new($repo.'/')->abs($baseMetamodelUrl));
	
	return $url;
}

sub _getCachedMetamodel($$) {
	my $self = shift;
	
	Carp::croak((caller(0))[3].' is an instance method!')  unless(ref($self));
	
	my($repo,$hub) = @_;
	
	my $metamodelId = join('_','mm',$repo,$hub);
	my($cachedMetamodel,$expiration) = $self->_getCached($metamodelId);
	unless(defined($expiration)) {
		my $ua = $self->_getUA();
		my $j = JSON::MaybeXS::JSON()->new()->utf8(1);
		my $url = $self->_getMetamodelEndpoint($repo,$hub);
		
		my $res = $ua->get($url->as_string());
		if($res->is_success()) {
			eval {
				my $p_metamodel = $j->decode($res->decoded_content());
				if(ref($p_metamodel) eq 'HASH') {
					# Last, storage
					$expiration = $self->_setCached($metamodelId,$p_metamodel);
					
					# TODO: build a secondary cache with weaken references
					$cachedMetamodel = $p_metamodel;
				}
			};
			
			if($@) {
				$self->{LOG}->error("Went wrong ".(caller(0))[3].": $@");
			}
		} else {
			$self->{LOG}->error("Fetch from $url went wrong ".(caller(0))[3].": ".$res->status_line);
		}
	}
	
	return wantarray ? ($cachedMetamodel,$expiration) : $cachedMetamodel;
}
	

sub _getCachedMetamodels() {
	my $self = shift;
	
	Carp::croak((caller(0))[3].' is an instance method!')  unless(ref($self));
	
	my @cachedMetamodels = ();
	# We need the hubs to query their associated metamodel
	my($p_cachedHubs,$expiration) = $self->_getCachedHubs();
	if(defined($p_cachedHubs)) {
		foreach my $p_cachedHub (@{$p_cachedHubs}) {
			my $repo = $p_cachedHub->{'repo'};
			my $hub = $p_cachedHub->{'hub'};
			
			my($p_metamodel,$mm_expiration) = $self->_getCachedMetamodel($repo,$hub);
			if(defined($mm_expiration)) {
				$expiration = $mm_expiration  if($mm_expiration < $expiration);
				if(defined($p_metamodel)) {
					push(@cachedMetamodels,$p_metamodel);
				}
			}
		}
		
		# All the references are weakened at once
		foreach my $cachedMetamodel (@cachedMetamodels) {
			Scalar::Util::weaken($cachedMetamodel);
		}
	}
	
	my $retval = defined($expiration) ? \@cachedMetamodels : undef;
	
	return wantarray ? ($retval,$expiration) : $retval;
}

sub _resolveAssemblies(\@) {
	my $self = shift;
	
	Carp::croak((caller(0))[3].' is an instance method!')  unless(ref($self));
	
	my($p_assemblies) = @_;
	
	my @resolvedAssemblies = ();
	foreach my $assembly (@{$p_assemblies}) {
		my $organism_id = undef;
		my $organism_name = undef;
		my $assembly_id = undef;
		my $assembly_name = undef;
		my $assembly_revision = undef;
		
		my $lAss = lc($assembly);
		# TODO: improve heuristics
		if(index($lAss,"grch")!=-1 || index($lAss,"hg")!=-1) {
			# identifiers.org
			$organism_id = 'taxonomy:9606';
			$organism_name = 'Homo sapiens';
			
			# TODO: use online resources to fetch an
			# authoritative guessing list
			if(index($lAss,'38')!=-1) {
				$assembly_id = 'inscd:GCA_000001405.15';
				$assembly_name = 'GRCh38';
			} elsif(index($lAss,'37')!=-1 || index($lAss,'19')!=-1) {
				$assembly_id = 'inscd:GCA_000001405.1';
				$assembly_name = 'GRCh37';
			} else {
				# Default?
				$assembly_id = 'inscd:GCF_000001405.12';
				$assembly_name = 'NCBI36'
			}
		} elsif(index($lAss,"grcm")!=-1 || index($lAss,"mm")!=-1 || index($lAss,"mgsc")) {
			$organism_id = 'taxonomy:10090';
			$organism_name = 'Mus musculus';
			
			# TODO: use online resources to fetch an
			# authoritative guessing list
			if(index($lAss,'38')!=-1 || index($lAss,'10')!=-1) {
				$assembly_id = 'inscd:GCA_000001635.2';
				$assembly_name = 'GRCm38';
				$assembly_revision = 'GRCm38';
			} elsif(index($lAss,'37')!=-1 || index($lAss,'9')!=-1) {
				$assembly_id = 'inscd:GCA_000001635.1';
				$assembly_name = 'MGSCv37';
				$assembly_revision = 'MGSCv37';
			} else {
				# Default?
				$assembly_id = 'inscd:GCF_000001635.15';
				$assembly_name = 'MGSCv36';
				$assembly_revision = 'MGSCv36';
			}
		}
		
		push(@resolvedAssemblies,{
			'id' => $assembly_id,
			'name' => $assembly_name,
			'revision' => $assembly_revision,
			'organism' => {
				'id' => $organism_id,
				'name' => $organism_name
			},
		});
	}
	
	return \@resolvedAssemblies;
}

sub getAssemblies($;$) {
	my $self = shift;
	
	Carp::croak((caller(0))[3].' is an instance method!')  unless(ref($self));
	
	my($assembly_name,$onlyIds) = @_;
	
	my($p_cachedMetamodels, $expiration) = $self->_getCachedMetamodels();
	my $p_resolvedAssemblies = undef;
	
	if(defined($p_cachedMetamodels)) {
		my %assemblies = ();
		foreach my $p_metamodel (@{$p_cachedMetamodels}) {
			if(exists($p_metamodel->{'tracks'}) && exists($p_metamodel->{'tracks'}{'genome_assembly'})) {
				foreach my $assembly (@{$p_metamodel->{'tracks'}{'genome_assembly'}}) {
					# TODO: consider using lower case
					$assemblies{$assembly} = undef;
				}
			}
		}
		
		my $p_assemblies = undef;
		if(defined($assembly_name)) {
			if(exists($assemblies{$assembly_name})) {
				$p_assemblies = [$assembly_name];
			}
		} else {
			my @assemblies = keys(%assemblies);
			$p_assemblies = \@assemblies;
		}
		
		$p_resolvedAssemblies = defined($p_assemblies) ? $self->_resolveAssemblies($p_assemblies) : [];
	}
	
	return wantarray ? ($p_resolvedAssemblies,$expiration) : $p_resolvedAssemblies;
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