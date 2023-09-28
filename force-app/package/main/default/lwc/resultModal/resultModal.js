import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class ResultModal extends LightningModal {
    @api content;

    // Data table data
	data;

	// Columns for the data table
	columns;

    handleClose() {
        this.disconnectedCallback();
        this.close();
    }

    resizeTable = () => {
        try{
            let box = this.template.querySelector("lightning-modal-body")
            let tableWrapper = this.template.querySelector(".tableWrapper");
            tableWrapper.style.height = null;
            tableWrapper.style.height = (box.offsetHeight - 44) + "px";
        }catch(error){
            console.log(error.message);
        }
    };


    connectedCallback(){
        try{
            window.addEventListener('resize', this.resizeTable);

            setTimeout(() => {
                let box = this.template.querySelector("lightning-modal-body")
                let tableWrapper = this.template.querySelector(".tableWrapper");
                tableWrapper.style.height = null;
                tableWrapper.style.height = (box.offsetHeight - 44) + "px";
            }, 500);
            
        }catch(error){
            console.log(error.message);
        }
    }

    disconnectedCallback(){
        try{
            window.removeEventListener('resize',this.resizeTable);
        }catch(error){
            console.log(error.message);
        }
    }
}