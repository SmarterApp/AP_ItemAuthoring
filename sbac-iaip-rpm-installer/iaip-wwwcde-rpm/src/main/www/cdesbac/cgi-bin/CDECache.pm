package CDECache;

use UrlConstants;
use ItemConstants;

sub new {
  my ($type) = shift;
  my ($self) = {};
  
  $self->{cache} = shift;
  $self->{features} = {};

  bless( $self, $type );
  return ($self);
}

sub setCache {
  my $self = shift;

  my $features = shift || ['all'];

  $self->_setFeatures($features);

  if(exists $self->{features}{'workflow.map'}) {
    foreach my $workflow ($ITEM_ACTION_MAP, $PASSAGE_ACTION_MAP) {
      $self->{cache}->set('workflow.map.' . $workflow, &getActionMap($workflow));
    }
  }

}

sub getCache {
  my $self = shift;
  my $cde_cache = {};

  if(exists $self->{features}{'workflow.map'}) {

    foreach my $workflow ($ITEM_ACTION_MAP, $PASSAGE_ACTION_MAP) {
      $cde_cache->{'workflow.map'}{$workflow} = $self->{cache}->get('workflow.map.' . $workflow);
    }
  }

  return $cde_cache;
}

sub _setFeatures {
  my $self = shift;
  my $features = shift;

  my @all_features = qw/workflow.map/;

  if($features->[0] eq 'all') {
    $self->{features}{$_} = 1 foreach @all_features;
  } else {
    $self->{features}{$_} = 1 foreach @$features;
  }
}
1;
