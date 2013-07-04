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

=head1 NAME

WWW::betfair - interact with the betfair API using OO Perl

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


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

=item *

Add encryption to object attributes.

=back

=head1 NON API METHODS

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

Example

    my $error = $betfair->getError;

=cut

sub getError {
    my $self = shift;
    return  $self->{headerError} eq 'OK' ? $self->{bodyError} : $self->{headerError};
}


=head2 getXMLSent

Returns a string of the XML message sent to betfair. This can be useful to inspect if de-bugging a failed API call.

Example

    my $xmlSent = $betfair->getXMLSent;

=cut

sub getXMLSent {
    my $self = shift;
    return $self->{xmlsent};
}

=head2 getXMLReceived

Returns a string of the XML message received from betfair. This can be useful to inspect if de-bugging a failed API call.

Example

    my $xmlReceived = $betfair->getXMLReceived;

=cut

sub getXMLReceived {
    my $self = shift;
    return $self->{xmlreceived};
}

=head2 getHashReceived

Returns a Perl data structure consisting of the entire de-serialized betfair XML response. This can be useful to inspect if de-bugging a failed API call and easier to read than the raw XML message, especially if used in conjunction with L<Data::Dumper>.

Example

    my $hashReceived = $betfair->getHashReceived;

=cut

sub getHashReceived {
    my $self = shift;
    return $self->{response};
}

=head1 GENERAL API METHODS

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

=head1 READ ONLY BETTING API METHODS

=head2 convertCurrency

Returns the betfair converted amount of currency see L<convertCurrency|http://bdp.betfair.com/docs/ConvertCurrency.html> for details. Requires a hashref with the following parameters:

=over

=item *

amount: this is the decimal amount of base currency to convert.

=item *

fromCurrency : this is the base currency to convert from.

=item *

toCurrency : this is the target currency to convert to.

=back

Example

    $betfair->convertCurrency({ amount          => 5,
                                fromCurrency    => 'GBP',
                                toCurrency      => 'USD',
                              });

=cut

sub convertCurrency {
    my ($self, $args) = @_;
    my $checkParams = {
        amount              => ['decimal', 1],
        fromCurrency        => ['string', 1],
        toCurrency          => ['string', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('convertCurrency', 3, $args) ) {
        return { convertedAmount =>
                $self->{response}->{'soap:Body'}->{'n:convertCurrencyResponse'}->{'n:Result'}->{'convertedAmount'}->{'content'}
        };
    }
    return 0;
}

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

=head2 getAllCurrencies

Returns an arrayref of currency codes and the betfair GBP exchange rate. See L<getAllCurrencies|http://bdp.betfair.com/docs/GetAllCurrencies.html>. Requires no parameters.

Example

    $betfair->getAllCurrencies;

=cut

sub getAllCurrencies {
    my $self = shift;
    my $currencies =[];
    if ($self->_doRequest('getAllCurrencies', 3, {}) ) {
        foreach (@{$self->{response}->{'soap:Body'}->{'n:getAllCurrenciesResponse'}->{'n:Result'}->{'currencyItems'}->{'n2:Currency'}}) {
            push(@{$currencies},{
                currencyCode    => $_->{'currencyCode'}->{'content'},
                rateGBP         => $_->{'rateGBP'}->{'content'},
            });
        }
        return $currencies;
    }
    return 0;
}

=head2 getAllCurrenciesV2

Returns an arrayref of currency codes, the betfair GBP exchange rate and staking sizes for the currency. See L<getAllCurrenciesV2|http://bdp.betfair.com/docs/GetAllCurrenciesV2.html>. Requires no parameters.

Example

    $betfair->getAllCurrenciesV2;

=cut

sub getAllCurrenciesV2 {
    my $self = shift;
    my $currenciesV2 =[];
    if ($self->_doRequest('getAllCurrenciesV2', 3, {}) ) {
        foreach (@{$self->{response}->{'soap:Body'}->{'n:getAllCurrenciesV2Response'}->{'n:Result'}->{'currencyItems'}->{'n2:CurrencyV2'}}) {
            push(@{$currenciesV2},{
                currencyCode            => $_->{'currencyCode'}->{'content'},
                rateGBP                 => $_->{'rateGBP'}->{'content'},
                minimumStake            => $_->{'minimumStake'}->{'content'},
                minimumRangeStake       => $_->{'minimumRangeStake'}->{'content'},
                minimumBSPLayLiability => $_->{'minimumBSPLayLiability'}->{'content'},
            });
        }
        return $currenciesV2;
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

=head2 getBet

Returns a hashref of betfair's bet response, including an array of all matches to a bet. See L<getBet|http://bdp.betfair.com/docs/GetBet.html> for details. Requires a hashref with the following argument:

=over

=item *

betId - the betId integer of the bet to retrieve data about.

=back

Example

    my $bet = $betfair->getBet({betId => 123456789});

=cut

sub getBet {
    my ($self, $args) = @_;
    my $checkParams = { betId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getBet', 1, $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getBetResponse'}->{'n:Result'}->{bet};
        my $bet = {
            asianLineId     => $response->{asianLineId}->{content},
            avgPrice        => $response->{avgPrice}->{content},
            betCategoryType => $response->{betCategoryType}->{content},
            betId           => $response->{betId}->{content},
            betPersistenceType  => $response->{betPersistenceType}->{content},
            betStatus           => $response->{betStatus}->{content},
            betType             => $response->{betType}->{content},
            bspLiability        => $response->{bspLiability}->{content},
            cancelledDate       => $response->{cancelledDate}->{content},
            executedBy          => $response->{executedBy}->{content},
            fullMarketName      => $response->{fullMarketName}->{content},
            handicap            => $response->{handicap}->{content},
            lapsedDate          => $response->{lapsedDate}->{content},
            marketId            => $response->{marketId}->{content},
            marketName          => $response->{marketName}->{content},
            marketType          => $response->{marketType}->{content},
            marketTypeVariant   => $response->{marketTypeVariant}->{content},
            matchedDate         => $response->{matchedDate}->{content},
            matchedSize         => $response->{matchedSize}->{content},
            matches             => [],
            placedDate          => $response->{placedDate}->{content},
            price               => $response->{price}->{content},
            profitAndLoss       => $response->{profitAndLoss}->{content},
            remainingSize       => $response->{remainingSize}->{content},
            requestedSize       => $response->{requestedSize}->{content},
            selectionId         => $response->{selectionId}->{content},
            selectionName       => $response->{selectionName}->{content},
            settledDate         => $response->{settledDate}->{content},
            voidedDate          => $response->{voidedDate}->{content},
        };
        my $matches = $self->_forceArray($response->{matches}->{'n2:Match'});
        foreach my $match (@{$matches}){
            push @{$bet->{matches}}, {
                betStatus       => $match->{betStatus}->{content},
                matchedDate     => $match->{matchedDate}->{content},
                priceMatched    => $match->{priceMatched}->{content},
                profitLoss      => $match->{profitLoss}->{content},
                settledDate     => $match->{settledDate}->{content},
                sizeMatched     => $match->{sizeMatched}->{content},
                transactionId   => $match->{transactionId}->{content},
                voidedDate      => $match->{voidedDate}->{content},
            };
        }
        return $bet;
    } 
    return 0;
}

=head2 getBetHistory

Returns an arrayref of hashrefs of bets. See L<getBetHistory|http://bdp.betfair.com/docs/GetBetHistory.html> for details. Requires a hashref with the following parameters:

=over

=item *

betTypesIncluded : string of a valid BetStatusEnum type as defined by betfair (see L<betStatusEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028849i1028849>)

=item *

detailed : boolean string e.g. ('true' or 'false') indicating whether or not to include the details of all matches per bet.

=item *

eventTypeIds : an arrayref of integers that represent the betfair eventTypeIds. (e.g. [1, 6] would be football and boxing). This is not mandatory if the betTypesIncluded parameter equals 'M' or 'U'.

=item *

marketId : an integer representing the betfair marketId (optional).

=item *

marketTypesIncluded : arrayref of strings of the betfair marketTypesIncluded enum. See L<marketTypesIncludedEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1020360i1020360> for details.

=item *

placedDateFrom : string date for which to return records on or after this date (a string in the XML datetime format see example).

=item *

placedDateTo : string date for which to return records on or before this date (a string in the XML datetime format see example).

=item *

recordCount : integer representing the maximum number of records to retrieve (must be between 1 and 100).

=item *

sortBetsBy : string of a valid BetsOrderByEnum types as defined by betfair. see L<BetsOrderByEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1033170i1033170>

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=back

Example

    my $betHistory = $betfair->getBetHistory({
                            betTypesIncluded    => 'M',
                            detailed            => 'false',
                            eventTypeIds        => [6],
                            marketTypesIncluded => ['O', 'L', 'R'],
                            placedDateFrom      => '2013-01-01T00:00:00.000Z',         
                            placedDateTo        => '2013-06-16T00:00:00.000Z',         
                            recordCount         => 100,
                            sortBetsBy          => 'PLACED_DATE',
                            startRecord         => 0,
                            });

=cut

sub getBetHistory {
    my ($self, $args) = @_;
    my $checkParams = {
        betTypesIncluded    => ['betStatusEnum', 1],
        detailed            => ['boolean', 1],
        eventTypeIds        => ['arrayInt', 1],
        sortBetsBy          => ['betsOrderByEnum', 1],
        recordCount         => ['int', 1,],
        startRecord         => ['int', 1],
        placedDateTo        => ['date', 1],
        placedDateFrom      => ['date', 1],
        marketTypesIncluded => ['arrayMarketTypeEnum', 1],
        marketId            => ['int',0],
    };
    # eventTypeIds is not mandatory if betTypesIncluded is 'M' or 'U'
    $checkParams->{eventTypeIds}->[1] = 0 if grep{/$args->{betTypesIncluded}/} qw/M U/;

    # marketId is mandatory if betTypesIncluded is 'S', 'C', or 'V'
    $checkParams->{marketId}->[1] = 1 if grep{/$args->betTypesIncluded/} qw/S C V/;
    
    return 0 unless $self->_checkParams($checkParams, $args);

    # make eventTypeIds an array of int
    my @eventTypeIds = $args->{eventTypeIds};
    delete $args->{eventTypeIds};
    $args->{eventTypeIds}->{'int'} = \@eventTypeIds;

    # make marketTypesIncluded an array of marketTypeEnum
    my @marketTypes = $args->{marketTypesIncluded};
    delete $args->{marketTypesIncluded};
    $args->{marketTypesIncluded}->{'MarketTypeEnum'} = \@marketTypes;

    if ($self->_doRequest('getBetHistory', 1, $args) ) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getBetHistoryResponse'}->{'n:Result'}->{'betHistoryItems'}->{'n2:Bet'});
        my $betHistory = [];
        foreach (@{$response}) {
            my $bet = {
                asianLineId         => $_->{asianLineId}->{content},
                avgPrice            => $_->{avgPrice}->{content},
                betCategoryType     => $_->{betCategoryType}->{content},
                betId               => $_->{betId}->{content},
                betPersistenceType  => $_->{betPersistenceType}->{content},
                betStatus           => $_->{betStatus}->{content},
                betType             => $_->{betType}->{content},
                bspLiability        => $_->{bspLiability}->{content},
                cancelledDate       => $_->{cancelledDate}->{content},
                fullMarketName      => $_->{fullMarketName}->{content},
                handicap            => $_->{handicap}->{content},
                lapsedDate          => $_->{lapsedDate}->{content},
                marketId            => $_->{marketId}->{content},
                marketName          => $_->{marketName}->{content},
                marketType          => $_->{marketType}->{content},
                marketTypeVariant   => $_->{marketTypeVariant}->{content},
                matchedDate         => $_->{matchedDate}->{content},
                matchedSize         => $_->{matchedSize}->{content},
                matches             => [],
                placedDate          => $_->{placedDate}->{content},
                price               => $_->{price}->{content},
                profitAndLoss       => $_->{profitAndLoss}->{content},
                remainingSize       => $_->{remainingSize}->{content},
                requestedSize       => $_->{requestedSize}->{content},
                selectionId         => $_->{selectionId}->{content},
                selectionName       => $_->{selectionName}->{content},
                settledDate         => $_->{settledDate}->{content},
                voidedDate          => $_->{voidedDate}->{content},
            };
            my $matches = $self->_forceArray($_->{matches}->{'n2:Match'});
            foreach my $match (@{$matches}){
                push @{$bet->{matches}}, {
                    betStatus       => $match->{betStatus}->{content},
                    matchedDate     => $match->{matchedDate}->{content},
                    priceMatched    => $match->{priceMatched}->{content},
                    profitLoss      => $match->{profitLoss}->{content},
                    settledDate     => $match->{settledDate}->{content},
                    sizeMatched     => $match->{sizeMatched}->{content},
                    transactionId   => $match->{transactionId}->{content},
                    voidedDate      => $match->{voidedDate}->{content},
                };
            }
            push @{$betHistory}, $bet;
        }
        return $betHistory;
    }
    return 0;
}

=head2 getBetLite

Returns a hashref of bet information. See L<getBetLite|http://bdp.betfair.com/docs/GetBetLite.html> for details. Requires a hashref with the following key pair/s:

=over

=item *

betId : integer representing the betfair id for the bet to retrieve data about.

=back

Example

    my $betData = $betfair->getBetLite({betId => 123456789});

=cut

sub getBetLite {
    my ($self, $args) = @_;
    my $checkParams = { betId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getBetLite', 1, $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getBetLiteResponse'}->{'n:Result'}->{'betLite'};
        return {
            betCategoryType     => $response->{betCategoryType}->{content},
            betId               => $response->{betId}->{content},
            betPersistenceType  => $response->{betPersistenceType}->{content},
            betStatus           => $response->{betStatus}->{content},
            bspLiability        => $response->{bspLiability}->{content},
            marketId            => $response->{marketId}->{content},
            matchedSize         => $response->{matchedSize}->{content},
            remainingSize       => $response->{remainingSize}->{content},
        };
    } 
    return 0; 
}


=head2 getBetMatchesLite

Returns an arrayref of hashrefs of matched bet information. See L<getBetMatchesLite|http://bdp.betfair.com/docs/GetBetMatchesLite.html> for details. Requires a hashref with the following key pair/s:

=over

=item *

betId : integer representing the betfair id for the bet to retrieve data about.

=back

Example

    my $betData = $betfair->getBetMatchesLite({betId => 123456789});

=cut

sub getBetMatchesLite {
    my ($self, $args) = @_;
    my $checkParams = { betId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getBetMatchesLite', 1, $args)) {
        my $response = $self->_forceArray($self->{response}->{'soap:Body'}->{'n:getBetMatchesLiteResponse'}->{'n:Result'}->{matchLites}->{'n2:MatchLite'});
        my $matchedBets = [];
        foreach (@{$response}) {
            push @{$matchedBets}, {
                betStatus       => $_->{betStatus}->{content},
                matchedDate     => $_->{matchedDate}->{content},
                priceMatched    => $_->{priceMatched}->{content},
                sizeMatched     => $_->{sizeMatched}->{content},
                transactionId   => $_->{transactionId}->{content},
            };
        }
        return $matchedBets;
    } 
    return 0; 
}

=head2 getCompleteMarketPricesCompressed

Returns a hashref of market data including an arrayhashref of individual selection prices data. See L<getCompleteMarketPricesCompressed|http://bdp.betfair.com/docs/GetCompleteMarketPricesCompressed.html> for details. Note that this method de-serializes the compressed string returned by the betfair method into a Perl data structure. Requires:

=over

=item *

marketId : integer representing the betfair market id.

=back

Example

    my $marketPriceData = $betfair->getCompleteMarketPricesCompressed({marketId => 123456789}); 

=cut

sub getCompleteMarketPricesCompressed {
    my ($self, $args) = @_;
    my $checkParams = { marketId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getCompleteMarketPricesCompressed', 1, $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getCompleteMarketPricesCompressedResponse'}->{'n:Result'}->{'completeMarketPrices'}->{'content'};
        my @fields = split /:/, $response;
        #109799180~0~;name,timeRemoved,reductionFactor;
        my $idAndRemovedRunners = shift @fields; # not used yet
        my $selections = [];
        foreach my $selection (@fields) {
            my @selectionFields = split /\|/, $selection;
            my @selectionData = split /~/, shift @selectionFields;
            my $prices = [];
            next unless $selectionFields[0];
            my @selectionPrices = split /~/, $selectionFields[0];
            while (@selectionPrices) {
                push @{$prices}, {
                    price           => shift @selectionPrices,
                    back_amount     => shift @selectionPrices,
                    lay_amount      => shift @selectionPrices,
                    bsp_back_amount => shift @selectionPrices,
                    bsp_lay_amount  => shift @selectionPrices,
                }; 
            }
            push @{$selections}, {
                prices              => $prices,
                selectionId         => $selectionData[0],
                orderIndex          => $selectionData[1],
                totalMatched        => $selectionData[2],
                lastPriceMatched    => $selectionData[3],
                asianHandicap       => $selectionData[4],
                reductionFactor     => $selectionData[5],
                vacant              => $selectionData[6],
                asianLineId         => $selectionData[7],
                farPriceSp          => $selectionData[8],
                nearPriceSp         => $selectionData[9],
                actualPriceSp       => $selectionData[10],
            };
        }
        return {    marketId    => $args->{marketId},
                    selections  => $selections,
        };
    }
    return 0;
}

=head2 getCurrentBets

Returns an arrayref of hashrefs of current bets or 0 on failure. See L<http://bdp.betfair.com/docs/GetCurrentBets.html> for details. Requires a hashref with the following parameters:

=over

=item *

betStatus : string of a valid BetStatus enum type as defined by betfair see L<betStatusEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028849i1028849> for details.

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
        foreach (@{$response}) {
            my $bet = {
                asianLineId         => $_->{asianLineId}->{content},
                avgPrice            => $_->{avgPrice}->{content},
                betCategoryType     => $_->{betCategoryType}->{content},
                betId               => $_->{betId}->{content},
                betPersistenceType  => $_->{betPersistenceType}->{content},
                betStatus           => $_->{betStatus}->{content},
                betType             => $_->{betType}->{content},
                bspLiability        => $_->{bspLiability}->{content},
                cancelledDate       => $_->{cancelledDate}->{content},
                fullMarketName      => $_->{fullMarketName}->{content},
                handicap            => $_->{handicap}->{content},
                lapsedDate          => $_->{lapsedDate}->{content},
                marketId            => $_->{marketId}->{content},
                marketName          => $_->{marketName}->{content},
                marketType          => $_->{marketType}->{content},
                marketTypeVariant   => $_->{marketTypeVariant}->{content},
                matchedDate         => $_->{matchedDate}->{content},
                matchedSize         => $_->{matchedSize}->{content},
                matches             => [],
                placedDate          => $_->{placedDate}->{content},
                price               => $_->{price}->{content},
                profitAndLoss       => $_->{profitAndLoss}->{content},
                remainingSize       => $_->{remainingSize}->{content},
                requestedSize       => $_->{requestedSize}->{content},
                selectionId         => $_->{selectionId}->{content},
                selectionName       => $_->{selectionName}->{content},
                settledDate         => $_->{settledDate}->{content},
                voidedDate          => $_->{voidedDate}->{content},
            };
            my $matches = $self->_forceArray($_->{matches}->{'n2:Match'});
            foreach my $match (@{$matches}){
                push @{$bet->{matches}}, {
                    betStatus       => $match->{betStatus}->{content},
                    matchedDate     => $match->{matchedDate}->{content},
                    priceMatched    => $match->{priceMatched}->{content},
                    profitLoss      => $match->{profitLoss}->{content},
                    settledDate     => $match->{settledDate}->{content},
                    sizeMatched     => $match->{sizeMatched}->{content},
                    transactionId   => $match->{transactionId}->{content},
                    voidedDate      => $match->{voidedDate}->{content},
                };
            }
            push @{$current_bets}, $bet;
        }
        return $current_bets;
    }
    return 0;
}

=head2 getCurrentBetsLite

Returns an arrayref of hashrefs of current bets for a single market or the entire exchange. See L<getCurrentBetsLite|http://bdp.betfair.com/docs/GetCurrentBetsLite.html> for details. Requires a hashref with the following parameters:

=over

=item *

betStatus : string of a valid BetStatus enum type as defined by betfair see L<betStatusEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028849i1028849> for details.

=item *

orderBy : string of a valid BetsOrderByEnum types as defined by betfair  (see L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>)

=item *

recordCount : integer of the maximum number of records to return

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=item *

noTotalRecordCount : string of either 'true' or 'false' to return a total record count

=item *

marketId : integer of the betfair market id for which current bets are required (optional)

=back

Example

    my $bets = $betfair->getCurrentBetsLite({
                            betStatus           => 'M',
                            orderBy             => 'PLACED_DATE',
                            recordCount         => 100,
                            startRecord         => 0,
                            noTotalRecordCount  => 'true',
                            });

=cut

sub getCurrentBetsLite {
    my ($self, $args) = @_;
    my $checkParams = {
        betStatus           => ['betStatusEnum', 1],
        orderBy             => ['betsOrderByEnum', 1],
        recordCount         => ['int', 1,],
        startRecord         => ['int', 1],
        noTotalRecordCount  => ['boolean', 1],
        marketId            => ['int',0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getCurrentBetsLite', 1, $args) ) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getCurrentBetsLiteResponse'}->{'n:Result'}->{'betLites'}->{'n2:BetLite'});
        my $current_bets = [];
        foreach (@{$response}) {
            push @{$current_bets}, {
                betCategoryType     => $_->{betCategoryType}->{content},
                betId               => $_->{betId}->{content},
                betPersistenceType  => $_->{betPersistenceType}->{content},
                betStatus           => $_->{betStatus}->{content},
                bspLiability        => $_->{bspLiability}->{content},
                marketId            => $_->{marketId}->{content},
                matchedSize         => $_->{matchedSize}->{content},
                remainingSize       => $_->{remainingSize}->{content},
            };
        }
        return $current_bets;
    }
    return 0;
}

=head2 getDetailAvailableMktDepth

Returns an arrayref of current back and lay offers in a market for a specific selection. See L<getAvailableMktDepth|http://bdp.betfair.com/docs/GetDetailAvailableMarketDepth.html> for details. Requires a hashref with the following arguments:

=over

=item *

marketId : integer representing the betfair market id to return the market prices for.

=item * 

selectionId : integer representing the betfair selection id to return market prices for.

=item *

asianLineId : integer representing the betfair asian line id of the market - only required if the market is an asian line market (optional).

=back

Example

    my $selectionPrices = $betfair->getDetailAvailableMktDepth({marketId    => 123456789,
                                                                selectionId => 987654321,
                                                               });

=cut

sub getDetailAvailableMktDepth {
    my ($self, $args) = @_;
    my $checkParams = { marketId    => ['int', 1], 
                        selectionId => ['int', 1],
                        asianLineId => ['int', 0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getDetailAvailableMktDepth', 1, $args)) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getDetailAvailableMktDepthResponse'}->{'n:Result'}->{'priceItems'}->{'n2:AvailabilityInfo'});
        my $marketPrices = [];
        foreach (@{$response}){
            push @{$marketPrices}, {
                odds                    => $_->{odds}->{content},
                totalAvailableBackAmount=> $_->{totalAvailableBackAmount}->{content},
                totalAvailableLayAmount => $_->{totalAvailableLayAmount}->{content},
                totalBspBackAmount      => $_->{totalBspBackAmount}->{content},
                totalBspLayAmount       => $_->{totalBspLayAmount}->{content},
            };
        }
        return $marketPrices;
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

=head2 getInPlayMarkets

Returns an arrayref of hashrefs of market data or 0 on failure. See L<getInPlayMarkets|http://bdp.betfair.com/docs/GetInPlayTodayMarkets.html> for details. Does not require any parameters.

Example

    my $inPlayMarkets = $betfair->getInPlayMarkets;

=cut

sub getInPlayMarkets {
    my $self = shift;
    if ($self->_doRequest('getInPlayMarkets', 1, {}) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getInPlayMarketsResponse'}->{'n:Result'}->{'marketData'}->{content};
        my $markets = [];
        foreach (split /:/, $response) {
            next unless $_;
            my @data = split /~/, $_;
            push @{$markets}, {
                marketId            => $data[0],
                marketName          => $data[1],
                marketType          => $data[2],
                marketStatus        => $data[3],
                eventDate           => $data[4],
                menuPath            => $data[5],
                eventHierarchy      => $data[6],
                betDelay            => $data[7],
                exchangeId          => $data[8],
                isoCountryCode      => $data[9],
                lastRefresh         => $data[10],
                numberOfRunner      => $data[11],
                numberOfWinners     => $data[12],
                totalAmountMatched  => $data[13],
                bspMarket           => $data[14],
                turningInPlay       => $data[15],
            };

        }
        return 1;
    } 
    return 0;
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

=head2 getMarketInfo

Returns a hash of market data or 0 on failure. See L<getMarketInfo|http://bdp.betfair.com/docs/GetMarketInfo.html> for details. Requires:

=over

=item *

marketId : integer which is the betfair id of the market

=back

Example

    my $marketData = $betfair->getMarketInfo({marketId => 108690258});

=cut

sub getMarketInfo {
    my ($self, $args) = @_;
    my $checkParams = { marketId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarketInfo', 1, $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketInfoResponse'}->{'n:Result'}->{'marketLite'};
        return {
            delay               => $response->{'delay'}->{'content'},
            numberOfRunners     => $response->{'numberOfRunners'}->{'content'},
            marketSuspendTime   => $response->{'marketSuspendTime'}->{'content'}, 
            marketTime          => $response->{'marketTime'}->{'content'},
            marketStatus        => $response->{'marketStatus'}->{'content'},
            openForBspBetting   => $response->{'openForBspBetting'}->{'content'},
        };
    } 
    return 0;
}

=head2 getMarketPrices

Returns a hashref of market data or 0 on failure. See L<getMarketPrices|http://bdp.betfair.com/docs/GetMarketPrices.html> for details. Requires:

=over

=item *

marketId : integer which is the betfair id of the market

=back

Example

    my $marketPrices = $betfair->getMarketPrices({marketId => 108690258});

=cut

sub getMarketPrices {
    my ($self, $args) = @_;
    my $checkParams = { marketId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarketPrices', 1, $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketPricesResponse'}->{'n:Result'}->{'marketPrices'};
        my $runners_list = $self->_forceArray($response->{'runnerPrices'}->{'n2:RunnerPrices'});
        my @parsed_runners = ();
        foreach my $runner (@{$runners_list}) {
            my $bestPricesToBack = $self->_forceArray($runner->{bestPricesToBack}->{'n2:Price'});
            my @backPrices = ();
            foreach my $backPrice (@{$bestPricesToBack}){
                push(@backPrices, {
                    amountAvailable => $backPrice->{amountAvailable}->{content},
                    betType         => $backPrice->{betType}->{content},
                    depth           => $backPrice->{depth}->{content},
                    price           => $backPrice->{price}->{content},
                });
            }
            my $bestPricesToLay = $self->_forceArray($runner->{bestPricesToLay}->{'n2:Price'});
            my @layPrices = ();
            foreach my $layPrice (@{$bestPricesToLay}){
                push(@layPrices, {
                    amountAvailable => $layPrice->{amountAvailable}->{content},
                    betType         => $layPrice->{betType}->{content},
                    depth           => $layPrice->{depth}->{content},
                    price           => $layPrice->{price}->{content},
                });
            }
            push(@parsed_runners, {
                actualBSP           => $runner->{'actualBSP'}->{content},
                asianLineId         => $runner->{asianLineId}->{content},
                bestPricesToBack    => \@backPrices,
                bestPricesToLay     => \@layPrices,
                farBSP              => $runner->{farBSP}->{content},
                handicap            => $runner->{handicap}->{content},
                lastPriceMatched    => $runner->{lastPriceMatched}->{content},
                nearBSP             => $runner->{nearBSP}->{content},
                reductionFactor     => $runner->{reductionFactor}->{content},
                selectionId         => $runner->{selectionId}->{content},
                sortOrder           => $runner->{sortOrder}->{content},
                totalAmountMatched  => $runner->{totalAmountMatched}->{content},
                vacant              => $runner->{vacant}->{content},
            });
        }
        return {
            bspMarket       => $response->{bspMarket}->{content},
            currencyCode    => $response->{currencyCode}->{content},
            delay           => $response->{delay}->{content}, 
            discountAllowed => $response->{discountAllowed}->{content},
            lastRefresh     => $response->{lastRefresh}->{content},
            marketBaseRate  => $response->{marketBaseRate}->{content},
            marketId        => $response->{marketId}->{content},
            marketInfo      => $response->{marketInfo}->{content},
            marketStatus    => $response->{marketStatus}->{content},
            numberOfWinners => $response->{numberOfWinners}->{content},
            removedRunners  => $response->{removedRunners}->{content},
            runners         => \@parsed_runners,
        };
    } 
    return 0;
}

=head2 getMarketPricesCompressed

Returns a hashref of market data including an arrayhashref of individual selection prices data. See L<getMarketPricesCompressed|http://bdp.betfair.com/docs/GetMarketPricesCompressed.html> for details. Note that this method de-serializes the compressed string returned by the betfair method into a Perl data structure. Requires:

=over

=item *

marketId : integer representing the betfair market id.

=back

Example

    my $marketPriceData = $betfair->getMarketPricesCompressed({marketId => 123456789}); 

=cut

sub getMarketPricesCompressed {
    my ($self, $args) = @_;
    my $checkParams = { marketId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarketPricesCompressed', 1, $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketPricesCompressedResponse'}->{'n:Result'}->{'marketPrices'}->{'content'};
        my @fields = split /:/, $response;
        my @marketData = split /~/, shift @fields;
        my @removedRunners;
        if ($marketData[9]){
            foreach (split /;/, $marketData[9]){
                next unless $_;
                my @removedRunnerData = split /,/;
                push (@removedRunners, {
                    selectionId     => $removedRunnerData[0],
                    timeRemoved     => $removedRunnerData[1],
                    reductionFactor => $removedRunnerData[2],
                });
            }
        }
        my @selections;
        foreach my $selection (@fields) {
            my @selectionFields = split /\|/, $selection;
            next unless $selectionFields[0];
            my @selectionData = split /~/, $selectionFields[0];
            my (@backPrices, @layPrices);
            my @backPriceData = split /~/, $selectionFields[1];
            while (@backPriceData) {
                push (@backPrices, {
                    price           => shift @backPriceData,
                    amount          => shift @backPriceData,
                    offerType       => shift @backPriceData,
                    depth           => shift @backPriceData,
                }); 
            }
            my @layPriceData = split /~/, $selectionFields[2];
            while (@layPriceData) {
                push (@layPrices, {
                    price           => shift @layPriceData,
                    amount          => shift @layPriceData,
                    offerType       => shift @layPriceData,
                    depth           => shift @layPriceData,
                }); 
            }
            push (@selections, {
                backPrices          => \@backPrices,
                layPrices           => \@layPrices,
                selectionId         => $selectionData[0],
                orderIndex          => $selectionData[1],
                totalMatched        => $selectionData[2],
                lastPriceMatched    => $selectionData[3],
                asianHandicap       => $selectionData[4],
                reductionFactor     => $selectionData[5],
                vacant              => $selectionData[6],
                farPriceSp          => $selectionData[7],
                nearPriceSp         => $selectionData[8],
                actualPriceSp       => $selectionData[9],
            });
        }
        return {    marketId                => $args->{marketId},
                    currency                => $marketData[1],
                    marketStatus            => $marketData[2],
                    InPlayDelay             => $marketData[3],
                    numberOfWinners         => $marketData[4],
                    marketInformation       => $marketData[5],
                    discountAllowed         => $marketData[6],
                    marketBaseRate          => $marketData[7],
                    refreshTimeMilliseconds => $marketData[8],
                    BSPmarket               => $marketData[10],
                    removedRunnerInformation=> \@removedRunners,
                    selections              => \@selections,
        };
    }
    return 0;
}

=head2 getMUBets

Returns an arrayref of hashes of bets or 0 on failure. See L<http://bdp.betfair.com/docs/GetMUBets.html> for details. Requires:

=over

=item *

betStatus : string of betfair betStatusEnum type, must be either matched, unmatched or both (M, U, MU). See L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>

=item *

orderBy : string of a valid BetsOrderByEnum types as defined by betfair. see L<BetsOrderByEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1033170i1033170>

=item *

recordCount : integer of the maximum number of records to return

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=item *

noTotalRecordCount : string of either true or false

=item *

marketId : integer of the betfair market id for which current bets are required (optional)

=item *

betIds : an array of betIds (optional). If included, betStatus must be 'MU'.

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
        betIds              => ['arrayInt', 0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if (exists $args->{betIds}) {
        my @betIds = $args->{betIds};
        $args->{betIds} = {betId => \@betIds};
    }
    my $mu_bets = [];
    if ($self->_doRequest('getMUBets', 1, $args)) {
        my $response = $self->_forceArray(
            $self->{response}->{'soap:Body'}->{'n:getMUBetsResponse'}->{'n:Result'}->{'bets'}->{'n2:MUBet'});
        foreach (@{$response} ) {
            push @{$mu_bets}, {
                marketId            => $_->{'marketId'}->{'content'},
                betType             => $_->{'betType'}->{'content'},
                transactionId       => $_->{'transactionId'}->{'content'},
                size                => $_->{'size'}->{'content'},
                placedDate          => $_->{'placedDate'}->{'content'},
                betId               => $_->{'betId'}->{'content'},
                betStatus           => $_->{'betStatus'}->{'content'},
                betCategory_type    => $_->{'betCategoryType'}->{'content'},
                betPersistence      => $_->{'betPersistenceType'}->{'content'},
                matchedDate         => $_->{'matchedDate'}->{'content'},
                selectionId         => $_->{'selectionId'}->{'content'},
                price               => $_->{'price'}->{'content'},
                bspLiability        => $_->{'bspLiability'}->{'content'},
                handicap            => $_->{'handicap'}->{'content'},
                asianLineId         => $_->{'asianLineId'}->{'content'}
            };
        }
        return $mu_bets;
    } 
    return 0;
}


=head2 getMUBetsLite

Returns an arrayref of hashes of bets or 0 on failure. See L<http://bdp.betfair.com/docs/GetMUBetsLite.html> for details. Requires:

=over

=item *

betStatus : string of betfair betStatusEnum type, must be either matched, unmatched or both (M, U, MU). See L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>

=item *

marketId : integer of the betfair market id for which current bets are required (optional)

=item *

excludeLastSecond : boolean string value ('true' or 'false'). If true then excludes bets matched in the past second (optional)

=item *

matchedSince : a string datetime for which to only return bets matched since this datetime. Must be a valid XML datetime format, see example below (optional)

=item *

orderBy : string of a valid BetsOrderByEnum types as defined by betfair. see L<BetsOrderByEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1033170i1033170>

=item *

recordCount : integer of the maximum number of records to return

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=item *

sortOrder : string of the betfair sortOrder enumerated type (either 'ASC' or 'DESC'). See L<sortOrderEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028852i1028852> for details. 

=item *

betIds : an array of betIds (optional). If included, betStatus must be 'MU'.

=back

Example

    my $muBets = $betfair->getMUBetsLite({
                            betStatus           => 'MU',
                            orderBy             => 'PLACED_DATE',
                            excludeLastSecond   => 'false',
                            recordCount         => 100,
                            startRecord         => 0,
                            matchedSince        => '2013-06-01T00:00:00.000Z',
                            sortOrder           => 'ASC',
                            marketId            => 123456789,
                 });

=cut

sub getMUBetsLite {
    my ($self, $args ) = @_;
    my $checkParams = {
        betStatus           => ['betStatusEnum', 1],
        orderBy             => ['betsOrderByEnum', 1],
        matchedSince        => ['date', 0],
        excludeLastSecond   => ['boolean', 0],
        recordCount         => ['int', 1,],
        startRecord         => ['int', 1],
        marketId            => ['int', 0],
        sortOrder           => ['sortOrderEnum', 1],
        betIds              => ['arrayInt', 0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if (exists $args->{betIds}) {
        my @betIds = $args->{betIds};
        $args->{betIds} = {betId => \@betIds};
    }
    my @muBetsLite;
    if ($self->_doRequest('getMUBetsLite', 1, $args)) {
        my $response = $self->_forceArray(
            $self->{response}->{'soap:Body'}->{'n:getMUBetsLiteResponse'}->{'n:Result'}->{'betLites'}->{'n2:MUBetLite'});
        foreach (@{$response} ) {
            push (@muBetsLite, {
                betCategoryType     => $_->{'betCategoryType'}->{'content'},
                betId               => $_->{'betId'}->{'content'},
                betPersistenceType  => $_->{'betPersistenceType'}->{'content'},
                betStatus           => $_->{'betStatus'}->{'content'},
                bspLiability        => $_->{'bspLiability'}->{'content'},
                marketId            => $_->{'marketId'}->{'content'},
                betType             => $_->{'betType'}->{'content'},
                size                => $_->{'size'}->{'content'},
                transactionId       => $_->{'transactionId'}->{'content'},
            });
        }
        return \@muBetsLite;
    } 
    return 0;
}

=head2 getMarketTradedVolume

Returns an arrayref of hashrefs containing the traded volume for a particular market and selection. See L<getMarketTradedVolume|http://bdp.betfair.com/docs/GetMarketTradedVolume.html> for details. Requires:

=over

=item *

marketId : integer representing the betfair market id to return the market traded volume for.

=item *

selectionId : integer representing the betfair selection id of the selection to return matched volume for.

=item *

asianLineId : integer representing the betfair asian line id - this is optional unless the request is for an asian line market.

=back

Example

    my $marketVolume = $betfair->getMarketTradedVolume({marketId    => 923456791,
                                                        selectionId => 30571,
                                                       });

=cut

sub getMarketTradedVolume {
    my ($self, $args) = @_;
    my $checkParams = { marketId    => ['int', 1], 
                        asianLineId => ['int', 0],
                        selectionId => ['int', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarketTradedVolume', 1, $args)) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getMarketTradedVolumeResponse'}->{'n:Result'}->{'priceItems'}->{'n2:VolumeInfo'});
        my $tradedVolume = [];
        foreach (@{$response}) {
            push @{$tradedVolume}, {
                odds                            => $_->{odds}->{content},
                totalMatchedAmount              => $_->{totalMatchedAmount}->{content},
                totalBspBackMatchedAmount       => $_->{totalBspBackMatchedAmount}->{content},
                totalBspLiabilityMatchedAmount  => $_->{totalBspLiabilityMatchedAmount}->{content},
            };
        }
        return $tradedVolume; 
    }
    return 0;
}


=head2 getMarketTradedVolumeCompressed

Returns an arrayref of selections with their total matched amounts plus an array of all traded volume with the trade size and amount. See L<getMarketTradedVolumeCompressed|http://bdp.betfair.com/docs/GetMarketTradedVolumeCompressed.html> for details. Note that this service de-serializes the compressed string return by betfair into a Perl data structure. Requires:

=over

=item *

marketId : integer representing the betfair market id to return the market traded volume for.

=back

Example

    my $marketVolume = $betfair->getMarketTradedVolumeCompressed({marketId => 923456791});

=cut

sub getMarketTradedVolumeCompressed {
    my ($self, $args) = @_;
    my $checkParams = { marketId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarketTradedVolumeCompressed', 1, $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketTradedVolumeCompressedResponse'}->{'n:Result'}->{'tradedVolume'}->{'content'};
        my $marketTradedVolume = { marketId => $args->{marketId} }; 
        foreach my $selection (split /:/, $response) {
            my @selectionFields = split /\|/, $selection;
            next unless defined $selectionFields[0];
            my @selectionData = split /~/, shift @selectionFields;
            my $tradedAmounts = [];
            foreach (@selectionFields) {
                my ($odds, $size) = split /~/, $_;
                push @{$tradedAmounts}, {
                    odds => $odds,
                    size => $size,
                };
            }

            push @{$marketTradedVolume->{selections}}, {
                selectionId                 => $selectionData[0],
                asianLineId                 => $selectionData[1],
                actualBSP                   => $selectionData[2],
                totalBSPBackMatched         => $selectionData[3],
                totalBSPLiabilityMatched    => $selectionData[4],
                tradedAmounts               => $tradedAmounts,
            } if (defined $selectionData[0]);
        }
        return $marketTradedVolume; 
    }
    return 0;
}

=head2 getPrivateMarkets

Note - this API method has not been fully tested as it requires a paid betfair subscription.

Returns an arrayref of private markets - see L<getPrivateMarkets|http://bdp.betfair.com/docs/GetPrivateMarket.html> for details. Requires a hashref with the following arguments:

=over

=item *

eventTypeId : integer representing the betfair id of the event type to return private markets for.

=item *

marketType : string of the betfair marketType enum see L<marketTypeEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1020360i1020360>.

=back

Example

    my $privateMarkets = $betfair->getPrivateMarkets({  eventTypeId => 1,
                                                        marketType  => 'O',
                                                    });

=cut

sub getPrivateMarkets {
    my ($self, $args) = @_;
    my $checkParams = { eventTypeId => ['int', 1],
                        marketType  => ['marketTypeEnum', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getPrivateMarkets', 1, $args)) {
        my $response = $self->_forceArray(
            $self->{response}->{'soap:Body'}->{'n:getPrivateMarketsResponse'}->{'n:Result'}->{'privateMarkets'}->{'privateMarket'});
        my @privateMarkets;
        foreach (@{$response}) {
            push(@privateMarkets, {
                        name            => $_->{name}->{content},
                        marketId        => $_->{marketId}->{content},
                        menuPath        => $_->{menuPath}->{content},
                        eventHierarchy  => $_->{eventHierarchy}->{content},
                    });
        }
        return 1;
    }
    return 0;
}

=head1 BET PLACEMENT API METHODS

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
        betIds => ['arrayInt', 1],
    };
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

=head2 cancelBetsByMarket

Receives an arrayref of marketIds and cancels all unmatched bets on those markets. Returns an arrayref of hashrefs of market ids and results. See L<cancelBetsByMarket|http://bdp.betfair.com/docs/CancelBetsByMarket.html> for details. Requires:

=over

=item *

markets : arrayref of integers representing market ids.

=back

=cut

sub cancelBetsByMarket {
    my ($self, $args) = @_;
    my $checkParams = {
        markets => ['arrayInt', 1],
    };
    # adjust args into betfair api required structure
    my $params = { markets  => {
                            int => $args->{markets},
                   },
    };
    my $cancelled_bets = [];
    if ($self->_doRequest('cancelBetsByMarket', 1, $params)) {
        my $response = $self->_forceArray( 
            $self->{response}->{'soap:Body'}->{'n:cancelBetsByMarketResponse'}->{'n:Result'}->{'n2:CancelBetsByMarketResult'});
        foreach (@{$response} ) {
            push(@$cancelled_bets, {
                success     => $_->{'marketId'}->{'content'},
                resultCode  => $_->{'resultCode'}->{'content'},
            });
        }
        return $cancelled_bets;
    } 
    return 0;
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


=head1 ACCOUNT MANAGEMENT API METHODS

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
