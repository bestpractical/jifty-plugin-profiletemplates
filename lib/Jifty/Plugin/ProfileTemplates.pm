package Jifty::Plugin::ProfileTemplates;
use strict;
use warnings;
use base 'Jifty::Plugin';
use Time::HiRes qw//;

sub prereq_plugins { 'RequestInspector' }

my @stack;
sub init {
    my $self = shift;
    return if $self->_pre_init;

    Jifty::Handler->add_trigger(
        before_render_template => sub {
            return unless @stack;
            my (undef, $handler, $path) = @_;

            push @stack, {
                path => $path,
                handler => ref $handler,
                start => Time::HiRes::time(),
                args => { %{Jifty->web->request->arguments}, %{Jifty->web->request->template_arguments || {}} },
            };
            delete $stack[-1]{args}{region};
        }
    );
    Jifty::Handler->add_trigger(
        after_render_template => sub {
            return unless @stack;
            $stack[-1]{time} = Time::HiRes::time() - delete $stack[-1]{start};
            push @{$stack[-2]{kids}}, pop @stack;
        }
    );
}


sub inspect_before_request {
    @stack = ( { kids => [] } );
}

sub inspect_after_request {
    my $self = shift;

    my $ret = $stack[0];
    $ret->{time} += $_->{time} for @{$ret->{kids}};
    warn YAML::Dump($ret);

    @stack = ();
    return $ret;
}

sub inspect_render_summary {
    my $self = shift;
    my $log = shift;

    return _("Total time in templates, %1", sprintf("%5.4f",$log->{time}));
}

sub inspect_render_analysis {
    my $self = shift;
    my $log = shift;
    my $id = shift;

    Jifty::View::Declare::Helpers::render_region(
        name => 'templates',
        path => '/__jifty/admin/requests/templates',
        args => {
            id => $id,
        },
    );
}

1;


__END__

=head1 NAME

Jifty::Plugin::ProfileTemplates - Show timing of template rendering

=head1 DESCRIPTION

This plugin will log the time each template takes to render, and
generate reports.  Such reports are available at:

    http://your.app/__jifty/admin/requests

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - ProfileTemplates: {}

=head1 METHODS

=head2 init

Adds the necessary hooks

=head2 inspect_before_request

Clears the query log so we don't log any unrelated previous queries.

=head2 inspect_after_request

Stash the query log.

=head2 inspect_render_summary

Display how many queries and their total time.

=head2 inspect_render_analysis

Render a template with all the detailed information.

=head2 prereq_plugins

This plugin depends on L<Jifty::Plugin::RequestInspector>.

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut
