/**
 * @description A class representing a data table that can be used in LWC
 */

 // add parse time in ms as an info
 



global with sharing class JsnTbl {
   
    // user updateable variables
    

    // Select this option to include child lists
    private Boolean includeChildLists = true;

    // Set to true if you want child lists to be added as a table object instead of
    // new rows with the fields for those object
    private Boolean addChildListsAsTables = false;

    // Select this option to ignore the key of a child list for better readabillity
    private Boolean hideChildListAttributeFromPath = true;
    
    // Values to be ignored when creating the data table
    private Set<String> attributeFilter;



    // app variables


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

    // private constants

 
    // Message
    private static final String UNSUPOPRTED_DATA_FORMAT_MESSAGE = 'When "addChildListsAsTables" is set to TRUE, you cannot create a JSON Table in an Indexed Data format "getIndexedData()" and a CSV Data format "getCsvData()". Only the Key Value Data format is supported "getKeyValueData()".';
    

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
     * @description Method to set the value for adding child lists as JsnTbl Objects
     */
    global JsnTbl setAddChildListsAsTables(Boolean addChildListsAsTables){
        this.addChildListsAsTables = addChildListsAsTables;
        return this;
    }

    /**
     * @description Method to set the value for hideChildListAttributeFromPath, when set to true
     *              the attribute name for child lists is not added to the path to allow for cleaner
     *              path names that potentially make more sense for certain types of payloads
     */
    global JsnTbl setHideChildListAttributeFromPath(Boolean hideChildListAttributeFromPath){
        this.hideChildListAttributeFromPath = hideChildListAttributeFromPath;
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

    
    /** **************************************************************************************************** **
     **                                       GLOBAL SUPPORT METHODS                                         **
     ** **************************************************************************************************** **/
    /**
     * @description Create table from an untyped Object list
     */
    global JsnTbl createFromObjectList(Object[] input){
        
        // Setup the table
        this.initiateTable();
        
        // Execute logic
        this.traverseObjectList(
            '',
            input,
            this.keyValueData
        );
        
        // Create the revised column index
        this.createColumnIndexMap();

        // Return self for method chaining
        return this;
    }


    /**
     * @description Create a table that starts with an untyped Object Map
     *              This is not a very common scenario, non the less possible
     */
    global JsnTbl createFromObjectMap(Map<String,Object> input){
        
        // Setup the table
        this.initiateTable();
        
        // Execute logic
        this.keyValueData.add(
            this.traverseObjectMap(
                '',
                input,
                new Map<String,Object>()
            )
        );

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

        // Check  to prevent any lovely errors with regards to nested table objects
        if(this.includeChildLists && this.addChildListsAsTables){
            throw new Jsn.JsonUtilException(JsnTbl.UNSUPOPRTED_DATA_FORMAT_MESSAGE);
        }

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
     * @description Method to traverse an Object Map
     * @param path
     * @param input
     * @param output
     */
    private Map<String,Object> traverseObjectMap(String path, Map<String,Object> input, Map<String,Object> output){
        for(String key : input.keySet()){

            // Concatenate the path levels with a period to flatten child objects
            String keyPath = (String.isEmpty(path)) ? key : path + '.' + key;

            // continue if a property needs to be ignored
            if(this.attributeFilter != null && attributeFilter.contains(key)){continue;}
         
            // Handle when the child propery is an object
            if(input.get(key) instanceof Map<String,Object>){
                
                this.traverseObjectMap(
                        keyPath,
                        (Map<String,Object>)input.get(key),
                        output
                    );

            // Handle when the child propery is an object list
            }else if(input.get(key) instanceof Object[]){

                // If lists are ignored, skip to the next record
                if(!this.includeChildLists){continue;}
                
                // Add a data table to the output
                if(this.addChildListsAsTables){  
                    output.put(
                        (this.hideChildListAttributeFromPath) ? keyPath.substringBeforeLast('.') : keyPath,
                        new JsnTbl()
                            .setIncludeChildLists(this.includeChildLists)    
                            .setAddChildListsAsTables(this.addChildListsAsTables)
                            .setHideChildListAttributeFromPath(this.hideChildListAttributeFromPath)
                            .setAttributeFilter(this.attributeFilter)
                            .createFromObjectList((Object[])input.get(key))
                    );
                }else{
                    for(Object o : (Object[]) input.get(key)){
                        
                        // Allow for the first child record to have the attribute removed
                        // This is required if the first object contains a child object i.e. "records"
                        // to not have the attribute name
                        keyPath = (
                            (String.isBlank(path) && this.hideChildListAttributeFromPath) ?
                                path : (
                                (this.hideChildListAttributeFromPath) ? 
                                    keyPath.substringBeforeLast('.') : 
                                    keyPath
                            )
                        );

                        // Extra check or we cannot deal with value types yet
                        if(o instanceOf Map<String,Object>){
                            // Add an object map to the data
                            this.keyValueData.add(
                                this.traverseObjectMap(
                                    keyPath,
                                    (Map<String,Object>) o,
                                    new Map<String,Object>()
                                )
                            );
                        }
                    }
                }

            // Handle the child propery as a value
            }else{
                // Add the columnn names for properties that contain values
                this.columnNames.add(keyPath);
                
                // Add the value to the outputlist
                output.put(
                    keyPath,
                    input.get(key)
                );
            }
        }
        return output;
    }


    /**
     * @description Method to traverse an Object List
     * @param path
     * @param input
     * @param output
     */
    private Object[] traverseObjectList(String path, Object[] input, List<Map<String,Object>> output){
        
        Map<String,Object> unknownAttributes =  new Map<String,Object>();

        // If there are values that are not objects and do not have a key/value pair structure
        // the will be put into a "unknown attributes" map that can be transformed into table columns
        Integer attributeCounter = 0;

        // Iterate each object in the list that will transform into a data row
        for (Integer i = 0, max=input.size(); i < max; i++) {
            
            if(input[i] instanceof Map<String,Object>){
                
                output.add(
                    this.traverseObjectMap(
                        path,
                        (Map<String,Object>) input[i],
                        new Map<String,Object>()
                    )
                );

            }else if(input[i] instanceof Object[]){
                
                // If lists are ignored, skip to the next record
                if(!this.includeChildLists){continue;}

                
                String pathKey = ( String.isNotBlank(path) ? path + '.' : '') +  String.valueOf(attributeCounter);

                this.columnNames.add(pathKey);
                attributeCounter++;

                // create a new map
                // each value from this list is added
                
                //output.add(this.handleList((Object[])input[i]));

                for( Object woot : this.traverseObjectList(
                    pathKey,
                    (Object[]) input[i],
                    new List<Map<String,Object>>()
                )){
                    output.add((Map<String,Object>)woot);
                }
                
                
            }else{

                String pathKey = String.valueOf(attributeCounter);

                this.columnNames.add(pathKey);

                attributeCounter++;

                // If there is a list with unknown attributes it will be added here i.e. [1,2,3]
                // will become [{"attr0" : 1}, {"attr0" : 2}, {"attr2" : 3}]
                // So this translates into 3 columns with values and unknow attribute name
                unknownAttributes.put(
                     pathKey,input[i]
                );
                
            }
        }

        // Collect all attributes and add them to the output
        if(!unknownAttributes.isEmpty()){
           output.add(unknownAttributes);
        }
        return output;
    }

    /**
     * @description Additional handling so that nested lists containing values can be handled
     *              i.e. [[1,2,3],["a","b","c"]]
     */
    private Map<String,Object> handleList(Object[] input){
        Integer counter = 0;
        Map<String,Object> output = new Map<String,Object>();
        for(Object o : input){
            
            if(o instanceOf Object[]){
                
                output.putAll(this.handleList((Object[]) o));
                

            }else if(o instanceOf Map<String,Object>){

                output.putAll(this.traverseObjectMap(
                    '',
                    (Map<String,Object>) o,
                    new Map<String,Object>()
                ));

            }else{
                output.put(String.valueOf(counter),String.valueOf(o));
            }
            counter++;
        }
        return output;
    }
}