package Slim::DataStores::DBI::GenreTrack;

# $Id$
#
# Genre to track mapping class

use strict;
use base 'Slim::DataStores::DBI::DataModel';

{
	my $class = __PACKAGE__;

	$class->table('genre_track');
	$class->columns(Essential => qw/id genre track/);

	$class->has_a(genre => 'Slim::DataStores::DBI::Genre');
	$class->has_a(track => 'Slim::DataStores::DBI::Track');

	$class->add_constructor('genresFor' => 'track = ?');
}

tie my %_cache, 'Tie::Cache::LRU', 5000;

sub add {
	my $class = shift;
	my $genre = shift;
	my $track = shift;

	my @genres = ();

	# Handle the case where $genre is already an object:
	if (ref $genre && $genre->isa('Slim::DataStores::DBI::Genre')) {

		Slim::DataStores::DBI::GenreTrack->create({
			track => $track,
			genre => $genre,
		});

		return wantarray ? ($genre) : $genre;
	}

	for my $genreSub (Slim::Music::Info::splitTag($genre)) {

		$_cache{$genreSub} ||= Slim::DataStores::DBI::Genre->find_or_create({ 
			name     => $genreSub,
			namesort => Slim::Utils::Text::ignoreCaseArticles($genreSub),
		});

		push @genres, $_cache{$genreSub};
		
		Slim::DataStores::DBI::GenreTrack->create({
			track => $track,
			genre => $_cache{$genreSub},
		});
	}

	return wantarray ? @genres : $genres[0];
}

1;

__END__


# Local Variables:
# tab-width:4
# indent-tabs-mode:t
# End:
