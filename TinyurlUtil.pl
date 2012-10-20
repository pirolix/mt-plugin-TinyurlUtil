package MT::Plugin::OMV::TinyurlUtil;
# $Id$

use strict;
use MT 4;

use vars qw( $VENDOR $MYNAME $VERSION );
($VENDOR, $MYNAME) = (split /::/, __PACKAGE__)[-2, -1];
(my $revision = '$Rev$') =~ s/\D//g;
$VERSION = '0.01'. ($revision ? ".$revision" : '');

use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new({
        id => $MYNAME,
        key => $MYNAME,
        name => $MYNAME,
        version => $VERSION,
        author_name => 'Open MagicVox.net',
        author_link => 'http://www.magicvox.net/',
        doc_link => 'http://www.magicvox.net/archive/2010/04030941/',
        description => <<HTMLHEREDOC,
<__trans phrase="Show the shorten URL with tinyurl.com in compose screen.">
HTMLHEREDOC
});
MT->add_plugin( $plugin );

sub instance { $plugin; }

### Registry
sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        tags => {
            modifier => {
                tinyurl => sub { get_tinyurl ($_[0]) || $_[0]; },
            },
        },
        callbacks => {
            'MT::App::CMS::template_source.edit_entry' => sub {
                5.0 <= $MT::VERSION
                    ? _edit_entry_source_v5 (@_)
                    : 4.0 <= $MT::VERSION
                        ? _edit_entry_source_v4 (@_)
                        : undef;
            },
            'MT::App::CMS::template_param.edit_entry' => \&_edit_entry_param,
        },
    });
}



### template_source.edit_entry for MT5.x
sub _edit_entry_source_v5 {
    my ($eh_ref, $app_ref, $tmpl_ref) = @_;

    my $old = quotemeta (<<'HTMLHEREDOC');
<strong><__trans phrase="Permalink:"></strong> <mt:var name="entry_permalink">
HTMLHEREDOC
    my $new = << 'HTMLHEREDOC';
<TMPL_IF NAME=TINYURL>
  (<span style="background:url('http://tinyurl.com/favicon.ico') center left no-repeat; padding-left:18px;"><a href="<TMPL_VAR NAME=TINYURL>"><TMPL_VAR NAME=TINYURL></a></span>)
</TMPL_IF>
HTMLHEREDOC
    $$tmpl_ref =~ s/($old)/$1$new/;
}

### template_source.edit_entry for MT4.x
sub _edit_entry_source_v4 {
    my ($eh_ref, $app_ref, $tmpl_ref) = @_;

    my $old = quotemeta (<<'HTMLHEREDOC');
<li class="pings-link"><__trans phrase="<a href="[_2]">[quant,_1,trackback,trackbacks]</a>" params="<$mt:var name="num_pings"$>%%<$mt:var name="script_url">?__mode=list_pings&amp;filter=entry_id&amp;filter_val=<$mt:var name="id" escape="url"$>&amp;blog_id=<$mt:var name="blog_id" escape="url"$>"></li>
HTMLHEREDOC
    my $new = << 'HTMLHEREDOC';
<TMPL_IF NAME=TINYURL>
  <li>TinyURL <span style="background:url('http://tinyurl.com/favicon.ico') center left no-repeat; padding: 0 8px 0 18px;"><a href="<TMPL_VAR NAME=TINYURL>"><TMPL_VAR NAME=TINYURL></a></span></li>
</TMPL_IF>
HTMLHEREDOC
    $$tmpl_ref =~ s/($old)/$1$new/;
}

### template_param.edit_entry
sub _edit_entry_param {
    my ($cb, $app, $param, $tmpl) = @_;

    my $entry_permalink = $param->{entry_permalink};
    if ($entry_permalink) {
        $param->{tinyurl} = get_tinyurl ($entry_permalink) || undef;
    }
}

########################################################################
sub get_tinyurl {
    my ($text) = @_;

    my $data = load_plugindata ($text);
    if (!defined $data) {
        require LWP::Simple;
        my $api_url = "http://tinyurl.com/api-create.php?url=$text";
        my $tinyurl = LWP::Simple::get ($api_url)
            or return undef;
        $data = { URL => $tinyurl };
        save_plugindata ($text, $data);
    }
    $data->{URL} || $text;
}

########################################################################
use MT::PluginData;

sub save_plugindata {
    my ($key, $data_ref) = @_;
    my $pd = MT::PluginData->load({ plugin => &instance->id, key=> $key });
    if (!$pd) {
        $pd = MT::PluginData->new;
        $pd->plugin( &instance->id );
        $pd->key( $key );
    }
    $pd->data( $data_ref );
    $pd->save;
}

sub load_plugindata {
    my ($key) = @_;
    my $pd = MT::PluginData->load({ plugin => &instance->id, key=> $key })
        or return undef;
    $pd->data;
}

1;