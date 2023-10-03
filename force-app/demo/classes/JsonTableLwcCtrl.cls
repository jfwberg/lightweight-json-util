public with sharing class JsonTableLwcCtrl {

    @AuraEnabled
    public static Map<String,Object> createTable(String jsonString, String attributeFilter, String listNameFilter, Boolean includeChildLists, String path, String cacheBust){
        return (Map<String,Object> ) createOutput(jsonString, attributeFilter, listNameFilter, includeChildLists, path, false);  
    }


    @AuraEnabled
    public static String createCsv(String jsonString, String attributeFilter, String listNameFilter, Boolean includeChildLists, String path, String cacheBust){
       return (String ) createOutput(jsonString, attributeFilter, listNameFilter, includeChildLists, path, true);  
    }

    
    private static Object createOutput(String jsonString, String attributeFilter, String listNameFilter, Boolean includeChildLists, String path, Boolean returnCsv){
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
                .setIncludeChildLists(includeChildLists)
                .setListNameFilter(listNameFilterSet)
                .setAttributeFilter(attributeFilterSet)
                .create(JSON.deserializeUntyped(jsonString))
            ;


            // return the csv or the data and columns
            if(returnCsv){
                return table.getCsvString();
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