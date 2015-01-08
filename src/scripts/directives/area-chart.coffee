angular.module "areaChartDirective", []
  .directive "areaChart", ($window, $filter, jsonFormatter) ->
    restrict: "E"
    scope: false
    link: (scope, element, attrs) ->
      formatted = null
      firstRun = true
      parseDate = d3.time.format("%Y-%m-%d %X").parse
      svgHeight = 450
      navigatorHeight = 50
      svgPadding =
        top: 30
        right: 25
        bottom: 65
        left: 25

      da_DK =
        "decimal": ",",
        "thousands": ".",
        "grouping": [3],
        "currency": ["", "kr."],
        "dateTime": "%d/%m-%Y %H:%M:%S",
        "date": "%d/%m-%Y",
        "time": "%H:%M:%S",
        "periods": ["AM", "PM"],
        "days": ["søndag", "mandag", "tirsdag", "onsdag", "torsdag", "fredag", "lørdag"],
        "shortDays": ["søn", "man", "tir", "ons", "tor", "fre", "lør"],
        "months": ["januar", "febuar", "marts", "april", "maj", "juni", "juli", "august", "september", "oktober", "november", "december"],
        "shortMonths": ["jan", "feb", "mar", "apr", "maj", "jun", "jul", "aug", "sep", "okt", "nov", "dec"]

      customTimeFormat = d3.locale(da_DK).timeFormat.multi [
        ["%a %d", (d) -> d.getDay() and d.getDate() isnt 1]
        ["%b %d", (d) -> d.getDate() isnt 1]
        ["%B", (d) -> d.getMonth()]
        ["%Y", (d) -> return true]
      ]

      barContainer = d3.select ".bar-container"

      svg = d3.select(element[0]).append "svg"
        .attr "width", "100%"
        .attr "height", svgHeight + svgPadding.top + svgPadding.bottom + navigatorHeight

      periodIndicator = d3.select(element[0]).append "div"
        .attr "class", "period-indicator"
        .attr "style", ->
          top = svgHeight + svgPadding.top - 21

          return "top: #{top}px; left: #{svgPadding.left}px"

      tip = d3.tip()
        .attr "class", "d3-tip"
        .html (index) ->
          date = $filter('date')(formatted.blocks[0].values[index].date, 'fullDate')
          html = "<header>#{date}</header>"
          html+= "<ul>"

          for block in formatted.blocks
            if scope.view is "percent"
              value = $filter('number')(block.values[index][scope.view], 1) + "%"
            else
              value = block.values[index][scope.view]

            html+= "<li class='#{block.class}'>"
            html+= "<i class='fa fa-square' style='color:#{block.color.first}'></i> "
            html+= "<strong>#{block.name} (#{block.values[index].letters}) #{value}</strong> "
            html+= "</li>"

          html+= "</ul>"

          return html

      svg.call tip
      $window.onresize = -> scope.$apply()

      scope.$watch (->
        angular.element($window)[0].innerWidth
      ), ->
        return if firstRun

        svg.selectAll("*").remove()
        render scope.view

      scope.$watch "loading", (newData, oldData) ->
        if newData is false
          formatted = jsonFormatter.format scope.polls
          render scope.view

      scope.$watch "view", (newView, oldView) ->
        return if firstRun

        svg.selectAll("*").remove()
        render newView

      updateBars = (index) ->
        total = 0

        for block in formatted.blocks
          if scope.view is "percent"
            value = $filter('number')(block.values[index][scope.view], 1) + "%"
          else
            value = block.values[index][scope.view]

          percent = block.values[index].percent
          total += percent

          if total > 100
            percent = percent - (total - 100)

          barContainer.select(".#{block.class}").style "width", "#{percent}%"
          barContainer.select(".#{block.class} strong").text "#{block.values[index].letters} #{value}"

      render = (view) ->
        chart = svg.append "g"
          .attr "class", "chart"
          .attr "transform", "translate(#{svgPadding.left}, #{svgPadding.top})"
        chartAreas = chart.append "g"
          .attr "class", "areas"
        chartLines = chart.append "g"
          .attr "class", "lines"
        controller = svg.append "g"
          .attr "class", "controller"
          .attr "transform", "translate(0, #{svgHeight + svgPadding.bottom})"
        svgWidth = d3.select(element[0])[0][0].offsetWidth
        minYScale = formatted.min[view] - 5
        maxYScale = formatted.max[view]
        xScale = d3.time.scale()
          .domain formatted.initDateDomain
          .range [0, svgWidth - svgPadding.left]
        xScale2 = d3.time.scale()
          .domain formatted.fulDateDomain
          .range [3, svgWidth - 13]
        yScale = d3.scale.linear()
          .domain [minYScale, maxYScale]
          .range [svgHeight, 0]
        yScale2 = d3.scale.linear()
          .domain [minYScale, maxYScale]
          .range [navigatorHeight, 0]
        xAxis = d3.svg.axis()
          .scale xScale
          .orient "bottom"
          .tickFormat customTimeFormat
          .ticks if svgWidth <= 750 then 5 else 10
        yAxis = d3.svg.axis()
          .scale yScale
          .ticks if view is "percent" then 10 else 5
          .tickSize -svgWidth, 0, 0
          .orient "left"
        brush = d3.svg.brush()
          .x xScale2
          .extent formatted.initDateDomain
          .on "brush", ->
            xScale.domain if brush.empty() then xScale2.domain() else brush.extent()

            x1 = xScale2 brush.extent()[0]
            x2 = xScale2 brush.extent()[1]
            maxX2 = xScale2 formatted.fulDateDomain[1]
            x2Diff = maxX2 - x2
            formatted.initDateDomain = brush.extent()

            chart.selectAll(".x.axis").call xAxis
            overlayW.attr "width", if x1 > 3 then x1 - 3 else 0
            overlayE
              .attr "x", x2 + 13
              .attr "width", x2Diff
            partyLines.attr "d", (d) -> line d.values
            partyAreas.attr "d", (d) -> area d.values
            periodIndicator.text ->
              from = $filter('date')(brush.extent()[0], 'longDate')
              to = $filter('date')(brush.extent()[1], 'longDate')

              return "#{from} - #{to}"
            electionResult.attr "transform", (d) -> "translate(#{xScale parseDate(d.datetime)}, 0)"

        bisectDate = d3.bisector((d) -> d.date).left
        area = d3.svg.area()
          .x (d) -> xScale d.date
          .y0 (d) -> yScale parseFloat d[view]
          .y1 (d) -> yScale 0

        stack = d3.layout.stack()
          .values (d) -> d.values

        line = d3.svg.line()
          .x (d) -> xScale d.date
          .y (d) -> yScale d[view]
        line2 = d3.svg.line()
          .x (d) -> xScale2 d.date
          .y (d) -> yScale2 d[view]

        periodIndicator.text ->
          from = $filter('date')(formatted.initDateDomain[0], 'longDate')
          to = $filter('date')(formatted.initDateDomain[1], 'longDate')

          return "#{from} - #{to}"

        partyAreas = chartAreas.selectAll ".area"
          .data formatted.blocks
          .enter()
            .append "path"
              .attr "class", (d) -> "#{d.class} area"
              .attr "fill", (d) -> d.color.first
              .attr "clip-path", "url(#clip)"

        partyAreas.attr "d", (d) -> area d.values

        partyLines = chartLines.selectAll ".line"
          .data formatted.blocks
          .enter()
            .append "path"
              .attr "class", (d) -> "line #{d.class}"
              .attr "stroke", (d) -> d.color.second
              .attr "data-stroke", (d) -> d.color.first
              .attr "stroke-width", 3
              .attr "fill", "transparent"
              .attr "clip-path", "url(#clip)"

        partyLines.attr "d", (d) -> line d.values

        chart.append "g"
          .attr "class", "y axis"
          .call yAxis

        chart.append "g"
          .attr "class", "x axis"
          .attr "transform", "translate(0, #{svgHeight})"
          .call xAxis
          .append "line"
            .attr "x1", 0
            .attr "y1", 0
            .attr "x2", svgWidth
            .attr "y2", 0

        chart.selectAll(".y.axis").call yAxis

        electionResult = chart.selectAll ".election-result"
          .data scope.electionResults
          .enter()
            .append "g"
              .attr "class", "election-result"
              .attr "transform", (d) -> "translate(#{xScale parseDate(d.datetime)}, 0)"

        electionResult.append "line"
          .attr "x1", 0
          .attr "y1", 0
          .attr "x2", 0
          .attr "y2", svgHeight

        electionResult.append "text"
          .attr "dy", -5
          .text (d) -> "Valget #{parseDate(d.datetime).getFullYear()}"

        partyLines2 = controller.selectAll ".partyLines"
          .data formatted.blocks
          .enter()
            .append "path"
              .attr "class", (d) -> "partyLines #{d.class}"
              .attr "stroke", (d) -> d.color.first
              .attr "stroke-width", 1
              .attr "fill", "transparent"

        partyLines2.attr "d", (d) -> line2 d.values

        gBrush = controller.append "g"
          .attr "class", "brush"
          .call brush

        gBrush.selectAll "rect"
          .attr "height", navigatorHeight

        gBrush.append "line"
          .attr "x1", -10
          .attr "y1", navigatorHeight + 1
          .attr "x2", svgWidth
          .attr "y2", navigatorHeight + 1

        overlayW = gBrush.append "rect"
          .attr "class", "overlay"
          .attr "height", navigatorHeight
          .attr "width", xScale2(formatted.initDateDomain[0]) - 3
        overlayE = gBrush.append "rect"
          .attr "class", "overlay"
          .attr "height", navigatorHeight
          .attr "x", xScale2(formatted.initDateDomain[1]) + 13
          .attr "width", xScale2(formatted.fulDateDomain[1]) - xScale2(formatted.initDateDomain[1])

        resize = gBrush.selectAll ".resize"

        resize.selectAll "rect"
          .attr "class", "control"
          .attr "width", 15
          .attr "y", 1

        resize
          .append "text"
            .attr "class", "control"
            .attr "y", navigatorHeight / 2 + 6.5
            .attr "x", (d, i) -> if i is 0 then 0 else 1
            .attr "text-anchor", "right"
            .text (d, i) -> if i is 0 then "\uf0d9" else "\uf0da"

        partyLines2.attr "d", (d) -> line2 d.values

        focus = chart.append "g"
          .attr "class", "focus"
          .style "display", "none"

        focus.append "line"
          .attr "x1", 0
          .attr "y1", 0
          .attr "x2", 0

          .attr "y2", svgHeight

        focus.selectAll ".focus-circle"
          .data formatted.blocks
          .enter()
            .append "circle"
              .attr "class", (d) -> "focus-circle #{d.class}"
              .attr "stroke", (d) -> d.color.first
              .attr "stroke-width", 2
              .attr "fill", "#fff"
              .attr "r", 6

        focusDom = focus[0][0]

        chart.append "rect"
          .attr "class", "overlay"
          .attr "width", svgWidth
          .attr "height", svgHeight
          .on "mouseover", -> focus.style "display", null
          .on "mouseout", ->
            focus.style "display", "none"
            tip.hide()
          .on "mousemove", ->
            x0 = xScale.invert(d3.mouse(this)[0])
            i = bisectDate(formatted.dates, x0, 1)
            o0 = formatted.dates.length - i - 1
            o1 = formatted.dates.length - i
            d0 = formatted.dates[i - 1]
            d1 = formatted.dates[i]
            d = (if x0 - d0.date > d1.date - x0 then d1 else d0)

            if d3.mouse(this)[0] > svgWidth / 2
              direction = "w"
              offset = -25
            else
              direction = "e"
              offset = 25

            focus.attr "transform", "translate(#{xScale(d.date)}, 0)"

            for party in formatted.blocks
              o = (if x0 - party.values[o0].date > party.values[o1].date - x0 then o0 else o1)

              focus.select ".focus-circle.#{party.class}"
                .attr "cy", yScale party.values[o][view]

            tip
              .direction direction
              .offset [0, offset]
              .show o, focusDom

            updateBars o

        svg.append "defs"
          .append "clipPath"
            .attr "id", "clip"
              .append "rect"
                .attr "width", svgWidth - svgPadding.left
                .attr "height", svgHeight

        firstRun = false
