package WWW::betfair::TypeCheck;
use strict;
use warnings;
use Regexp::Common;

=head1 DESCRIPTION

Provides type checking for parameters passed to the betfair API. Includes betfair's enumerated types.

=head2 new

Returns a new L<WWW::betfair::Type> object. Requires no parameters.

=cut

sub new {
    my $class = shift;
    my $self = {
        typeChecks => { int                         => \&checkInt,
                        decimal                     => \&checkDecimal,
                        date                        => \&checkDate,
                        string                      => \&checkString,
                        string9                     => \&checkString9,
                        cardDate                    => \&checkCardDate,
                        cv2                         => \&checkCv2,
                        username                    => \&checkUsername,
                        password                    => \&checkPassword,
                        boolean                     => \&checkBoolean,
                        accountStatementEnum        => \&checkAccountStatementEnum,
                        accountStatementIncludeEnum => \&checkAccountStatementIncludeEnum,
                        accountStatusEnum           => \&checkAccountStatusEnum,
                        accountTypeEnum             => \&checkAccountTypeEnum,
                        betCategoryTypeEnum         => \&checkBetCategoryTypeEnum,
                        betPersistenceTypeEnum      => \&checkBetPersistenceTypeEnum,
                        betsOrderByEnum             => \&checkBetsOrderByEnum,
                        betStatusEnum               => \&checkBetStatusEnum,
                        betTypeEnum                 => \&checkBetTypeEnum,
                        billingPeriodEnum           => \&checkBillingPeriodEnum,
                        cardTypeEnum                => \&checkCardTypeEnum,
                        gamcareLimitFreqEnum        => \&checkGamcareLimitFreqEnum,
                        genderEnum                  => \&checkGenderEnum,
                        marketStatusEnum            => \&checkMarketStatusEnum,
                        marketTypeEnum              => \&checkMarketTypeEnum,
                        marketTypeVariantEnum       => \&checkMarketTypeVariantEnum,
                        paymentCardStatusEnum       => \&checkPaymentCardStatusEnum,
                        regionEnum                  => \&checkRegionEnum,
                        securityQuestion1Enum       => \&checkSecurityQuestion1Enum,
                        securityQuestion2Enum       => \&checkSecurityQuestion2Enum,
                        serviceEnum                 => \&checkServiceEnum,
                        sortOrderEnum               => \&checkSortOrderEnum,
                        subscriptionStatusEnum      => \&checkSubscriptionStatusEnum,
                        titleEnum                   => \&checkTitleEnum,
                        validationErrorsEnum        => \&checkValidationErrorsEnum,
                    },
    };
    return bless $self, $class;
}


=head2 checkParameter

Receives a parameter and parameter type and executes the appropriate check method for that type.

=cut

sub checkParameter {
    my ($self, $type, $parameter) = @_;
    return 0 unless (defined $type and defined $parameter);
    return 0 unless exists $self->{typeChecks}->{$type};
    my $check = $self->{typeChecks}->{$type};
    return $self->$check($parameter);
}

=head2 checkAccountStatementEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkAccountStatementEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/OK RESULT_ERR RESULT_FIX RESULT_LOST RESULT_NOT_APPLICABLE RESULT_WON COMMISSION_REVERSAL/;
    return 0; 
}

=head2 checkAccountStatementIncludeEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkAccountStatementIncludeEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/ALL DEPOSITS_WITHDRAWALS EXCHANGE POKER_ROOM/;
    return 0; 
}

=head2 checkAccountStatusEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkAccountStatusEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/A C D L P S T X Z/;
    return 0; 
}

=head2 checkAccountTypeEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkAccountTypeEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/STANDARD MARGIN TRADING AGENT_CLIENT/;
    return 0; 
}

=head2 checkBetCategoryTypeEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkBetCategoryTypeEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/NONE E M L/;
    return 0; 
}

=head2 checkBetPersistenceTypeEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkBetPersistenceTypeEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/NONE IP SP/;
    return 0; 
}

=head2 checkBetsOrderByEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkBetsOrderByEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/BET_ID CANCELLED_DATE MARKET_NAME MATCHED_DATE NONE PLACED_DATE/;
    return 0; 
}

=head2 checkBetStatusEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkBetStatusEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/C L M MU S U V/;
    return 0; 
}

=head2 checkBetTypeEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkBetTypeEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/B L/;
    return 0; 
}

=head2 checkBillingPeriodEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkBillingPeriodEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/WEEKLY MONTHLY QUARTERLY ANNUALLY/;
    return 0; 
}

=head2 checkCardTypeEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkCardTypeEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/VISA MASTERCARD VISADELTA SWITCH SOLO ELECTRON LASER MAESTRO INVALID_CARD_TYPE/;
    return 0; 
}

=head2 checkGamcareLimitFreqEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkGamcareLimitFreqEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/DAILY WEEKLY MONTHLY YEARLY/;
    return 0; 
}

=head2 checkGenderEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkGenderEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/M F/;
    return 0; 
}

=head2 checkMarketStatusEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkMarketStatusEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/ACTIVE CLOSED INACTIVE SUSPENDED/;
    return 0; 
}


=head2 checkMarketTypeEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkMarketTypeEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/A L O R NOT_APPLICABLE/;
    return 0; 
}

=head2 checkMarketTypeVariantEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkMarketTypeVariantEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/D ASL ADL/;
    return 0; 
}

=head2 checkPaymentCardStatusEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkPaymentCardStatusEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/LOCKED UNLOCKED/;
    return 0; 
}

=head2 checkRegionEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkRegionEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/AUZ_NZL GBR IRL NA NORD ZAF/;
    return 0; 
}

=head2 checkSecurityQuestion1Enum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkSecurityQuestion1Enum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/SQ1A SQ1B SQ1C SQ1D/;
    return 0; 
}

=head2 checkSecurityQuestion2Enum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkSecurityQuestion2Enum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/SQ2A SQ2B SQ2C SQ2S/;
    return 0; 
}

=head2 checkServiceEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkServiceEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/ADD_PAYMENT_CARD CANCEL_BETS CREATE_ACCOUNT CONVERT_CURRENCY DELETE_PAYMENT_CARD DEPOSIT_FROM_PAYMENT_CARD
                                 DO_KEEP_ALIVE EDIT_BETS FORGOT_PASSWORD GET_ACCOUNT_STATEMENT GET_BET GET_CURRENT_BETS GET_CURRENCIES
                                 GET_MARKET_TRADED_VOLUME GET_PAYMENT_CARD LOAD_BET_HISTORY LOAD_DETAILED_AVAIL_MKT_DEPTH LOAD_EVENT_TYPES
                                 LOAD_EVENTS LOAD_MARKET LOAD_MARKET_PRICES LOAD_MARKET_PRICES_COMPRESSED LOAD_MARKET_PROFIT_LOSS
                                 LOAD_SERVICE_ANNOUNCEMENTS LOAD_SUBSCRIPTION_INFO LOGIN LOGOUT MODIFY_PASSWORD MODIFY_PROFILE PLACE_BETS
                                 RETRIEVE_LIMB_MESSAGE SUBMIT_LIMB_MESSAGE UPDATE_PAYMENT_CARD VIEW_PROFILE WITHDRAW_TO_PAYMENT_CARD/;
    return 0; 
}

=head2 checkSortOrderEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkSortOrderEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/ASC DESC/;
    return 0; 
}

=head2 checkSubscriptionStatusEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkSubscriptionStatusEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/ACTIVE INACTIVE SUSPENDED/;
    return 0; 
}

=head2 checkTitleEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkTitleEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/Dr Miss Mr Mrs Ms/;
    return 0; 
}

=head2 checkValidationErrorsEnum

Checks submitted value is a valid betfair enumerated type, see the L<betfair documentation|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html>.

=cut

sub checkValidationErrorsEnum {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/DUPLICATE_USERNAME FUND_TRANSFER_CANCEL FUND_TRANSFER_CURRENCY_MISMATCH INCOMPLETE_DETAILS 
                                 INSUFFICIENT_FUNDS INVALID_ACCOUNT_TYPE INVALID_ADDRESS_LINE1 INVALID_ADDRESS_LINE2 INVALID_ADDRESS_LINE3
                                 INVALID_ANSWER1 INVALID_ANSWER2 INVALID_BROWSER INVALID_CITY INVALID_COUNTRY_OF_RESIDENCE INVALID_COUNTY_STATE
                                 INVALID_CURRENCY INVALID_DEPOSIT_LIMIT INVALID_DEPOSIT_LIMIT_FREQUENCY INVALID_DETAILS INVALID_DOB
                                 INVALID_EMAIL INVALID_FIRSTNAME INVALID_GENDER INVALID_HOME_PHONE INVALID_IP_ADDRESS INVALID_LANGUAGE INVALID_LOCALE
                                 INVALID_LOSS_LIMIT INVALID_LOSS_LIMIT_FREQUENCY INVALID_MASTER_ID INVALID_MOBILE_PHONE INVALID_PARTNERID 
                                 INVALID_PASSWORD INVALID_POSTCODE INVALID_PRIVACY_VERSION INVALID_PRODUCT_ID INVALID_REFERRER_CODE
                                 INVALID_REGION INVALID_SECURITY_QUESTION1 INVALID_SECURITY_QUESTION2 INVALID_SUBPARTNER_ID INVALID_SUPERPARTNER_ID
                                 INVALID_SURNAME INVALID_TC_VERSION INVALID_TIMEZONE INVALID_TITLE INVALID_USERNAME INVALID_WORK_PHONE 
                                 RESERVED_PASSWORD/;
    return 0; 
}

=head2 checkDecimal

Checks the value submitted is a decimal number. Accepts whole numbers with no decimal point and negative numbers with a leading minus ('-').

=cut

sub checkDecimal {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if $arg =~ qr/^-?(?:\d+(?:\.\d*)?|\.\d+)$/;
    return 0;
}


=head2 checkInt

Checks the value submitted is a whole number. Accepts negative numbers with a leading minus ('-').

=cut

sub checkInt {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if $arg =~ /^$RE{num}{int}$/;
    return 0;
}

=head2 checkUsername

Checks the username is between 8-20 characters and contains only letters and numbers.

=cut

sub checkUsername {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if $arg =~ qr/^[a-zA-Z0-9]{8,20}$/;
    return 0;
}

=head2 checkPassword

Checks password is between 8-20 characters. No further checking is done as the password is encrypted. The actual betfair rules are alphanumeric characters plus these valid symbols: $!?()*+,:;=@_./-[]{} with the total length between 8-20 characters.

=cut

sub checkPassword {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if $arg =~ qr/^.{8,20}$/;
    return 0;
}

=head2 checkDate

Checks date follows the XML datetime specification. Note that betfair will only accept datetimes not date values and it must be passed as a string. Some valid examples:

    # standard datetime
    '2013-01-18T12:30:58'
    
    # datetime with UTC timezone
    '2013-01-18T12:30:58Z'

    # datetime with -5hrs timezone
    '2013-01-18T12:30:58-05:00'

    # datetime with +6hrs timezone
    '2013-01-18T12:30:58+06:00'

=cut

sub checkDate {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if $arg =~ qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}/;
    return 0;
}

=head2 checkBoolean

Checks that value is of a valid boolean type: a string value of either 'true' or 'false'.

=cut

sub checkBoolean {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if grep {/^$arg$/} qw/true false/;
    return 0;
}

=head2 checkString

Checks that the value is a string with a non-zero length.

=cut

sub checkString {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if length($arg) > 0;
    return 0;
}

=head2 checkString9

Checks that the value is a string with a non-zero length that is less than 10 characters.

=cut

sub checkString9 {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if (length($arg) > 0 and length($arg) < 10);
    return 0;
}

=head2 checkCardDate

Checks for a number containing exactly 4 digits. If the number begins with 0, it must be quoted (else Perl will remove the leading 0).

=cut

sub checkCardDate {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if $arg =~ /^[0-9]{4}$/;
    return 0;
}

=head2 checkCv2

Checks for a number containing exactly 3 digits. If the number begins with 0, it must be quoted (else Perl will remove the leading 0).

=cut

sub checkCv2 {
    my ($self, $arg) = @_;
    return 0 unless defined $arg;
    return 1 if $arg =~ /^[0-9]{3}$/;
    return 0;
}

1; 
