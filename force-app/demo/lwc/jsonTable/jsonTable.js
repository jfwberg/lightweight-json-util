import LightningModal   from 'lightning/modal';
import LightningAlert   from 'lightning/alert';
import TableResultModal from 'c/resultModal';
import CsvResultModal   from 'c/csvResultModal';
import createCsv        from '@salesforce/apex/JsonTableLwcCtrl.createCsv';
import createTable      from '@salesforce/apex/JsonTableLwcCtrl.createTable';

export default class JsonTable extends LightningModal {
	
	// Some magic to work around the caching issues with Apex Data
	_cacheBust = Math.random();

    // Loading indicator
    loading = false;

    height;
    width;

    // Configuration attributes for our data table creation
    jsonString       = "";
    attributeFilter  = "attributes, totalSize, done, nextRecordsUrl"
    includeChildLists= true;
    listNameFilter   = "records";
    startPath        = "";


    /** **************************************************************************************************** **
     **                                          CREATE TABLE LOGIC                                          **
     ** **************************************************************************************************** **/
	handleClickCreateTable() {
		
        this.loading =true;
			
        createTable({ 
            jsonString        : this.jsonString,
            attributeFilter   : this.attributeFilter,
            listNameFilter    : this.listNameFilter,
            includeChildLists : this.includeChildLists,
            path              : this.startPath,
            cacheBust         : this._cacheBust
        })
        .then(data => {
            try{
                // Create lightning data columns for the result table in the modal
                let columns = [];    

                for (let index = 0; index <data.columns.length; index++) {
                    columns.push({ 
                        label        : data.columns[index],
                        fieldName    : data.columns[index],
                        initialWidth : data.columns[index].length < 10 ? 120 : (data.columns[index].length * 12)
                    });
                }

                // Open the modal
                this.handleOpenTableResultModal({"columns" : columns, "data" : data.data});

            }catch(error){
                LightningAlert.open({
                    message: error.message,
                    label: 'Error',
                    theme : 'error'
                });
            }
        })
        .catch(error => {
            LightningAlert.open({
                message: error.body.message,
                label: 'Error',
                theme : 'error'
            });
        })
        .finally(() => {
            this.loading = false;
        });
		
	}


    /** **************************************************************************************************** **
     **                                           CREATE CSV LOGIC                                           **
     ** **************************************************************************************************** **/
    handleClickCreateCsv() {
		
        this.loading =true;
			
        createCsv({ 
            jsonString        : this.jsonString,
            attributeFilter   : this.attributeFilter,
            listNameFilter    : this.listNameFilter,
            includeChildLists : this.includeChildLists,
            path              : this.startPath,
            cacheBust         : this._cacheBust
        })
        .then(data => {
            try{
                // Open the modal
                this.handleOpenCsvResultModal(data);

            }catch(error){
                LightningAlert.open({
                    message: error.message,
                    label: 'Error',
                    theme : 'error'
                });
            }
        })
        .catch(error => {
            LightningAlert.open({
                message: error.body.message,
                label: 'Error',
                theme : 'error'
            });
        })
        .finally(() => {
            this.loading = false;
        });
    }


    /** **************************************************************************************************** **
     **                                            MODAL METHODS                                             **
     ** **************************************************************************************************** **/    
    async handleOpenTableResultModal (content) {
        const result = await TableResultModal.open({
            size: 'large',
            description: 'Table Create Results',
            content: content,
        });
    }


    async handleOpenCsvResultModal(content) {
        const result = await CsvResultModal.open({
            size: 'large',
            description: 'CSV Create Results',
            content: content,
        });
    }


    /** **************************************************************************************************** **
     **                                        INPUT CHANGE HANDLERS                                         **
     ** **************************************************************************************************** **/
    handleChangeJsonString(event){
        this.jsonString = event.target.value;
    }


    handleChangeAttributeFilter(event){
        this.attributeFilter = event.target.value;
    }


    handleChangeListNameFilter(event){
        this.listNameFilter = event.target.value;
    }


    handleChangeIncludeChildLists(event){
        this.includeChildLists = event.target.checked;
    }

    handleChangeStartPath(event){
        this.startPath = event.target.value;
    }
}