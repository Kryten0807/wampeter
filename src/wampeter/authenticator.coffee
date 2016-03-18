_ = require('lodash')
util          = require('./util')
logger        = util.logger()


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

    constructor: (config)->
        logger.debug('instantiating authenticator', config)

        # if config is null, then we have NO authentication. In this case, set
        # up the authenticate method to always return true
        #
        if config==null
            @authenticate = ()-> true
            return

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

            # is the type static? if so, then carry on
            #
            if config.wampcra.type!='static'
                throw 'non-static wampcra config'

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

            # set up the authenticate method
            #
            @authenticate = @_wampcra_authenticate

        catch err
            # the config failed validation somewhere. Log the error
            #
            logger.error("unable to define authenticator: #{err} - falling back to impossible authentication")

            # set up the authenticate method
            #
            @authenticate = ()-> false

        ###
        wampcra:
            type: 'static'
            users:
                'alpha':
                    secret: VALID_KEY
                    role: 'frontend'
        ###

    _wampcra_authenticate: (user, secret)=>




module.exports = (config)-> if config==null then null else new Authenticator(config)
