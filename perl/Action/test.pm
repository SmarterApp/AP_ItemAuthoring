package Action::test;

use Data::Dumper;
use UrlConstants;
use Session;

sub run {

  my $q = shift;
  my $dbh = shift;

  # Test out session storage

  $q->env->{'psgix.session'}{counter}++;

  my $user = Session::getUser($q->env, $dbh);

  my $q_dump = Dumper($q);
  my $env_dump = Dumper($q->env);

  my $psgi_out = <<END_HERE;
<html>
  <head>
    <title>Test Mode</title>
    <meta http-equiv="x-ua-compatible" content="IE=9" />
  </head>
  <body>
    <h3>CGI Query object</h3>
    <pre>
    $q_dump
    </pre>
    <h3>ENV</h3>
    <pre>
    $env_dump
    </pre>
    <h3>Other Stuff</h3>
    <pre>
    dbDsn = $dbDsn
    webPath = $webPath
    orcaPath = $orcaPath
    orcaUrl = $orcaUrl
    javaUrl = $javaUrl
    authUrl = $authUrl
    webHost = $webHost
    instanceName = $instance_name
    another change
    </pre>
  </body>
</html>
END_HERE

  return [ $q->psgi_header('text/html'), [ $psgi_out ] ];
}
1;
