# plack libs
use Plack::App::URLMap;
use Plack::Builder;
use Plack::Session::Store::Cache;
use CHI;
use CGI::PSGI;

# libs used by our scripts
use Module::Runtime qw(require_module);
use UrlConstants;
use ItemConstants;
use DBIx::Connector;
use Session;
use CGI::Cookie;
use Data::Dumper;
use Item;
use ItemAsset;
use CDECache;
use Authz;

# add some global variables
our $conn = DBIx::Connector->new($dbDsn, $dbUser, $dbPass) || die "Unable to connect to database: $!";
our $cde_cache_handler = CHI->new ( driver => 'FastMmap' );
our $cde_cache = new CDECache($cde_cache_handler);
$cde_cache->setCache();

# load libs for each script from Action::*
my @scripts = map { /\/(.*)\.pm$/ } <Action/*.pm>;

# load script libs dynamically
foreach my $script (@scripts) { require_module("Action::$script"); };

# make a dispatch table for the run functions
my %app_dispatch = ();
foreach my $script (@scripts) { $app_dispatch{$script} = \&{'Action::' . $script . '::run'}; }

# make plack app cache, to be called by router
my %app_store = ();
foreach my $script (@scripts) {

  $app_store{$script} = sub {
    my $env = shift;

    # use CGI emulation for now, refactor this later
    my $q = CGI::PSGI->new($env);

    # use CDE app cache
    $q->env->{'cde.cache'} = $cde_cache->getCache();

    # also pass a dbh to each action method
    my $dbh = $conn->dbh;

    return [ $q->psgi_header('text/html'), [ ItemConstants::print_no_auth() ]] 
      unless Authz::isAuthorized($script, $q, $dbh);

    return $app_dispatch{$script}->($q,$dbh);
  };
}

# now do the routing, map between path and script calls
my $urlmap = Plack::App::URLMap->new;

foreach my $script (@scripts) {
  $urlmap->map('/' . $ENV{PLACK_ENV} . '/cgi-bin/' . $script . '.pl' => $app_store{$script});
}

# and return the app
my $app = $urlmap->to_app;

# now use builder to add the middleware

builder {
  enable 'Session',
    store => Plack::Session::Store::Cache->new(
      cache => CHI->new( driver => 'FastMmap')
    );
  $app;
};
