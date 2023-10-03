/**
 * @description A test class with coverage as the sole purpose. This should not be deployed in a prod org
 *              but in case you need it for something it's beter to have a bit of coverage.
 */
@IsTest
private with sharing class JsonTableLwcCtrlTest {

    @IsTest
    static void testJsonTableLwcCtrl(){
        JsonTableLwcCtrl.createCsv(  '[[],[]]',  'a' , 'a', true, null, 'random');
        JsonTableLwcCtrl.createTable('{"b":"b"}','a' , 'a', true, null, 'random');
        
        try{
            JsonTableLwcCtrl.createTable('','a' , 'a', true, null, 'random');
        }catch(Exception e){
            Assert.areEqual('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
    }
}