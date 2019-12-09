# Dependencies by EPICO FAIRTracks backend
requires 'File::Basename';
requires 'File::Spec';
requires 'Log::Log4perl';
requires 'boolean';
requires 'Carp';
requires 'Log::Log4perl';

requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';
requires 'JSON::MaybeXS';
requires 'URI';
requires 'Scalar::Util';

# This dependency is in the BSC INB DarkPAN
requires 'EPICO::REST::Backend', 'v2.0.0';

on test => sub {
    requires 'Test::More', '0.96';
};

on develop => sub {
    requires 'Dist::Milla', '1.0.20';
    requires 'Dist::Zilla::Plugin::MakeMaker';
    requires 'Dist::Zilla::Plugin::ModuleShareDirs';
    requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
    requires 'Dist::Zilla::Plugin::Run', '0.048';
    requires 'OrePAN2';
};