public with sharing class JsonTableLwcCtrl {

    @AuraEnabled
    public static Map<String,Object> createTable(String jsonString, String attributeFilter, Boolean hideChildListAttributeFromPath, String cacheBust){
        try {
            // The filter set
            Set<String> attributeFilterSet;
            
            // Populate the attribute filter
            if(String.isNotBlank(attributeFilter)){
                attributeFilterSet = new Set<String>{};
                for(String attribute : attributeFilter.split(',')){
                    attributeFilterSet.add(attribute?.trim());
                }
            }

            // Create a new table
            utl.JsnTbl table = new utl.JsnTbl()
                .setHideChildListAttributeFromPath(hideChildListAttributeFromPath)
                .setAttributeFilter(attributeFilterSet)
            ;

            // Handle as a list or as a string
            if(jsonString.startsWith('[')){
                table.createFromObjectList((Object[])JSON.deserializeUntyped(jsonString));
            }else if(jsonString.startsWith('{')){
                table.createFromObjectMap((Map<String,Object>)JSON.deserializeUntyped(jsonString));
            }else{
                throw new StringException('Only JSON lists and objects are supported.');
            }

            // return the data and columns
            return new Map<String,Object>{
                'columns' => table.getColumnNames(),
                'data'    => table.getKeyValueData()
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}