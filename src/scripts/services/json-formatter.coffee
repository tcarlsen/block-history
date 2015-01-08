angular.module "jsonFormatterService", []
  .service "jsonFormatter", ($filter) ->
    format: (polls) ->
      parseDate = d3.time.format("%Y-%m-%d %X").parse
      dates = []
      max =
        percent: 0
        mandates: 0
      min =
        percent: 9999
        mandates: 9999
      redBlock =
        name: "Rød"
        class: "red"
        values: []
        color:
          first: "#BB242E"
          second: "#D77C83"
      blueBlock =
        name: "Blå"
        class: "blue"
        values: []
        color:
          first: "#136A90"
          second: "#74A6BC"

      for poll in polls
        continue if !poll.entries.entry

        ruler = "blue"
        firstBlock =
          date: parseDate poll.datetime
          percent: 0
          mandates: 0
          letters: []
        secondBlock =
          date: parseDate poll.datetime
          percent: 0
          mandates: 0
          letters: []

        for entry in poll.entries.entry
          supports = parseInt entry.supports

          if supports is 1 or supports is 9
            firstBlock.percent += parseFloat entry.percent
            firstBlock.mandates += parseFloat entry.mandates
            firstBlock.letters.push entry.party.letter
          else if supports is 2
            secondBlock.percent += parseFloat entry.percent
            secondBlock.mandates += parseFloat entry.mandates
            secondBlock.letters.push entry.party.letter

          if supports is 9
            ruler = "red" if entry.party.letter is "A"

        if ruler is "red"
          redBlock.values.push firstBlock
          blueBlock.values.push secondBlock
        else
          redBlock.values.push secondBlock
          blueBlock.values.push firstBlock

        firstBlock.letters = $filter('orderBy')(firstBlock.letters).join ""
        secondBlock.letters = $filter('orderBy')(secondBlock.letters).join ""

        pollMinPercent = Math.min firstBlock.percent, secondBlock.percent
        pollMinMandates = Math.min firstBlock.mandates, secondBlock.mandates
        pollMaxPercent = Math.max firstBlock.percent, secondBlock.percent
        pollMaxMandates = Math.max firstBlock.mandates, secondBlock.mandates

        min.percent = Math.min pollMinPercent, min.percent
        min.mandates = Math.min pollMinMandates, min.mandates
        max.percent = Math.max pollMaxPercent, max.percent
        max.mandates = Math.max pollMaxMandates, max.mandates

        dates.push {date: parseDate poll.datetime}

      dates.sort (a, b) ->
        return a.date - b.date

      dateDomain = d3.extent dates, (d) -> d.date

      return {
        blocks: [blueBlock, redBlock]
        dates: dates
        fulDateDomain: dateDomain
        initDateDomain: [parseDate("2011-06-15 00:00:00"), dateDomain[1]]
        view: "percent"
        max: max
        min: min
      }
