_ = require('lodash')


isUri = (value)-> /^([0-9a-z_]*\.)*[0-9a-z_]*$/.test(value)

###*
 * Check a number to see if it's a valid port number (ie. an integer in the
 * range [1, 65535])
 *
 * @param  {Mixed} p The value to check
 *
 * @return {Boolean} True if it's a valid port number, false otherwise
###
isValidPort = (p)->
    p? and _.isInteger(p) and 1<=p<=65535

###*
 * Check that the identifier & config for a role are valid
 *
 * @param  {Object}  config     The permissions for the role
 * @param  {String}  identifier The role identifier
 *
 * @return {Boolean}            True if the role is valid
 *
 * @throws {TypeError} if the configuration or identifier are not valid
###
isValidRole = (config, identifier)->
    if not isUri(identifier)
        throw new TypeError('Invalid role')

    if not _.isPlainObject(config)
        throw new TypeError('Invalid permissions')

    true

###*
 * Check that the identifier & config describe a valid realm
 *
 * @param  {Object}  config     The configuration object
 * @param  {String}  identifier The realm identifier
 *
 * @return {Boolean}            True if the realm is valid
 *
 * @throws {TypeError} if the realm configuration or identifier are not valid
###
isValidRealm = (config, identifier)->
    if not isUri(identifier)
        throw new TypeError('Invalid realm identifier')

    if config.roles?
        if not _.isPlainObject(config.roles)
            throw new TypeError('Invalid roles')

        # check the role identifiers & permissions
        #
        _.forEach(config.roles, isValidRole)

    true

###*
 * Check a user to see if the configuration is valid
 *
 * @param  {Object}  user       The user object
 * @param  {String}  identifier The identifier
 *
 * @return {Boolean}            True if the user is valid
###
isValidUser = (user, identifier)->
    # is the value an object? if not, then fail
    #
    if not _.isPlainObject(user)
        throw new TypeError('Invalid WAMP-CRA configuration - invalid user')

    if not user.secret?
        throw new TypeError('Invalid WAMP-CRA configuration - missing user secret')

    if not _.isString(user.secret) and not _.isNumber(user.secret)
        throw new TypeError('Invalid WAMP-CRA configuration - invalid user secret')

    if not user.role?
        throw new TypeError('Invalid WAMP-CRA configuration - missing user role')

    if not _.isString(user.role) and not _.isNumber(user.role)
        throw new TypeError('Invalid WAMP-CRA configuration - invalid user role')

    true

###*
 * Check the static WAMP-CRA list of users
 *
 * @param  {Object}  users The list of users
 *
 * @return {Boolean}       True if the list is valid
 *
 * @throws {TypeError} if the list of users is not valid
###
isValidWAMPCRAStaticUsers = (users)->
    # we must have a list of users
    #
    if not users?
        throw new TypeError('Invalid WAMP-CRA configuration - missing user list')

    # users must be an object - a hash mapping user ID to parameters
    #
    if not _.isPlainObject(users)
        throw new TypeError('Invalid WAMP-CRA configuration - invalid user list')

    # validate each user
    #
    _.forEach(users, isValidUser)

    true





###*
 * Check a string to ensure that it's a valid path
 *
 * @param  {String}  p The string to check
 *
 * @return {Boolean}   True if it's a valid path, false otherwise
###
isValidPath = (p)-> /^(\/[a-z0-9\._-]+)*(\/)?$/i.test(p)

validateConfiguration = (config)->
    # check the port - must be an integer in the range [1, 65535]
    #
    if not isValidPort(config.port)
        throw new TypeError('Invalid port number')

    # check the path - if it exists, it must be a valid URI path string
    #
    if config.path? and not isValidPath(config.path)
        throw new TypeError('Invalid path')

    # validate realms
    #
    if config.realms?
        # must be an object
        #
        if not _.isPlainObject(config.realms)
            throw new TypeError('Invalid realms')

        # make sure that all the realm IDs are URIs and do any validation of
        # details in each realm
        #
        _.forEach(config.realms, isValidRealm)

    # validate wampcra config
    #
    if config.wampcra?
        # we must have a type
        #
        if not config.wampcra.type?
            throw new TypeError('Invalid WAMP-CRA configuration - missing type')

        if config.wampcra.type=='static'
            isValidWAMPCRAStaticUsers(config.wampcra.users)

        else if config.wampcra.type=='dynamic'
            # we must have an authenticator function
            #
            if not config.wampcra.authenticator?
                throw new TypeError('Invalid WAMP-CRA configuration - missing authenticator')

            if not _.isFunction(config.wampcra.authenticator)
                throw new TypeError('Invalid WAMP-CRA configuration - invalid authenticator')
        else
            throw new TypeError('Invalid WAMP-CRA configuration - invalid type')





    true

module.exports.validateConfiguration = validateConfiguration
module.exports.isUri = isUri
