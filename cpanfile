# Dependencies by EPICO FAIRTracks backend
requires 'File::Basename';
requires 'File::Spec';
requires 'Log::Log4perl';
requires 'boolean';
requires 'Carp';
requires 'Log::Log4perl';

requires 'EPICO::REST::Backend', 'v2.0.0', url => 'https://github.com/inab/EPICO-abstract-backend/archive/v2.0.0.tar.gz';

on test => sub {
    requires 'Test::More', '0.96';
};

on develop => sub {
    requires 'Dist::Milla', '1.0.20';
    requires 'Dist::Zilla::Plugin::MakeMaker';
    requires 'Dist::Zilla::Plugin::ModuleShareDirs';
    requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
};
