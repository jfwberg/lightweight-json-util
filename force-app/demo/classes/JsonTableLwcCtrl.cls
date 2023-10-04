@SuppressWarnings('PMD.ExcessiveParameterList')
public with sharing class JsonTableLwcCtrl {

    @AuraEnabled
    public static Map<String,Object> createTable(String jsonString, String attributeFilter, String listNameFilter, String cacheBust){
        return (Map<String,Object> ) createOutput(jsonString, attributeFilter, listNameFilter, false, false);  
    }


    @AuraEnabled
    public static String createCsv(String jsonString, String attributeFilter, String listNameFilter, String cacheBust){
       return (String ) createOutput(jsonString, attributeFilter, listNameFilter, true, false);  
    }


    @AuraEnabled
    public static String createConsole(String jsonString, String attributeFilter, String listNameFilter, String cacheBust){
       return (String ) createOutput(jsonString, attributeFilter, listNameFilter, true, true);  
    }

    
    private static Object createOutput(String jsonString, String attributeFilter, String listNameFilter, Boolean returnCsv, Boolean returnConsole){
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
            throw new AuraHandledException(e.getMessage());
        }
    }
}