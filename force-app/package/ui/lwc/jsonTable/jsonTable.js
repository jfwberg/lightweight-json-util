// Lightning stuff
import {LightningElement} from "lwc";

// Custom Utils
import {handleError}      from 'c/util';

// Custom Modals
import cmModal            from 'c/cmModal';
import ldtModal           from 'c/ldtModal';
import textModal          from 'c/textModal';

// apex methods
import createTable        from '@salesforce/apex/JsonTableLwcCtrl.createTable';

// Attribute filter preset
const ATTRIBUTE_FILTER_PRESET = {
    "none" : '',
    "soql" : 'status, warnings, totalSize, done, nextRecordsUrl, attributes',
    "saql" : 'metadata, warnings, query, action, responseId, responseTime',
    "dc"   : 'done, endTime, metadata, queryId, rowCount, startTime, nextBatchId',
};

// Attribute filter preset
const LIST_NAME_FILTER_PRESET = {
    "none" : '',
    "soql" : 'records',
    "saql" : 'records',
    "dc"   : 'data',
};

// Main class
export default class JsonTable extends LightningElement {
	
    // Loading indicator
    loading = false;

    // Button options
    prettifyVariant = 'neutral';

    // Input values
    path                = "";
    //jsonString          = "";
    outputFormatValue   = 'lwctable';
    filterPresetValue   = 'none';
    numberColumn        = false;
    attributeFilterValue= ""
    listNameFilterValue = "";

    // CodeMirror Always set some default values
    codemirrorClass     = 'ta';
	codemirrorLoaded	= false;
	codemirrorMode		= 'text/javascript';
	codemirrorTheme		= 'default';
	codemirrorValue		= '';
	codemirrorDisabled	= false;

    // Result modal codemirror theme
    codemirrorResultTheme = 'default';

    // Output formats
    get filterPresetOptions() {
        return [
            { label: 'None',      value: 'none' },
            { label: 'SOQL',      value: 'soql' },
            { label: 'SAQL',      value: 'saql' },
            { label: 'Data Cloud',value: 'dc'   }
        ];
    }

    // Output formats
    get outputFormatOptions() {
        return [
            { label: 'LWC Datatable',           value: 'lwctable'         },
            { label: 'LWC Key/Value table',     value: 'lwckeyvaluetable' },
            { label: 'CSV String',              value: 'csvstring'        },
            { label: 'Console String',          value: 'consolestring'    },
            { label: 'RAW Key/Value data',      value: 'rawkeyvalue'      },
            { label: 'RAW Indexed data',        value: 'rawindexed'       },
            { label: 'RAW Key/Value Pair data', value: 'rawkeyvaluepair'  },
            { label: 'RAW CSV Data ',           value: 'rawcsv'           }
        ];
    }

    // Method to get the CodeMirror Textarea Child component
    getCmTa(){
        return this.template.querySelector('c-cm-textarea');
    }

    /** **************************************************************************************************** **
     **                                          CREATE TABLE LOGIC                                          **
     ** **************************************************************************************************** **/
    handleClickCreateTable() {
        
        // Show spinner
        this.loading = true;

        try{   
            // Execute Apex
            createTable({ 
                jsonString        : this.getCmTa().value,
                numberColumn      : this.numberColumn,
                attributeFilter   : this.attributeFilterValue,
                listNameFilter    : this.listNameFilterValue,
                outputFormatValue : this.outputFormatValue
            })
            .then(apexResponse => {
                try{
                    // Handle each output format accordingly
                    switch (this.outputFormatValue) {
                        case 'lwctable' :{
                            ldtModal.open({
                                size   : 'large',
                                header : 'Key / Value Table Result',
                                ldt    : apexResponse
                            });
                            break;
                        }

                        case 'lwckeyvaluetable' :{
                            ldtModal.open({
                                size   : 'large',
                                header : 'Key / Value Pair Table Result',
                                ldt    : apexResponse
                            });
                            break;
                        }

                        case 'csvstring' :{
                            cmModal.open({
                                size             : "large",
                                header           : "CSV String",
                                value            : apexResponse,
                                mode             : "csv",
                                theme            : this.codemirrorResultTheme,
                                disabled         : false,
                                
                                // Download info
                                fileName         : 'JSONTableCsvString',
                                fileExtension    : '.csv',
                                fileMimeType     : 'text/csv; charset=utf-8;',
                                includeTimestamp : true,
                                
                                // Button visibillity
                                copyButton       : true,
                                downloadButton   : true,
                                prettifyButton   : false,
                                closeButton      : true
                            });
                            break;
                        }

                        case 'consolestring' : {
                            cmModal.open({
                                
                                // Modal info
                                size             : "large",
                                header           : "Console String Result",
                                value            : apexResponse,
                                mode             : "text/plain",
                                theme            : this.codemirrorResultTheme,
                                disabled         : false,
                                
                                // Download info
                                fileName         : 'JSONTableConsoleString',
                                fileExtension    : '.txt',
                                fileMimeType     : 'text/plain; charset=utf-8;',
                                includeTimestamp : true,
                                
                                // Button visibillity
                                copyButton       : true,
                                downloadButton   : true,
                                prettifyButton   : false,
                                closeButton      : true
                            });
                            break;
                        }

                        case 'rawkeyvalue' :{
                            cmModal.open({
                                
                                // Modal info
                                size             : "medium",
                                header           : "RAW Key/Value Result",
                                value            : JSON.stringify(apexResponse,null,4),
                                mode             : "text/javascript",
                                theme            : this.codemirrorResultTheme,
                                disabled         : false,
                                
                                // Download info
                                fileName         : 'JSONTableKeyValueData',
                                fileExtension    : '.json',
                                fileMimeType     : 'application/json; charset=utf-8;',
                                includeTimestamp : true,
                                
                                // Button visibillity
                                copyButton       : true,
                                downloadButton   : true,
                                prettifyButton   : true,
                                closeButton      : true
                            });
                            break;
                        }

                        case 'rawindexed' :{
                            cmModal.open({
                                // Modal info
                                size             : "medium",
                                header           : "RAW Indexed Data Result",
                                value            : JSON.stringify(apexResponse,null,4),
                                mode             : "text/javascript",
                                theme            : this.codemirrorResultTheme,
                                disabled         : false,
                                
                                // Download info
                                fileName         : 'JSONTableIndexedData',
                                fileExtension    : '.json',
                                fileMimeType     : 'application/json; charset=utf-8;',
                                includeTimestamp : true,
                                
                                // Button visibillity
                                copyButton       : true,
                                downloadButton   : true,
                                prettifyButton   : true,
                                closeButton      : true
                            });
                            break;
                        }

                        case 'rawkeyvaluepair' :{
                            cmModal.open({
                                // Modal info
                                size             : "medium",
                                header           : "RAW Key/Value Pair Data Result",
                                value            : JSON.stringify(apexResponse,null,4),
                                mode             : "text/javascript",
                                theme            : this.codemirrorResultTheme,
                                disabled         : false,
                                
                                // Download info
                                fileName         : 'JSONTableKeyValuePairData',
                                fileExtension    : '.json',
                                fileMimeType     : 'application/json; charset=utf-8;',
                                includeTimestamp : true,
                                
                                // Button visibillity
                                copyButton       : true,
                                downloadButton   : true,
                                prettifyButton   : true,
                                closeButton      : true
                            });
                            break;
                        }

                        case 'rawcsv' :{
                            cmModal.open({
                                // Modal info
                                size             : "medium",
                                header           : "RAW CSV Data Result",
                                value            : JSON.stringify(apexResponse,null,4),
                                mode             : "text/javascript",
                                theme            : this.codemirrorResultTheme,
                                disabled         : false,
                                
                                // Download info
                                fileName         : 'JSONTableCsvData',
                                fileExtension    : '.json',
                                fileMimeType     : 'application/json; charset=utf-8;',
                                includeTimestamp : true,
                                
                                // Button visibillity
                                copyButton       : true,
                                downloadButton   : true,
                                prettifyButton   : true,
                                closeButton      : true
                            });
                            break;
                        }
                    }
                }catch(error){
                    handleError(error);
                }
            })
            .catch(error => {
                handleError(error);
            })
            .finally(() => {
                this.loading = false;
            });
        }catch(error){
            handleError(error);
        }
    }

    
    handleClickPrettify(){
        try{
            this.loading = true;

            // change button color to green
            this.prettifyVariant = 'success';
            
            // Make it pretty
            this.getCmTa().value = JSON.stringify(JSON.parse(this.getCmTa().value),null,4);
            
        }catch(error){
            // Change color to red
            this.prettifyVariant = 'destructive';
            handleError(error);
        }finally{
            this.loading = false;
        }
    }
    

    handleClickHelp(){
        this.handleOpenHelpModal();
    }

    /** **************************************************************************************************** **
     **                                        INPUT CHANGE HANDLERS                                         **
     ** **************************************************************************************************** **/
    handleChangeNumberColumn(event){
        this.numberColumn = event.target.checked;
    }


    handleChangeAttributeFilter(event){
        this.attributeFilterValue = event.target.value;
    }


    handleChangeListNameFilter(event){
        this.listNameFilterValue = event.target.value;
    }


    handleChangeOutputFormat(event) {
        this.outputFormatValue = event.detail.value;
    }


    handleChangeFilterPreset(event) {
        this.filterPresetValue = event.detail.value;

        // Update the preset values
        this.attributeFilterValue = ATTRIBUTE_FILTER_PRESET[this.filterPresetValue];
        this.listNameFilterValue  = LIST_NAME_FILTER_PRESET[this.filterPresetValue]; 
    }


    /** **************************************************************************************************** **
     **                                            MODAL METHODS                                             **
     ** **************************************************************************************************** **/    
    /**
     * Open the help modal
     */
    handleOpenHelpModal(){
        try{
            textModal.open({
                header  : "Lightweight - JSON Util - Help",
                content : "Tool to convert JSON data into ready formatted data tables. Tool to quickly view JSON data with the option to filter. This is a UI for the Lightweight - JSON Util package utility class",
                size    : 'small'
            });
        }catch(error){
            handleError(error);
        }
    }


    // Actions that run once the code mirror windows has been loaded and added to the DOM
    handleCodemirrorLoaded(){
        this.codemirrorLoaded = true;
    }


    handleCodemirrorSave(){
        this.createTable();
    }

    
    // Handle any updates in case the theme changes
    handleThemeChange(event) {
        this.codemirrorResultTheme = event.detail;
    }
}