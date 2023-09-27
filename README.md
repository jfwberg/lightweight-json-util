# Lightweight - JSON Util
A lightweight Apex utility that allows for easy traversing of untyped JSON Object Maps using a path with dot notation.
It has the ability to transform nested data structures into a flat data table structure that can be used in LWCs.


## Object Map/List Traverse methods

# Data Tables / CSV
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
|My Second Account|Henk de Bruin|Owner.Profile.Name|


The Column headers are stored in the order they appear in the JSON and cannot be sorted or filtered through this library. This will require some additional custom logic.

## Output (table) formats
|Type|format Example|Data Type|Note|
|--------|-------------|---|---|
|Key Value Pairs|```[{"row_1_col_1" : "row_1_col_1_value", "row_1_col_2" : "row_1_col_2_value"}, {"row_2_col_1" : "row_2_col_1_value", "row_2_col_2" : "row_2_col_2_value"}]``` | ```List<Map<String,Object>>```| Ideal for Javascript handling
|Indexed|```[["row_1_col_1_value","row_1_col_2_value"],["row_2_col_1_value","row_2_col_2_value"]]``` |```List<List<Object>>```|Allows for the use of matrix indexes i.e. ```value = table[1][19]```|
|CSV Data|```[["header_col_1","header_col_2"],["row_1_col_1_value","row_1_col_2_value"],["row_2_col_1_value","row_2_col_2_value"]]``` |```List<List<String>>```|Same as Indexed but all values are Strings and CSV escaped|
|CSV String|```"header_col_1", "header_col_2" <br/> "row_1_col_1_value","row_1_col_2_value" <br/> "row_2_col_1_value","row_2_col_2_value"``` |```String```|



### Construct
You start with a basic constructor, configure using the configuration methods, create the table based on a list or object and finish with a method to get the table or CSV data.
```java 
// Standard constructor to create a new table
utl.JsnTbl table = new utl.JsnTbl();
```
### Data table configuration methods
A JSON Data table is configured using a number of methods to override the default behaviour.

| Method | Description |Default|
|--------|-------------|-------------|
| ```setIncludeChildLists(Boolean)```             | Includes nested list objects. I.e. if you have sub query results, these will be included | true |
| ```setAddChildListsAsTables(Boolean)```         | When set to true, each child list is handled a nested JsnTbl Object. This is handy when you want to create displays that have nested tables with their own headers.<br />Set to false to join child lists to the main flat table as individual columns.            |false|
| ```setHideChildListAttributeFromPath(Boolean)```| When set to true, the name of the attribute containing the child list is removed. I.e. if the list attribute name is *records* like "Contacts.records.FistName", the list name is removed resulting in: "Contacts.FirstName"<br /> This is really handy when you are working with the Salesforce Query Rest API to get Clean results like "Contacts.Owner.Profile.Name" |true|
| ```setAttributeFilter(Set<String>)```           | This allows you to specify attributes names you want to filter out. For example if you work with Salesforce REST API Query results, you might want to filter out the attributes and query result details for display purposes and only show the data attributes. You can do that using a filter like:  ```new Set<String>{'attributes', 'totalSize', 'done'}``` |null|

### Data table create methods
Once you have setup your data

| Method | Description |
|--------|-------------|
| ```createFromObjectList(List<Object>)```      | Includes nested list objects. I.e. if you have sub query results, these will be included |
| ```createFromObjectMap(Map<String,Object>)``` | Create your table from a |







### Example
```java
utl.JsnTbl table = new utl.JsnTbl()
     utl.JsnTbl table = new utl.JsnTbl()
        .setIncludeChildLists(true)
		.setAddChildListsAsTables(false)
		.setHideChildListAttributeFromPath(true)
        .setPropertyFilter(new Set<String>{'attributes', 'done' })
        //.createFromObjectList(utl.Jsn.getObjectList('records',(Map<String,Object>) JSON.deserializeUntyped(jsonString)));
		.createFromObjectMap((Map<String,Object>) JSON.deserializeUntyped(jsonString));

```


## Create data table Objects

