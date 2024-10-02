# dCalendar (Power Query M)

## Ready-to-use PBIX Download
[dcalendar-v6.0.pbix](https://github.com/alisonpezzott/dcalendar-powerquery/releases/tag/v6.0)

This version already includes the [dPeriods](https://github.com/alisonpezzott/dperiods-powerquery) table.

## Using the code in Power Query + Tabular Editor Script
1. Copy the code from [dcalendar.pq](dcalendar.pq);
2. In Power Query, create a new blank query;
3. Open the advanced editor and paste the code;
4. Adjust the settings in the steps;
5. Rename the query to dCalendar;
6. Close and apply;
7. Click on the `External Tools` menu;
8. Open the [Tabular Editor](https://www.sqlbi.com/tools/tabular-editor), which should already be installed;
9. Go to `File > Preferences > Features` and enable `Allow unsupported Power BI features`, then click `OK`;
10. Copy the code from [dcalendar-tabular-editor.cs](dcalendar-tabular-editor.cs) and paste it into the `C# Script` window, then click `Run` or press `F5`;
11. Then go to `File > Save` or press `Ctrl+S`;
12. Done! Go back to Power BI, and your dCalendar table will be complete, sorted, and organized.

## Using the code in Power Query + Manual Sorting
1. Copy the code from [dcalendar.pq](dcalendar.pq);
2. In Power Query, create a new blank query;
3. Open the advanced editor and paste the code;
4. Adjust the settings in the steps;
5. Rename the query to dCalendar;
6. Close and apply;
7. Based on the file [dcalendar-sorting.xlsx](dcalendar-sorting.xlsx), manually sort the columns, folders, and mark the table as a date.
