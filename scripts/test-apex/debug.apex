// Query configuration
String  query  = 'SELECT Id, Name, Owner.Profile.Name ';
        //query +='(SELECT Id, AccountId, FirstName, LastName, Owner.Profile.Name FROM contacts LIMIT 10), ';
        //query +='(SELECT Id, AccountId, Name, StageName, CloseDate, Owner.Profile.Name FROM opportunities LIMIT 10) ';
        query +='FROM Account WHERE Name LIKE \'Demo Account - %\' ORDER BY Name ASC LIMIT 10';

Boolean isTooling         = false;
String  jsonString        = getQueryResponseBody(query, isTooling);


try{
    // Create a data table from a Salesforce API query response
    utl.JsnTbl table = new utl.JsnTbl()
        // Run before create
        .setAttributeFilter(new Set<String>{'attributes', 'done'})
        .setListNameFilter(new Set<String>{'records'})
        
        // Create the table
        .create((Object[]) ((Map<String,Object>)JSON.deserializeUntyped(jsonString)).get('records')) 
    ;   

    // Output the result as a csv
    System.debug(table.getColumnNames());
    
}catch(Exception e){
    
    // Handle JSON related exceptions
    if(       e.getTypeName() == String.valueOf(System.JSONException.class)){
        System.debug('Invalid JSON Exception: ' + e.getMessage()); 
    
    // Handle JSON Util related Exceptions
    }else if (e.getTypeName() == String.valueOf(utl.Jsn.JsonUtilException.class)){
        System.debug('JSON Util Exeption: '     + e.getMessage()); 
    
    // Handle Unknown Exceptions
    }else {
        System.debug('Unknown Exeption: '       + e.getMessage() + e.getStackTraceString());
    }
}








/**
 * Method for calling a Salesforce Rest API
 */
private static String getQueryResponseBody(String query, Boolean isTooling){
    
    Http http = new Http();
    HttpRequest httpRequest = new HttpRequest();
    httpRequest.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v59.0/'+ (IsTooling ? 'tooling/' : '' ) +'query?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
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