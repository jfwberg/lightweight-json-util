# Lightweight - JSON Util
A lightweight Apex utility that allows for easy getting the nested data of an untyped JSON Object Map using a path with dot notation i.e. Owner.Profile.Name.
The JSON Table Utility transforms nested key/value data structures into a flat data table structure that can be used in Apex, FLows, LWCs or Visualforce.
It handles multiple data output formats including CSV and is optimised for the use of Salesforce REST Query API Responses.

## Dependency info
| Info | Value |
|---|---|
|Name|Lightweight - Apex Unit Test Util v2|
|Version|2.3.0-1|
|Managed Installation URL | */packaging/installPackage.apexp?p0=04tP30000007oePIAQ*
|Unlocked Installation URL| */packaging/installPackage.apexp?p0=04tP30000007og1IAA*
|Github URL | https://github.com/jfwberg/lightweight-apex-unit-test-util-v2

## Package Info
| Info | Value |
|---|---|
|Name|Lightweight - JSON Util|
|Version|0.4.0-1|
|Managed Installation URL | */packaging/installPackage.apexp?p0=04tP30000008cL3IAI*
|Unlocked Installation URL| */packaging/installPackage.apexp?p0=04tP30000008cMfIAI* 


## Methods to fetch Objects, Object Maps and Object Lists from an untyped Object Map
If you have a complex data structure and have used ```JSON.deserializeUntyped()``` you can get a complex set of deeply nested untyped object values, lists and data structures.
To simplify getting a specific data from a number levels deep this utility's ```Jsn``` class contains methods that can be leveraged to make this process easier, less verbose and more readable.

|Method|Data Type|Description|
|--------|-------------|---|
|``` setThrowException(Boolean )```                          | void              | When set to true a ```utl.JsonUtilException``` exception is thrown if a requested path does not exist. When false, a null value is returned. The default value is *true*. I.e. ```Jsn.setThrowException(true);```|
|``` getObject(String path, Map<String, Object> input)```    | Object            | Method to get a value out of a map. I.e. ```String ownerProfileName = (String) utl.Jsn.getObject('Owner.Profile.Name', dataMap); ``` Note: This object type requires you to cast it to the data type you need.|
|``` getObjectMap(String path, Map<String, Object> input)``` | Map<String,Object>| Method to get a value out of a map. I.e. ```Map<String,Object> contactData = utl.Jsn.getObject('Contacts', dataMap); ``` Note: Casting goes automatically|
|``` getObjectList(String path, Map<String, Object> input)```| Object[]          | Method to get a value out of a map. I.e. ```Object[] contactRecords = utl.Jsn.getObjectList('Contacts.records', dataMap); ``` Note: Casting goes automatically|

### Example
Let's say we have a query response that had queried some account data with a sub query for contacts that goes a couple levels deep to fetch the profile name of the contact record owner. We would need to go through a series of objects lists and object maps to get to the data.

We'd have something like  ```toplevelObject.records[].Contacts.records[].Owner.Profile.Name``` to get all the way down the the profile name for the contacts.

There is no nice simple unified way to handle lists, so we have to do a couple of loops, but we can make the code a lot simpler, more readable by simply adding the methods as loop variables and do the type casting in the method calls.

This method decreases the heap size significantly and it saves a lot of lines of code compared writing this with boiler plate code. CPU time is roughly the same.
```java
// Iterate the account records
for(Object accountRecord : utl.Jsn.getObjectList('records', (Map<String,Object>) JSON.deserializeUntyped(jsonString))){
    
    // Iterate the contact records
    for(Object contactRecord : utl.Jsn.getObjectList('Contacts.records', (Map<String,Object>) accountRecord)){
        
        // Get the profile name of the contact owner
        String contactOwnerProfileName = (String) utl.Jsn.getObject('Owner.Profile.Name',(Map<String,Object>) contactRecord);
    }
}
```

## Methods to generate Data Table or a CSV formats
The ```JsnTbl``` class allows you to automatically convert your input JSON Object Maps to flat data table structutes that can be used in Apex, Flow, LWC or Visualforce.

The goal is to combine nested JSON into a flat table type and combine the headers in a dot type notation and optimise it for Salesforce REST API Query Result format, but still keep it usable for any result format, like Date Cloud Queries.
```json
[
    {
        "Name" : "My First Account"
        "Owner": {"Name" : "Henk de Vries"}
    },
    {
        "Name" : "My Second Account"
        "Owner": {
            "Name" : "Henk de Bruin",
            "Profile" : {
                "Name" : "System Administrator"
            }
        }
    }
]
```
This results into a table that looks like this
|Name|Owner.Name|Owner.Profile.Name|
|--------|-------------|-----------|
|My First Account|Henk de Vries||
|My Second Account|Henk de Bruin|System Administrator|


It also works with a Data Cloud API format where you have an indexed set of result. This is a bit more tricky to handle as there are no key/column names that you can use.

To overcome this issue, the table headers will be numbered based on the index they have in a list

```json
[
    ["a","b","c"],
    ["d","e","f","g","h"],
    ["i","j"]
]
```
This results into a table that looks like this. There is a method ```updateColumnNames(Set<String>)``` that allow you to override the column names so you can set them yourself
|0|1|2|3|4|
|-|-|-|-|-|
|a|b|c|
|d|e|f|g|h|
|i|j|


Column headers are stored in the order they appear in the JSON and cannot be sorted or filtered through this library. This will require some additional custom logic.

## Output (table) formats
|Type|format Example|Data Type|Note|
|--------|-------------|---|---|
|Key Value Pairs|```[{"row_1_col_1" : "row_1_col_1_value", "row_1_col_2" : "row_1_col_2_value"}, {"row_2_col_1" : "row_2_col_1_value", "row_2_col_2" : "row_2_col_2_value"}]``` | ```List<Map<String,Object>>```| Ideal for Javascript handling
|Indexed Data   |```[["row_1_col_1_value","row_1_col_2_value"],["row_2_col_1_value","row_2_col_2_value"]]``` |```List<List<Object>>```|Allows for the use of matrix indexes i.e. ```value = table[1][19]```|
|CSV Data       |```[["header_col_1","header_col_2"],["row_1_col_1_value","row_1_col_2_value"],["row_2_col_1_value","row_2_col_2_value"]]``` |```List<List<String>>```|Same as Indexed but all values are Strings and CSV escaped|
|CSV String     |```"header_col_1", "header_col_2" <br/> "row_1_col_1_value","row_1_col_2_value" <br/> "row_2_col_1_value","row_2_col_2_value"``` |```String```|CSV data converted to a usable CSV string|
|Console String |```"header_col_1", "header_col_2" <br/> "row_1_col_1_value","row_1_col_2_value" <br/> "row_2_col_1_value","row_2_col_2_value"``` |```String```|Table data converted to a human readable spaced string that is readable in a console, this is mainly for debugging and previewing purposes|


## Create a JSON Data Table
### Construct
You start with a basic constructor, configure using the configuration methods, create the table based on a list or object and finish with a method to get the table or CSV data.
```java 
// Standard constructor to create a new table
utl.JsnTbl table = new utl.JsnTbl();
```
### Configure
A JSON Data table is configured using a number of methods to override the default behaviour.

| Method | Description |Default|
|--------|-------------|-------------|
| ```setListNameFilter(Set<String>)```  | This allows you to remove the name from attributes containing a child list. I.e. if the list attribute name is *records* like "Contacts.records.FistName", the list name is removed resulting in: "Contacts.FirstName"<br /> This is really handy when you are working with the Salesforce Query Rest API to get Clean results like "Contacts.Owner.Profile.Name" |true|
| ```setAttributeFilter(Set<String>)``` | This allows you to specify attributes names you want to filter out. For example if you work with Salesforce REST API Query results, you might want to filter out the attributes and query result details for display purposes and only show the data attributes. You can do that using a filter like:  ```new Set<String>{'attributes', 'totalSize', 'done'}``` |null|

### Create
Once you have setup your class you're now ready to create the data content with the configuration.
Optionally you can fill your columns with null values. 

| Method | Description |
|--------|-------------|
| ```create(Object)``` | Create your table from an Object List, this will usually be ```JSON.deserializeUntyped(jsonString)```. But you can typecast the response as well|
| ```fillColumnsWithNullValue(Set<String> columnNames)``` | This creates a key for each record where that key does not exist and is required when concatenating column data in the manipulate section


### Manipulate
Once you have created your table and you can now add new static columns or remove columns you don't need
| ```upsertColumnData(String columnName, Object[] columnValues, Integer columnIndex)``` | This needs to run after the create method. It allows you to add a column or update a columm. This can be useful to add a number column or an UUID column or override an random id number or timestamp. It can also be handy if you need to add any static column data for system updates. |
| ```concatColumnData(Set<String> columnNames, String glue, String outputColumnName,  Integer outputColumnIndex)``` | This method concates the data multiple columns and puts them in a new column. This is useful to generate combined keys. Its uses the above method but has a pre-built most used method.|
| ```deleteColums(Set<String> columnNames``` | This method allows you to remove columns you don't need from the table |

### Update headers
Once you have created your table and you are done adding or removing columns you have to options to rename the headers of your columns. Always run this method last to prevent null pointer exceptions

| Method | Description |
| ```updateColumnNames(Set<String>)```        | This needs to run after the create methods. It allows you to set your own column names. These need to be in order of the data. This is especially useful when you have a Data Cloud Query response.|
| ```updateColumnNames(Map<String,String>)``` | This needs to run after the create methods. It allows you to set your own column names. This can be any number of values as long as the source column name has a matching target name. This is really useful when you need to convert CSV headers to a target system.|

### Use
Once your table is created you can now extract the data using one of the following methods

| Method | Data Type |Description|
|--------|-------------|----|
| ```getKeyValueData()```      | ```List<Map<String,Object>>``` |Get a key/value pair data structure|
| ```getIndexedData()```       | ```List<Object[]>```           |Get a multi-dimentional array data structure|
| ```getCsvData()```           | ```List<String[]>```           |Get a multi-dimentional array with header row and csv encoded values|
| ```getCsvString()```         | ```String```                   |Get a CSV formatted String|
| ```getConsoleString()```     | ```String```                   |Get a human readable formatted table with equally spaced out columns based on the largest value (Testing only and resource intensive, not for large tables and expect CPU or heap size issues)|
| ```getColumnNames()```       | ```String[]```                 |Get a list of column names in the order of the JSON input|
| ```getColumnNameIndexMap()```| ```Map<String,Integer>```      |Get a mapping between the column header name and the location of the column|

## Examples
### Full example usising an Object map as input
```java
String jsonString = '[{"records" : [[1,2,3],[4,5,6]], "mapData" : {"TopLevel" : "data", "child" : {"Name" : "myChild"}}, "done" : true}]';

// Create a data table from a Salesforce API query response
utl.JsnTbl table = new utl.JsnTbl()
    .setListNameFilter(new Set<String>{'records'})
    .setAttributeFilter(new Set<String>{'done'})
    .create(JSON.deserializeUntyped(jsonString))
	.updateColumnNames(new Set<String>{'Column A', 'Column B', 'Column C'})
;

// Methods to get the data type you require
List<Map<String,Object>> keyValueData   = table.getKeyValueData();
List<Object[]>           indexedData    = table.getIndexedData();
List<String[]>           csvData        = table.getCsvData();
String                   csvFile        = table.getCsvString();
String                   consoleData    = table.getConsoleString();
	
// Methods to get column info
String[]                 columnNames    = table.getColumnNames();
Map<String,Integer>      columnIndexMap = table.getColumnNameIndexMap();

System.debug(consoleData);
```
This outputs:
```txt
COLUMN A  COLUMN B  COLUMN C  MAPDATA.TOPLEVEL  MAPDATA.CHILD.NAME  
1         2         3                                               
4         5         6                                               
                              data              myChild                   
```

## Multi Dimentional Array Example
```java
String jsonString = '[[1.1,1.2,1.3],[2.1,2.2,2.3],[3.1,3.2,3.3,3.4]]';

// Create a data table from a Salesforce API query response
utl.JsnTbl table = new utl.JsnTbl()
    .create(JSON.deserializeUntyped(jsonString))
	.updateColumnNames(new Set<String>{'Column A', 'Column B', 'Column C','Column D'})
;
```
This outputs:
```txt
COLUMN A  COLUMN B  COLUMN C  COLUMN D  
1.1       1.2       1.3                 
2.1       2.2       2.3                 
3.1       3.2       3.3       3.4       
```



### Default values example
```java
utl.JsnTbl table = new utl.JsnTbl()
    .create(JSON.deserializeUntyped(jsonString))
;

List<Map<String,Object>> keyValueData = table.getKeyValueData();
```

### Exception handling example
Depending on the type of exception, you might want to handle messaging slightly different for different scenarios. This example shows a way of handling the different types
```java
try{
    
    // Offending code here
    
}catch(Exception e){
    
    // Handle JSON related exceptions
    if(       e.getTypeName() == String.valueOf(System.JSONException.class)){
        System.debug('Invalid JSON Exception: ' + e.getMessage()); 
    
    // Handle JSON Util related Exceptions
    }else if (e.getTypeName() == String.valueOf(utl.Jsn.JsonUtilException.class)){
        System.debug('JSON Util Exeption: '     + e.getMessage()); 
    
    // Handle Unknown Exceptions
    }else {
        System.debug('Unknown Exeption: '       + e.getMessage());
    }
}
```

### Simple Data Cloud Example
```java
/**
 * SIMPLE EXAMPLE
 */
// Query callout to named credential with error handling
utl.Rst callout = new utl.Rst('DC_ORG_01', true)
	.setHandleSfEndpoint(false)
    .setEndpoint('/api/v2/query')
    .setMethod('POST')
	.setBody('{"sql" : "SELECT ssot__Id__c, ssot__Name__c, ssot__Number__c, ssot__AccountTypeId__c, ssot__BillContactAddressId__c, ssot__CreatedDate__c, ssot__DataSourceId__c, ssot__DataSourceObjectId__c FROM ssot__Account__dlm LIMIT 100"}')
    .call()
;

// Create a datatable
utl.JsnTbl table = new utl.JsnTbl()
	.setAttributeFilter(new Set<String>{'startTime','endTime','rowCount','queryId','done','metadata','nextBatchId'})
	.setListNameFilter(new Set<String>{'data'})
    .create(JSON.deserializeUntyped(callout.getResponse().getBody()))
	.updateColumnNames(new Set<String>{'Id','Name','Number','Account Type Id','Billing Address Id','Created Date','Data Source Id','Data Source Object'})
;

// Creeate a number list
// Note: Try to always do this on the key value data. This data gets always created
// Indexed data and CSV data are only created once the method is called)
Object[] columnData =  new Object[]{};
for(Integer i = 1, max=table.getKeyValueData().size(); i <= max; i++){
    columnData.add(i);
}

// Add the number list at the start of the table
table.upsertColumnData('#', columnData, 0);

// Data table output in the console
System.debug(table.getConsoleString());
```

### Data Cloud Example with headers from response
```java
// Query callout to named credential
utl.Rst callout = new utl.Rst('DC_ORG_01', true)
    .setHandleSfEndpoint(false)
    .setEndpoint('/api/v2/query')
    .setMethod('POST')
	.setBody('{"sql" : "SELECT ssot__Id__c, ssot__Name__c, ssot__Number__c, ssot__AccountTypeId__c, ssot__BillContactAddressId__c, ssot__CreatedDate__c, ssot__DataSourceId__c, ssot__DataSourceObjectId__c FROM ssot__Account__dlm LIMIT 100"}')
    .call()
;

// Parse the top level map to split the data and metadata maps
Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(callout.getResponse().getBody());
Map<String,Object> metadataMap = utl.Jsn.getObjectMap('metadata',responseMap);

// Create a mapping between column index and column name
Map<Integer,String> columnIndexMap = new Map<Integer,String>();

// Create a new set for the column names
Set<String> columnNamesInOrder = new Set<String>{};

// Iterate the metadata to get the columns
for(String key : metadataMap.keySet()){
	columnIndexMap.put(
		(Integer) utl.Jsn.getObject('placeInOrder', (Map<String,Object>) metadataMap.get(key)),
		key
	);
}

// Create an ordered list
for(Integer i=0,max=columnIndexMap.size(); i<max;i++){
	columnNamesInOrder.add(columnIndexMap.get(i));
}

// Create a datatable
utl.JsnTbl table= new utl.JsnTbl()
    .create(utl.Jsn.getObjectList('data',responseMap))
	.updateColumnNames(columnNamesInOrder)
;

// Data table output in the console
System.debug(table.getConsoleString());
```