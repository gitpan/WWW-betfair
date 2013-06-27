package WWW::betfair;
use strict;
use warnings;
use WWW::betfair::Template;
use WWW::betfair::Request;
use WWW::betfair::TypeCheck;
use Time::Piece;
use XML::Simple;
use Carp qw /croak/;
use feature qw/switch/;
use Data::Dumper;

=head1 NAME

WWW::betfair - interact with the betfair API using OO Perl

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 WARNING

This version of the WWW::betfair is beta - it has not been thoroughly tested. Therefore be cautious and check all argument types and values before using the methods in this library. Ensure that you adequately test any method of L<WWW::betfair> before using the method. As per the software license it is provided AS IS and no liability is accepted for any costs or penalties caused by using L<WWW::betfair>. 

To understand how to use the betfair API it is essential to read  the L<betfair documentation|http://bdp.betfair.com/docs/> before using L<WWW::betfair>. The betfair documentation is an excellent reference which also explains some of the quirks and bugs with the current betfair API.

=head1 WHAT IS BETFAIR?

L<betfair|http://www.betfair.com> is a sports betting services provider best known for hosting a sports betting exchange. The sports betting exchange works like a marketplace: betfair provides an anonymous platform for individuals to offer and take bets on sports events at a certain price and size; it is the ebay of betting. betfair provides an API for the sports betting exchange which enables users to search for sports events and markets, place and update bets and manage their account by depositing and withdrawing funds.


=head1 WHY USE THIS LIBRARY?

The betfair API communicates using verbose XML files which contain various bugs and quirks. L<WWW::betfair> makes it easier to use the betfair API by providing a Perl interface which manages the befair session, serializing API calls to betfair into the required XML format and de-serializing and parsing the betfair responses back into Perl data structures.


=head1 SYNOPSIS

L<WWW::betfair> provides an object oriented Perl interface for the betfair v6 API. This library communicates via HTTPS to the betfair servers using XML. To use the API you must have an active and funded account with betfair, and be accessing the API from a location where betfair permits use (e.g. USA based connections are refused, but UK connections are allowed). L<WWW::betfair> provides methods to connect to the betfair exchange, search for market prices place and update bets and manage your betfair account.

Example

    use WWW::betfair;
    use Data::Dumper;

    my $betfair = WWW::betfair->new;
    
    # login is required before performing any other services
    if ($betfair->login({username => 'sillymoos', password => 'password123'}) {
        
        # check account balance
        print Dumper($betfair->getAccountFunds);

        # get a list of all active event types (categories of sporting events e.g. football, tennis, boxing).
        print Dumper($betfair->getActiveEventTypes);

    }
    # login failed print the error message returned by betfair
    else {
        print Dumper($betfair->getError);
    }


=head1 TO DO

=over

=item *

Enable use of Australian exchange server - currently this is not supported

=item *

Add remaining L<betfair API methods|http://bdp.betfair.com/docs/>

=back

=head1 METHODS

=head2 new

Returns a new WWW::betfair object. Does not require any parameters.

Example

    my $betfair = WWW::betfair->new;

=cut

sub new {
    my $class = shift;
    my $self = {
        xmlsent     => undef,
        xmlreceived => undef,
        headerError => undef,
        bodyError   => undef,
        response    => {},
        sessionToken=> undef,
    };
    my $obj = bless $self, $class;
    my $typechecker = WWW::betfair::TypeCheck->new;
    $obj->{type} = $typechecker;
    return $obj;
}

=head2 getError

Returns the error message from the betfair API response. Upon a successful call API the value returned by getError is usually 'OK'.

=cut

sub getError {
    my $self = shift;
    return  $self->{headerError} eq 'OK' ? $self->{bodyError} : $self->{headerError};
}


=head2 getXMLSent

Returns a string of the XML message sent to betfair. This can be useful to inspect if de-bugging a failed API call.

=cut

sub getXMLSent {
    my $self = shift;
    return $self->{xmlsent};
}

=head2 getXMLReceived

Returns a string of the XML message received from betfair. This can be useful to inspect if de-bugging a failed API call.

=cut

sub getXMLReceived {
    my $self = shift;
    return $self->{xmlreceived};
}

=head2 getHashReceived

Returns a Perl data structure consisting of the entire de-serialized betfair XML response. This can be useful to inspect if de-bugging a failed API call and easier to read than the raw XML message, especially if used in conjunction with L<Data::Dumper>.

=cut

sub getHashReceived {
    my $self = shift;
    return $self->{response};
}

=head1 GENERAL API SERVICES METHODS

=head2 login

Authenticates the user and starts a session with betfair. This is required before any other methods can be used. Returns 1 on success and 0 on failure. If login fails and you are sure that you are using the correct the credentials, check the $betfair->{error} attribute. A common reason for failure on login is not having a funded betfair account. To resolve this, simply make a deposit into your betfair account and the login should work. See L<http://bdp.betfair.com/docs/Login.html> for details. Required arguments:

=over

=item *

username: string of your betfair username

=item *

password: string of your betfair password


=item *

productID: integer that indicates the API product to be used (optional). This defaults to 82 (the free personal API). Provide this argument if using a commercial version of the betfair API.

=back

Example

    $betfair->login({
                username => 'sillymoos',
                password => 'password123',
              });

=cut

sub login {
    my ($self, $args) = @_;
    my $paramChecks = { 
            username    => ['username', 1],
            password    => ['password', 1],
            productId   => ['int', 0],
    };
    return 0 unless $self->_checkParams($paramChecks, $args);
    my $params = {
        username    => $args->{username},
        password    => $args->{password}, 
        productId   => $args->{productId} || 82,
        locationId  => 0,
        ipAddress   => 0,
        vendorId    => 0,
    };
    return $self->_doRequest('login', 3, $params); 
}

=head2 keepAlive

Refreshes the current session with betfair. Returns 1 on success and 0 on failure. See L<http://bdp.betfair.com/docs/keepAlive.html> for details. Does not require any parameters. This method is not normally required as a session expires after 24 hours of inactivity.

Example

    $betfair->keepAlive;

=cut

sub keepAlive {
    my ($self) = @_;
    return $self->_doRequest('keepAlive', 3, {});
}

=head2 logout

Closes the current session with betfair. Returns 1 on success and 0 on failure. See L<http://bdp.betfair.com/docs/Logout.html> for details. Does not require any parameters.

Example

    $betfair->logout;

=cut

sub logout {
    my ($self) = @_;
    if ($self->_doRequest('logout', 3, {})) {
        # check body error message, different to header error
        my $self->{error} 
            = $self->{response}->{'soap:Body'}->{'n:logoutResponse'}->{'n:Result'}->{'errorCode'}->{'content'};
        return 1 if $self->{error} eq 'OK';
    }
    return 0;
}

=head1 READ ONLY BETTING API SERVICES

=head2 getActiveEventTypes

Returns an array of hashes of active event types or 0 on failure. See L<http://bdp.betfair.com/docs/GetActiveEventTypes.html> for details. Does not require any parameters.

Example

    my $activeEventTypes = $betfair->getActiveEventTypes;

=cut

sub getActiveEventTypes {
    my $self = shift;
    my $active_event_types =[];
    if ($self->_doRequest('getActiveEventTypes', 3, {}) ) {
        foreach (@{$self->{response}->{'soap:Body'}->{'n:getActiveEventTypesResponse'}->{'n:Result'}->{'eventTypeItems'}->{'n2:EventType'}}) {
            push(@{$active_event_types},{ 
                name            => $_->{'name'}->{'content'},
                id              => $_->{'id'}->{'content'},
                exchangeId      => $_->{'exchangeId'}->{'content'},
                nextMarketId    => $_->{'nextMarketId'}->{'content'},
            });
        }
        return $active_event_types;
    }
    return 0;
}

=head2 getAllEventTypes

Returns an array of hashes of all event types or 0 on failure. See L<http://bdp.betfair.com/docs/GetAllEventTypes.html> for details. Does not require any parameters.

Example

    my $allEventTypes = $betfair->getAllEventTypes;

=cut

sub getAllEventTypes {
    my $self = shift;
    if ($self->_doRequest('getAllEventTypes', 3, {})) {
        my $all_event_types = [];
        foreach (@{$self->{response}->{'soap:Body'}->{'n:getAllEventTypesResponse'}->{'n:Result'}->{'eventTypeItems'}->{'n2:EventType'} }) {
            push(@{$all_event_types},{
                name            => $_->{'name'}->{'content'},
                id              => $_->{'id'}->{'content'},
                exchangeId      => $_->{'exchangeId'}->{'content'},
                nextMarketId    => $_->{'nextMarketId'}->{'content'},
            });   
        }
        return $all_event_types;  
    } 
    return 0;
}

=head2 getAllMarkets

Returns an array of hashes of all markets or 0 on failure. See L<http://bdp.betfair.com/docs/GetAllMarkets.html> for details. Does not require any parameters.

Example

    my $allMarkets = $betfair->getAllMarkets;

=cut

sub getAllMarkets {
    my $self = shift;
    if ($self->_doRequest('getAllMarkets', 1, {})) {
        my $all_markets = [];
        foreach (split /[^\\]:/, $self->{response}->{'soap:Body'}->{'n:getAllMarketsResponse'}->{'n:Result'}->{'marketData'}->{'content'}) {
            my @market = split /~/, $_;
            push @{$all_markets}, { 
                    marketId            => $market[0], 
                    marketName          => $market[1],         
                    marketType          => $market[2],
                    marketStatus        => $market[3],
                    marketDate          => $market[4], 
                    menuPath            => $market[5],
                    eventHierarchy      => $market[6],
                    betDelay            => $market[7],
                    exchangeId          => $market[8],
                    iso3CountryCode     => $market[9],
                    lastRefresh         => $market[10],
                    numberOfRunners     => $market[11],
                    numberOfWinners     => $market[12],
                    totalMatchedAmount  => $market[13],
                    bspMarket           => $market[14],
                    turningInPlay       => $market[15],
            };
        }
        return $all_markets;
    } 
    return 0; 
}

=head2 getCurrentBets

Returns an array of hashrefs of current bets or 0 on failure. See L<http://bdp.betfair.com/docs/GetCurrentBets.html> for details. Requires a hashref with the following parameters:

=over

=item *

betStatus : string of a valid BetStatusEnum type as defined by betfair (see L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>)

=item *

detailed : string of either true or false

=item *

orderBy : string of a valid BetsOrderByEnum types as defined by betfair  (see L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>)

=item *

recordCount : integer of the maximum number of records to return

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=item *

noTotalRecordCount : string of either true or false

=item *

marketId : integer of the betfair market id for which current bets are required (optional)

=back

Example

    my $bets = $betfair->getCurrentBets({
                            betStatus           => 'M',
                            detailed            => 'false',
                            orderBy             => 'PLACED_DATE',
                            recordCount         => 100,
                            startRecord         => 0,
                            noTotalRecordCount  => 'true',
                            });

=cut

sub getCurrentBets {
    my ($self, $args) = @_;
    my $checkParams = {
        betStatus           => ['betStatusEnum', 1],
        detailed            => ['boolean', 1],
        orderBy             => ['betsOrderByEnum', 1],
        recordCount         => ['int', 1,],
        startRecord         => ['int', 1],
        noTotalRecordCount  => ['boolean', 1],
        marketId            => ['int',0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getCurrentBets', 1, $args) ) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getCurrentBetsResponse'}->{'n:Result'}->{'bets'}->{'n2:Bet'});
        my $current_bets = [];
        foreach (@{$response} ) {
            push(@$current_bets, {
                market_id           => $_->{'marketId'}->{'content'},
                bet_type            => $_->{'betType'}->{'content'},
                placed_date         => $_->{'placedDate'}->{'content'},
                bet_id              => $_->{'betId'}->{'content'},
                market_name         => $_->{'marketName'}->{'content'},
                profit_loss         => $_->{'profitAndLoss'}->{'content'},
                voided_date         => $_->{'voidedDate'}->{'content'},
                bet_status          => $_->{'betStatus'}->{'content'},
                bet_category_type   => $_->{'betCategoryType'}->{'content'},
                cancelled_date      => $_->{'cancelledDate'}->{'content'},
                matches             => $_->{'matches'}->{'content'},
                selection_name      => $_->{'selectionName'}->{'content'},
                selection_id        => $_->{'selectionId'}->{'content'},
                matched_size        => $_->{'matchedSize'}->{'content'},
                settled_date        => $_->{'settledDate'}->{'content'},
                avg_price           => $_->{'avgPrice'}->{'content'},
                price               => $_->{'price'}->{'content'},
                market_type_variant => $_->{'marketTypeVariant'}->{'content'},
                requested_size      => $_->{'requestedSize'}->{'content'},
                remaining_size      => $_->{'remainingSize'}->{'content'}
                });
            }
        return $current_bets;
    }
    return 0;
}

=head2 getEvents

Returns an array of hashes of events / markets or 0 on failure. See L<http://bdp.betfair.com/docs/GetEvents.html> for details. Requires:

=over

=item *

eventParentId : an integer which is the betfair event id of the parent event

=back

Example

    # betfair event id of tennis is 14
    my $tennisEvents = $betfair->getEvents({eventParentId => 14});

=cut

sub getEvents {
    my ($self, $args) = @_;
    my $checkParams = { eventParentId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getEvents', 3, $args)) {
        my $event_response = $self->_forceArray($self->{response}->{'soap:Body'}->{'n:getEventsResponse'}->{'n:Result'}->{'eventItems'}->{'n2:BFEvent'});
        my $event_parent_id = $self->{response}->{'soap:Body'}->{'n:getEventsResponse'}->{'n:Result'}->{'eventParentId'}->{'content'};
        my $events;
        foreach (@{$event_response}) {
            $events = _add_event($events, $_, $event_parent_id);
        }
        my $market_response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getEventsResponse'}->{'n:Result'}->{'marketItems'}->{'n2:MarketSummary'});  
        foreach (@{$market_response}) {
            $events = _add_market($events, $_, $event_parent_id);
        }

        # Coupons not currently supported by betfair API, hence deprecating this code for now:
        #my $coupon_ref = $self->_forceArray($self->{response}->{'soap:Body'}->{'n:getEventsResponse'}->{'n:Result'}->{'couponLinks'}->{'n2:CouponLink'});  
        #foreach (@{$coupon_ref}) {
        #   $events->{ 'coupon' }->{ $_->{'couponName'}->{'content'} } = $_->{'couponId'}->{'content'};
        #}
        return $events;
    } 
    return 0;
    sub _add_event {
        my ($events, $event_to_be_added, $event_parent_id) = @_;
        push(@{$events->{event}}, {
            bf_id       => $event_to_be_added->{'eventId'}->{'content'},
            name        => $event_to_be_added->{'eventName'}->{'content'},
            menu_level  => $event_to_be_added->{'menuLevel'}->{'content'},
            order_index => $event_to_be_added->{'orderIndex'}->{'content'},
            parent_id   => $event_parent_id,
            active_flag => 1,
            });
        return $events;
    }
    sub _add_market {
        my ($events, $market_to_be_added, $market_parent_id) = @_;
        push(@{$events->{market}}, {
            bf_id           => $market_to_be_added->{'marketId'}->{'content'},
            name            => $market_to_be_added->{'marketName'}->{'content'},
            menu_level      => $market_to_be_added->{'menuLevel'}->{'content'},
            order_index     => $market_to_be_added->{'orderIndex'}->{'content'},
            type            => $market_to_be_added->{'marketType'}->{'content'},
            exchange_id     => $market_to_be_added->{'exchangeId'}->{'content'},
            time            => $market_to_be_added->{'startTime'}->{'content'},
            timezone        => $market_to_be_added->{'timezone'}->{'content'},
            parent_id       => $market_parent_id,
            event_type_id   => $market_to_be_added->{'eventTypeId'}->{'content'},
            active_flag => 1,
        });
        return $events;
    }
}

=head2 getMarket

Returns a hash of market data or 0 on failure. See L<http://bdp.betfair.com/docs/GetMarket.html> for details. Requires:

=over

=item *

marketId : integer which is the betfair id of the market

=back

Example

    my $marketData = $betfair->getMarket({marketId => 108690258});

=cut


sub getMarket {
    my ($self, $args) = @_;
    my $checkParams = { marketId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarket', 1, $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketResponse'}->{'n:Result'}->{'market'};
        my $runners_list = $self->_forceArray($response->{'runners'}->{'n2:Runner'});
        my @parsed_runners = ();
        foreach (@{$runners_list}) {
            push(@parsed_runners, {
                name        => $_->{'name'}->{'content'},
                selectionId => $_->{'selectionId'}->{'content'},
            });
        }
        return {
            name            => $response->{'name'}->{'content'},
            bf_id           => $response->{'marketId'}->{'content'},
            event_type_id   => $response->{'eventTypeId'}->{'content'}, 
            time            => $response->{'marketTime'}->{'content'},
            marketStatus    => $response->{'marketStatus'}->{'content'},
            runners         => \@parsed_runners,
            description     => $response->{'marketDescription'}->{'content'},
            active_flag     => 1,
        };
    } 
    return 0;
}

=head2 getCompleteMarketPrices

Returns a hashref of market data including an arrayhashref of individual runners prices or 0 on failure. See L<http://bdp.betfair.com/docs/GetCompleteMarketPricesCompressed.html> for details. Note that this method de-serializes the compressed string returned by the betfair method into a Perl data structure. Requires:

=over

=item *

marketId : integer of the betfair market id,

=item *

currencyCode : string of the three letter ISO 4217 currency code (optional). If this is not provided, the users home currency is used

=back

Example

    my $marketPriceData = $betfair->getCompleteMarketPrices({marketId => 123456789, currencyCode => 'GBP'}); 

=cut

sub getCompleteMarketPrices {
    my ($self, $args) = @_;
    my $checkParams = { marketId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getCompleteMarketPricesCompressed', 1, $args)) {
        my @compressed_prices = split /:/, $self->{response}->{'soap:Body'}->{'n:getCompleteMarketPricesCompressedResponse'}->{'n:Result'}->{'completeMarketPrices'}->{'content'};
        my $compressed_prices_ref = { marketId => shift @compressed_prices };
        foreach (@compressed_prices) {
            my @selection_array = split /\|/, $_;
            my ($selection_back_prices_ref, $selection_lay_prices_ref, $selection_bspBack_prices_ref, $selection_bspLay_prices_ref);
            my @selection_prices_array = split /~/, $selection_array[1];
            while (@selection_prices_array){
                my $price_ref = {
                    price           => shift(@selection_prices_array),
                    back_amount     => shift(@selection_prices_array),
                    lay_amount      => shift(@selection_prices_array),
                    bsp_back_amount => shift(@selection_prices_array),
                    bsp_lay_amount  => shift(@selection_prices_array),
                };
                push(@$selection_back_prices_ref, $price_ref) if $price_ref->{ 'back_amount' } ne '0.0';
                push(@$selection_lay_prices_ref, $price_ref) if $price_ref->{ 'lay_amount' } ne '0.0';
                push(@$selection_bspBack_prices_ref, $price_ref) if $price_ref->{ 'bsp_back_amount' } ne '0.0';
                push(@$selection_bspLay_prices_ref, $price_ref) if $price_ref->{ 'bsp_lay_amount' } ne '0.0';
            }
            
            my @selection_metadata_array = split /~/, $selection_array[0];
            push(@{$compressed_prices_ref->{runners}},{
                bf_id               => $selection_metadata_array[0],
                order_index         => $selection_metadata_array[1],
                total_matched       => $selection_metadata_array[2],
                last_price_matched  => $selection_metadata_array[3],
                asian_handicap      => $selection_metadata_array[4],
                reduction_factor    => $selection_metadata_array[5],
                vacant              => $selection_metadata_array[6],
                asian_line_id       => $selection_metadata_array[7],
                far_price_sp        => $selection_metadata_array[8],
                near_price_sp       => $selection_metadata_array[9],
                actual_price_sp     => $selection_metadata_array[10],
                prices              => {
                                    back_prices    => [_sortArrayRef($selection_back_prices_ref)], 
                                    lay_prices     => [_sortArrayRef($selection_lay_prices_ref)],
                                    bsp_back_prices => [_sortArrayRef($selection_bspBack_prices_ref)], 
                                    bsp_lay_prices  => [_sortArrayRef($selection_bspLay_prices_ref)],
                },
                name            => undef, #name is added in getMarketPricesCombined method
            });
        }
        return $compressed_prices_ref;
    }
    return 0;
}

=head2 getMUBets

Returns an arrayref of hashes of bets or 0 on failure. See L<http://bdp.betfair.com/docs/GetMUBets.html> for details. Requires:

=over

=item *

betStatus : string of betfair betStatusEnum type, must be either matched, unmatched or both (M, U, MU). See L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>

=item *

orderBy : string of a valid BetsOrderByEnum types as defined by betfair. see L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>

=item *

recordCount : integer of the maximum number of records to return

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=item *

noTotalRecordCount : string of either true or false

=item *

marketId : integer of the betfair market id for which current bets are required (optional)

=item *

betId : an array of betIds (optional). If included, betStatus must be 'MU'.

=back

Example

    my $muBets = $betfair->getMUBets({
                            betStatus           => 'MU',
                            orderBy             => 'PLACED_DATE',
                            recordCount         => 1000,
                            startRecord         => 0,
                            noTotalRecordCount  => 'true',
                            sortOrder           => 'ASC',
                            marketId            => 123456789,
                 });

=cut

sub getMUBets {
    my ($self, $args ) = @_;
    my $checkParams = {
        betStatus           => ['betStatusEnum', 1],
        orderBy             => ['betsOrderByEnum', 1],
        recordCount         => ['int', 1,],
        startRecord         => ['int', 1],
        marketId            => ['int', 0],
        sortOrder           => ['sortOrderEnum', 1],
        betId               => ['int', 0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    my $mu_bets = [];
    if ($self->_doRequest('getMUBets', 1, $args)) {
        my $response = $self->_forceArray(
            $self->{response}->{'soap:Body'}->{'n:getMUBetsResponse'}->{'n:Result'}->{'bets'}->{'n2:MUBet'});
        foreach (@{$response} ) {
            $mu_bets = _add_mu_bet($mu_bets, $_);
        }
        return $mu_bets;
    } 
    return 0;

    sub _add_mu_bet {
        my ($mu_bets, $bet_to_be_added) = @_;
        push(@$mu_bets, {
            market_id           => $bet_to_be_added->{'marketId'}->{'content'},
            bet_type            => $bet_to_be_added->{'betType'}->{'content'},
            transaction_id      => $bet_to_be_added->{'transactionId'}->{'content'},
            size                => $bet_to_be_added->{'size'}->{'content'},
            placed_date         => $bet_to_be_added->{'placedDate'}->{'content'},
            bet_id              => $bet_to_be_added->{'betId'}->{'content'},
            bet_status          => $bet_to_be_added->{'betStatus'}->{'content'},
            bet_category_type   => $bet_to_be_added->{'betCategoryType'}->{'content'},
            bet_persistence     => $bet_to_be_added->{'betPersistenceType'}->{'content'},
            matched_date        => $bet_to_be_added->{'matchedDate'}->{'content'},
            selection_id        => $bet_to_be_added->{'selectionId'}->{'content'},
            price               => $bet_to_be_added->{'price'}->{'content'},
            bsp_liability       => $bet_to_be_added->{'bspLiability'}->{'content'},
            handicap            => $bet_to_be_added->{'handicap'}->{'content'},
            asian_line_id       => $bet_to_be_added->{'asianLineId'}->{'content'}
        });
        return $mu_bets;
    }
}

=head2 cancelBets

Cancels up to 40 unmatched and active bets on betfair. Returns an arrayref of hashes of cancelled bets. See L<http://bdp.betfair.com/docs/CancelBets.html> for details. Requires:

=over

=item *

betIds : an arrayref of integers of betIds that should be cancelled, up to 40 betIds are permitted by betfair.

=back

Example

    my $cancelledBetsResults = $betfair->cancelBets({betIds => [123456789, 987654321]});

=cut

sub cancelBets {
    my ($self, $args) = @_;
    my $checkParams = {
        betIds => ['int', 1],
    };
    foreach (@{$args->{betIds}}) {
        return 0 unless $self->_checkParams($checkParams, { betIds => $_ });
    }
    # adjust args into betfair api required structure
    my $params = { bets => {
                            CancelBets => {
                                            betId => $args->{betIds},
                            },
                   },
    };
    my $cancelled_bets = [];
    if ($self->_doRequest('cancelBets', 1, $params)) {
        my $response = $self->_forceArray( 
            $self->{response}->{'soap:Body'}->{'n:cancelBetsResponse'}->{'n:Result'}->{'betResults'}->{'n2:CancelBetsResult'});
        foreach (@{$response} ) {
            $cancelled_bets = _add_cancelled_bet($cancelled_bets, $_);
        }
        return $cancelled_bets;
    } 
    return 0;
    sub _add_cancelled_bet {
        my ($cancelled_bets, $bet_to_be_added) = @_;
        push(@$cancelled_bets, {
            success           => $bet_to_be_added->{'success'}->{'content'},
            result_code       => $bet_to_be_added->{'resultCode'}->{'content'},
            size_matched      => $bet_to_be_added->{'sizeMatched'}->{'content'},
            size_cancelled    => $bet_to_be_added->{'sizeCancelled'}->{'content'},
            bet_id            => $bet_to_be_added->{'betId'}->{'content'},
        });
        return $cancelled_bets;
    }
}

=head2 placeBets

Places up to 60 bets on betfair and returns an array of results or zero on failure. See L<http://bdp.betfair.com/docs/PlaceBets.html> for details. Requires:

=over

=item *

bets : an arrayref of hashes of bets. Up to 60 hashes are permitted by betfair. Every bet hash should contain:

=over 8

=item *

asianLineId : integer of the ID of the asian handicap market, usually 0 unless betting on an asian handicap market

=item *

betCategoryType : a string of the betCategoryTypeEnum, usually 'E' for exchange, see L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html> for details.

=item *

betPersistenceType : a string of the betPersistenceTypeEnum, usually 'NONE' for standard exchange bets. See L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html> for details.

=item *

betType : a string of the betTypeEnum. Either 'B' to back or 'L' to lay.

=item *

bspLiability : a number of the maximum amount to risk for a bsp bet. For a back / lay bet this is equivalent to the whole stake amount.

=item *

marketId : integer of the marketId for which the bet should be placed.

=item *

price : number of the decimal odds for the bet.

=item *

selectionId : integer of the betfair id of the runner (selection option) that the bet should be placed on.

=item *

size : number for the stake amount for this bet.

=back

=back

Example

    # place one bet to back selection 99 on market 123456789 at 5-to-1 for 10 
    $myBetPlacedResults = $betfair->placeBets({
                                        bets => [{ 
                                                asianLineId         => 0,
                                                betCategoryType     => 'E',
                                                betPersistenceType  => 'NONE',
                                                betType             => 'B',
                                                bspLiability        => 2,
                                                marketId            => 123456789,
                                                price               => 5,
                                                selectionId         => 99,
                                                size                => 10,
                                            },
                                        ],
                                    });

=cut

sub placeBets {
    my ($self, $args) = @_;
    my $checkParams = { 
        asianLineId         => ['int', 1],
        betCategoryType     => ['betCategoryTypeEnum', 1],
        betPersistenceType  => ['betPersistenceTypeEnum', 1],
        betType             => ['betTypeEnum', 1],
        bspLiability        => ['int', 1],
        marketId            => ['int', 1],
        price               => ['decimal', 1],
        selectionId         => ['int', 1],
        size                => ['decimal', 1],
    };
    foreach (@{$args->{bets}}) {
        return 0 unless $self->_checkParams($checkParams, $_);
    }
    # adjust args into betfair api required structure
    my $params = { bets => {
                            PlaceBets =>  $args->{bets},
                   },
    };
    if ($self->_doRequest('placeBets', 1, $params) ) {
        my $response = $self->_forceArray($self->{response}->{'soap:Body'}->{'n:placeBetsResponse'}->{'n:Result'}->{'betResults'}->{'n2:PlaceBetsResult'});
        my $placed_bets = [];
        foreach (@{$response}) {
            push @{$placed_bets}, {
            success             => $_->{'success'}->{'content'},
            result_code         => $_->{'resultCode'}->{'content'},
            bet_id              => $_->{'betId'}->{'content'},
            size_matched        => $_->{'sizeMatched'}->{'content'},
            avg_price_matched   => $_->{'averagePriceMatched'}->{'content'}
            };
        }
        return $placed_bets;
    } 
    return 0;
}

=head2 updateBets

Updates existing unmatched bets on betfair: the size, price and persistence can be updated. Note that only the size or the price can be updated in one request, if both parameters are provided betfair ignores the new size value. Returns an arrayref of hashes of updated bet results. See L<http://bdp.betfair.com/docs/UpdateBets.html> for details. Requires:

=over

=item *

bets : an arrayref of hashes of bets to be updated. Each hash represents one bet and must contain the following key / value pairs:

=over 8

=item *

betId : integer of the betId to be updated

=item *

newBetPersistenceType : string of the betfair betPersistenceTypeEnum to be updated to see L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html> for more details.

=item *

newPrice : number for the new price of the bet

=item *

newSize : number for the new size of the bet

=item *

oldBetPersistenceType : string of the current bet's betfair betPersistenceTypeEnum see L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html> for more details.

=item *

oldPrice : number for the old price of the bet

=item *

oldSize : number for the old size of the bet

=back

=back


Example

    my $updateBetDetails = $betfair->updateBets({
                                        bets => [{
                                                betId                   => 12345,
                                                newBetPersistenceType   => 'NONE',
                                                newPrice                => 5,
                                                newSize                 => 10,
                                                oldBetPersistenceType   => 'NONE',
                                                oldPrice                => 2,
                                                oldSize                 => 10,
                                        }],
                                    });


=cut

sub updateBets {
    my ($self, $args) = @_;
    my $checkParams = { 
        betId                   => ['int', 1],
        newBetPersistenceType   => ['betPersistenceTypeEnum', 1],
        oldBetPersistenceType   => ['betPersistenceTypeEnum', 1],
        newSize                 => ['decimal', 1],
        oldSize                 => ['decimal', 1],
        newPrice                => ['decimal', 1],
        oldPrice                => ['decimal', 1],
    };
    foreach (@{$args->{bets}}) {
        return 0 unless $self->_checkParams($checkParams, $_);
    }
    my $params = {
        bets => {
            UpdateBets => $args->{bets},
        },
    };
    my $updated_bets = [];
    if ($self->_doRequest('updateBets', 1, $params)) {
        my $response = $self->_forceArray($self->{response}->{'soap:Body'}->{'n:updateBetsResponse'}->{'n:Result'}->{'betResults'}->{'n2:UpdateBetsResult'});
        foreach (@{$response}) {
            push @{$updated_bets}, {
                success         => $_->{'success'}->{'content'},
                size_cancelled  => $_->{'sizeCancelled'}->{'content'},
                new_price       => $_->{'newPrice'}->{'content'},
                bet_id          => $_->{'betId'}->{'content'},
                new_bet_id      => $_->{'newBetId'}->{'content'},
                result_code     => $_->{'content'}->{'content'},
                new_size        => $_->{'newSize'}->{'content'},
            };
        }
        return $updated_bets;
    }
    return 0;
}


=head1 ACCOUNT MANAGEMENT API SERVICES

=head2 addPaymentCard

Adds a payment card to your betfair account. Returns an arrayref of hashes of payment card responses or 0 on failure. See L<http://bdp.betfair.com/docs/AddPaymentCard.html>. Requires:

=over

=item *

cardNumber : string of the card number

=item *

cardType : string of a valid betfair cardTypeEnum (e.g. 'VISA'). See L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>

=item *

cardStatus : string of a valid betfair paymentCardStatusEnum, either 'LOCKED' or 'UNLOCKED'

=item *

startDate : string of the card start date, optional depending on type of card

=item *

expiryDate : string of the card expiry date

=item *

issueNumber : string of the issue number or NULL if the cardType is not Solo or Switch

=item *

billingName : name of person on the billing account for the card

=item *

nickName : string of the card nickname must be less than 9 characters

=item *

password : string of the betfair account password

=item *

address1 : string of the first line of the address for the payment card

=item *

address2 : string of the second line of the address for the payment card

=item *

address3 : string of the third line of the address for the payment card (optional)

=item *

address4 : string of the fourth line of the address for the payment card (optional)

=item *

town : string of the town for the payment card

=item *

county : string of the county for the payment card

=item *

zipCode : string of the zip / postal code for the payment card

=item *

country : string of the country for the payment card

=back

Example

    my $addPaymentCardResponse = $betfair->addPaymentCard({
                                            cardNumber  => '1234123412341234',
                                            cardType    => 'VISA',
                                            cardStatus  => 'UNLOCKED',
                                            startDate   => '0113',
                                            expiryDate  => '0116',
                                            issueNumber => 'NULL',
                                            billingName => 'The Sillymoose',
                                            nickName    => 'democard',
                                            password    => 'password123',
                                            address1    => 'Tasty bush',
                                            address2    => 'Mountain Plains',
                                            town        => 'Hoofton',
                                            zipCode     => 'MO13FR',
                                            county      => 'Mooshire',
                                            country     => 'UK',
                                 });

=cut

sub addPaymentCard {
    my ($self, $args) = @_;
    my $checkParams = {
        cardNumber  => ['int', 1],
        cardType    => ['cardTypeEnum', 1],
        cardStatus  => ['cardStatusEnum', 1],
        startDate   => ['cardDate', 1],
        expiryDate  => ['cardDate', 1],
        issueNumber => ['int', 1],
        billingName => ['string', 1],
        nickName    => ['string9', 1],
        password    => ['password', 1],
        address1    => ['string', 1],
        address2    => ['string', 1],
        address3    => ['string', 0],
        address4    => ['string', 0],
        town        => ['string', 1],
        zipCode     => ['string', 1],
        county      => ['string', 1],
        country     => ['string', 1],

    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('addPaymentCard', 3, $args) ) {
        return  $self->_addPaymentCardLine([], $self->{response}->{'soap:Body'}->{'n:addPaymentCardResponse'}->{'n:Result'}->{'n2:PaymentCard'});
    }
    return 0;
}

=head2 depositFromPaymentCard

Deposits money in your betfair account using a payment card. See L<http://bdp.betfair.com/docs/DepositFromPaymentCard.html> for further details. Returns the betfair response as a hashref or 0 on failure. Requires:

=over

=item *

amount : number which represents the amount of money to deposit

=item *

cardIdentifier : string of the nickname for the payment card

=item *

cv2 : string of the CV2 digits from the payment card (also known as the security digits)

=item *

password : string of the betfair account password

=back

Example

    # deposit 10 in my account
    my $depositResponse = $betfair->depositFromPaymentCard({
                                            amount          => 10,
                                            cardIdentifier  => 'checking',
                                            cv2             => '999',
                                            password        => 'password123',
                                    });

=cut

sub depositFromPaymentCard {
    my ($self, $args) = @_;
    my $checkParams = {
         amount         => ['decimal', 1],
         cardIdentifier => ['string9', 1],
         cv2            => ['cv2', 1],
         password       => ['password', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('depositFromPaymentCard', 3, $args)) {
        my $deposit_response = $self->{response}->{'soap:Body'}->{'n:depositFromPaymentCardResponse'}->{'n:Result'};
        return  {
            fee                 => $deposit_response->{'fee'}->{'content'},
            transaction_id      => $deposit_response->{'transactionId'}->{'content'},
            min_amount          => $deposit_response->{'minAmount'}->{'content'},
            error_code          => $deposit_response->{'errorCode'}->{'content'},
            minor_error_code    => $deposit_response->{'minorErrorCode'}->{'content'},
            max_amount          => $deposit_response->{'maxAmount'}->{'content'},
            net_amount          => $deposit_response->{'netAmount'}->{'content'},
        };
    }
    return 0;
}

=head2 getAccountFunds

Returns a hashref of the account funds betfair response. See L<http://bdp.betfair.com/docs/GetAccountFunds.html> for details. No parameters are required.

Example

    my $funds = $betfair->getAccountFunds;

=cut

sub getAccountFunds {
    my ($self) = @_;
    if ($self->_doRequest('getAccountFunds', 1, {})) {
        return {
            availBalance => $self->{response}->{'soap:Body'}->{'n:getAccountFundsResponse'}->{'n:Result'}->{'availBalance'}->{'content'},
            balance => $self->{response}->{'soap:Body'}->{'n:getAccountFundsResponse'}->{'n:Result'}->{'balance'}->{'content'},
            exposure => $self->{response}->{'soap:Body'}->{'n:getAccountFundsResponse'}->{'n:Result'}->{'exposure'}->{'content'},
            withdrawBalance => $self->{response}->{'soap:Body'}->{'n:getAccountFundsResponse'}->{'n:Result'}->{'withdrawBalance'}->{'content'}
        };
    } 
    return 0;
}

=head2 getAccountStatement

Returns an arrayref of hashes of account statement entries or 0 on failure. See L<http://bdp.betfair.com/docs/GetAccountStatement.html> for further details. Requires:

=over

=item *

startRecord : integer indicating the first record number to return. Record indexes are zero-based, hence 0 is the first record

=item *

recordCount : integer of the maximum number of records to return

=item *

startDate : date for which to return records on or after this date (a string in the XML datetime format see example)

=item *

endDate : date for which to return records on or before this date (a string in the XML datetime format see example)

=item *

itemsIncluded : string of the betfair AccountStatementIncludeEnum see l<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html> for details

=back

Example

    # return an account statement for all activity starting at record 1 up to 1000 records between 1st January 2013 and 16th June 2013
    my $statement = $betfair->getAccountStatement({
                                    startRecord     => 0,
                                    recordCount     => 1000,
                                    startDate       => '2013-01-01T00:00:00.000Z',         
                                    endDate         => '2013-06-16T00:00:00.000Z',         
                                    itemsIncluded   => 'ALL',
                              });

=cut

sub getAccountStatement {
    my ($self, $args) = @_; 
    my $checkParams = {
        startRecord     => ['int', 1],
        recordCount     => ['int', 1],
        startDate       => ['date', 1],         
        endDate         => ['date', 1],         
        itemsIncluded   => ['accountStatementIncludeEnum', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    my $account_statement = [];
    if ($self->_doRequest('getAccountStatement', 1, $args)) {
        my $response = 
            $self->_forceArray($self->{response}->{'soap:Body'}->{'n:getAccountStatementResponse'}->{'n:Result'}->{'items'}->{'n2:AccountStatementItem'});
        foreach (@{$response}) {
            $account_statement = _add_statement_line($account_statement, $_);
        }
        return $account_statement;
    } 
    return 0;

    sub _add_statement_line {
        my ($account_statement, $line_to_be_added) = @_;
        push(@$account_statement, {
            bet_type            => $line_to_be_added->{'betType'}->{'content'},
            transaction_id      => $line_to_be_added->{'transactionId'}->{'content'},
            transaction_type    => $line_to_be_added->{'transactionType'}->{'content'},
            bet_size            => $line_to_be_added->{'betSize'}->{'content'},            
            placed_date         => $line_to_be_added->{'placedDate'}->{'content'},
            bet_id              => $line_to_be_added->{'betId'}->{'content'},
            market_name         => $line_to_be_added->{'marketName'}->{'content'},
            gross_bet_amount    => $line_to_be_added->{'grossBetAmount'}->{'content'},
            market_type         => $line_to_be_added->{'marketType'}->{'content'},
            event_id            => $line_to_be_added->{'eventId'}->{'content'},
            account_balance     => $line_to_be_added->{'accountBalance'}->{'content'},
            event_type_id       => $line_to_be_added->{'eventTypeId'}->{'content'},            
            bet_category_type   => $line_to_be_added->{'betCategoryType'}->{'content'},
            selection_name      => $line_to_be_added->{'selectionName'}->{'content'},
            selection_id        => $line_to_be_added->{'selectionId'}->{'content'},
            commission_rate     => $line_to_be_added->{'commissionRate'}->{'content'},
            full_market_name    => $line_to_be_added->{'fullMarketName'}->{'content'},
            settled_date        => $line_to_be_added->{'settledDate'}->{'content'},
            avg_price           => $line_to_be_added->{'avgPrice'}->{'content'},
            start_date          => $line_to_be_added->{'startDate'}->{'content'},
            win_lose            => $line_to_be_added->{'winLose'}->{'content'},
            amount              => $line_to_be_added->{'amount'}->{'content'}
        });
        return $account_statement;
    }
}

=head2 getPaymentCard

Returns an arrayref of hashes of payment card or 0 on failure. See L<http://bdp.betfair.com/docs/GetPaymentCard.html> for details. Does not require any parameters.

Example

    my $cardDetails = $betfair->getPaymentCard;

=cut

sub getPaymentCard {
    my ($self, $args) = @_;
    my $payment_cards = [];
    if ($self->_doRequest('getPaymentCard', 3, $args) ) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getPaymentCardResponse'}->{'n:Result'}->{'paymentCardItems'}->{'n2:PaymentCard'});
        foreach (@{$response}) {
            $payment_cards = $self->_addPaymentCardLine($payment_cards, $_);
        }
        return $payment_cards;
    }
    return 0;
}

=head2 getSubscriptionInfo

Returns an arrayref of hashes of subscription or 0 on failure. Does not require any parameters. See L<http://bdp.betfair.com/docs/GetSubscriptionInfo.html> for details. Note that if you are using the personal free betfair API, this service will return no data.

Example

    my $subscriptionData = $betfair->getSubscriptionInfo;

=cut


sub getSubscriptionInfo {
    my ($self, $args) = @_;
    if ($self->_doRequest('getSubscriptionInfo', 3, $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getSubscriptionInfoResponse'}->{'n:Result'};
        return {
            minor_error_code    => $response->{'minorErrorCode'}->{'content'},
            billing_amount      => $response->{'subscriptions'}->{'billingAmount'}->{'content'},
            billing_date        => $response->{'subscriptions'}->{'billingDate'}->{'content'},
            billing_period      => $response->{'subscriptions'}->{'billingPeriod'}->{'content'},
            product_id          => $response->{'subscriptions'}->{'productId'}->{'content'},
            product_name        => $response->{'subscriptions'}->{'productName'}->{'content'},
            subscribed_date     => $response->{'subscriptions'}->{'subscribedDate'}->{'content'},
            status              => $response->{'subscriptions'}->{'status'}->{'content'},
            vat_enabled         => $response->{'subscriptions'}->{'vatEnabled'}->{'content'},
            setup_charge        => $response->{'subscriptions'}->{'setupCharge'}->{'content'},
            setup_charge_active => $response->{'subscriptions'}->{'setupChargeActive'}->{'content'}
        };
    }
    return 0;
}

=head2 withdrawToPaymentCard

Withdraws money from your betfair account to the payment card specified. Returns a hashref of the withdraw response from betfair or 0 on failure. See L<http://bdp.betfair.com/docs/WithdrawToPaymentCard.html> for details. Requires:

=over

=item *

amount : number representing the amount of money to withdraw

=item *

cardIdentifier : string of the nickname of the payment card

=item *

password : string of your betfair password

=back

Example

    my $withdrawalResult = $betfair->withdrawToPaymentCard({
                                        amount          => 10,
                                        cardIdentifier  => 'checking',
                                        password        => 'password123',
                                    }); 

=cut

sub withdrawToPaymentCard {
    my ($self, $args) = @_; 
    my $checkParams = {
        amount          => ['decimal', 1],
        cardIdentifier  => ['string9', 1],
        password        => ['password', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('withdrawToPaymentCard', 3, $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:withdrawToPaymentCardResponse'}->{'n:Result'};
        return {
            amount_withdrawn   => $response->{'amountWithdrawn'}->{'content'},
            error_code         => $response->{'errorCode'}->{'content'},
            minor_error_code   => $response->{'minorErrorCode'}->{'content'},
            max_amount         => $response->{'maxAmount'}->{'content'}            
        };
    }
    return 0;
}

=head1 INTERNAL METHODS

=head2 _doRequest

Processes requests to and from the betfair API.

=cut

sub _doRequest {
    my ($self, $action, $server, $params) = @_;

    # clear data from previous request
    $self->_clearData;
  
    # add header to $params
    $params->{header}->{sessionToken} = $self->{sessionToken} if defined $self->{sessionToken}; 
    $params->{header}->{clientStamp} = 0;

    my $uri = $self->_getServerURI($server);

    # build xml message
    $self->{xmlsent} = WWW::betfair::Template::populate($uri, $action, $params);

    # save response, session token and error as attributes
    my $uaResponse = WWW::betfair::Request::new_request($uri, $action, $self->{xmlsent});
    $self->{xmlreceived} = $uaResponse->decoded_content(charset => 'none');
    $self->{response} = eval {XMLin($self->{xmlreceived})};
    if ($@) {
        croak 'error parsing betfair XML response ' . $@;
    }
    if ($self->{response}){

        $self->{sessionToken} 
            = $self->{response}->{'soap:Body'}->{'n:'.$action.'Response'}->{'n:Result'}->{'header'}->{'sessionToken'}->{'content'};
        
        $self->{headerError}
            = $self->{response}->{'soap:Body'}->{'n:'.$action.'Response'}->{'n:Result'}->{'header'}->{'errorCode'}->{'content'} 
                || 'OK';

        $self->{bodyError} 
            = $self->{response}->{'soap:Body'}->{'n:'.$action.'Response'}->{'n:Result'}->{'errorCode'}->{'content'}
                || 'OK';
        return 1 if $self->getError eq 'OK';
    }
    return 0;
}

=head2 _getServerURI

Returns the URI for the target betfair server depending on whether it is an exchange server (1 and 2) or the global server.

=cut

sub _getServerURI {
    my ($self, $server) = @_;
    given($server) {
        when (/1/) { return 'https://api.betfair.com/exchange/v5/BFExchangeService'}
        when (/2/) { return 'https://api-au.betfair.com/exchange/v5/BFExchangeService'} 
        default    { return 'https://api.betfair.com/global/v3/BFGlobalService'}
    }
}


=head2 _sortArrayRef

Returns a sorted arrayref based on price.

=cut

sub _sortArrayRef {
    my $array_ref = shift;
    if (ref($array_ref) eq 'ARRAY'){
       return sort { $b->{price} <=> $a->{price} } @$array_ref;
    }
    return $array_ref;
}

=head2 _addPaymentCardLine

Pushes a hashref of payment card key / value pairs into an arrayref and returns the result.

=cut

sub _addPaymentCardLine {
    my ($self, $payment_card, $line_to_be_added) = @_;
    push(@{$payment_card}, {
        country_code_iso3       => $line_to_be_added->{'billingCountryIso3'}->{'content'},
        billing_address1        => $line_to_be_added->{'billingAddress1'}->{'content'},
        billing_address2        => $line_to_be_added->{'billingAddress2'}->{'content'},
        billing_address3        => $line_to_be_added->{'billingAddress3'}->{'content'},
        billing_address4        => $line_to_be_added->{'billingAddress4'}->{'content'},
        card_type               => $line_to_be_added->{'cardType'}->{'content'},
        issuing_country_iso3    => $line_to_be_added->{'issuingCountryIso3'}->{'content'},
        total_withdrawals       => $line_to_be_added->{'totalWithdrawals'}->{'content'},
        expiry_date             => $line_to_be_added->{'expiryDate'}->{'content'},
        nickname                => $line_to_be_added->{'nickName'}->{'content'},
        card_status             => $line_to_be_added->{'cardStatus'}->{'content'},
        issue_number            => $line_to_be_added->{'issueNumber'}->{'content'},
        country                 => $line_to_be_added->{'country'}->{'content'},
        county                  => $line_to_be_added->{'county'}->{'content'},
        billing_name            => $line_to_be_added->{'billingName'}->{'content'},
        town                    => $line_to_be_added->{'town'}->{'content'},
        postcode                => $line_to_be_added->{'postcode'}->{'content'},
        net_deposits            => $line_to_be_added->{'netDeposits'}->{'content'},
        card_short_number       => $line_to_be_added->{'cardShortNumber'}->{'content'},
        total_deposits          => $line_to_be_added->{'totalDeposits'}->{'content'}            
    });
    return $payment_card;
}

=head2 _forceArray

Receives a reference variable and if the data is not an array, returns a single-element arrayref. Else returns the data as received.

=cut

sub _forceArray {
    my ($self, $data) = @_;
    return ref($data) eq 'ARRAY' ? $data : [$data];
}

=head2 _checkParams

Receives an hashref of parameter types and a hashref of arguments. Checks that all mandatory arguments are present using _checkParam and that no additional parameters exist in the hashref. 

=cut

sub _checkParams {
    my ($self, $paramChecks, $args) = @_;

    # check no rogue arguments have been included in parameters
    foreach my $paramName (keys %{$args}) {
        if (not exists $paramChecks->{$paramName}) {
            $self->{headerError} = "Error: unexpected parameter $paramName is not a correct argument for the method called.";
            return 0;
        }
        # if exists now check that the type is correct
        else {
            return 0 unless $self->_checkParam( $paramChecks->{$paramName}->[0],
                                                $args->{$paramName});
        }
    }
    # check all mandatory parameters are present 
    foreach my $paramName (keys %{$paramChecks}){
        if ($paramChecks->{$paramName}->[1]){
            unless (exists $args->{$paramName}) {
                $self->{headerError} = "Error: missing mandatory parameter $paramName.";
                return 0;
            }
        }
    }
    return 1;
}

=head2 _checkParam

Checks the parameter using the TypeCheck.pm object, returns 1 on success and 0 on failure.

=cut

sub _checkParam {
    my ($self, $type, $value) = @_;
    unless($self->{type}->checkParameter($type, $value)) {
        $self->{headerError} = "Error: message not sent as parameter $value failed the type requirements check for $type. Check the documentation at the command line: perldoc WWW::betfair::TypeCheck";
        return 0;
    }
    return 1;
}

=head2 _clearData

Sets all message related object attributes to null - this is so that the error message from the previous API call is not mis-read as relevant to the current call.

=cut

sub _clearData {
    my $self = shift;
    $self->{xmlsent}        = undef;
    $self->{xmlreceived}    = undef;
    $self->{headerError}    = undef;
    $self->{bodyError}      = undef;
    $self->{response}       = {};
    return 1;
}


1;

=head1 AUTHOR

David Farrell, C<< <davidnmfarrell at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-betfair at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-betfair>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::betfair


You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-betfair>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-betfair>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-betfair>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-betfair/>

=back

=head1 ACKNOWLEDGEMENTS

This project was inspired by the L<betfair free|http://code.google.com/p/betfairfree/> Perl project. Although L<WWW::betfair> uses a different approach, the betfair free project was a useful point of reference at inception. Thanks guys!

Thanks to L<betfair|http://www.betfair.com> for creating the exchange and API.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Farrell.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
