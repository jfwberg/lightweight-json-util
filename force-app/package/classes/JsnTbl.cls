/**
 * @description A class representing a data table that can be used in LWC
 */


// set column names as well
// use global list, not the passed in list

global with sharing class JsnTbl {
   
    // user updateable variables
    
    // Select this option to include child lists
    private Boolean includeChildLists = true;

    // Values to be ignored when creating the data table
    private Set<String> attributeFilter = new Set<String>{};

    // List names of this type will not be appended, this allows for a more flat table
    private Set<String> listNameFilter  = new Set<String>{};



    // app variables

    // Indicator if there are any attributes to check
    private Boolean hasAttributeFilter = false;

    // Indicator if there are any list name filters to check
    private Boolean hasListNameFilter = false;

    // A list of all the column names, can be used when auto generating a data table or CSV output
    private Set<String> columnNames = new Set<String>{};

    // Creates a list of column indexes when creaing the table, to map the location of the column names
    private Map<String,Integer> columnIndexMap = new Map<String,Integer>();
    
    // A data table structure that can be used in an LWC and for converting to other formats
    private List<Map<String,Object>> keyValueData = new List<Map<String,Object>>();

    // A data table in the format of a multi-dimentional index array
    private List<Object[]> indexedData = new List<Object[]>();

    // The output containing the CSV data
    private List<String[]> csvData = new List<String[]>();

    

    /** **************************************************************************************************** **
     **                                         GLOBAL SETTER METHODS                                          **
     ** **************************************************************************************************** **/
    /**
     * @description Method that allows you to ignore any child lists
     *              Any properties that that is an instance of Object[] will be
     *              filtered out. This allows for a clean table creation
     */
    global JsnTbl setIncludeChildLists(Boolean includeChildLists){
        this.includeChildLists = includeChildLists;
        return this;
    }


    /**
     * @description Method to enable the property filter
     *              Any properties that are part of this list will be ignored when generating
     *              the data table, so unused attributes are filtered out
     *              i.e. new Set<String>{'attributes', 'totalSize' , 'done'} 
     */
    global JsnTbl setAttributeFilter(Set<String> attributeFilter){
        this.attributeFilter = attributeFilter;
        return this;
    }


    /**
     * @description Method to enable the list name filter
     *              Any list names like "records" will NOT be appended to to the column name
     *              this allows for flatter tables, but might result in some funky results
     *              i.e. new Set<String>{'attributes', 'totalSize' , 'done'} 
     */
    global JsnTbl setListNameFilter(Set<String> listNameFilter){
        this.listNameFilter = listNameFilter;
        return this;
    }

    
    /** **************************************************************************************************** **
     **                                       GLOBAL SUPPORT METHODS                                         **
     ** **************************************************************************************************** **/
    /**
     * @description Create table from an untyped Object list
     */
    global JsnTbl create(Object input){
        
        // Setup the table
        this.initiateTable();

        // Set the attribute indicator so we do not have to check the set status on each iteration
        this.hasAttributeFilter = (attributeFilter!= null) && !this.attributeFilter.isEmpty();
        this.hasListNameFilter  = (listNameFilter != null) && !this.listNameFilter.isEmpty();
        
        // Execute logic
        this.traverseParent(input, null, this.keyValueData);
        
        // Create the revised column index
        this.createColumnIndexMap();

        // Return self for method chaining
        return this;
    }


    /** **************************************************************************************************** **
     **                                       GLOBAL GETTER METHODS                                         **
     ** **************************************************************************************************** **/
    global String[] getColumnNames(){
        return new List<String>(this.columnNames);
    }

    global Map<String,Integer> getColumnNameIndexMap(){
        return this.columnIndexMap;
    }



    global List<Map<String,Object>> getKeyValueData(){
        return this.keyValueData;
    }


    /**
     * @description Method to generate an indexed multi-dimentional array containing the data
     */
    global List<Object[]> getIndexedData(){
        
        // Run creation logic
        this.createIndexedData();

        // Return the indexed data
        return this.indexedData;
    }


    /**
     * @description Method to generate CSV data
     */
    global List<String[]> getCsvData(){
        
        // Run creation logic
        this.createCsvData();

        // Return the indexed data
        return this.csvData;
    }


    global String getCsvString(){
        
        // Run creation logic
        this.createCsvData();

        // Create a list to hold each joined csv line
        String[] csvLines = new String[]{};

        // Join each individual line
        for(Integer line=0, numLines=this.csvData.size();line<numLines;line++){
            csvLines.add(String.join(this.csvData[line],','));
        }
        // Return all lines joined by a return character, you might want to update this based on your required output
        return String.join(csvLines, '\n');
    }







    /** **************************************************************************************************** **
     **                                       PRIVATE SUPPORT METHODS                                        **
     ** **************************************************************************************************** **/
    
     private void initiateTable(){
         // Reset data on when creatin the table
         this.columnNames    = new Set<String>{};
         this.columnIndexMap = new Map<String,Integer>();
         this.keyValueData   = new List<Map<String,Object>>();
         this.indexedData    = new List<Object[]>();
         this.csvData        = new List<String[]>();
     }
    
     /**
     * @description Method to create a mapping between the column name and the index in the
     *              multi-dimentional array
     */
    private void createColumnIndexMap(){
        
        // Reset the variable on create
        this.columnIndexMap = new Map<String,Integer>();

        // Populate the map
        for(Integer i=0, max=this.columnNames.size(); i<max;i++){
            this.columnIndexMap.put(this.getColumnNames()[i], i);
        }
    }


    /**
     * @description Method to Pre-populate all values in the indexedData array
     * @param a
     * @param a
     * @param a
     * @trows
     */
    private void createIndex(List<Object[]> input, Integer additionalRows, Boolean stringList){

        // Create the rows
        for(Integer row=0, numRows = this.keyValueData.size() + additionalRows; row < numRows; row++){

            // Add a new row
            input.add(stringList ? new String[]{} : new Object[]{});
            
            for(Integer column=0, numColumns = this.getColumnNames().size(); column<numColumns;column++){
                // Add a new place holder column
                input[row].add(null);
            }
        }
    }


    private void createIndexedData(){
        
        // Only run the logic if there is no data yet
        if(this.indexedData.isEmpty()){
            
            // Setup the index data multi-dimentional array
            this.createIndex(this.indexedData, 0, false);

            // Populate the data in the correct columns
            for(Integer row=0, numRows = this.keyValueData.size(); row < numRows; row++){
                for(String key : this.keyValueData[row].keySet()){
                    this.indexedData[row][this.columnIndexMap.get(key)] = this.keyValueData[row].get(key);
                }
            }
        }
    }


    private void createCsvData(){
        
        // Only run the logic if there is no data yet
        if(this.csvData.isEmpty()){
            
            // Set an offset for the header row
            Integer offset = 1;

            // Setup the index data multi-dimentional array, add an additional row for the header
            this.createIndex(this.csvData, offset, true);

            // Add the CSV Header row
            for(Integer column=0, numColumns = this.getColumnNames().size(); column<numColumns;column++){
                // Add a new place holder column
                this.csvData[0][column] = this.getColumnNames()[column]?.escapeCsv();
            }

            // Populate the data in the correct columns
            for(Integer row=0, numRows = this.keyValueData.size(); row < numRows; row++){
                for(String key : this.keyValueData[row].keySet()){
                    this.csvData[row+offset][this.columnIndexMap.get(key)] = String.valueOf(this.keyValueData[row].get(key))?.escapeCsv();
                }
            }
        }
    }



    /** **************************************************************************************************** **
     **                                       PRIVATE TRAVERSE METHODS                                       **
     ** **************************************************************************************************** **/
    /**
     * @description Parent selector method, this method splits out how the top level record needs to be handled
     *              based on the type. This makes sure the least amount of type casting has to be done.
     */
    private void traverseParent(Object input, String path, List<Map<String,Object>> dataRows){
        if(input instanceof Map<String,Object>){
            traverseParentMap((Map<String,Object>)input, path, dataRows);
        }else if(input instanceof Object[]){
            traverseParentList(        (Object[]) input, path, dataRows);
        }else{
            traverseParentObject(                 input, path, dataRows);
        }
    }


    private void traverseParentMap(Map<String,Object> input, String path, List<Map<String,Object>> dataRows){
        
        // Create a new row for the parent
        Map<String,Object> row = new Map<String,Object>();
        
        // Iterate each key in the input map
        for(String key : input.keySet()){		
            
            // Continue if a property needs to be ignored
            if(this.hasAttributeFilter && this.attributeFilter.contains(key)){continue;}

            // Traverse all children
            traverseChild(input.get(key), ((String.isNotBlank(path)) ? path + '.' + key : key), row, dataRows, false, 0);
        }
        
        // Add the row to the table
        if(!row.isEmpty()){dataRows.add(row);}
    }


    private void traverseParentList(Object[] input, String path, List<Map<String,Object>> dataRows){
            
        // Create a new row to combine the values in the list
        Map<String,Object> row = new Map<String,Object>();
        
        // Some values in the list do not have a key, in this cases we need to use the index
        // i.e. the data looks like ["a","b","c", "d"]
        Integer objectIndex = 0;
        
        // Having this type casting again seems redundant, but doing the check in here
        // saves having to do it twice, what on 10k+ statements gives a small performance improvement
        for(Integer i=0, max=input.size();i<max;i++){
            if(input[i] instanceof Map<String,Object>){
                traverseChildMap((Map<String,Object>) input[i], path, row, dataRows, false, null);
            }else if(input[i] instanceof Object[]){
                traverseChildList(         (Object[]) input[i], path, row, dataRows, false, null);
            }else{
                traverseChildObject(                  input[i], path, row, dataRows, true, objectIndex);
                objectIndex++;
            }	
        }
        
        // Add the row to the table
        if(!row.isEmpty()){dataRows.add(row);}
    }


    /**
     * @description Method to handle a parent object like a Number, String or Boolean
     *              'true', ''"String"'', '123' are all valid JSON Strings, this method
     *              accomodates single value JSON just in case
     */ 
    private void traverseParentObject(Object input, String path, List<Map<String,Object>> dataRows){
        // Add the column name
        this.columnNames.add(String.valueOf(0));
        
        // Add the single value to the output
        dataRows.add(
            new Map<String,Object>{
                String.valueOf(0) => input
            }
        );
    }


    /**
     * @description Child selector method, this method splits out the wat a child record needs to be handled
     *              based on the type. This makes sure the least amount of type casting has to be done.
     */
    private void traverseChild(Object input, String path, Map<String,Object> row, List<Map<String,Object>> dataRows, Boolean isObjectInlist, Integer objectIndex){
        if(input instanceof Object[]){
           
            // Allow top level lists names to be filtered out
            path = this.hasListNameFilter && this.listNameFilter.contains(path) && !path?.contains('.') ? '' : path;
 
            traverseChildList((Object[]) input, path, row,dataRows, isObjectInlist, objectIndex);
        }else if(input instanceof Map<String,Object>){
            traverseChildMap((Map<String,Object>) input, path, row, dataRows, isObjectInlist, objectIndex);
        }else{
            traverseChildObject(input, path, row, dataRows, isObjectInlist, objectIndex);
        }
    }


    private void traverseChildMap(Map<String,Object> input, String path, Map<String,Object> row, List<Map<String,Object>> dataRows, Boolean isObjectInlist, Integer objectIndex){
        for(String key : input.keySet() ){

            // Continue if a property needs to be ignored
            if(this.hasAttributeFilter && this.attributeFilter.contains(key)){continue;}
        
            // Traverse self for each child record
            traverseChild(input.get(key), ((String.isNotBlank(path)) ? path + '.' + key : key), row, dataRows, isObjectInlist, objectIndex);
        }
    }


    private void traverseChildList(Object[] input, String path, Map<String,Object> row, List<Map<String,Object>> dataRows, Boolean isObjectInlist, Integer objectIndex){
            
        // Allow to filter out certain list names. Note that this can have some funky results
        // Each list should be added as new records, so handle the list as a PARENT
        traverseParentList(
            input,
            (this.hasListNameFilter && this.listNameFilter.contains(path?.substringAfterLast('.'))) ? path?.substringBeforeLast('.') : path,
            dataRows
        );
    }


    private void traverseChildObject(Object input, String path, Map<String,Object> row, List<Map<String,Object>> dataRows, Boolean isObjectInlist, Integer objectIndex){
        
        // Extract the path so it can be added in to the column names
        path = (isObjectInlist) ? ((String.isNotBlank(path)) ? path + '.' + objectIndex : String.valueOf(objectIndex)) : path;
        
        // If the object is in a list we need to add the list index as a key
        this.columnNames.add(path);
        
        // Add the value to the row		
        row.put(path,input);
    }
}