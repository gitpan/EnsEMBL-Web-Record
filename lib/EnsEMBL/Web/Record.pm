package EnsEMBL::Web::Record;

### Inside-out class representing persistent user information. This class
### follows the Active Record design pattern: it contains both the domain
### logic required to create and manipulate a piece of persistent data, and
### the information necessary to maintain this data in a database.
  
### It allows the storage of arbitrary hash keys and their values 
### (user bookmarks, etc) in a single database field, and uses autoloading
### to enable new data to be stored at will without the need for additional code

=head1 NAME

EnsEMBL::Web::Record - A family of modules used for representing and storing a user's
persistant data.

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

This family of modules provides a fast, flexible representation of persitant user data. It allows
the storage and retrieval of arbitrary key-value pairs, in a single database field.

It was initially developed for use with the Ensembl Genome Browser (http://www.ensembl.org).

    use EnsEMBL::Web::Record;

    my $bookmark = EnsEMBL::Web::Record->new();
    $bookmark->url('http://www.ensembl.org');
    $bookmark->name('Ensembl');
    $bookmark->save;
    ...

=cut 

use strict;
use warnings;
use Data::Dumper;

our $AUTOLOAD;

{

my %Adaptor_of;
my %Fields_of;
my %ParameterSet_of;
my %Records_of;
my %Tainted_of;
my %Id_of;
my %CreatedAt_of;
my %ModifiedAt_of;
my %Type_of;
my %Owner_of;

=head1 FUNCTIONS
=cut

sub AUTOLOAD {
  ### AUTOLOAD method for getting and setting record attributes, and processing
  ### find_by requests. Attributes should be named after columns in the
  ### appropriate database table.
  ###
  ### Attribute names are not validated against the database table.
  my $self = shift;
  my ($key) = ($AUTOLOAD =~ /::([a-z].*)$/);
  my ($value, $options) = @_;
  #warn "AUTOLOADING $key";
  if ($value) {
    if (my ($find, $by) = ($key =~ /find_(.*)_by_(.*)/)) {
      my $table = "user";
      my $record_type = "User";
      if ($find eq "records") {
         $find = "";
      }
      if ($find eq "group_records") {
        $find = "";
        $table = "group";
      }
      if ($by =~ /group_record/) {
        $table = "group";  
        $record_type = "Group";
      }
      return find_records(( record_type => $record_type, type => $find, $by => $value, table => $table, options => $options));
    } else {
      if (my ($type) = ($key =~ /(.*)_records/)) {
        return $self->records_of_type($type, $value);
      }
      $self->fields($key, $value);
    }
  } else {
    if (my ($type) = ($key =~ /(.*)_records/)) {
      return $self->records_of_type($type);
    }
  }
  return $self->fields($key);
}


=head2 new 

Creates a new Record object. This module follows the Active Record pattern: it contains both the domain
logic required to create and manipulate a piece of persistent data, and
the information necessary to maintain this data in a database.

=cut

sub new {
  ### c
  my ($class, %params) = @_;
  my $self = bless \my($scalar), $class;
  $Adaptor_of{$self} = defined $params{'adaptor'} ? $params{'adaptor'} : undef;
  $Records_of{$self} = defined $params{'records'} ? $params{'records'} : [];
  $ParameterSet_of{$self} = defined $params{'parameter_set'} ? $params{'parameter_set'} : undef;
  $Id_of{$self} = defined $params{'id'} ? $params{'id'} : undef;
  $CreatedAt_of{$self} = defined $params{'created_at'} ? $params{'created_at'} : undef;
  $ModifiedAt_of{$self} = defined $params{'modified_at'} ? $params{'modified_at'} : undef;
  $Type_of{$self} = defined $params{'type'} ? $params{'type'} : "record";
  $Fields_of{$self} = {};
  $Tainted_of{$self} = {};
  if ($params{'data'}) {
    #$self->data($params{'data'});
    my $eval = eval($params{'data'});
    $Fields_of{$self} = $eval;
  } else {
    $Fields_of{$self} = {};
  }
  return $self;
}


=head2 taint 

Marks a particular collection of records for an update. Tainted 
records are updated in the database when the Record's save method
is called.

=cut

sub taint {
  ### Marks a particular collection of records for an update. Tainted 
  ### records are updated in the database when the Record's save method
  ### is called.
  my ($self, $type) = @_;
  $self->tainted->{$type} = 1;
}

=head2 dump_data 
Uses Data::Dumper to format a record's data for storage, 
and also handles escaping of quotes to avoid SQL errors
=cut 

sub dump_data {
  ### Uses Data::Dumper to format a record's data for storage, 
  ### and also handles escaping of quotes to avoid SQL errors
  my $self = shift;
  my $temp_fields = {};
  foreach my $key (keys %{ $self->fields }) {
    $temp_fields->{$key} = $self->fields->{$key};
    $temp_fields->{$key} =~ s/'/\\'/g;
  }
  my $dump = Dumper($temp_fields);
  #$dump =~ s/'/\\'/g;
  $dump =~ s/^\$VAR1 = //;
  return $dump;
}

=head2 fields 
Accessor for the fields property.
=cut 

sub fields {
  ### a
  my ($self, $key, $value) = @_;
  if ($key) {
    if ($value) {
      $value =~ s/'/\\'/g;
      $Fields_of{$self}->{$key} = $value;
    }
    return $Fields_of{$self}->{$key}
  } else {
    return $Fields_of{$self};
  }
}

=head2 records 
Accessor for the records property.
=cut 

sub records {
  ### a
  my $self = shift;
  $Records_of{$self} = shift if @_;
  return $Records_of{$self};
}

=head2 type 
Accessor for the type property.
=cut 

sub type {
  ### a
  my $self = shift;
  $Type_of{$self} = shift if @_;
  return $Type_of{$self};
}

=head2 tainted 
Accessor for the tainted property.
=cut 

sub tainted {
  ### a
  my $self = shift;
  $Tainted_of{$self} = shift if @_;
  return $Tainted_of{$self};
}

=head2 adaptor 
Accessor for the tainted property.
=cut 

sub adaptor {
  ### a
  my $self = shift;
  $Adaptor_of{$self} = shift if @_;
  return $Adaptor_of{$self};
}

=head2 parameter_set 
Accessor for the parameter_set property.
=cut 

sub parameter_set {
  ### a
  my $self = shift;
  $ParameterSet_of{$self} = shift if @_;
  return $ParameterSet_of{$self};
}

=head2 id 
Accessor for the id property.
=cut 

sub id {
  ### a
  my $self = shift;
  $Id_of{$self} = shift if @_;
  return $Id_of{$self};
}

=head2 created_at 
Accessor for the created_at property.
=cut

sub created_at {
  ### a
  my $self = shift;
  $CreatedAt_of{$self} = shift if @_;
  return $CreatedAt_of{$self};
}

=head2 modified_at 
Accessor for the modified_at property.
=cut

sub modified_at {
  ### a
  my $self = shift;
  $ModifiedAt_of{$self} = shift if @_;
  return $ModifiedAt_of{$self};
}

=head2 records_of_type 
Returns an array of records, that match a particular type.
=cut

sub records_of_type {
  ### Returns an array of records
  ### Argument 1: Type - string corresponding to a type of record, e.g. 'bookmark'
  ### Argument 2: Options - hash ref ('order_by' => sort expression, e.g.) 
  my ($self, $type, $options) = @_;
  my @return = ();
  if ($self->records) {
    foreach my $record (@{ $self->records }) {
      if ($record->type eq $type) {
        push @return, $record;
      }
    }
  } 
  if ($options->{'order_by'}) {
    my $sorter = $options->{'order_by'};
    @return = reverse sort { $a->$sorter <=> $b->$sorter } sort @return;
  }
  return @return;
}

=head2 find_records 
Returns an array of records. This method is called by the autoloading mechanism, and is not intended for 
public use.
=cut

sub find_records {
  my (%params) = @_;
  my $record_type = "User";
  if ($params{record_type}) {
    $record_type = $params{record_type};
    delete $params{record_type};
  }
  $record_type = "EnsEMBL::Web::Record::" . $record_type;
  my $user_adaptor = undef;
  if ($params{options}->{adaptor}) {
    $user_adaptor = $params{options}->{adaptor};  
    warn "ADAPTOR for FIND: " . $user_adaptor;
  }
  my $results = $user_adaptor->find_records(%params);
  my @records = ();
  foreach my $result (@{ $results }) {
    #if (&dynamic_use($record_type)) {
      my $record = $record_type->new((
                                         id => $result->{id},
                                       type => $result->{type},
                                       user => $result->{user},
                                       data => $result->{data},
                                 created_at => $result->{created_at},
                                modified_at => $result->{modified_at}
                                                ));
      push @records, $record;
    #}
  }
  if ($params{options}) {
    my %options = %{ $params{options} };
    if ($options{order_by}) {
      @records = sort { $b->click <=> $a->click } @records;
    }
  }
  return @records;
}

=head2 owner 
Accessor for the owner property.
=cut


sub owner {
  ### a
  my $self = shift;
  $Owner_of{$self} = shift if @_;
  return $Owner_of{$self};
}

=head2 DESTROY 
Called automatically by Perl when object reference count reaches zero.
=cut

sub DESTROY {
  ### d
  my $self = shift;
  delete $Adaptor_of{$self};
  delete $Fields_of{$self};
  delete $Id_of{$self};
  delete $CreatedAt_of{$self};
  delete $ModifiedAt_of{$self};
  delete $Records_of{$self};
  delete $ParameterSet_of{$self};
  delete $Tainted_of{$self};
  delete $Type_of{$self};
  delete $Owner_of{$self};
}

}

=head1 AUTHOR

Matt Wood, C<< <mjw at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ensembl-web-record at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=EnsEMBL-Web-Record>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc EnsEMBL::Web::Record

You can also look for information at: http://www.ensembl.org

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/EnsEMBL-Web-Record>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/EnsEMBL-Web-Record>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=EnsEMBL-Web-Record>

=item * Search CPAN

L<http://search.cpan.org/dist/EnsEMBL-Web-Record>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to everyone on the Ensembl team, in particular James Smith, Anne Parker, Fiona Cunningham and Beth Prichard.

=head1 COPYRIGHT & LICENSE

Copyright (c) 1999-2006 The European Bioinformatics Institute and Genome Research Limited, and others. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
   3. The name Ensembl must not be used to endorse or promote products derived from this software without prior written permission. For written permission, please contact ensembl-dev@ebi.ac.uk
   4. Products derived from this software may not be called "Ensembl" nor may "Ensembl" appear in their names without prior written permission of the Ensembl developers.
   5. Redistributions of any form whatsoever must retain the following acknowledgment: "This product includes software developed by Ensembl (http://www.ensembl.org/).

THIS SOFTWARE IS PROVIDED BY THE ENSEMBL GROUP "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE ENSEMBL GROUP OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

=cut

1;
