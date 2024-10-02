// This script performs the following operations:
// 1. Sorts text columns by their corresponding numeric columns
// 2. Organizes columns into folders by granularity
// 3. Applies the short date format to date-type columns
// 4. Removes aggregations from numeric columns
// 5. Marks the table as a date table

// Access the dCalendar table
var dCalendar = Model.Tables["dCalendar"];

// Create a mapping of text columns and their respective numeric columns for sorting
var columnPairs = new Dictionary<string, string>
{
    {"DescendingYearName", "DescendingYearNum"}, 
    {"CurrentYearName", "YearNum"}, 
    {"BimonthlyYearName", "BimonthlyYearNum"}, 
    {"CurrentBimonthlyYearName", "BimonthlyYearNum"}, 
    {"CurrentDateName", "Date"}, 
    {"DayOfWeekName", "DayOfWeekNum"}, 
    {"DayOfWeekAbbrevName", "DayOfWeekNum"}, 
    {"DayOfWeekInitial", "DayOfWeekNum"}, 
    {"BusinessDayName", "BusinessDayNum"}, 
    {"SeasonOfYearName", "SeasonOfYearNum"}, 
    {"ClosingYearMonthName", "ClosingYearMonthNum"}, 
    {"YearMonthName", "YearMonthNum"}, 
    {"CurrentYearMonthName", "YearMonthNum"}, 
    {"WeeklyYearMonthName", "WeeklyYearMonthNum"}, 
    {"MonthDayName", "MonthDayNum"}, 
    {"ClosingMonthName", "ClosingMonthNum"}, 
    {"ClosingAbbrevMonthName", "ClosingMonthNum"}, 
    {"MonthName", "MonthNum"}, 
    {"MonthAbbrevName", "MonthNum"}, 
    {"CurrentAbbrevMonthName", "MonthNum"}, 
    {"CurrentMonthName", "MonthNum"}, 
    {"MonthInitial", "MonthNum"}, 
    {"WeeklyMonthName", "WeeklyMonthNum"}, 
    {"WeeklyAbbrevMonthName", "WeeklyMonthNum"}, 
    {"FortnightYearMonthName", "FortnightYearMonthNum"}, 
    {"CurrentFortnightYearMonthName", "FortnightYearMonthNum"}, 
    {"FortnightName", "FortnightNum"}, 
    {"FortnightPeriod", "FortnightYearMonthNum"}, 
    {"WeekYearName", "WeekYearNum"}, 
    {"CurrentWeekYearName", "WeekYearNum"}, 
    {"StandardWeekOfMonthYearName", "StandardWeekOfMonthYearNum"}, 
    {"IsoWeekYearName", "IsoWeekYearNum"}, 
    {"CurrentIsoWeekYearName", "IsoWeekYearNum"}, 
    {"WeekPeriod", "WeekIndex"}, 
    {"SemesterYearName", "SemesterYearNum"}, 
    {"CurrentSemesterYearName", "SemesterYearNum"}, 
    {"QuarterYearName", "QuarterYearNum"}, 
    {"CurrentQuarterYearName", "QuarterYearNum"}
};

// Apply sorting for each text column
foreach (var pair in columnPairs)
{
    var textColumn = dCalendar.Columns[pair.Key];  // Text column
    var sortColumn = dCalendar.Columns[pair.Value];  // Corresponding numeric column

    // Check if both columns exist and apply sorting
    if (textColumn != null && sortColumn != null)
    {
        textColumn.SortByColumn = sortColumn;  // Sort text column by numeric column
    }
}

// Dictionary to associate columns with their respective folders
var displayFolders = new Dictionary<string, string[]>
{
    { "Year", new[] { "DescendingYearName", "DescendingYearNum", "YearEnd", "FiscalYear", "YearIndex", "YearStart", "IsoYearNum", "CurrentYearName", "YearNum", "YearOffset" } },
    { "Closing", new[] { "ClosingYearNum", "ClosingYearMonthName", "ClosingYearMonthNum", "ClosingMonthName", "ClosingAbbrevMonthName", "ClosingMonthNum" } },
    { "Week of Month (Complete)", new[] { "WeeklyYearNum", "WeeklyYearMonthName", "WeeklyYearMonthNum", "WeeklyMonthName", "WeeklyAbbrevMonthName", "WeeklyMonthNum", "StandardWeekOfMonthNum" } },
    { "Bimonthly", new[] { "BimonthlyYearName", "CurrentBimonthlyYearName", "BimonthlyYearNum", "BimonthlyOfYearNum", "BimonthlyIndex", "BimonthlyOffset" } },
    { "Day", new[] { "FutureDate", "DateIndex", "CurrentDateName", "DateOffset", "DayOfWeekName", "DayOfWeekAbbrevName", "DayOfWeekInitial", "DayOfWeekNum", "DayOfYearNum", "DayOfMonthNum" } },
    { "Business Days / Holidays", new[] { "BusinessDayOfMonth", "BusinessDayName", "BusinessDayNum", "HolidayName" } },
    { "Seasons of the Year", new[] { "SeasonOfYearName", "SeasonOfYearNum" } },
    { "Months", new[] { "YearMonthName", "CurrentYearMonthName", "YearMonthNum", "MonthDayName", "MonthDayNum", "MonthEnd", "MonthIndex", "MonthStart", "MonthName", "MonthAbbrevName", "CurrentAbbrevMonthName", "CurrentMonthName", "MonthInitial", "MonthNum", "MonthOffset" } },
    { "Fortnights", new[] { "FortnightOfMonthNum", "FortnightIndex", "FortnightYearMonthName", "CurrentFortnightYearMonthName", "FortnightYearMonthNum", "FortnightName", "FortnightNum", "FortnightOffset", "FortnightPeriod" } },
    { "Week of the Year (Standard)", new[] { "WeekYearName", "CurrentWeekYearName", "WeekYearNum", "WeekEnd", "WeekIndex", "WeekStart", "WeekNum", "WeekOffset", "WeekPeriod" } },
    { "Week of the Month (Standard)", new[] { "StandardWeekOfMonthYearName", "StandardWeekOfMonthYearNum", "StandardWeekOfMonthNum" } },
    { "Week of the Year (ISO)", new[] { "IsoWeekYearName", "CurrentIsoWeekYearName", "IsoWeekYearNum", "IsoWeekEnd", "IsoWeekIndex", "IsoWeekStart", "IsoWeekNum", "IsoWeekOffset" } },
    { "Semesters", new[] { "SemesterYearName", "CurrentSemesterYearName", "SemesterYearNum", "SemesterOfYearNum", "SemesterIndex", "SemesterOffset" } },
    { "Quarters", new[] { "QuarterYearName", "CurrentQuarterYearName", "QuarterYearNum", "QuarterEnd", "QuarterIndex", "QuarterStart", "QuarterNum", "QuarterOffset" } }
};

// Iterate through the folders and apply the DisplayFolder to each associated column
foreach (var folder in displayFolders)
{
    var folderName = folder.Key;
    var columns = folder.Value;

    foreach (var columnName in columns)
    {
        var column = dCalendar.Columns[columnName];
        if (column != null)
        {
            column.DisplayFolder = folderName; // Assign columns to the corresponding folder
        }
    }
}

// Disable aggregations for all columns in the table
foreach (var column in dCalendar.Columns)
{
    column.SummarizeBy = AggregateFunction.None;  // Disable aggregation
}

// Set the format for date-type columns
var dateColumns = new[] { "WeekEnd", "WeekStart", "YearEnd", "YearStart", "Date", "MonthEnd", "MonthStart", "IsoWeekEnd", "IsoWeekStart", "QuarterEnd", "QuarterStart" };  // Columns containing dates
foreach (var columnName in dateColumns)
{
    var column = dCalendar.Columns[columnName];
    if (column != null)
    {
        column.FormatString = "Short Date";  // Apply short date format
    }
}

// Mark as a date table
dCalendar.DataCategory = "Time";
dCalendar.Columns["Date"].IsKey = true;
