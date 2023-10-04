/**
 * @description A class representing a data table that can be used in LWC
 */
// performance test
// apex docs
// test classes
// package

global with sharing class JsnTbl {
   
 
    // Values to be ignored when creating the data table
    private Set<String> attributeFilter = new Set<String>{};

    // List names of this type will not be appended, this allows for a more flat table
    private Set<String> listNameFilter  = new Set<String>{};

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
        this.traverseParent(input, null);
        
        // Create the revised column index
        this.createColumnIndexMap();

        // Return self for method chaining
        return this;
    }


    /**
     * @description Method to set your custom column names
     *              This method should run after the create method, not that this takes
     *              will only override the output in the headers
     */
    global JsnTbl updateColumnNames(Set<String> columnNames){

        // Get the current column names
        String[] oldNames = this.getColumnNames();
        String[] newNames = new List<String>(columnNames);

        // To prevent the list going out of bounds we need to create a combined list
        // if the current list is greater than the new list
        if(oldNames.size() > newNames.size()){
            
            // Pad the new column names with the left over names from existing columns
            for(Integer i=newNames.size(),max=oldNames.size();i<max;i++){
                newNames.add(oldNames[i]);
            }  
        }
        // Update the column names
        this.columnNames = new Set<String>(newNames);

        // Return self
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

    global String getConsoleString(){

        // Run creation logic for CSV
        this.createCsvData();

        // The output string
        String table='';
    
        // Create a map to keep track of the column widths
        Map<Integer,Integer> maxColumnLengthMap = new Map<Integer,Integer>();
    
        // Iterate rows and columns
        for(Integer i=0,max= this.csvData.size(); i<max; i++){
            for(Integer j=0,jmax= this.csvData[i].size(); j<jmax; j++){
                // populate the column
                if(!maxColumnLengthMap.containsKey(j)){
                    maxColumnLengthMap.put(j,0);
                }
                // Define the length of the  this.csvData value
                Integer length = ( this.csvData[i][j] != null) ? String.valueOf( this.csvData[i][j]).length() : 0;
    
                // If there is a new greatest length, update the map
                if(length > maxColumnLengthMap.get(j)){
                    maxColumnLengthMap.put(j,length);
                }
            }
        }
    
        // Iterate rows and columns again and apply the correct padding and add a linebreak at the end of each line
        for(Integer i=0,max= this.csvData.size(); i<max; i++){
            String row = ''; 
            for(Integer j=0,jmax= this.csvData[i].size(); j<jmax; j++){
                row+= ( this.csvData[i][j] == null) ? ''.rightPad(maxColumnLengthMap.get(j) + 2) : String.valueOf( this.csvData[i][j]).rightPad(maxColumnLengthMap.get(j) + 2);
            }
            // Add the line to the table
            table += ((i!=0) ? row :  row.toUpperCase()) +'\n';
        }
    
        // Return the table 
        return table.removeEnd('\n');
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
    private void traverseParent(Object input, String path){
        if(input instanceof Map<String,Object>){
            traverseParentMap((Map<String,Object>)input, path);
        }else if(input instanceof Object[]){
            traverseParentList(        (Object[]) input, path);
        }else{
            traverseParentObject(                 input, path);
        }
    }


    private void traverseParentMap(Map<String,Object> input, String path){
        for(String key : input.keySet()){		

            // Create a new row for the parent
            Map<String,Object> row = new Map<String,Object>();
            
            // Continue if a property needs to be ignored
            if(this.hasAttributeFilter && this.attributeFilter.contains(key)){continue;}

            // Traverse all children
            traverseChild(input.get(key), ((String.isNotBlank(path)) ? path + '.' + key : key), row, false, 0);

            // Add the row to the table
            if(!row.isEmpty()){this.keyValueData.add(row);}
        }
    }


    private void traverseParentList(Object[] input, String path){

        // Some values in the list do not have a key, in this cases we need to use the index
        // i.e. the data looks like ["a","b","c", "d"]
        Integer objectIndex = 0;
        
        // In order to bundle the values without an attributes, create a single row
        Map<String,Object> attributeLessValuesRow = new Map<String,Object>();

        // Having this type casting again seems redundant, but doing the check in here
        // saves having to do it twice, what on 10k+ statements gives a small performance improvement
        for(Integer i=0, max=input.size();i<max;i++){
            
            // Create a new row to combine the values in the list
            Map<String,Object> row = new Map<String,Object>();

            // Handle each child object according to it's type
            if(input[i] instanceof Map<String,Object>){
                traverseChildMap((Map<String,Object>) input[i], path, row, false, null);
            }else if(input[i] instanceof Object[]){
                traverseChildList(         (Object[]) input[i], path, row, false, null);
            }else{
                traverseChildObject(                  input[i], path, attributeLessValuesRow, true, objectIndex);
                objectIndex++;
            }	
            
            // Add the row to the table
            if(!row.isEmpty()){this.keyValueData.add(row);}
        }

        // Add the row to the table
        if(!attributeLessValuesRow.isEmpty()){this.keyValueData.add(attributeLessValuesRow);}
    }


    /**
     * @description Method to handle a parent object like a Number, String or Boolean
     *              'true', ''"String"'', '123' are all valid JSON Strings, this method
     *              accomodates single value JSON just in case
     */ 
    private void traverseParentObject(Object input, String path){
        // Add the column name
        this.columnNames.add(String.valueOf(0));
        
        // Add the single value to the output
        this.keyValueData.add(
            new Map<String,Object>{
                String.valueOf(0) => input
            }
        );
    }


    /**
     * @description Child selector method, this method splits out the wat a child record needs to be handled
     *              based on the type. This makes sure the least amount of type casting has to be done.
     */
    private void traverseChild(Object input, String path, Map<String,Object> row, Boolean isObjectInlist, Integer objectIndex){
        if(input instanceof Object[]){
           
            // Allow top level lists names to be filtered out
            path = this.hasListNameFilter && this.listNameFilter.contains(path) && !path?.contains('.') ? '' : path;
 
            traverseChildList((Object[]) input, path, row, isObjectInlist, objectIndex);
        }else if(input instanceof Map<String,Object>){
            traverseChildMap((Map<String,Object>) input, path, row, isObjectInlist, objectIndex);
        }else{
            traverseChildObject(input, path, row, isObjectInlist, objectIndex);
        }
    }


    private void traverseChildMap(Map<String,Object> input, String path, Map<String,Object> row, Boolean isObjectInlist, Integer objectIndex){
        for(String key : input.keySet() ){

            // Continue if a property needs to be ignored
            if(this.hasAttributeFilter && this.attributeFilter.contains(key)){continue;}
        
            // Traverse self for each child record
            traverseChild(input.get(key), ((String.isNotBlank(path)) ? path + '.' + key : key), row, isObjectInlist, objectIndex);
        }
    }


    private void traverseChildList(Object[] input, String path, Map<String,Object> row, Boolean isObjectInlist, Integer objectIndex){
            
        // Allow to filter out certain list names. Note that this can have some funky results
        // Each list should be added as new records, so handle the list as a PARENT
        traverseParentList(
            input,
            (this.hasListNameFilter && this.listNameFilter.contains(path?.substringAfterLast('.'))) ? path?.substringBeforeLast('.') : path
        );
    }


    private void traverseChildObject(Object input, String path, Map<String,Object> row, Boolean isObjectInlist, Integer objectIndex){
        
        // Extract the path so it can be added in to the column names
        path = (isObjectInlist) ? ((String.isNotBlank(path)) ? path + '.' + objectIndex : String.valueOf(objectIndex)) : path;
        
        // If the object is in a list we need to add the list index as a key
        this.columnNames.add(path);
        
        // Add the value to the row		
        row.put(path,input);
    }
}