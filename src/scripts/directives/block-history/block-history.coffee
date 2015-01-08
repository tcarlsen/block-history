angular.module "blockHistoryDirective", []
  .directive "blockHistory", ($filter, xmlGetter) ->
    restrict: "E"
    templateUrl: "/upload/tcarlsen/block-history/partials/block-history.html"
    link: (scope, element, attr) ->
      currentYear = 2014#new Date().getFullYear()
      polls = []
      scope.view = "percent"
      scope.polls = []
      scope.loading = true

      scope.showFill = ->
        lines = $("g.lines").find("path")

        for line in lines
          strokeNow = line.attributes["stroke"].value
          strokeNew = line.attributes["data-stroke"].value

          $(line).attr "stroke", strokeNew
          $(line).attr "data-stroke", strokeNow

        $("g.areas").toggle()

        return true

      xmlGetter.get("valgresultater.xml").then (data) ->
        scope.electionResults = data.result.poll

      angular.forEach [2010..currentYear], (year) ->
        xmlGetter.get("#{year}/10.xml").then (data) ->
          if data.error
            currentYear -= 1
          else
            polls.push
              year: year
              data: data.result.polls.poll

            if polls.length is [2010..currentYear].length
              polls = $filter('orderBy')(polls, 'year', true)

              for poll in polls
                scope.polls = scope.polls.concat poll.data

              scope.loading = false
