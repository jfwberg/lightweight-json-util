@IsTest
private with sharing class JsnTest {

    /** **************************************************************************************************** **
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    // Get the test JSON body from the static resource
    private static final String ACC_CON_JSON          = getStaticResourceBody('Lightweight_JSON_Util_Apex_Unit_Test_Data');

    // (Error) messages
    private static final String STATIC_RESOURCE_ERROR = 'No static resource with the name "{0}" found in the metadata';
    
    
    /** **************************************************************************************************** **
     **                                            TEST METHODS                                              **
     ** **************************************************************************************************** **/
    @IsTest
    static void testGetObject(){
        
        // Get the first sample record
        Map<String,Object> record = (Map<String,Object>) Jsn.getObjectList('records', (Map<String,Object>) JSON.deserializeUntyped(ACC_CON_JSON))[0];
        
        // Single level deep
        Assert.areEqual(
            'Demo Account - 0001', 
            (String) Jsn.getObject(
                'Name',
                record
            ),
            'Unexpected Object value'
        );

        // Multiple levels deep
        Assert.areEqual(
            'System Administrator', 
            (String) Jsn.getObject(
                'Owner.Profile.Name',
                record
            ),
            'Unexpected Object value'
        );

        // Test the exception message
        try{
            Jsn.getObject('Owner.invalidField',record);
        }catch(Exception e){
            Assert.areEqual(
                String.format(Jsn.PATH_ERROR_MSG, new String[]{'invalidField'}), 
                e.getMessage(),
                'Unexpected exception message'
            );
        }

        // Test return null with exceptions turned off
        Jsn.setThrowException(false);

        // Test invalid field without exception top level
        Assert.areEqual(
            null, 
            Jsn.getObject('invalidField', record),
            'Unexpected Object value'
        );

        // Test invalid field without exception, multiple levels deep
        Assert.areEqual(
            null, 
            Jsn.getObject('invalidField.invalidField',record),
            'Unexpected Object value'
        );
    }


    @IsTest
    static void testGetObjectMap(){
        
        // Get the account records, top level
        Map<String,Object> accRecord = (Map<String,Object>)((Object[]) Jsn.getObjectList('records', (Map<String,Object>) JSON.deserializeUntyped(ACC_CON_JSON)))[0];

        // Assert account record, single level
        Assert.areEqual(
            (Map<String,Object>) accRecord.get('Contacts'),
            Jsn.getObjectMap('Contacts', (Map<String,Object>) accRecord),
            'Unexpected contacts map'
        );

        // Assert account record, multiple levels
        Assert.areEqual(
            (Map<String,Object>)((Map<String,Object>) accRecord.get('Owner')).get('Profile'),
            Jsn.getObjectMap('Owner.Profile', (Map<String,Object>) accRecord),
            'Unexpected profile map'
        );

        // Test return null with exceptions turned off
        Jsn.setThrowException(false);

        // Test invalid field without exception top level
        Assert.areEqual(
            null, 
            Jsn.getObjectMap('invalidField', (Map<String,Object>) accRecord),
            'Unexpected Object value'
        );

        // Test invalid field without exception, multiple levels deep
        Assert.areEqual(
            null, 
            Jsn.getObjectMap('invalidField.invalidField',(Map<String,Object>) accRecord),
            'Unexpected Object value'
        );
    }

    
    @IsTest
    static void testGetObjectList(){
        
        // Get the account records, top level
        Object[] accRecords = (Object[]) Jsn.getObjectList('records', (Map<String,Object>) JSON.deserializeUntyped(ACC_CON_JSON));

        // Assert account records
        Assert.areEqual(
            10,
            accRecords.size(),
            'Unexpected number of account records'
        );
        
        // Get the contact records, multiple levels deep
        Object[] conRecords = (Object[]) Jsn.getObjectList('Contacts.records', (Map<String,Object>) accRecords[0]);
        
        
        // Assert contact records
        Assert.areEqual(
            10,
            conRecords.size(),
            'Unexpected number of contact records'
        );

        // Test return null with exceptions turned off
        Jsn.setThrowException(false);

        // Test invalid field without exception top level
        Assert.areEqual(
            null, 
            Jsn.getObjectList('invalidField', (Map<String,Object>) accRecords[0]),
            'Unexpected Object value'
        );

        // Test invalid field without exception, multiple levels deep
        Assert.areEqual(
            null, 
            Jsn.getObjectList('invalidField.invalidField',(Map<String,Object>) accRecords[0]),
            'Unexpected Object value'
        );
        
    }


    /** **************************************************************************************************** **
     **                                     PRIVATE TEST UTILITY METHODS                                     **
     ** **************************************************************************************************** **/
    /**
     * @description Method to get a text body from a static resource
     *              Ideal if you have stored cert data (temporarily) in a static resource or during
     *              apex tests
     * @param       staticResourceName   The developer name of the static resource you want the body
     *                                   value from
     * @return      Static resource body
     * @throws      InvalidDataException There is an issue with the static resource
     */
    private static String getStaticResourceBody(String staticResourceName){
        try{
            return ([SELECT Body FROM StaticResource WHERE Name = :staticResourceName LIMIT 1].Body).toString();
        }catch(System.QueryException e){
            throw new InvalidDataException(String.format(STATIC_RESOURCE_ERROR, new String[]{staticResourceName}));
        }
    }


    /** **************************************************************************************************** **
     **                                     PRIVATE EXCEPTION CLASSES                                        **
     ** **************************************************************************************************** **/
    /**
     * @description An exception that is thrown when something goes wrong retrieving
     *              any (meta) data
     * @note        This class is private and test visible as it should only be ever caught
     *              when an Apex Unit Test is running and never from normal code
     */
    @TestVisible
    private with sharing class InvalidDataException extends Exception{}
}