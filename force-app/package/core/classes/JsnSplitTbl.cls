/**
 * @author      Justus van den Berg (jfwberg@gmail.com)
 * @date        July 2024
 * @copyright   (c) 2024 Justus van den Berg
 * @license     MIT (See LICENSE file in the project root)
 * @description Class that converts JSON with nested objects to flat values and splits out
 *              each child list to it's own individual list using the path as map key
 *              The parent map key is called "parent", child map keys are based on the
 *              path like: "Opportunities" or Opportunities.OpportunityContactRoles
 * @use case    The main use case is to transform SOQL query results that can be used
 *              for exporting CSV or XLSX data that require individual tables for child lists.
 *              A secondary use is to store related data for archiving purposes where a 
 *              potential reverse loading of related data might be required.
 */
@SuppressWarnings('PMD.OneDeclarationPerLine, PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.ExessiveParameterList')
global with sharing class JsnSplitTbl {

    /** **************************************************************************************************** **
     **                                          PRIVATE VARIABLES                                           **
     ** **************************************************************************************************** **/
    // Values to be ignored when creating the data table
    private Set<String> attributeFilter = new Set<String>{};

    // List names of this type will not be appended, this allows for a more flat table
    private Set<String> listNameFilter  = new Set<String>{};

    // Indicator if there are any attributes to check
    private Boolean hasAttributeFilter = false;

    // Indicator if there are any list name filters to check
    private Boolean hasListNameFilter = false;

    // Filter out the base path like "parent.opportunities" from the names
    private Boolean filterPathNamesInChildTables = true;

    // Each table has a unique key, used in tableColumnMap
    private Set<String> listPaths = new Set<String>{};

    // Mapping between the table path and the table columns
    private Map<String, Set<String>> tableColumnMap  = new Map<String, Set<String>>();

    // Mapping between the table path and the table data
    private Map<String,List<Map<String,Object>>> tableDataMap = new Map<String,List<Map<String,Object>>>();


    /** **************************************************************************************************** **
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    // Path name to reference the parent
    @TestVisible private static final String PARENT_TABLE_PATH = 'parent';

    // (Error) Messages
    @TestVisible private static final String MSG_UNSUPPORTED_JSON_FORMAT = 'Unsupported JSON structure, only objects and lists are allowed';


    /** **************************************************************************************************** **
     **                                         GLOBAL SETTER METHODS                                        **
     ** **************************************************************************************************** **/
    /**
     * @description Method to enable the property filter
     *              Any properties that are part of this list will be ignored when generating
     *              the data table, so unused attributes are filtered out
     *              i.e. new Set<String>{'attributes', 'totalSize' , 'done'}
     * @param  attributeFilter The set of values to filter
     * @return      Self
     */
    global JsnSplitTbl setAttributeFilter(Set<String> attributeFilter){
        this.attributeFilter = attributeFilter;
        return this;
    }


    /**
     * @description Method to enable the list name filter
     *              Any list names like "records" will NOT be appended to to the column name
     *              this allows for shorted column names, but might result in some funky results
     * @param  listNameFilter The set of values to filter
     * @return      Self
     */
    global JsnSplitTbl setListNameFilter(Set<String> listNameFilter){
        this.listNameFilter = listNameFilter;
        return this;
    }


    /** **************************************************************************************************** **
     **                                   GLOBAL CREATE SUPPORT METHODS                                      **
     ** **************************************************************************************************** **/
    /**
     * @description Create table from an untyped Object list
     * @param input The object to create the table from (Untyped JSON maps)
     * @return      Self
     */
    global JsnSplitTbl create(Object input){

        // Input validation
        if(input == null){throw new StringException('Table input cannot be null');}
        
        // Set the attribute indicator so we do not have to check the set status on each iteration
        this.hasAttributeFilter = (attributeFilter!= null) && !this.attributeFilter.isEmpty();
        this.hasListNameFilter  = (listNameFilter != null) && !this.listNameFilter.isEmpty();

        // By default we exepect a list of objects
        if(input instanceof Object[]){
            this.traverseList(
                (Object[]) JSON.deserializeUntyped(JSON.serialize(input)),
                PARENT_TABLE_PATH
            );
        
        // If the input is a single result, wrap it into a list and execute as normal
        }else if(input instanceof Map<String,Object>){
            this.traverseList(
                (Object[]) JSON.deserializeUntyped(JSON.serialize(new Object[]{input})),
                PARENT_TABLE_PATH
            );    
        }
    
        // Return self
        return this;
    }


    /** **************************************************************************************************** **
     **                                       GLOBAL GETTER METHODS                                          **
     ** **************************************************************************************************** **/
    /**
     * @description Returns the map with table data
     * @return      A map with table data based on the JSON path
     */
    global Map<String,List<Map<String,Object>>> getTableDataMap(){
        return this.tableDataMap;
    }


    /**
     * @description Method to get a map with the table column names
     * @return      A map with a list of the column names for each table
     */
    global Map<String, Set<String>> getTableColumnMap(){
        return this.tableColumnMap;
    }


    /** **************************************************************************************************** **
     **                                       PRIVATE TRAVERSE METHODS                                       **
     ** **************************************************************************************************** **/
    /**
     * @description Traverse the parent list 
     * @param input The input to traverse
     * @param path  The location in the traverse path
     */
    private void traverseList(Object[] input, String path){

        // Each list goes into it's own flat table, so create the empty set, map and 
        // populate the lists paths
        if(!this.listPaths.contains(path)){
            this.tableColumnMap.put( path, new Set<String>{});    
            this.tableDataMap.put(path, new List<Map<String,Object>>());
            this.listPaths.add(path);
        }
        
        // Having this type casting again seems redundant, but doing the check in here
        // saves having to do it twice, what on 10k+ statements gives a small performance improvement
        for(Integer i=0, max=input.size();i<max;i++){

            // Create a new row to combine the values in the list
            Map<String,Object> row = new Map<String,Object>();

            // Handle each child object according to it's type
            if(input[i] instanceof Map<String,Object>){
                this.traverseMap((Map<String,Object>) input[i], row, path, path);
            
            // If the child is a list, traverse the child list
            }else if(input[i] instanceof Object[]){
                this.traverseList(
                    (Object[]) input[i],
                    (this.hasListNameFilter && this.listNameFilter.contains(path?.substringAfterLast('.'))) ?
                        path?.substringBeforeLast('.') :
                        path
                );
            }else{
                throw new JSONException(MSG_UNSUPPORTED_JSON_FORMAT);
            }
            
            // After the traversal is complete, Add the full row to the table
            if(!row.isEmpty()){this.tableDataMap.get(path).add(row);}
        }
    }


    /**
     * @description Method to traverse a map
     * @param input    The input to traverse
     * @param row      The current row in the traverse path
     * @param path     The location in the traverse path
     * @param listPath The current list path (map key) in the traverse path
     */
    private void traverseMap(Map<String,Object> input, Map<String,Object> row, String path, String listPath){
        
        // Iterate all the values in the input
        for(String key : input.keySet() ){

            // Continue if an attribute needs to be ignored
            if(this.hasAttributeFilter && this.attributeFilter.contains(key)){continue;}

            // Create the path for the specfic child node
            String childPath = ((String.isNotBlank(path) && path != PARENT_TABLE_PATH) ? path + '.' + key : key);

            // If the child node is an object list, traverse as list
            if(input.get(key) instanceof Object[]){
                this.traverseList(
                    (Object[]) input.get(key),
                    (this.hasListNameFilter && this.listNameFilter.contains(childPath?.substringAfterLast('.'))) ?
                        childPath?.substringBeforeLast('.') :
                        childPath
                );
            
            // If the child node is an object, (i.e. owner.name), traverse as map
            }else if(input.get(key) instanceof Map<String,Object>){
                this.traverseMap(
                    (Map<String,Object>) input.get(key),
                    row,
                    childPath,
                    listPath
                );

            // If it's not a map or a list, it must a value, so add the value to row
            }else{
                this.populateRow(
                    input.get(key),
                    childPath,
                    row,
                    listPath
                );
            }
        }
    }


    /**
     * @description Method to add the value to a row at the end of a traversel path
     * @param input    The input to traverse
     * @param path     The location in the traverse path
     * @param row      The current row in the traverse path
     * @param listPath The current list path (map key) in the traverse path
     */
    private void populateRow(Object input, String path, Map<String,Object> row, String listPath){
        
        // Create the column name of the column where the data is stored
        // Optionally remove the list path from the object value
        String columnName = this.filterPathNamesInChildTables ? path.removeStart(listPath).removeStart('.') : path;

        // Add the path names so we can generate a table header in case
        // not every record has an actual value as part of the JSON object
        this.tableColumnMap.get(listPath).add(columnName);

        // Add the value to the row		
        row.put(columnName,input);
    }
}