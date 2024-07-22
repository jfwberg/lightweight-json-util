/**
 * Optimize with list instead of lists mpas where a mapping is used betweein index and path
 */
String  query  = 'SELECT Id, Name, Owner.Name, Owner.Profile.Name, ';
        query +='(SELECT AccountId, FirstName, LastName, Owner.Profile.Name FROM contacts LIMIT 10), ';
        query +='(SELECT AccountId, Name, StageName, CloseDate, Owner.Profile.Name, (SELECT Id, ContactId FROM OpportunityContactRoles) FROM opportunities LIMIT 10) ';
        query +='FROM Account WHERE Name LIKE \'Demo Account - %\' ORDER BY Name ASC LIMIT 1000';



// Create a new JSON Table Split Utility
utl.JsnSplitTbl jsnSplitTbl = new utl.JsnSplitTbl()

    // Filter out any attribute values
    .setAttributeFilter(new Set<String>{'attributes','done','totalSize'})

    // Remove the name records from the lists paths to make it more readable
    .setListNameFilter(new Set<String>{'records'})

    // Execute the creation logic
    .create(Database.Query(query))
;

// Method to get the individual columns
Map<String, Set<String>> tableColumnMap = jsnSplitTbl.getTableColumnMap();

// Get a mapping with all data
Map<String,List<Map<String,Object>>> tableDataMap = jsnSplitTbl.getTableDataMap();

// Debug info
System.debug(JSON.serializePretty(tableColumnMap));
System.debug(JSON.serialize(tableDataMap));