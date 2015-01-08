angular.module "xmlGetterService", []
  .service "xmlGetter", ($http, $location) ->
    get: (url) ->
      url = "/upload/webred/bmsandbox/opinion_poll/#{url}"
      url = "http://localhost:9292/www.b.dk#{url}" if $location.$$host is "localhost"
      promise = $http.get url,
        cache: true
        transformResponse: (data) ->
          x2js = new X2JS()
          return x2js.xml_str2json data
      .then ((response) ->
        return response.data
      ), (data) ->
        return {
          error: data.status
        }
