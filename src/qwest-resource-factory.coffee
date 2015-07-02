###
# This file is part of the KappaJs resource factory package.
# (c) Ondřej Záruba <zarubaondra@gmail.com>
#
# For the full copyright and license information, please view
# the license.md file that was distributed with this source code.
###

qwest = require "qwest"
objectAssign = require "object-assign"
Promise = require "bluebird"

class ResourceFactory

  allowedMethods: ["post", "put", "get", "delete"]

  create: (url, api) ->

    methods = {}

    before = null
    if api.before?
      before = api.before
      delete api.before

    for action, options of api

      if before?
        options.before = before

      methods[action] = @_createQwest url, options

    return methods

  _parseUrl: (url, params = {}) ->
    urlMatches = url.match(/^http(s)?:\/\/[^\/]+(.*)$/)
    if urlMatches.length < 3
      throw "Invalid URL"
    uri = defaultUri = urlMatches[2]
    matches = uri.match(/:([^:]+):/g) || []

    for match in matches
      paramName = match.substr(1, match.length - 2)
      if params[paramName]?
        value = params[paramName]
        uri = uri.replace match, value
        delete params[paramName]
      else
        uri = uri.replace match, ""

    uri = uri.replace /\/{2,}/g, "/"
    url = url.replace defaultUri, uri

    return url

  _createQwest: (url, options) ->

    if not options.method?
      throw "Missing method options"
    options.method = options.method.toLowerCase()
    if @allowedMethods.indexOf(options.method) is -1
      throw "Invalid method '#{method}'"

    qwestConfiguration =
      dataType: "json"

    callback = (params = {}, successCallback = null, errorCallback = null) =>
      return new Promise (resolve, reject) =>
        params = objectAssign {}, options.params, params
        qwestInstance = qwest[options.method](@_parseUrl(url, params), params, qwestConfiguration)

        if options.before?
          qwestInstance.before options.before()

        qwestInstance.then((response) ->
          successCallback(response) if successCallback?
          resolve response
        )['catch']((err, response) ->
          errorCallback(err, response) if errorCallback?
          reject err
        )

    return callback

module.exports = new ResourceFactory()