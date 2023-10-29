/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           May 2023
 * @copyright      (c) 2023 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class that converts JSON to a data table that can be used in LWC or as a CSV
 * @false-positive PMD.AvoidGlobalModifier This is a utility that is designed to be called from a
 *                                         managed package. It can be used for a user's own custom
 *                                         Implementation, so global is the way to open up this
 *                                         utility for global use.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.OneDeclarationPerLine, PMD.ExcessiveParameterList, PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
global with sharing class JsnTbl {
   
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
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    @TestVisible private static final String INVALID_VALUE_SIZE_MSG    = 'The number of additional values cannot exceed the number of values in the table.';
    @TestVisible private static final String INVALID_COLUMN_NAME_MSG   = 'The column name cannot be blank.';
    @TestVisible private static final String COLUMN_DOES_NOT_EXIST_MSG = 'The column name "{0}" does not exist.';
    @TestVisible private static final String EMPTY_COLUMNS_MSG         = 'The set of Column names cannot be empty.';

    

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
    global JsnTbl setAttributeFilter(Set<String> attributeFilter){
        this.attributeFilter = attributeFilter;
        return this;
    }


    /**
     * @description Method to enable the list name filter
     *              Any list names like "records" will NOT be appended to to the column name
     *              this allows for flatter tables, but might result in some funky results
     *              i.e. new Set<String>{'attributes', 'totalSize' , 'done'} 
     * @param  listNameFilter The set of values to filter
     * @return      Self
     */
    global JsnTbl setListNameFilter(Set<String> listNameFilter){
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
     * @description Sometimes not each key/value pair exists for each record.
     *              This can lead to issues when updating values. Use this method to add
     *              the missing key/value pair to records that do not have them.
     * @param columnNames The names of columns that will be added as a key item for records
     *                    that do not have the specific key
     * @return self
     */
    global JsnTbl fillColumnsWithNullValue(Set<String> columnNames){

        // Validate the input
        validateColumnNames(columnNames);

        // Convert to string list for faster iterations later.
        // Seems overkill but integer loops are significantly faster when we're talking about 1000+ rows
        String[] columnNameList = new List<String>(columnNames);
        Integer numberOfColumns = columnNames.size();

        // Iterate each record in the row
        for(Integer i = 0, max=this.keyValueData.size(); i < max; i++){
            
            // If the record does not contain a certain key, add a null value
            for(Integer j = 0; j < numberOfColumns; j++){
                if(!this.keyValueData[i].containsKey(columnNameList[j])){
                    this.keyValueData[i].put(columnNameList[j],null);
                }
            }
        }

        // return self
        return this;
    }

    
    /**
     * @description There are scenarios where you want to fill empty values with a custom value.
     *              This method allows you to pad the empty values with a value of your choice
     * @param columnNames The names of columns that will be added as a key item for records
     *                    that do not have the specific key
     * @return self
     */
    global JsnTbl fillNullValuesWithCustomValue(Map<String,Object> columnNameValueMap){

        // Validate the input
        validateColumnNames(columnNameValueMap.keySet());

        // Convert to string list for faster iterations later.
        // Seems overkill but integer loops are significantly faster when we're talking about 1000+ rows
        String[] columnNameList = new List<String>(columnNameValueMap.keySet());
        Integer numberOfColumns = columnNameList.size();

        // Iterate each record in the row
        for(Integer i = 0, max=this.keyValueData.size(); i < max; i++){
            
            // If the record does not contain a certain key, add a null value
            for(Integer j = 0; j < numberOfColumns; j++){
                if(this.keyValueData[i].containsKey(columnNameList[j]) && this.keyValueData[i].get(columnNameList[j]) == null){
                    this.keyValueData[i].put(columnNameList[j],columnNameValueMap.get(columnNameList[j]));
                }
            }
        }
        
        // return self
        return this;
    }


    /**
     * @description There are scenarios where you want to fill empty values with a value from
     *              a different column. For instance you have a merged table with parent and child records
     *              and you want to populate the parent Id in each column of the child to normalize a table.
     * @param sourceTargetColumnMap The name of the source and target columns. Null values will be overwritten
     *                              with the value of the target column
     * @return self
     */
    global JsnTbl fillNullValuesWithColumnValue(Map<String,String> sourceTargetColumnMap){
        
        // Validate the input (both source and target names)
        validateColumnNames(sourceTargetColumnMap.keySet());
        validateColumnNames(new Set<String>(sourceTargetColumnMap.values()));

        // Convert to string list for faster iterations later.
        // Seems overkill but integer loops are significantly faster when we're talking about 1000+ rows
        String[] columnNameList = new List<String>(sourceTargetColumnMap.keySet());
        Integer numberOfColumns = columnNameList.size();

        // Iterate each record in the row
        for(Integer i = 0, max=this.keyValueData.size(); i < max; i++){
            
            // If the record does not contain a certain key, add a null value
            for(Integer j = 0; j < numberOfColumns; j++){
                if(this.keyValueData[i].containsKey(columnNameList[j]) && this.keyValueData[i].get(columnNameList[j]) == null){
                    this.keyValueData[i].put(columnNameList[j],this.keyValueData[i].get(sourceTargetColumnMap.get(columnNameList[j])));
                }
            }
        }

        // return self
        return this;
    }


    /** **************************************************************************************************** **
     **                                  GLOBAL MANIPULATE SUPPORT METHODS                                   **
     ** **************************************************************************************************** **/
    /**
     * @description Method to add your own custom columns or override an existing column value
     *              This method should run after the create method.
     *              Note that the order will need to match the column index. This is used to update
     *              (external) Ids or to add numbering to the output.
     * @param columnName   The name of the column
     * @param columnValues The value for that specific column index.
     * @return      Self
     */
    global JsnTbl upsertColumnData(String columnName, Object[] columnValues, Integer columnIndex){
        
        // Valiate we have a column name
        if(String.isBlank(columnName) || columnValues == null || columnValues.isEmpty() ){
            return this;
        }
        
        // Add or update the value for the column.
        for(Integer i = 0, max=((this.keyValueData.size() <= columnValues.size()) ? this.keyValueData.size() : columnValues.size()); i < max; i++){
            this.keyValueData[i].put(columnName,columnValues[i]);
        }

        // Check if the column name already exists, if so there is no need to re-index
        if(!this.columnNames.contains(columnName)){
            
            // If the column needs to be added at the end or no index is provided, simply add it on at the end
            if(columnIndex == null || columnIndex >= this.columnNames.size()){
                this.columnNames.add(columnName);
            
            // If the column needs to be added at the start, create a new list and add existing list
            }else if(columnIndex <= 0){
                Set<String> columnNames = new Set<String>{columnName};
                columnNames.addAll(this.columnNames);
                this.columnNames = columnNames;

            // If the column needs to be added somewhere half way, add it in at the index point
            }else{
                // Temporary set of column names
                Set<String> columnNames = new Set<String>();
                Integer i=0;
                
                // Add in the new column name at the specified index
                for(String currentColumnName : this.columnNames){
                    if(i == columnIndex){
                        columnNames.add(columnName);
                    }
                    columnNames.add(currentColumnName);
                    i++;
                }

                // Update the column names in the table
                this.columnNames = columnNames;
            }

            // Create the revised column index
            this.createColumnIndexMap();
        }

        // return self
        return this;
    }


    /**
     * @description Method to add a column that is the concatenated value of 2 other columns
     *              This is used to create combined keys.
     * @param columnNames       The names of the columns to concatenate
     * @param glue              The separator string that glues the column values together
     * @param outputColumnName  The name of the new column
     * @param outputColumnIndex The index of where in the file this column is added
     * @return      Self
     */
    global JsnTbl concatColumnData(Set<String> columnNames, String glue, String outputColumnName, Integer outputColumnIndex){

        // Validate the input
        this.validateColumnNames(columnNames);

        // Convert to string list for faster iterations later.
        // Seems overkill but integer loops are significantly faster when we're talking about 1000+ rows
        String[] columnNameList = new List<String>(columnNames);
        Integer numberOfColumns = columnNames.size();

        // List to hold our output
        Object[] columnValues = new Object[]{};

        // Iterate each record in the row
        for(Integer i = 0, max=this.keyValueData.size(); i < max; i++){
            
            // Temporary String
            String[] concatData = new String[]{};
            
            // Add each concat value to the list
            for(Integer j = 0; j < numberOfColumns; j++){
                if(this.keyValueData[i].get(columnNameList[j]) != null){
                    concatData.add(String.valueOf(this.keyValueData[i].get(columnNameList[j])));
                }
            }
            // Add the glued value to the column values
            columnValues.add(String.join(concatData, glue));
        }

        // Use the upsert logic to add the column
        return upsertColumnData( outputColumnName, columnValues, outputColumnIndex);
    }


    /**
     * @description Method to remove columns from the data table
     * @param  columnNames The names of columns that will be deleted
     * @return self
     */
    global JsnTbl deleteColumns(Set<String> columnNames){

        // Validate the input
        this.validateColumnNames(columnNames);

        // Convert to string list for faster iterations later.
        // Seems overkill but integer loops are significantly faster when we're talking about 1000+ rows
        String[] columnNameList = new List<String>(columnNames);
        Integer numberOfColumns = columnNames.size();

        // Remove the column key from the data map
        for(Integer i = 0, max=this.keyValueData.size(); i < max; i++){
            for(Integer j = 0; j < numberOfColumns; j++){
                this.keyValueData[i].remove(columnNameList[j]);
            }
        }

        // Remove the columns from the columns list
        for(Integer j = 0; j < numberOfColumns; j++){
            this.columnNames.remove(columnNameList[j]);
        }

        // Create the revised column index
        this.createColumnIndexMap();

        // return self
        return this;
    }


    /** **************************************************************************************************** **
     **                                   GLOBAL HEADER SUPPORT METHODS                                      **
     ** **************************************************************************************************** **/
    /**
     * @description Method to set your custom column names
     *              This method should run after the create method, note that this method
     *              will only override the output headers.
     *              Use this method if you have an ordered list of header names
     *              Like in a Data Cloud Query response with a multi dimentional array.
     * @note        Do NOT rebuild the index, the record keys are not updated, only the output column names change
     *              the internal naming should not be updated, for performance reasons.
     * @param columnNames Set of column values to override the defaults with
     * @return      Self
     */
    global JsnTbl updateColumnNames(Set<String> columnNames){

        // Input validation on the input set
        if(columnNames == null || columnNames.isEmpty()){
            return this;
        }

        // Get the current column names
        String[] oldNames = this.getColumnNames();
        String[] newNames = new List<String>(columnNames);

        // To prevent the list going out of bounds we need to create a combined list
        // if the current list is greater than the new list
        if(oldNames.size() > newNames.size()){
            
            // Pad the new column names with the leftover names from existing columns
            for(Integer i=newNames.size(),max=oldNames.size();i<max;i++){
                newNames.add(oldNames[i]);
            }  
        }
        // Update the column names
        this.columnNames = new Set<String>(newNames);

        // Return self
        return this;
    }


    /**
     * @description Method to set your custom column names
     *              This method should run after the create method, note that this method
     *              will only override the output headers.
     *              Use this to override specific field names only or if you have a mapping
     *              between like a source and target system CSV file
     * @param oldNameNewNameMap Map that contains the old name and the new name
     * @note        Do NOT rebuild the index, the record keys are not updated, only the output column names change
     *              the internal naming should not be updated, for performance reasons.
     * @return      Self
     */
    global JsnTbl updateColumnNames(Map<String,String> oldNameNewNameMap){
        
        // Input validation on the conversion map
        if(oldNameNewNameMap == null || oldNameNewNameMap.isEmpty()){
            return this;
        }

        // Get the current column names
        String[] oldNames = this.getColumnNames();
        String[] newNames = new String[]{};

        // Iterate the existing columns and override if the mapping contains the matching value
        for(Integer i=0,max=oldNames.size();i<max;i++){
            newNames.add((oldNameNewNameMap.containsKey(oldNames[i])) ? oldNameNewNameMap.get(oldNames[i]) : oldNames[i]);
        }  
        
        // Update the column names
        this.columnNames = new Set<String>(newNames);

        // Return self 
        return this;
    }

    

    /** **************************************************************************************************** **
     **                                       GLOBAL GETTER METHODS                                          **
     ** **************************************************************************************************** **/
    /**
     * @description Method to get the column names
     * @return      A list of column names
     */
    global String[] getColumnNames(){
        return new List<String>(this.columnNames);
    }


    /**
     * @description Method to get the column names and index location
     * @return      A map with the column name and the corresponding index
     */
    global Map<String,Integer> getColumnNameIndexMap(){
        return this.columnIndexMap;
    }


    /**
     * @description Method to get the table data as a LWC compatible key value format
     * @return      A list of maps with the key value pairs
     */
    global List<Map<String,Object>> getKeyValueData(){
        return this.keyValueData;
    }


    /**
     * @description Method to generate an indexed multi-dimentional array containing the data
     * @return      A multi-dimentional array with the values
     */
    global List<Object[]> getIndexedData(){
        
        // Run creation logic
        this.createIndexedData();

        // Return the indexed data
        return this.indexedData;
    }


    /**
     * @description Method to generate CSV data
     * @return      A multi-dimentional with header row and CSV escaped string values
     */
    global List<String[]> getCsvData(){
        
        // Run creation logic
        this.createCsvData();

        // Return the indexed data
        return this.csvData;
    }


    /**
     * @description Method to generate a CSV string from the CSV data
     * @return      A CSV string from the table
     */
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


    /**
     * @description Method to generate a user readable table that can be outputed to a console
     *              !! Very resource intensive and for testing purposes only !!
     * @return      A Console spaced table string from the table
     */
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
    /**
     * @description Method to reset all table data
     */
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
     * @param input          The array to index
     * @param additionalRows Option to add additional rows to the index
     * @param stringList     When true, the pre-population is done using string lists instead of
     *                       object lists
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


    /**
     * @description Method to create indexed data based on the key value data
     */
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


    /**
     * @description Method to create CSV data based on the key value data
     */
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


    /**
     * @description Method to validate that input colum names exist
     * @param columnNames Test set of input columns
     * @trhows      Jsn.JsonUtilException when the column name is invalid
     */
    @TestVisible
    private void validateColumnNames( Set<String> columnNames){

        // Input validation on the input set
        if(columnNames == null || columnNames.isEmpty()){
            throw new Jsn.JsonUtilException(EMPTY_COLUMNS_MSG);
        }

        // Input validation for the column names
        for(String columnName : columnNames){
            if(!this.columnNames.contains(columnName)){
                throw new Jsn.JsonUtilException(String.format(
                    COLUMN_DOES_NOT_EXIST_MSG, new String[]{columnName})
                );
            }
        }
    }


    /** **************************************************************************************************** **
     **                                       PRIVATE TRAVERSE METHODS                                       **
     ** **************************************************************************************************** **/
    /**
     * @description Parent selector method, this method splits out how the top level record needs to be handled
     *              based on the type. This makes sure the least amount of type casting has to be done.
     * @param input The input to traverse
     * @param path  The location in the traverse path
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


    /**
     * @description Traverse the parent map 
     * @param input The input to traverse
     * @param path  The location in the traverse path
     */
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


    /**
     * @description Traverse the parent list 
     * @param input The input to traverse
     * @param path  The location in the traverse path
     */
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
     * @param input The input to traverse
     * @param path  The location in the traverse path
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
     * @param input          The input to traverse
     * @param path           The location in the traverse path
     * @param row            The current row in the traverse path
     * @param isObjectInlist Indicator if this is a single object value inside a list
     * @param objectIndex    The location of the object in the list
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


    /**
     * @description Child Map traverse method
     * @param input          The input to traverse
     * @param path           The location in the traverse path
     * @param row            The current row in the traverse path
     * @param isObjectInlist Indicator if this is a single object value inside a list
     * @param objectIndex    The location of the object in the list
     */
    private void traverseChildMap(Map<String,Object> input, String path, Map<String,Object> row, Boolean isObjectInlist, Integer objectIndex){
        for(String key : input.keySet() ){

            // Continue if a property needs to be ignored
            if(this.hasAttributeFilter && this.attributeFilter.contains(key)){continue;}
        
            // Traverse self for each child record
            traverseChild(input.get(key), ((String.isNotBlank(path)) ? path + '.' + key : key), row, isObjectInlist, objectIndex);
        }
    }


    /**
     * @description Child List traverse method
     * @param input          The input to traverse
     * @param path           The location in the traverse path
     * @param row            The current row in the traverse path
     * @param isObjectInlist Indicator if this is a single object value inside a list
     * @param objectIndex    The location of the object in the list
     */
    private void traverseChildList(Object[] input, String path, Map<String,Object> row, Boolean isObjectInlist, Integer objectIndex){
            
        // Allow to filter out certain list names. Note that this can have some funky results
        // Each list should be added as new records, so handle the list as a PARENT
        traverseParentList(
            input,
            (this.hasListNameFilter && this.listNameFilter.contains(path?.substringAfterLast('.'))) ? path?.substringBeforeLast('.') : path
        );
    }


    /**
     * @description Child Object traverse method
     * @param input          The input to traverse
     * @param path           The location in the traverse path
     * @param row            The current row in the traverse path
     * @param isObjectInlist Indicator if this is a single object value inside a list
     * @param objectIndex    The location of the object in the list
     */
    private void traverseChildObject(Object input, String path, Map<String,Object> row, Boolean isObjectInlist, Integer objectIndex){
        
        // Extract the path so it can be added in to the column names
        path = (isObjectInlist) ? ((String.isNotBlank(path)) ? path + '.' + objectIndex : String.valueOf(objectIndex)) : path;
        
        // If the object is in a list we need to add the list index as a key
        this.columnNames.add(path);
        
        // Add the value to the row		
        row.put(path,input);
    }
}