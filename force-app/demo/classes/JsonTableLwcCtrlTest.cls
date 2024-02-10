/**
 * @description A test class with coverage as the sole purpose. This should not be deployed in a prod org
 *              but in case you need it for something it's beter to have a bit of coverage.
 */
@IsTest
private with sharing class JsonTableLwcCtrlTest {

    @IsTest
    static void testJsonTableLwcCtrl(){
        JsonTableLwcCtrl.createCsv(  '[[],[]]',  false, 'a' , 'a', 'random');
        JsonTableLwcCtrl.createTable('{"b":"b"}',false,'a' , 'a', 'random');
        
        try{
            JsonTableLwcCtrl.createTable('',false,'a' , 'a', 'random');
        }catch(Exception e){
            Assert.areEqual('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
    }
}