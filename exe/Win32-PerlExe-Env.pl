# =============================================================================
# $Id: Win32-PerlExe-Env.pl 399 2006-08-25 17:25:26Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Test Program for Win32::PerlExe::Env
# ==============================================================================

    use strict;
    use warnings;
    
    my $progname = $0; 
    $progname =~ s|.*\\||;      # use basename only
    $progname =~ s|\.\w*$||;    # strip extension

    my $opt = $ARGV[0] || ':DEFAULT';
    my $fil = $ARGV[1] || 'PerlExe';
    
    print "Runs as '$progname $opt $fil'\n";
    &usage unless ( my $vars ) = ( $opt =~ /:(tmp|vars|all|DEFAULT)/ );

    use lib '../lib';
    eval "use Win32::PerlExe::Env '$opt'";
    die $@ if $@;
    
    use Data::Dumper;
    $Data::Dumper::Sortkeys = 1;
    
    push my @names,
    
            $vars eq 'tmp'
        ?   qw(tmpdir filename)
        
        :   $vars eq 'vars'
        ?   qw(BUILD PERL5LIB RUNLIB TOOL VERSION)
        
        :   $vars eq 'all'
        ?   qw(tmpdir filename BUILD PERL5LIB RUNLIB TOOL VERSION)
        
        :   qw(tmpdir);
    
    my %vars = (   map { uc $_ => eval "get_$_(\$fil)" } map { lc } @names );
    die $@ if $@;
    
    print "Result is " . Data::Dumper->Dump([\%vars], [$vars]);
    
    sub usage
    {
        die <<"EOT";
Test of Win32::PerlExe::Env
Option '$opt' is unknown
Usage: $progname [:opt]
    :tmp        print get_tmpdir, get_filename
    :vars       print get_build, get_perl5lib, get_runlib, get_tool, get_version
    :all        print :tmp and :vars
    :DEFAULT    print get_tmpdir
    
    No option   sets to :DEFAULT   
EOT
    }
    
=pod

=head1 SYNOPSYS

    win32: Win32-PerlExe-Env.exe
    win32: Win32-PerlExe-Env.exe :tmp 
    win32: Win32-PerlExe-Env.exe :tmp filename
    win32: Win32-PerlExe-Env.exe :vars
    win32: Win32-PerlExe-Env.exe :all 
    win32: Win32-PerlExe-Env.exe :all filename
    win32: Win32-PerlExe-Env.exe :DEFAULT
    win32: Win32-PerlExe-Env.exe :DEFAULT filename

=head1 DESCRIPTION

Test program for Win32::PerlExe::Env

=head1 AUTHOR

Thomas Walloschke E<lt>thw@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Thomas Walloschke (thw@cpan.org).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut