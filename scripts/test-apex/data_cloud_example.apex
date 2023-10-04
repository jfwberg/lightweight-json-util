// Query callout to named credential
utl.Rst callout = new utl.Rst('DC_ORG_01')
    .setEndpoint('/api/v2/query')
    .setMethod('POST')
	.setBody('{"sql" : "SELECT ssot__Id__c, ssot__Name__c, ssot__Number__c, ssot__AccountTypeId__c, ssot__BillContactAddressId__c, ssot__CreatedDate__c, ssot__DataSourceId__c, ssot__DataSourceObjectId__c FROM ssot__Account__dlm LIMIT 100"}')
    .call()
;

// Parse the top level map to split the data and metadata maps
Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(callout.getResponse().getBody());
Map<String,Object> metadataMap = utl.Jsn.getObjectMap('metadata',responseMap);

// Create a mapping between column index and column name
Map<Integer,String> columnIndexMap = new Map<Integer,String>();

// Create a new set for the column names
Set<String> columnNamesInOrder = new Set<String>{};

// Iterate the metadata to get the columns
for(String key : metadataMap.keySet()){
	columnIndexMap.put(
		(Integer) utl.Jsn.getObject('placeInOrder', (Map<String,Object>) metadataMap.get(key)),
		key
	);
}

// Create an ordered list
for(Integer i=0,max=columnIndexMap.size(); i<max;i++){
	columnNamesInOrder.add(columnIndexMap.get(i));
}

// Create a datatable
utl.JsnTbl table= new utl.JsnTbl()
    .create(utl.Jsn.getObjectList('data',responseMap))
	.updateColumnNames(columnNamesInOrder)
;

// Data table output in the console
System.debug(table.getConsoleString());