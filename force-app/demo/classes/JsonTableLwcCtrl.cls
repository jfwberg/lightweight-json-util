@SuppressWarnings('PMD.ExcessiveParameterList')
public with sharing class JsonTableLwcCtrl {

    @AuraEnabled
    public static Map<String,Object> createTable(String jsonString, Boolean numberColumn, String attributeFilter, String listNameFilter, String cacheBust){
        return (Map<String,Object> ) createOutput(jsonString, numberColumn, attributeFilter, listNameFilter, false, false,false);  
    }

    @AuraEnabled
    public static Map<String,Object> createKeyValueTable(String jsonString, Boolean numberColumn, String attributeFilter, String listNameFilter, String cacheBust){
        return (Map<String,Object> ) createOutput(jsonString, numberColumn, attributeFilter, listNameFilter, false, false,true);  
    }

    @AuraEnabled
    public static String createCsv(String jsonString, Boolean numberColumn, String attributeFilter, String listNameFilter, String cacheBust){
       return (String ) createOutput(jsonString, numberColumn, attributeFilter, listNameFilter, true, false,false);  
    }


    @AuraEnabled
    public static String createConsole(String jsonString, Boolean numberColumn, String attributeFilter, String listNameFilter, String cacheBust){
       return (String ) createOutput(jsonString, numberColumn, attributeFilter, listNameFilter, true, true, false);  
    }

    
    private static Object createOutput(String jsonString, Boolean numberColumn, String attributeFilter, String listNameFilter, Boolean returnCsv, Boolean returnConsole, Boolean returnKeyValue){
        try {
            // The filter sets
            Set<String> attributeFilterSet;
            Set<String> listNameFilterSet;
            
            // Populate the attribute filter
            if(String.isNotBlank(attributeFilter)){
                attributeFilterSet = new Set<String>{};
                for(String attribute : attributeFilter.split(',')){
                    attributeFilterSet.add(attribute?.trim());
                }
            }

            // Populate the list name filter
            if(String.isNotBlank(listNameFilter)){
                listNameFilterSet = new Set<String>{};
                for(String listName : listNameFilter.split(',')){
                    listNameFilterSet.add(listName?.trim());
                }
            }

            // Create a new table
            utl.JsnTbl table = new utl.JsnTbl()
                .setListNameFilter(listNameFilterSet)
                .setAttributeFilter(attributeFilterSet)
                .create(JSON.deserializeUntyped(jsonString))
            ;

            // Example of how to add data (or update data to a table)
            // Can only be added at the end. But the idea is that the value can get sorted.
            if(numberColumn){
                Object[] columnData =  new Object[]{};
                for(Integer i = 1, max=table.getKeyValueData().size(); i <= max; i++){
                    columnData.add(i);
                }
                table.upsertColumnData('#', columnData, 0);
            }

            if(returnKeyValue){
                return new Map<String,Object>{
                    'columns' => new String[]{'key','value'},
                    'data'    => table.getKeyValuePairData()
                };
            }

            // return the csv or the data and columns
            if(returnCsv){
                return (returnConsole) ? table.getConsoleString() : table.getCsvString();
            }else{
                return new Map<String,Object>{
                    'columns' => table.getColumnNames(),
                    'data'    => table.getKeyValueData()
                };
            }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
        }
    }
}