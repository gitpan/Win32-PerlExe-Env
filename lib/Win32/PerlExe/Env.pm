# =============================================================================
# $Id: Env.pm 397 2006-08-25 17:19:23Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Get environment informations of Win32 Perl executables
# ==============================================================================

package Win32::PerlExe::Env;

CHECK { warn "Warning: No MSWin32 System" unless $^O eq 'MSWin32' }

# -- Pragmas
use 5.008006;
use strict;
use warnings;

# -- Global modules
use File::Basename;

# -- Debug only
use Data::Dumper;

# -- Items to export into callers namespace
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(get_tmpdir);
our %EXPORT_TAGS = (  'tmp'  => [ qw(get_tmpdir get_filename) ],
                      'vars' => [ qw(get_build get_perl5lib get_runlib
                                get_tool get_version) ],
                    );
$EXPORT_TAGS{all} = [ map {$_} @{$EXPORT_TAGS{tmp}}, @{$EXPORT_TAGS{vars}} ];
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# -- Version (reformatted)
our $VERSION = do { my @r=( q<Version value="0.01.03">=~/\d+/g, q$Revision: 397 $=~/\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

# -- Defaults
my $_def = { map { $_ => 1 } split "::", __PACKAGE__ };

# -- Get internal temporary working dir of executable 
sub get_tmpdir
{
    ( my $_tmpdir ) = _get_tmpdir() if not defined $_[0] or $_def->{$_[0] };
    
    # -- Try it again implicitly 
    do { $_tmpdir = get_filename( $_[0] );
         $_tmpdir = $_tmpdir
          ? dirname ( $_tmpdir ) . '/'
          : undef;
       } unless $_tmpdir;
    
    return $_tmpdir;
}

# -- Get internal temporary filename
sub get_filename {
  
    my $_name;
    foreach ( $_[0] || keys %{$_def} )
    {
      last if ( $_name ) = _get_filename( $_ );
    }
    
    return $_name;
}

# -- Get variables of executable
sub get_build     { ( $_ ) = _get_var('BUILD'); $_ }
sub get_perl5lib  { ( $_ ) = _get_var('PERL5LIB'); $_ }
sub get_runlib    { ( $_ ) = _get_var('RUNLIB'); $_ }
sub get_tool      { ( $_ ) = _get_var('TOOL'); $_ }
sub get_version   { ( $_ ) = _get_var('VERSION'); $_ }

# *** Internal functions *******************************************************

sub _get_tmpdir
{
    return
      map { defined $_ ? s|\\|/|g : (); $_  }
      
      # -- Ignore unvalid files
      &_nowin32 ? undef
      
      # -- ActiveState PDK
      #    Try to read temp dir of (win32-)parent (no win32 kids allowed)
      : ( eval "PerlApp::exe()"  and $$ > 0 ) ? eval { PerlApp::get_temp_dir()  =~ /^(.*)(\\)$/; $1 . "-$$" . $2 }
      : ( eval "PerlSvc::exe()"  and $$ > 0 ) ? eval { PerlSvc::get_temp_dir()  =~ /^(.*)(\\)$/; $1 . "-$$" . $2 }
      : ( eval "PerlTray::exe()" and $$ > 0 ) ? eval { PerlTray::get_temp_dir() =~ /^(.*)(\\)$/; $1 . "-$$" . $2 }
      
      # -- PerlExe ... (assumed code :) )                                       XXX
      : eval "PerlExe::exe()"  ? eval { PerlExe::get_temp_dir() }           #   XXX
    
      # -- No .exe infos found
      : undef;
}

sub _get_filename {
    
    my $_file = shift ;
    
    return
      map { defined $_ ? s|\\|/|g : (); $_  }
      
      # -- Ignore unvalid files
      &_nowin32 ? undef 
      
      # -- ActiveState PDK          
      #    Try to extract bound file to get full filename
      : eval "PerlApp::exe()"  ? eval { PerlApp::extract_bound_file( $_file ) }
      : eval "PerlSvc::exe()"  ? eval { PerlSvc::extract_bound_file( $_file ) }
      : eval "PerlTray::exe()" ? eval { PerlTray::extract_bound_file( $_file ) }
      
      # -- PerlExe ... (assumed code :) )                                       XXX
      : eval "PerlExe::exe()"  ? eval { PerlExe::get_file( $_file ) }       #   XXX
      
      # -- No .exe infos found
      : undef;
}

sub _get_var
{
    my $_var = shift;
    my $_map = {
                # -- PDK mapping
                #    redundant if accessed directly but better global design
                "PerlApp::BUILD"      => "\$PerlApp::BUILD",
                "PerlApp::PERL5LIB"   => "\$PerlApp::PERL5LIB",
                "PerlApp::RUNLIB"     => "\$PerlApp::RUNLIB",
                "PerlApp::TOOL"       => "\$PerlApp::TOOL",
                "PerlApp::VERSION"    => "\$PerlApp::VERSION",
                  
                "PerlSvc::BUILD"      => "\$PerlSvc::BUILD",
                "PerlSvc::PERL5LIB"   => "\$PerlSvc::PERL5LIB",
                "PerlSvc::RUNLIB"     => "\$PerlSvc::RUNLIB",
                "PerlSvc::TOOL"       => "\$PerlSvc::TOOL",
                "PerlSvc::VERSION"    => "\$PerlSvc::VERSION",
                
                "PerlTray::BUILD"     => "\$PerlTray::BUILD",
                "PerlTray::PERL5LIB"  => "\$PerlTray::PERL5LIB",
                "PerlTray::RUNLIB"    => "\$PerlTray::RUNLIB",
                "PerlTray::TOOL"      => "\$PerlTray::TOOL",
                "PerlTray::VERSION"   => "\$PerlTray::VERSION",

                # -- PerlExe ... (assumed code :) )                             XXX
                "PerlExe::BUILD"      => "\$PerlExe::foo",                  #   XXX
                "PerlExe::PERL5LIB"   => "\$PerlExe::bar",                  #   XXX
                "PerlExe::RUNLIB"     => "\$PerlExe::foobar",               #   XXX
                "PerlExe::TOOL"       => "\$PerlExe::barfoo",               #   XXX
                "PerlExe::VERSION"    => "\$PerlExe::foofoo",               #   XXX
               };
    
    return
      map { defined $_ ? s|\\|/|g : (); $_  }
    
      # -- Ignore unvalid files
      &_nowin32 ? undef 
      
      # -- ActiveState PDK
      #    Try to read variables (via mapping)
      : eval "\$_map->{PerlApp::$_var}"   ? eval "\$_map->{PerlApp::$_var}"
      : eval "\$_map->{PerlSvc::$_var}"   ? eval "\$_map->{PerlSvc::$_var}"
      : eval "\$_map->{PerlTray::$_var}"  ? eval "\$_map->{PerlTray::$_var}"
      
      #    Try to read variables (directly)                                     XXX
      #    XXX: a little bit faster but redundant ... may be omitted in future  XXX
      : eval "\$PerlApp::$_var"           ? eval "\$PerlApp::$_var"         #   XXX
      : eval "\$PerlSvc::$_var"           ? eval "\$PerlSvc::$_var"         #   XXX
      : eval "\$PerlTray::$_var"          ? eval "\$PerlTray::$_var"        #   XXX
      
      # -- PerlExe ... (assumed code :) )                                       XXX
      : eval "\$_map->{PerlExe::$_var}"  ? eval "\$_map->{PerlExe::$_var}"  #   XXX
      
      # -- No .exe infos found
      : undef;
}

# -- Assume valid Win32 executable
sub _nowin32 { not ( -s $0 and -B $0 and $0 =~ /\.(exe|dll|sys|drv)$/ ) };    

1;

__END__

=head1 NAME

Win32::PerlExe::Env - Get environment informations of Win32 Perl executables

=head1 SYNOPSYS

=item :DEFAULT

    use Win32::PerlExe::Env;
    $dir  = get_tmpdir();
    $dir  = get_tmpdir( 'Copyright' );

=item :tmp

    use Win32::PerlExe::Env qw(:tmp);
    $dir  = get_tmpdir();
    $file = get_filename();

=item :vars

    use Win32::PerlExe::Env qw(:vars);
    @vars = ( map { &$_ }
            qw(get_build get_perl5lib get_runlib get_tool get_version) );

=item :all

    use Win32::PerlExe::Env qw(:all);
    %vars = ( map { uc $_ => eval "&get_$_" }
              map { lc }
              qw(tmpdir filename BUILD PERL5LIB RUNLIB TOOL VERSION) );

=head1 DESCRIPTION

C<Win32::PerlExe::Env> supports special 'build-in' environment informations of
Perl .exe files.

The main goal of this module version (L<VERSION AND DATE>) is to get the
internal temporary directory of packed Perl executables (L<[PDK] BOUND FILES>)
regardless of the used packer.

This version supports ActiveState PDK packer (L<LIMITS> and L<SEE ALSO>).

=head1 EXPORTS

=item :DEFAULT

  get_tmpdir

=item :tmp

  get_tmpdir get_filename

=item :vars

  get_build get_perl5lib get_runlib get_tool get_version

=item :all

  get_tmpdir get_filename get_build get_perl5lib get_runlib get_tool get_version

=head1 FUNCTIONS

=item * get_tmpdir()

=item * get_tmpdir(filename)

Get internal temporary working directory of executable.

I<Hint for ActiveState PDK packer: The returned internal temporary working
directory will exist only if any packed file was automactically or explicitly
extracted L<SEE ALSO>. Therefore it is strongly recommended to test the
existence of the directory (-d) before usage>.

=item * get_filename()

=item * get_filename(filename)

Get internal temporary filename of executable.

I<Security Hint for ActiveState packer: As a side effect the given file will be
extracted into internal temporary working directory L<SEE ALSO>>.

=item * get_build

Get the packers (PerlApp, ...) build number.

=item * get_perl5lib

Get the PERL5LIB environment variable. If that does not exist, it contains the
value of the PERLLIB environment variable. If that one does not exists either,
result is undef. 

=item * get_runlib

Get the fully qualified path name to the runtime library directory.

ActiveState specifies this by the --runlib option. If the --norunlib
option is used, this variable is undef. 

=item * get_tool

Get string B<Perl...> (PerlApp, PerlSvc, PerlTray ...), indicating that the
currently running executable has been produced by this packer (=tool). 

=item * get_version

Get the packers version number: "major.minor.release", but not including the
build number. 

=head1 [PDK] BOUND FILES

B<ActiveState PDK only:>

Bound files are additional files to be included in the executable which can
be extracted to an internal temporary directory or can be read directly like
normal files.

C<Win32::PerlExe::Env> supports different strategies to find out the internal
temporary directory because basically inofficial PDK functions are used.

To get a stable configuration under all circumstances it is recommended that
the PDK configuration files (.perlapp, .perlsvc or .perltray) contain one of
the following entries to define an internal B<default bound file>:

  Bind: Win32[data=Win32]
  Bind: PerlExe[data=PerlExe]
  Bind: Env[data=Env]

These 'identifiers' will be tested internally as defaults. See L<EXAMPLE>.

Alternatively the B<default bound file> can be omitted if one or more
B<user bound files> were bound into the executable instead, e. g.

  Bind: Get_Info.ico[file=res\icons\Get_Info.ico] and/or
  Bind: Copyright[data=Copyright (c) 2006 Thomas Walloschke.]

This means the ':tmp' functions can be called with one of these filenames:

  get_filename( 'Get_Info.ico' );
  get_tmpdir( 'Copyright' );

=head1 EXAMPLE

See source F<exe/Win32-PerlExe-Env.pl>, packer config
F<exe/Win32-PerlExe-Env.perlapp> and executable F<exe/Win32-PerlExe-Env.exe>
of this installation.

The executable was packed with ActiveState PDK PerlApp 6.0.2. The size was
optimized with packer options set to B<Make dependent executable> and
B<Exclude perl58.dll from executable>. To run this executable properly a
C<Win32 Perl Distribution> and the recent C<Win32::PerlExe::Env> must be
installed. 

=head1 LIMITS

This version examines 'ActiveState PDK executables' only (PerlApp, PerlSvc and
PerlTray).

Precautions: This is an alpha release.

C<Win32::PerlExe::Env> was tested under Win32 XP SR2 and ActiveState PDK 6.0.2.

I<I would be pleased if anyone could send me more test identifiers for other
.exe distributions ( Ref. in source: -- PerlExe ... (assumed code :) ) )>.

=head1 SEE ALSO

Perl Development Kit [PDK] L<http://www.activestate.com/Products/Perl_Dev_Kit/?mp=1>

=head1 AUTHOR

Thomas Walloschke E<lt>thw@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Thomas Walloschke (thw@cpan.org).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 VERSION AND DATE

This is Version 0.1.3 $Revision: 397 $

Precautions: alpha release.

Last changed $Date: 2006-08-25 19:19:23 +0200 (Fr, 25 Aug 2006) $.

=cut