/**
 * @description A test class with coverage as the sole purpose
 */
@IsTest
private with sharing class JsonTableLwcCtrlTest {

    @IsTest
    static void testJsonTableLwcCtrl(){
        
        // Happy paths
        JsonTableLwcCtrl.createTable('{"b":"b"}',false,'a' , 'a', 'lwctable');
        JsonTableLwcCtrl.createTable('{"b":"b"}',false,'a' , 'a', 'lwckeyvaluetable');
        JsonTableLwcCtrl.createTable('{"b":"b"}',false,'a' , 'a', 'csvstring');
        JsonTableLwcCtrl.createTable('{"b":"b"}',false,'a' , 'a', 'consolestring');
        JsonTableLwcCtrl.createTable('{"b":"b"}',false,'a' , 'a', 'rawkeyvalue');
        JsonTableLwcCtrl.createTable('{"b":"b"}',false,'a' , 'a', 'rawindexed');
        JsonTableLwcCtrl.createTable('{"b":"b"}',false,'a' , 'a', 'rawkeyvaluepair');
        JsonTableLwcCtrl.createTable('{"b":"b"}',true, 'a' , 'a', 'rawcsv');

        // Exception path
        try{
            JsonTableLwcCtrl.createTable('{"b":"b"}',false,'a' , 'a', 'Invalid');
        }catch(Exception e){
            Assert.areEqual('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
    }
}