try{
	utl.Rst callout = new utl.Rst(true);
	
	//setQuery(callout, 'SELECT Id, EventType, LogFile FROM EventLogFile');
	setSObjectDescribe(callout,'EventLogFile');
	//setOAS3Spec(callout, new String[]{'/services/data/v59.0/sobjects/EventLogFile/{id}'});
	//setOAS3SpecProgress(callout, 'NTByNlMwMDAwMDBQQXNE');
	
	callout.call();
		
	
	//queryTable(callout.getResponse().getBody());
	describeTable(callout.getResponse().getBody());
	
	
}catch(Exception e){
	System.debug(e.getMessage());
}


void setSObjectDescribe(utl.Rst callout, String sObjectName){
	callout.setEndpoint('/sobjects/' + sObjectName + '/describe');
	callout.setMethod('GET');
}

void setQuery(utl.Rst callout, String query){
	callout.setEndpoint('/query?q=' + EncodingUtil.urlEncode(query,'UTF-8'));
	callout.setMethod('GET');
}

void setOAS3Spec(utl.Rst callout, String[] resources){
	callout.setEndpoint('/async/specifications/oas3');
	callout.setMethod('POST');
	callout.setBody('{"resources" : ["' + String.join(resources,'","') + '"]}');
}

void setOAS3SpecProgress(utl.Rst callout, String resourceId){
	callout.setEndpoint('/async/specifications/oas3/'+resourceId);
	callout.setMethod('GET');
}

void queryTable(String jsonString){
	System.debug(
		new utl.JsnTbl()
		.setAttributeFilter(new Set<String>{'totalSize','done','attributes'})
		.setListNameFilter(new Set<String>{'records'})
		.create(JSON.deserializeUntyped(jsonString))
		.getConsoleString()
	);
}

void describeTable(String jsonString){
	System.debug(
		new utl.JsnTbl()
		.create(
			invertTable(
				new utl.JsnTbl()
				.setAttributeFilter(new Set<String>{'totalSize','done','attributes','urls'})
				.setListNameFilter(new Set<String>{'records'})
				.create(JSON.deserializeUntyped(jsonString))
				.getCSVData()
			)
		).getConsoleString()
	);
}

List<Object[]> invertTable(List<Object[]> input){

	Integer numRows = 0;
	Integer numCols = 0;

	List<Object[]> output = new List<Object[]>();

	// Get the required row and column length
	for(Integer i=0,imax=input.size(); i<imax; i++){
		if(numCols < imax){numCols = imax;}
		for(Integer j=0,jmax=input[i].size(); j<jmax; j++){
			if(numRows < jmax){numRows = jmax;}
		}
	}

	// Pad the table with null values
	for(Integer i=0; i<numRows; i++){
		output.add(new Object[]{});
		for(Integer j=0; j<numCols; j++){
			output[i].add(null);
		}
	}

	// Invert the array
	for(Integer i=0,imax=input.size(); i<imax; i++){
		for(Integer j=0,jmax=input[i].size(); j<jmax; j++){
			output[j][i] = input[i][j];
		}
	}
	
	return output;
}
