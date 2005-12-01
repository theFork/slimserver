package Plugins::RadioIO::ProtocolHandler;

# $Id$

# SlimServer Copyright (c) 2001-2004 Vidur Apparao, Slim Devices Inc.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

use strict;
use base qw(Slim::Player::Protocols::HTTP);

use Scalar::Util qw(blessed);

use Slim::Formats::Parse;
use Slim::Player::Source;

sub new {
	my $class  = shift;
	my $args   = shift;

	my $url    = $args->{'url'};
	my $client = $args->{'client'};

	if ($url !~ /^radioio:\/\/(.*?)\.mp3/) {
		return undef;
	}

	my $pls  = Plugins::RadioIO::Plugin::getHTTPURL($1);

	my $sock = $class->SUPER::new({
		'url'    => $pls,
		'client' => $client
	}) || return undef;
	
	my @items = Slim::Formats::Parse::parseList($pls, $sock);

	return undef unless scalar(@items);

	return $class->SUPER::new({
		'url'     => $items[0],
		'client'  => $client,
		'infoUrl' => $url,
	});
}

sub canDirectStreamDisabled {
	my $self = shift;
	my $url = shift;

	if ($url =~ /^radioio:\/\/stream\/(.*)/) {
		return 'http://' . Plugins::RadioIO::Plugin::decrypt($1);
	}
	elsif ($url =~ /^radioio:\/\/(.*?)\.mp3/) {
		return Plugins::RadioIO::Plugin::getHTTPURL($1);
	}

	return undef;
}

sub parseDirectBody {
	my $self = shift;
	my $url = shift;
	my $body = shift;

	my $io = IO::String->new($body);
	my @items = Slim::Formats::Parse::parseList($url, $io);

	return () unless scalar(@items);

	my $stream = $items[0];
	$stream =~ s/http:\/\///;
	$stream = 'radioio://stream/' . Plugins::RadioIO::Plugin::decrypt($stream);

	my $currentDB = Slim::Music::Info::getCurrentDataStore();
	my $track = $currentDB->objectForUrl($url);

	if (blessed($track) && $track->can('title')) {

		Slim::Music::Info::setTitle($stream, $track->title());
	}

	return ($stream);
}

1;
