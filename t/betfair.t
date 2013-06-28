use strict;
use warnings;
use Test::More; 
use Data::Dumper;
use Crypt::CBC;


# Skip all tests as authentication is required to test

BEGIN{do {plan skip_all => 'tests not run on install as user credentials are required to test betfair API.'}};

# Prepare cipher
my $key = Crypt::CBC->random_bytes(56);
my $cipher = Crypt::CBC->new(-key    => $key,
                             -cipher => 'Blowfish',
                             -salt   => 1,
                            );

BEGIN{ use_ok('WWW::betfair'); }
ok(my $b = WWW::betfair->new, 'create new betfair object');

SKIP: {
    print 'WWW::betfair needs to connect to the betfair API to fully test the library is working. The tests are all read-only betfair services and will not affect your betfair account. This will require your betfair username and password to start a session with betfair and an active internet connection. Would you like to run these tests? [y/n] ';

    chomp (my $response = <STDIN>);
    skip '- user decided not to run', 16 unless lc $response eq 'y';
    print 'Please enter your betfair username: ';
    chomp( my $username = <STDIN>);
    print 'Please enter your betfair password: ';
    system("stty -echo");
    my $ciphertext = $cipher->encrypt(<STDIN> =~ s/\n$//r);
    system("stty echo");

    # attempt to login
    my $loginResult = $b->login({  username => $username, 
                                   password => $cipher->decrypt($ciphertext),
                            });
    ok($loginResult, 'login');
    skip 'as login failed -' . $b->getError, 15 unless $loginResult;
    ok($b->getError, 'getError');
    ok($b->getHashReceived, 'getHashReceived');
    ok($b->getXMLReceived, 'getXMLReceived');
    ok($b->getXMLSent, 'getXMLSent');
    ok($b->keepAlive, 'keepAlive');
    ok($b->getActiveEventTypes, 'getActiveEventTypes');
    ok($b->getEvents({eventParentId => 1}), 'getEvents - 1');
    ok($b->getActiveEventTypes, 'getActiveEventTypes');
    ok($b->getAllEventTypes, 'getAllEventTypes');
    ok($b->getAllMarkets, 'getAllMarkets');
    ok($b->getPaymentCard, 'getPaymentCard');
    ok($b->getSubscriptionInfo, 'getSubscriptionInfo');
    ok($b->getAccountFunds, 'getAccountFunds');
    ok($b->getCurrentBets({
                            betStatus           => "C",
                            detailed            => "false",
                            orderBy             => "NONE",
                            recordCount         => "100",
                            startRecord         => "0",
                            noTotalRecordCount  => "true",
                            }), 'getCurrentBets');

    ok($b->logout, 'logout');
}


=head2 Other example tests not included due to their time / event dependence

    ok($b->getMarket({marketId => 109694512}), 'getMarket'); 
    ok($b->cancelBets({betIds => [27886464953, 27886464952]}), 'cancelBets');
    ok($b->getAccountStatement({
                            startRecord     => 0,                                
                            recordCount     => 1000,     
                            startDate       => '2013-01-01T00:00:00-06:00',         
                            endDate         => '2013-06-24T00:00:00-06:00',         
                            itemsIncluded   => 'ALL', 
                           }), 'getAccountStatement');
    ok($b->getMarket({marketId => 109694512}), 'getMarket'); 
    ok($b->getCompleteMarketPrices({marketId => 108690258}), 'getCompleteMarketPrices - 108690258');
    ok($b->getMarketPricesCombined({marketId => 108690258}), 'getMarketPricesCombined - 108690258'); 
    ok($b->placeBets({bets => [{ 
                            asianLineId         => 0,
                            betCategoryType     => 'E',
                            betPersistenceType  => 'NONE',
                            betType             => 'B',
                            bspLiability        => 2,
                            marketId            => 109694512,
                            price               => 10,
                            selectionId         => 162084,
                            size                => 2,
                            },
                            {asianLineId         => 0,
                            betCategoryType     => 'E',
                            betPersistenceType  => 'NONE',
                            betType             => 'B',
                            bspLiability        => 2,
                            marketId            => 109694512,
                            price               => 20,
                            selectionId         => 162083,
                            size                => 2,
                            }],
                            }), 'placeBets');
    ok($b->updateBets({bets => [{
                                 betId                   => 27886464952,
                                 newBetPersistenceType   => 'NONE',
                                 newPrice                => 9,
                                 newSize                 => 2,
                                 oldBetPersistenceType   => 'NONE',
                                 oldPrice                => 10,
                                 oldSize                 => 2,
                                },{
                                 betId                   => 27886464953,
                                 newBetPersistenceType   => 'NONE',
                                 newPrice                => 18,
                                 newSize                 => 2,
                                 oldBetPersistenceType   => 'NONE',
                                 oldPrice                => 20,
                                 oldSize                 => 2,
                                }]    
                      }), 'updateBets');
    ok($b->getMUBets({
                    betStatus           => "MU",
                    orderBy             => "PLACED_DATE",
                    recordCount         => "100",
                    startRecord         => "0",
                    sortOrder           => 'ASC',
                    }), 'getMUBets');
    ok($b->cancelBets({betIds => [27886464953,27886464952]}), 'cancelBets');
    ok($b->getCurrentBets({
                            betStatus           => "C",
                            detailed            => "false",
                            orderBy             => "NONE",
                            recordCount         => "100",
                            startRecord         => "0",
                            noTotalRecordCount  => "true",
                            }), 'getCurrentBets');
    ok($b->addPaymentCard({}), 'addPaymentCard');
    ok($b->placeBets({bets => [{ 
                            asianLineId         => 0,
                            betCategoryType     => 'E',
                            betPersistenceType  => 'NONE',
                            betType             => 'B',
                            bspliability        => 2,
                            marketId            => 109694512,
                            price               => 10,
                            selectionId         => 162084,
                            size                => 2,
                            },
                            {asianLineId         => 0,
                            betCategoryType     => 'E',
                            betPersistenceType  => 'NONE',
                            betType             => 'B',
                            bspliability        => 2,
                            marketId            => 109694512,
                            price               => 20,
                            selectionId         => 162083,
                            size                => 2,
                            }],
                            }), 'placeBets');

=cut

done_testing;
