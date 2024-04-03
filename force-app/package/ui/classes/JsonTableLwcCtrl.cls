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
@SuppressWarnings('PMD.ExcessiveParameterList')
public with sharing class JsonTableLwcCtrl {

    @AuraEnabled
    public static Object createTable(String jsonString, Boolean numberColumn, String attributeFilter, String listNameFilter, String outputFormatValue){
        try {
            // The filter sets
            Set<String> attributeFilterSet;
            Set<String> listNameFilterSet;
            
            // Populate the attribute filter and trim any values
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
                for(Integer i = 0, max=table.getKeyValueData().size(); i <= max; i++){
                    columnData.add(i);
                }
                table.upsertColumnData('#', columnData, 0);
            }

            // Change the output based on the selected output format
            switch on (outputFormatValue) {
                
                // By default go for a lightning data table view
                when 'lwctable' {
                    
                    // Create a new data table
                    utl.Ldt ldt = new utl.Ldt()
                        .setData(table.getKeyValueData())
                    ;

                    // Add all the columns
                    for(String columnName : table.getColumnNames()){
                        ldt.addColumn(
                            new utl.Ldt.Col(columnName,columnName)
                                .setInitialWidth(150)
                        );
                    }
                    return ldt;
                }

                when 'lwckeyvaluetable' {
                    // Create a new key value data table
                    return new utl.Ldt()
                        .setupKeyValue()
                        .setData(table.getKeyValuePairData())
                    ;
                }

                when 'csvstring' {
                    return table.getCsvString();
                }

                when 'consolestring' {
                    return table.getConsoleString();
                }

                when 'rawkeyvalue' {
                    return table.getKeyValueData();
                }

                when 'rawindexed' {
                    return table.getIndexedData();
                }

                when 'rawkeyvaluepair' {
                    return table.getKeyValuePairData();
                }

                when 'rawcsv' {
                    return table.getCsvData();
                }

                // By default go for a lightning data table view
                when else {
                    throw new Jsn.JSONUtilException('Invalid output format');
                }
            }

        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}