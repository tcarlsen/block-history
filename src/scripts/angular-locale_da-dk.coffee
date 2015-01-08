# https://github.com/angular/angular.js/blob/master/src/ngLocale/angular-locale_da-dk.js
"use strict"
angular.module "ngLocale", [], [
  "$provide"
  ($provide) ->
    getDecimals = (n) ->
      n = n + ""
      i = n.indexOf(".")
      (if (i is -1) then 0 else n.length - i - 1)
    getVF = (n, opt_precision) ->
      v = opt_precision
      v = Math.min(getDecimals(n), 3)  if `undefined` is v
      base = Math.pow(10, v)
      f = ((n * base) | 0) % base
      v: v
      f: f
    getWT = (v, f) ->
      if f is 0
        return (
          w: 0
          t: 0
        )
      while (f % 10) is 0
        f /= 10
        v--
      w: v
      t: f
    PLURAL_CATEGORY =
      ZERO: "zero"
      ONE: "one"
      TWO: "two"
      FEW: "few"
      MANY: "many"
      OTHER: "other"

    $provide.value "$locale",
      DATETIME_FORMATS:
        AMPMS: [
          "AM"
          "PM"
        ]
        DAY: [
          "søndag"
          "mandag"
          "tirsdag"
          "onsdag"
          "torsdag"
          "fredag"
          "lørdag"
        ]
        MONTH: [
          "januar"
          "februar"
          "marts"
          "april"
          "maj"
          "juni"
          "juli"
          "august"
          "september"
          "oktober"
          "november"
          "december"
        ]
        SHORTDAY: [
          "søn."
          "man."
          "tir."
          "ons."
          "tor."
          "fre."
          "lør."
        ]
        SHORTMONTH: [
          "jan."
          "feb."
          "mar."
          "apr."
          "maj"
          "jun."
          "jul."
          "aug."
          "sep."
          "okt."
          "nov."
          "dec."
        ]
        fullDate: "EEEE 'den' d. MMMM y"
        longDate: "d. MMM y"
        medium: "dd/MM/y HH.mm.ss"
        mediumDate: "dd/MM/y"
        mediumTime: "HH.mm.ss"
        short: "dd/MM/yy HH.mm"
        shortDate: "dd/MM/yy"
        shortTime: "HH.mm"

      NUMBER_FORMATS:
        CURRENCY_SYM: "kr"
        DECIMAL_SEP: ","
        GROUP_SEP: "."
        PATTERNS: [
          {
            gSize: 3
            lgSize: 3
            macFrac: 0
            maxFrac: 3
            minFrac: 0
            minInt: 1
            negPre: "-"
            negSuf: ""
            posPre: ""
            posSuf: ""
          }
          {
            gSize: 3
            lgSize: 3
            macFrac: 0
            maxFrac: 2
            minFrac: 2
            minInt: 1
            negPre: "-"
            negSuf: " ¤"
            posPre: ""
            posSuf: " ¤"
          }
        ]

      id: "da-dk"
      pluralCat: (n, opt_precision) ->
        i = n | 0
        vf = getVF(n, opt_precision)
        wt = getWT(vf.v, vf.f)
        return PLURAL_CATEGORY.ONE  if n is 1 or wt.t isnt 0 and (i is 0 or i is 1)
        PLURAL_CATEGORY.OTHER

]
