_ = require('lodash')
util          = require('./util')
logger        = util.logger()
crypto = require('crypto-js')
q = require('q')

###*
 * An authenticator for auth requests to the router
 *
 * Currently, the only authentication method supported is static WAMP-CRA.
 *
 * What's going to happen if we have invalid `authConfig`? There is no specific
 * `wamp.error.*`` code to return for an invalid router configuration, and we
 * don't want to leave the application in a state where just anyone can
 * authenticate. so, in the case of an invalid configuration, the `authenticate`
 * method will be one that always fails.
###
class Authenticator

    users = {}

    constructor: (@session, config)->
        logger.debug('instantiating authenticator', config)

        # if config is null, then we have NO authentication. In this case, set
        # up the authenticate method to always return true
        #
        if config==null
            @authenticate = ()-> true
            return

        # set up the challenge method
        #
        @challenge = @_wampcra_challenge

        # now wander through the config structure & validate, finally saving the
        # appropriate values if all goes well
        #
        try
            # do we have a valid config?
            #
            if not config?
                throw 'missing config'

            # do we have a wampcra configuration?
            #
            if not config.wampcra?
                throw 'no wampcra config'

            # set up authentication based on the type
            #
            if config.wampcra.type=='static'
                # handle STATIC authentication

                # do we have a list of users?
                #
                if not config.wampcra.users?
                    throw 'no users defined'

                # build a list of users which are properly formatted
                #
                @users = config.wampcra.users

                _.forEach(@users, (v, k)->
                    if not _.isPlainObject(v)
                        throw "invalid details for user '#{k}'"

                    if not v.secret?
                        throw "missing secret for user '#{k}'"

                    if not _.isString(v.secret)
                        throw "invalid secret for user '#{k}'"

                    if not v.role?
                        throw "missing role for user '#{k}'"

                    if not _.isString(v.role)
                        throw "invalid role for user '#{k}'"
                )

                # set up the challenge generator method
                #
                @generateChallenge = (message)=>
                    # extract the user ID from the message
                    #
                    userID = message?.details?.authid

                    # find the user
                    #
                    user = @users[userID]

                    if not user?
                        user = null
                        throw new Error('wamp.error.not_not_authorized')

                    user.authid = userID

                    challenge = JSON.stringify({
                        authid: user.authid
                        authrole: user.role
                        authmethod: 'wampcra'
                        authprovider: 'static'
                        session: @session.id
                        nonce: util.randomid()
                        timestamp: Math.floor(Date.now()/1000)
                    })

                    [challenge, user]

            else if config.wampcra.type=='dynamic'
                # handle DYNAMIC authentication

                # do we have an authenticator function? if not, throw an error
                #
                if not config.wampcra.authenticator? or not _.isFunction(config.wampcra.authenticator)
                    throw 'missing/invalid wamp-cra authenticator function'

                # set up the challenge generator method
                #
                @generateChallenge = (message)=>
                    logger.debug("----------------- generate challenge", message)

                    realm = message?.realm
                    authid = message?.details?.authid
                    details = message?.details

                    # find the user
                    #
                    credentials = config.wampcra.authenticator(realm, authid, details)

                    if not credentials?
                        credentials = null
                        throw new Error('wamp.error.not_not_authorized')

                    credentials.authid = authid

                    challenge = JSON.stringify({
                        authid: authid
                        authrole: credentials.role
                        authmethod: 'wampcra'
                        authprovider: 'dynamic'
                        session: @session.id
                        nonce: util.randomid()
                        timestamp: Math.floor(Date.now()/1000)
                    })

                    [challenge, credentials]

            else
                # is the type static? if so, then carry on
                #
                throw 'unrecognized wamp-cra type'



        catch err
            # the config failed validation somewhere. Log the error
            #
            logger.error("unable to define authenticator: #{err} - falling back to impossible authentication")

            # set up the authenticate method
            #
            @authenticate = ()-> false

    authenticate: (message)=>
        q.fcall(()=>
            logger.debug('----------------------- dynamic auth underway', message)

            logger.debug('authenticating', message)

            logger.debug('----- auth sig', message.signature)
            logger.debug('----- auth should be', @signature)

            if message.signature? and message.signature==@signature
                @user.authid
            else
                @user = null
                throw new Error('wamp.error.not_not_authorized')
        )


    _wampcra_challenge: (message)=>

        @user = null

        derive_key = (secret, salt, iterations, keylen)->
            if not salt?
                return secret

            logger.debug('deriving key')
            iterations ?= 1000

            keylen ?= 32


            config =
                keySize: keylen / 4
                iterations: iterations
                hasher: crypto.algo.SHA256

            logger.debug('key config', config)

            key = crypto.PBKDF2(secret, salt, config)
            key.toString(crypto.enc.Base64)

        sign = (key, challenge)->
            crypto.HmacSHA256(challenge, key).toString(crypto.enc.Base64)


        q.fcall(()=>

            # get the details from the message
            #
            userID = message.details.authid

            if not userID?
                throw new Error('no user provided')

            [challenge, @user] = @generateChallenge(message)

            extra =
                challenge: challenge

            if @user.salt?
                extra.salt = @user.salt
                extra.iterations = @user.iterations ? 1000
                extra.keylen = @user.keylen ? 32

            logger.debug('getting key')

            key = derive_key(@user.secret, @user.salt, @user.iterations, @user.keylen)
            logger.debug('key', key)

            @signature = sign(key, challenge)

            logger.debug('signature', @signature, @user)

            {authmethod: 'wampcra', extra: extra}

        )

    getUser: ()=> @user

module.exports = (session, authConfig)->
    logger.debug('in authenticator factory', authConfig)
    if authConfig==null then null else new Authenticator(session, authConfig)
