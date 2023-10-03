//String jsonString = '[{"listData" : [[1,2,3],[4,5,6]], "mapData" : {"a" : "b", "child" : {"ca" : "cb"}}}]';
//String jsonString = '{"mapData" : {"a" : "b", "child" : {"ca" : "cb"}}}';
//String jsonString = '{"Name" : "david", "child" : {"name" : "crystal", "grandchild" : {"Name" : "emmett"}}, "childList" : ["GC1", "GC2" , "GC3", {"random": "listItem"},"GC4"]}';
String jsonString = '[[1,2,3],[4,5,6],[7,8,9,10]]';

List<Map<String,Object>> fullTable = createTable(jsonString);
System.debug(JSON.serializePretty(fullTable));


/**
 * @description Method to create a flat data table
 */
List<Map<String,Object>> createTable(String jsonString){
	
	// The list of data table rows
	List<Map<String,Object>> dataRows = new List<Map<String,Object>>();
		
	// Handle as a list or as a string
	if(jsonString.startsWith('{')){
		
		handleTopLevelMap((Map<String,Object>)JSON.deserializeUntyped(jsonString), null, dataRows);
		
	}else if(jsonString.startsWith('[')){
		
		handleTopLevelList((Object[])JSON.deserializeUntyped(jsonString), null, dataRows);
		
	}else{
		throw new StringException('Only JSON Object Maps and Object Lists are currently supported');
	}
	return dataRows;
}


void handleTopLevelMap(Map<String,Object> input, String path, List<Map<String,Object>> dataRows){
	
	Map<String,Object> row = new Map<String,Object>();
	
	for(String key : input.keySet()){		
		handleChild(
			input.get(key),
			(String.isNotBlank(path)) ? path +'.'+ key : key,
			row,
			dataRows,
			false,
			0
		);
	}
	
	if(!row.isEmpty()){
		dataRows.add(row);
	}
}


void handleTopLevelList(Object[] input, String path,  List<Map<String,Object>> dataRows){
	Map<String,Object> row = new Map<String,Object>();
	
	
	Integer objectIndex = 0;
	
	for(Integer i=0, max=input.size();i<max;i++){
		
		Boolean isObjectInlist = false;
		
		if(!(input[i] instanceOf Object[] || input[i] instanceOf Map<String,Object>)){
			isObjectInlist = true;
			objectIndex++;
		}
		
		handleChild(
			input[i],
			path,
			row,
			dataRows,
			isObjectInlist,
			objectIndex
		);
		
	}
	
	if(!row.isEmpty()){
		dataRows.add(row);
	}
}


void handleChild(Object input, String path, Map<String,Object> row, List<Map<String,Object>> dataRows, Boolean isObjectInlist, Integer objectIndex){
	
	System.debug('PATH : ' + path + ' - INPUT : ' + input + ' - ROW: ' + row);
		
	// Needs to create a new set of rows for each object
	if(input instanceof Object[]){
		
		handleTopLevelList((Object[])input, path, dataRows);
	
	// Needs to roll up to the same row, so traverse in the child record again
	}else if(input instanceof Map<String,Object>){
		
		for(String key : ((Map<String,Object>) input).keySet() ){
			handleChild(
				((Map<String,Object>)input).get(key),
				(String.isNotBlank(path)) ? path+'.'+key : key,
				row,
				dataRows,
				isObjectInlist,
				objectIndex
			);
		}
		
	// Needs to add a value to the row, so here we add the value to the path
	}else{
		// If the object is in a list we need to add the list index as a key
		if(isObjectInlist){
			path = (String.isNotBlank(path)) ? path+'.'+objectIndex : String.valueOf(objectIndex);
		}
		row.put(path,input);
		//System.debug(row);
	}
}
