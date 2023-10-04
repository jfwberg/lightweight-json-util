/**
 * DATA    : 1000 Accounts with 10 Contacts and 10 Oppoertunities each each
 * TEST 01 : Check performance of creating a table with 21k rows from a JSON response
 * RESULT  : AVG CPU Time : 911
 *           Heap Size    : 1,610,406
 */
// Query configuration
String  query  = 'SELECT Id, Name, Owner.Name, Owner.Profile.Name, ';
        query +='(SELECT AccountId, FirstName, LastName, Owner.Profile.Name FROM contacts LIMIT 10), ';
        query +='(SELECT AccountId, Name, StageName, CloseDate, Owner.Profile.Name FROM opportunities LIMIT 10) ';
        query +='FROM Account WHERE Name LIKE \'Demo Account - %\' ORDER BY Name ASC LIMIT 1000';

String  jsonString = getQueryResponseBody(query, false);


try{
 	// Register the starting limits
    Integer startCpuTime = Limits.getCpuTime();
    Integer startHeapSize= Limits.getHeapSize();
	
	// Create a basic table
	utl.JsnTbl table = new utl.JsnTbl()
    	.create(JSON.deserializeUntyped(jsonString))
	;

	Integer endCpuTime  = Limits.getCpuTime();
    Integer endHeapSize = Limits.getHeapSize();

	// Output the limits info for performance measuring
	System.debug('CPU Time : ' + (endCpuTime - startCpuTime));
	System.debug('Heap size: ' + (endHeapSize - startHeapSize));
	
	
}catch(System.JSONException e){
    System.debug('Invalid JSON detected: ' + e.getMessage());
}


/**
 * Method for calling a Salesforce Rest API
 */
private static String getQueryResponseBody(String query, Boolean isTooling){
    
    Http http = new Http();
    HttpRequest httpRequest = new HttpRequest();
    httpRequest.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v58.0/'+ (IsTooling ? 'tooling/' : '' ) +'query?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
    httpRequest.setMethod('GET');
    httpRequest.setHeader('Content-Type', 'application/json;charset=UTF-8');
    httpRequest.setHeader('Authorization', 'Bearer ' + userInfo.getSessionId());
    HttpResponse response =  http.send(httpRequest);
    
    switch on response.getStatusCode() {
        // Success responses
        when 200 {
            return response.getBody();
        }
        when 400, 401, 404, 405 {
            handleSalesforceErrorResponse(response.getBody());
        }
        when else{
            handleUnknownResponse(response.getBody());
        }
    }
    return null;
}


/**
 * Method to throw an exception containing the Salesforce API Error Message 
 */
private static void handleSalesforceErrorResponse(String responseBody){
    for( Object record : (Object[]) JSON.deserializeUntyped(responseBody)){
        throw new StringException((String)((Map<String, Object>) record).get('message'));
    }
}


private static void handleUnknownResponse(String responseBody){
    throw new StringException('Unknown error response: ' + responseBody);
}