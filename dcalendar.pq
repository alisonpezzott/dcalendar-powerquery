let

    // Specify the start date 
    startDate = #date(2024, 1, 1),
    // Specify the end date. Default: End of the current year 
    endDate = Date.EndOfYear(Date.From(DateTime.LocalNow())),
    // Specify the current date. Default: Current server date 
    currentDate = Date.From(DateTime.LocalNow()),
    // Specify the start of the week. Default: Day.Monday 
    weekStart = Day.Monday,
    // Specify the month of the fiscal year start. Default: 4 (April)
    fiscalYearStartMonth = 4,
    /* Start day of the closing month. 
       Default: 16 (means the closing month goes from the 16th of the current month 
       to the 15th of the next month) */
    closingMonthStartDay = 16,
    // Specify the language. Default: en-US (English - United States)
    language = "en-US",
    // Generate the calendar table
    dCalendar =
        let

            // List with all dates 
            dateRange = List.Buffer(
                List.Transform({Number.From(startDate) .. Number.From(endDate)}, Date.From)
            ),
            // List with all years 
            yearRange = List.Buffer({Date.Year(startDate) .. Date.Year(endDate)}),
            // Fixed holidays that occur every year 
            fixedHolidaysList = #table(
                type table [Day = Int64.Type, Month = Int64.Type, Holiday = text],
                {

                    // Day, Month, Holiday
                    {1, 1, "New Year's Day"},
                    {7, 4, "Independence Day"},
                    {11, 11, "Veterans Day"},
                    {12, 25, "Christmas Day"}
                }
            ),
            // Function that generates the fixed holidays for all years 
            fxGenerateFixedHolidays = (year) =>
                Table.AddColumn(
                    fixedHolidaysList,
                    "Date",
                    each #date(year, [Month], [Day]),
                    type date
                )[[Date], [Holiday]],
            // Generate the fixed holiday table 
            fixedHolidays = Table.Combine(List.Transform(yearRange, fxGenerateFixedHolidays)),
            // Function that generates the moving holidays 
            fxGenerateMovingHolidays = (year) =>
                let
                    modExcel = (x, y) =>
                        let
                            m = Number.Mod(x, y)
                        in
                            if m < 0 then m + y else m,
                    easter = Date.From(
                        Number.Round(
                            Number.From(#date(year, 4, 1))
                                / 7
                                + modExcel(19 * modExcel(year, 19) - 7, 30) * 0.14,
                            0,
                            RoundingMode.Up
                        )
                            * 7
                            - 6
                    ),
                    movingHolidays = #table(
                        type table [Date = date, Holiday = text],
                        {
                            {Date.AddDays(easter, - 2), "Good Friday"},
                            {easter, "Easter"},
                            {Date.AddDays(easter, 50), "Memorial Day"},
                            {Date.AddDays(easter, - 47), "Thanksgiving Day"}
                        }
                    )
                in
                    movingHolidays,
            // Generate the moving holiday table 
            movingHolidays = Table.Combine(List.Transform(yearRange, fxGenerateMovingHolidays)),
            // Table containing all holidays 
            holidays = Table.Combine({fixedHolidays, movingHolidays}),
            // Define the transformation function for each date 
            fxCalendarRow = (date) =>
                let
                    zws = Character.FromNumber(8203),  // Invisible character (zero-width spacing)
                    dateOffset = Number.From(date - currentDate),
                    year = Date.Year(date),
                    month = Date.Month(date),
                    quarter = Date.QuarterOfYear(date),
                    startYear = Date.Year(startDate),
                    currentYear = Date.Year(currentDate),
                    endYear = Date.Year(endDate),
                    yearOffset = year - currentYear,
                    startMonth = Date.Month(startDate),
                    currentMonth = Date.Month(currentDate),
                    startQuarter = Date.QuarterOfYear(startDate),
                    currentQuarter = Date.QuarterOfYear(currentDate),
                    dayOfWeek = Date.DayOfWeek(date, weekStart) + 1,
                    dayOfWeekZwsIndex = Text.Repeat(zws, 7 - dayOfWeek),
                    isoWeekNumber =
                        let
                            thursdayInWeek = Date.AddDays(
                                date,
                                3 - Date.DayOfWeek(date, Day.Monday)
                            ),
                            startYearThursdayInWeek = #date(Date.Year(thursdayInWeek), 1, 1),
                            diffDays = Duration.Days(thursdayInWeek - startYearThursdayInWeek)
                        in
                            Number.IntegerDivide(diffDays, 7, 0) + 1,
                    weekOfYearNumber = Date.WeekOfYear(date, weekStart),
                    dayOfWeekName = Text.Proper(Date.DayOfWeekName(date, language)),
                    monthName = Text.Proper(Date.MonthName(date, language)),
                    monthZwsIndex = Text.Repeat(zws, 12 - month),
                    monthYearIndex = 12 * (year - startYear) + month,
                    startMonthDate = Date.StartOfMonth(date),
                    endMonthDate = Date.EndOfMonth(date),
                    dayOfMonth = Date.Day(date),
                    monthOffset = ((year * 12) - 1 + month)
                        - ((currentYear * 12) - 1 + currentMonth),
                    quarterOffset = ((year * 4) - 1 + quarter)
                        - ((currentYear * 4) - 1 + currentQuarter),
                    quarterYear = "Q" & Text.From(quarter) & "/" & Text.From(year),
                    isoYear = Date.Year(Date.AddDays(date, 26 - isoWeekNumber)),
                    isoWeekStartDate = Date.StartOfWeek(date, Day.Monday),
                    isoWeekEndDate = Date.EndOfWeek(date, Day.Monday),
                    weekStartDate = Date.StartOfWeek(date, weekStart),
                    weekEndDate = Date.EndOfWeek(date, weekStart),
                    isoWeekStartInitialDate = Date.StartOfWeek(date, Day.Monday),
                    initialWeekStartDate = Date.StartOfWeek(startDate, weekStart),
                    isoWeekStartCurrentDate = Date.StartOfWeek(currentDate, Day.Monday),
                    weekStartCurrentDate = Date.StartOfWeek(currentDate, weekStart),
                    isoWeekOffset = Number.From(isoWeekStartDate - isoWeekStartCurrentDate) / 7,
                    weekOffset = Number.From(weekStartDate - weekStartCurrentDate) / 7,
                    isoWeekYear = "W"
                        & Text.PadStart(Text.From(isoWeekNumber), 2, "0")
                        & "/"
                        & Text.From(isoYear),
                    weekYear = "W"
                        & Text.PadStart(Text.From(weekOfYearNumber), 2, "0")
                        & "/"
                        & Text.From(year),
                    weekOfMonth =
                        let
                            startMonthDate = Date.StartOfMonth(Date.StartOfWeek(date, weekStart)),
                            firstSevenDays = List.Dates(startMonthDate, 7, #duration(1, 0, 0, 0)),
                            firstDay = List.Select(
                                firstSevenDays,
                                each Date.DayOfWeek(_, weekStart) = 0
                            ){0}
                        in
                            Number.RoundUp(Duration.Days(date - firstDay) / 7 + 0.05),
                    weeklyYear = Date.Year(weekStartDate),
                    weeklyMonth = Date.Month(weekStartDate),
                    weeklyMonthName = Text.Proper(Date.MonthName(weekStartDate, language)),
                    weeklyMonthAbbrevName = Text.Start(weeklyMonthName, 3),
                    defaultWeekOfMonthNumber = Date.WeekOfMonth(date, weekStart),
                    fortnightOfMonthNumber = if Date.Day(date) <= 15 then 1 else 2,
                    currentFortnightOfMonthNumber = if Date.Day(currentDate) <= 15 then 1 else 2,
                    monthYear = Text.Proper(
                        Date.ToText(date, [Format = "MMM/yy", Culture = language])
                    ),
                    fortnightMonthYear = "Ft "
                        & Text.From(fortnightOfMonthNumber)
                        & " - "
                        & monthYear,
                    fortnightIndex = 24
                        * (year - startYear)
                        + 2 * (month - startMonth)
                        + fortnightOfMonthNumber,
                    currentFortnightIndex = 24
                        * (currentYear - startYear)
                        + 2 * (currentMonth - startMonth)
                        + currentFortnightOfMonthNumber,
                    fortnightOffset = fortnightIndex - currentFortnightIndex,
                    semesterNumber = if month <= 6 then 1 else 2,
                    currentSemesterNumber = if currentMonth <= 6 then 1 else 2,
                    semesterIndex = (2 * (year - startYear)) + semesterNumber,
                    currentSemesterIndex = (2 * (currentYear - startYear)) + currentSemesterNumber,
                    semesterOffset = semesterIndex - currentSemesterIndex,
                    semesterYear = "S" & Text.From(semesterNumber) & " - " & Text.From(year),
                    bimonthlyNumber = Number.RoundUp(month / 2, 0),
                    currentBimonthlyNumber = Number.RoundUp(currentMonth / 2, 0),
                    bimonthlyYear = "B" & Text.From(bimonthlyNumber) & " - " & Text.From(year),
                    bimonthlyIndex = (6 * (year - startYear)) + bimonthlyNumber,
                    currentBimonthlyIndex = (6 * (currentYear - startYear)) + currentBimonthlyNumber,
                    bimonthlyOffset = bimonthlyIndex - currentBimonthlyIndex,
                    holiday = try holidays{[Date = date]}[Holiday] otherwise null,
                    businessDayNumber =
                        if holiday
                            <> null
                            or List.Contains({6 .. 7}, Date.DayOfWeek(date, Day.Monday) + 1)
                        then
                            0
                        else
                            1,
                    monthDayNumber = Date.Month(date) * 100 + Date.Day(date),
                    seasonOfTheYearNumber =
                        if monthDayNumber >= 321 and monthDayNumber <= 620 then
                            1
                        else if monthDayNumber >= 621 and monthDayNumber <= 921 then
                            2
                        else if monthDayNumber >= 922 and monthDayNumber <= 1221 then
                            3
                        else
                            4,
                    closingReferenceDate =
                        if dayOfMonth <= closingMonthStartDay - 1 then
                            date
                        else
                            Date.AddMonths(date, 1)
                in
                    // Output of transformations 
                    {

                        // DateIndex 
                        Number.From(date - startDate) + 1,
                        // Date 
                        date,
                        // DateOffset 
                        dateOffset,
                        // CurrentDateName 
                        if dateOffset = 0 then
                            "Current Date"
                        else if dateOffset = - 1 then
                            "Previous Date"
                        else if dateOffset = 1 then
                            "Next Date"
                        else
                            Date.ToText(date, "MM/dd/yyyy"),
                        // YearNum 
                        year,
                        // YearStart 
                        Date.StartOfYear(date),
                        // YearEnd 
                        Date.EndOfYear(date),
                        // YearIndex 
                        year - startYear + 1,
                        // YearDescendingName 
                        year,
                        // YearDescendingNum 
                        year * - 1,
                        // FiscalYear 
                        if month >= fiscalYearStartMonth then year else year - 1,
                        // YearOffset 
                        yearOffset,
                        // CurrentYearName 
                        if yearOffset = 0 then
                            "Current Year"
                        else if yearOffset = - 1 then
                            "Previous Year"
                        else if yearOffset = 1 then
                            "Next Year"
                        else
                            Date.ToText(date, "yyyy"),
                        // DayOfMonthNum 
                        dayOfMonth,
                        // DayOfYearNum 
                        Date.DayOfYear(date),
                        // DayOfWeekNum 
                        dayOfWeek,
                        // DayOfWeekName 
                        dayOfWeekName,
                        // DayOfWeekAbbreviatedName 
                        Text.Start(dayOfWeekName, 3),
                        // DayOfWeekInitial 
                        dayOfWeekZwsIndex & Text.Start(dayOfWeekName, 1),
                        // MonthNum 
                        month,
                        // MonthName 
                        monthName,
                        // MonthAbbreviatedName 
                        Text.Start(monthName, 3),
                        // MonthInitial 
                        monthZwsIndex & Text.Start(monthName, 1),
                        // YearMonthNum 
                        year * 100 + month,
                        // MonthYearName 
                        monthYear,
                        // MonthDayNum 
                        month * 100 + dayOfMonth,
                        // MonthDayName
                        Text.Proper(Date.ToText(date, [Format = "MMM/dd", Culture = language])),
                        // MonthStart 
                        Date.StartOfMonth(date),
                        // MonthEnd 
                        Date.EndOfMonth(date),
                        // MonthIndex 
                        monthYearIndex,
                        // MonthOffset 
                        monthOffset,
                        // CurrentMonthName 
                        if monthOffset = 0 then
                            "Current Month"
                        else if monthOffset = - 1 then
                            "Previous Month"
                        else if monthOffset = 1 then
                            "Next Month"
                        else
                            monthName,
                        // CurrentAbbreviatedMonthName 
                        if monthOffset = 0 then
                            "Current Month"
                        else if monthOffset = - 1 then
                            "Previous Month"
                        else if monthOffset = 1 then
                            "Next Month"
                        else
                            Text.Start(monthName, 3),
                        // CurrentYearMonthName 
                        if monthOffset = 0 then
                            "Current Month"
                        else if monthOffset = - 1 then
                            "Previous Month"
                        else if monthOffset = 1 then
                            "Next Month"
                        else
                            monthYear,
                        // QuarterNum 
                        quarter,
                        // QuarterStart 
                        Date.StartOfQuarter(date),
                        // QuarterEnd 
                        Date.EndOfQuarter(date),
                        // QuarterYearNum
                        year * 100 + quarter,
                        // QuarterYearName 
                        quarterYear,
                        // QuarterIndex 
                        4 * (year - startYear) + quarter,
                        // QuarterOffset 
                        quarterOffset,
                        // CurrentQuarterYearName 
                        if quarterOffset = 0 then
                            "Current Quarter"
                        else if quarterOffset = - 1 then
                            "Previous Quarter"
                        else if quarterOffset = 1 then
                            "Next Quarter"
                        else
                            quarterYear,
                        // IsoWeekNum 
                        isoWeekNumber,
                        // IsoYearNum 
                        isoYear,
                        // IsoWeekYearNum 
                        isoYear * 100 + isoWeekNumber,
                        // IsoWeekYearName 
                        isoWeekYear,
                        // IsoWeekStart 
                        isoWeekStartDate,
                        // IsoWeekEnd 
                        isoWeekEndDate,
                        // IsoWeekIndex 
                        Number.From(isoWeekStartDate - isoWeekStartInitialDate) / 7 + 1,
                        // IsoWeekOffset 
                        isoWeekOffset,
                        // CurrentIsoWeekYearName 
                        if isoWeekOffset = 0 then
                            "Current Week"
                        else if isoWeekOffset = - 1 then
                            "Previous Week"
                        else if isoWeekOffset = 1 then
                            "Next Week"
                        else
                            isoWeekYear,
                        // WeekNum 
                        weekOfYearNumber,
                        // YearWeekNum 
                        year * 100 + weekOfYearNumber,
                        // WeekYearName 
                        weekYear,
                        // WeekStart 
                        weekStartDate,
                        // WeekEnd 
                        weekEndDate,
                        // WeekPeriod
                        Date.ToText(weekStartDate, "MM/dd/yyyy")
                            & " to "
                            & Date.ToText(weekEndDate, "MM/dd/yyyy"),
                        // WeekIndex 
                        Number.From(weekStartDate - initialWeekStartDate) / 7 + 1,
                        // WeekOffset
                        weekOffset,
                        // CurrentWeekYearName 
                        if weekOffset = 0 then
                            "Current Week"
                        else if weekOffset = - 1 then
                            "Previous Week"
                        else if weekOffset = 1 then
                            "Next Week"
                        else
                            weekYear,
                        // WeekOfMonthNum 
                        weekOfMonth,
                        // WeeklyYearNum 
                        weeklyYear,
                        // WeeklyMonthNum 
                        weeklyMonth,
                        // WeeklyMonthName 
                        weeklyMonthName,
                        // WeeklyAbbreviatedMonthName 
                        weeklyMonthAbbrevName,
                        // WeeklyYearMonthNum 
                        weeklyYear * 100 + weeklyMonth,
                        // WeeklyYearMonthName 
                        Text.Proper(
                            Date.ToText(weekStartDate, [Format = "MMM/yy", Culture = language])
                        ),
                        // StandardWeekOfMonthNum
                        defaultWeekOfMonthNumber,
                        // StandardWeekOfMonthYearName
                        monthYear & " " & Text.From(defaultWeekOfMonthNumber),
                        // StandardWeekOfMonthYearNum
                        year * 10000 + month * 100 + defaultWeekOfMonthNumber,
                        // FortnightOfMonthNum 
                        fortnightOfMonthNumber,
                        // FortnightMonthNum 
                        month * 10 + fortnightOfMonthNumber,
                        // FortnightMonthName 
                        "Ft " & Text.From(fortnightOfMonthNumber) & " - " & monthName,
                        // FortnightMonthYearNum 
                        year * 10000 + month * 100 + fortnightOfMonthNumber,
                        // FortnightMonthYearName 
                        fortnightMonthYear,
                        // FortnightPeriod
                        let
                            startFortnight =
                                if fortnightOfMonthNumber = 1 then
                                    startMonthDate
                                else
                                    Date.AddDays(startMonthDate, 15),
                            endFortnight =
                                if fortnightOfMonthNumber = 2 then
                                    endMonthDate
                                else
                                    Date.AddDays(startMonthDate, 14)
                        in
                            Date.ToText(startFortnight, "MM/dd/yyyy")
                                & " to "
                                & Date.ToText(endFortnight, "MM/dd/yyyy"),
                        // FortnightIndex
                        fortnightIndex,
                        // FortnightOffset 
                        fortnightOffset,
                        // CurrentFortnightMonthYearName 
                        if fortnightOffset = 0 then
                            "Current Fortnight"
                        else if fortnightOffset = - 1 then
                            "Previous Fortnight"
                        else if fortnightOffset = 1 then
                            "Next Fortnight"
                        else
                            fortnightMonthYear,
                        // SemesterOfYearNum 
                        semesterNumber,
                        // SemesterYearNum 
                        year * 100 + semesterNumber,
                        // SemesterYearName
                        "S" & Text.From(semesterNumber) & " - " & Text.From(year),
                        // SemesterIndex 
                        semesterIndex,
                        // SemesterOffset 
                        semesterOffset,
                        // CurrentSemesterYearName 
                        if semesterOffset = 0 then
                            "Current Semester"
                        else if semesterOffset = - 1 then
                            "Previous Semester"
                        else if semesterOffset = 1 then
                            "Next Semester"
                        else
                            semesterYear,
                        // BimonthlyOfYearNum 
                        bimonthlyNumber,
                        // BimonthlyYearNum 
                        year * 100 + bimonthlyNumber,
                        // BimonthlyYearName 
                        bimonthlyYear,
                        // BimonthlyIndex 
                        bimonthlyIndex,
                        // BimonthlyOffset 
                        bimonthlyOffset,
                        // CurrentBimonthlyYearName 
                        if bimonthlyOffset = 0 then
                            "Current Bimonthly"
                        else if bimonthlyOffset = - 1 then
                            "Previous Bimonthly"
                        else if bimonthlyOffset = 1 then
                            "Next Bimonthly"
                        else
                            bimonthlyYear,
                        // HolidayName 
                        holiday,
                        // BusinessDayNum 
                        businessDayNumber,
                        // BusinessDayName 
                        if businessDayNumber = 0 then "Non-Business Day" else "Business Day",
                        // SeasonOfYearNum 
                        seasonOfTheYearNumber,
                        // SeasonOfYearName 
                        if seasonOfTheYearNumber = 1 then
                            "Spring"
                        else if seasonOfTheYearNumber = 2 then
                            "Summer"
                        else if seasonOfTheYearNumber = 3 then
                            "Fall"
                        else
                            "Winter",
                        // ClosingMonthNum
                        Date.Month(closingReferenceDate),
                        // ClosingMonthName
                        Text.Proper(
                            Date.ToText(closingReferenceDate, [Format = "MMMM", Culture = language])
                        ),
                        // ClosingAbbreviatedMonthName
                        Text.Proper(
                            Date.ToText(closingReferenceDate, [Format = "MMM", Culture = language])
                        ),
                        // ClosingYearNum
                        Date.Year(closingReferenceDate),
                        // ClosingYearMonthNum
                        Date.Year(closingReferenceDate) * 100 + Date.Month(closingReferenceDate),
                        // ClosingYearMonthName
                        Text.Proper(
                            Date.ToText(
                                closingReferenceDate,
                                [Format = "MMM/yy", Culture = language]
                            )
                        ),
                        // FutureDate
                        dateOffset > 0
                    },
            // Generate the calendar table 
            calendar = #table(

                // Column names and types 
                type table [
                    DateIndex = Int64.Type,
                    Date = date,
                    DateOffset = Int64.Type,
                    CurrentDateName = text,
                    YearNum = Int64.Type,
                    YearStart = date,
                    YearEnd = date,
                    YearIndex = Int64.Type,
                    YearDescendingName = Int64.Type,
                    YearDescendingNum = Int64.Type,
                    FiscalYear = Int64.Type,
                    YearOffset = Int64.Type,
                    CurrentYearName = text,
                    DayOfMonthNum = Int64.Type,
                    DayOfYearNum = Int64.Type,
                    DayOfWeekNum = Int64.Type,
                    DayOfWeekName = text,
                    DayOfWeekAbbreviatedName = text,
                    DayOfWeekInitial = text,
                    MonthNum = Int64.Type,
                    MonthName = text,
                    MonthAbbreviatedName = text,
                    MonthInitial = text,
                    YearMonthNum = Int64.Type,
                    MonthYearName = text,
                    MonthDayNum = Int64.Type,
                    MonthDayName = text,
                    MonthStart = date,
                    MonthEnd = date,
                    MonthIndex = Int64.Type,
                    MonthOffset = Int64.Type,
                    CurrentMonthName = text,
                    CurrentAbbreviatedMonthName = text,
                    CurrentYearMonthName = text,
                    QuarterNum = Int64.Type,
                    QuarterStart = date,
                    QuarterEnd = date,
                    QuarterYearNum = Int64.Type,
                    QuarterYearName = text,
                    QuarterIndex = Int64.Type,
                    QuarterOffset = Int64.Type,
                    CurrentQuarterYearName = text,
                    IsoWeekNum = Int64.Type,
                    IsoYearNum = Int64.Type,
                    IsoWeekYearNum = Int64.Type,
                    IsoWeekYearName = text,
                    IsoWeekStart = date,
                    IsoWeekEnd = date,
                    IsoWeekIndex = Int64.Type,
                    IsoWeekOffset = Int64.Type,
                    CurrentIsoWeekYearName = text,
                    WeekNum = Int64.Type,
                    YearWeekNum = Int64.Type,
                    WeekYearName = text,
                    WeekStart = date,
                    WeekEnd = date,
                    WeekPeriod = text,
                    WeekIndex = Int64.Type,
                    WeekOffset = Int64.Type,
                    CurrentWeekYearName = text,
                    WeekOfMonthNum = Int64.Type,
                    WeeklyYearNum = Int64.Type,
                    WeeklyMonthNum = Int64.Type,
                    WeeklyMonthName = text,
                    WeeklyAbbreviatedMonthName = text,
                    WeeklyYearMonthNum = Int64.Type,
                    WeeklyYearMonthName = text,
                    StandardWeekOfMonthNum = Int64.Type,
                    StandardWeekOfMonthYearName = text,
                    StandardWeekOfMonthYearNum = Int64.Type,
                    FortnightOfMonthNum = Int64.Type,
                    FortnightMonthNum = Int64.Type,
                    FortnightMonthName = text,
                    FortnightMonthYearNum = Int64.Type,
                    FortnightMonthYearName = text,
                    FortnightPeriod = text,
                    FortnightIndex = Int64.Type,
                    FortnightOffset = Int64.Type,
                    CurrentFortnightMonthYearName = text,
                    SemesterOfYearNum = Int64.Type,
                    SemesterYearNum = Int64.Type,
                    SemesterYearName = text,
                    SemesterIndex = Int64.Type,
                    SemesterOffset = Int64.Type,
                    CurrentSemesterYearName = text,
                    BimonthlyOfYearNum = Int64.Type,
                    BimonthlyYearNum = Int64.Type,
                    BimonthlyYearName = text,
                    BimonthlyIndex = Int64.Type,
                    BimonthlyOffset = Int64.Type,
                    CurrentBimonthlyYearName = text,
                    HolidayName = text,
                    BusinessDayNum = Int64.Type,
                    BusinessDayName = text,
                    SeasonOfTheYearNum = Int64.Type,
                    SeasonOfTheYearName = text,
                    ClosingMonthNum = Int64.Type,
                    ClosingMonthName = text,
                    ClosingAbbreviatedMonthName = text,
                    ClosingYearNum = Int64.Type,
                    ClosingYearMonthNum = Int64.Type,
                    ClosingYearMonthName = text,
                    FutureDate = Logical.Type
                ],
                // Invoke transformation function 
                List.Transform(dateRange, fxCalendarRow)
            ),
            // Add business day number of the month
            addBusinessDayOfMonth =
                let
                    table = Table.Buffer(
                        Table.SelectColumns(
                            calendar,
                            {"DayOfMonthNum", "MonthIndex", "BusinessDayNum"}
                        )
                    ),
                    addBusinessDayOfMonth = Table.AddColumn(
                        table,
                        "BusinessDayOfMonth",
                        each
                            let
                                __monthIndex = [MonthIndex],
                                __dayOfMonth = [DayOfMonthNum]
                            in
                                List.Sum(
                                    Table.SelectRows(
                                        table,
                                        each [MonthIndex]
                                            = __monthIndex
                                            and [DayOfMonthNum] <= __dayOfMonth
                                    )[BusinessDayNum]
                                ),
                        Int64.Type
                    )[[MonthIndex], [DayOfMonthNum], [BusinessDayOfMonth]],
                    join = Table.Join(
                        calendar,
                        {"MonthIndex", "DayOfMonthNum"},
                        addBusinessDayOfMonth,
                        {"MonthIndex", "DayOfMonthNum"}
                    )
                in
                    join
        in
            addBusinessDayOfMonth
in
    dCalendar
