use strict;
use warnings;

package CatalystX::ProtoWiki::Controller::User;

use base "Catalyst::Example::Controller::InstantCRUD";
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;


sub get_user {
    my ( $self, $c, $username ) = @_;
    my $user = $self->model_schema($c)->resultset( 'User' )->search( { username => $username } )->first;
    if( !$user ){
        $c->response->status(404);
        $c->response->body("404 Not Found");
        $c->detach;
    }
    return $user;
}

sub view : Local {
    my ( $self, $c, $username ) = @_;
    my $user = $self->get_user( $c, $username );
    $c->stash( item => $user );
}

sub check_auth {
    my( $self, $c, $username ) = @_;
    if( !$c->user 
        || ( $c->user->username ne $username && !$c->check_user_roles('admin') ) 
    ){
        $c->detach( '/auth/unauthorized' );
    }
}

sub confirm_email : Local {
    my ( $self, $c, $username, $code ) = @_;
    my $user = $self->get_user( $c, $username );
    if( $code eq $user->email_conf_code ){
        $user->update( { email_confirmed => 1 } );
        $c->stash( confirmed => 1 );
    } 
}

sub edit_info : Local {
    my ( $self, $c, $username ) = @_;
    $self->check_auth( $c, $username );
    my $user = $self->get_user( $c, $username );
    my $form = CatalystX::ProtoWiki::Controller::User::InfoUpdateForm->new(
        params => $c->req->params,
        item => $user,
    );
    if( $c->req->method eq 'POST' && $form->process() ){
        $c->res->redirect( $c->uri_for( 'view', $username ) );
    }
    else{
    $form->field( 'submit' )->value( 'Update' );
        $c->stash( form => $form->render );
        $c->stash( template => 'edit.tt' );
    }
}

sub edit_password : Local {
    my ( $self, $c, $username ) = @_;
    $self->check_auth( $c, $username );
    my $user = $self->get_user( $c, $username );
    my $form = CatalystX::ProtoWiki::Controller::User::PasswordUpdateForm->new(
        params => $c->req->params,
        item => $user,
    );
    if( $c->req->method eq 'POST' ){
        if( ! $c->authenticate( { 
                    username => $username,
                    password => $c->req->params->{old_password} 
                }
            )
        ){
            $form->field( 'old_password' )->add_error( 'Wrong password' );
        }
        elsif( $form->process() ){
            $c->res->redirect( $c->uri_for( 'view', $username ) );
        }
    }
    $c->stash( form => $form->render );
    $c->stash( template => 'edit.tt' );
}

sub send_confirmation_email {
    my ( $self, $user, $conf_url, $our_email ) = @_;
    my $email = Email::Simple->create( 
        header => [
        To      => $user->email,
        From    => $our_email,
        Subject => "Registration",
        ],
        body => "Hi there!  Someone has registered your email address at our site.  Please go to $conf_url/" . $user->username . '/' . $user->email_conf_code . ' to confirm your email address.',
    );
    sendmail($email);
}


{
    package CatalystX::ProtoWiki::Controller::User::InfoUpdateForm;
    use HTML::FormHandler::Moose;
    extends 'HTML::FormHandler::Model::DBIC';
    with 'HTML::FormHandler::Render::Simple';

    has '+item_class' => ( default => 'User' );

    has_field 'email' => ( type => 'Email', required => 1 );
    
    has_field submit => ( widget => 'submit', )
}

{
    package CatalystX::ProtoWiki::Controller::User::PasswordUpdateForm;
    use HTML::FormHandler::Moose;
    extends 'HTML::FormHandler::Model::DBIC';
    with 'HTML::FormHandler::Render::Simple';
    use HTML::FormHandler::Types ('NoSpaces', 'WordChars', 'NotAllDigits' );


    has '+item_class' => ( default => 'User' );

        has_field 'old_password' => ( type => 'Password', required => 1 );
        has_field 'password' => ( type => 'Password', min_length => 5, size => 32, apply => [ NotAllDigits ], required => 1 );
        has_field 'password_' => ( type => 'PasswordConf', size => 32, );
    
    has_field submit => ( widget => 'submit', value => 'change password' )
}




1;

