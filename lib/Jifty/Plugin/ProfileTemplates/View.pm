package Jifty::Plugin::ProfileTemplates::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/__jifty/admin/requests/templates' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    my $id = get('id');

    my $data = $request_inspector->get_plugin_data($id, "Jifty::Plugin::ProfileTemplates");

    show '/__jifty/admin/requests/template', id => $id;
};

template '/__jifty/admin/requests/template' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    my $id    = get('id');
    my @index = split /\./, (defined get('t') ? get('t') : "");
    my $data = $request_inspector->get_plugin_data($id, "Jifty::Plugin::ProfileTemplates");
    $data = $data->{kids}[$_] for @index;

    ol {
        for my $t (0..@{$data->{kids}}-1) {
            my $seconds = sprintf('%.2f', $data->{kids}[$t]{time});
            my $path = $data->{kids}[$t]{path};
            my $label = _("(%1s) %2", $seconds, $path);
            li {
                my @kids = @{$data->{kids}[$t]{kids} || []};
                if (@kids) {
                    hyperlink(
                        label => $label,
                        onclick => {
                            region    => Jifty->web->qualified_region("t_$t"),
                            replace_with => '/__jifty/admin/requests/template',
                            toggle    => 1,
                            effect    => 'slideDown',
                            arguments => {
                                id => $id,
                                t  => join(".",@index,$t),
                            },
                        },
                    );
                } else {
                    outs $label;
                }

                outs " [";
                hyperlink(
                    label => _("Arguments"),
                    onclick => {
                        region    => Jifty->web->qualified_region("args_$t"),
                        replace_with => '/__jifty/admin/requests/template_args',
                        toggle    => 1,
                        effect    => 'slideDown',
                        arguments => {
                            id => $id,
                            t  => join(".",@index,$t),
                        },
                    },
                );
                outs "]";
                render_region("args_$t");
                render_region("t_$t") if @kids;
            }
        }
    }
};

template '/__jifty/admin/requests/template_args' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    my $id    = get('id');
    my @index = split /\./, get('t');
    my $data = $request_inspector->get_plugin_data($id, "Jifty::Plugin::ProfileTemplates");
    $data = $data->{kids}[$_] for @index;

    dl {
        for (sort keys %{$data->{args}}) {
            dt { $_ };
            dd { $data->{args}{$_} };
        }
    }
};

1;

__END__

=head1 NAME

Jifty::Plugin::ProfileTemplates::View - View for ProfileTemplates

=cut

