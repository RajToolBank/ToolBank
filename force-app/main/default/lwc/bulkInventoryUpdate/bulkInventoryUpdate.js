import { api,LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BulkInventoryUpdate extends LightningElement {
    @api recordId;
    productIds=[];
    tools;
    showHide = false;
    selectedRecordType;
    subType;
    donatingCompany;
    note="";

    connectedCallback(){
        console.log(this.recordId);
    }

    onselecttool(event){
        console.log(event.detail.tools);
        this.tools = event.detail.tools;
        if(this.tools.length > 0){
            this.showHide = true;
        }else{
            const evt = new ShowToastEvent({
                title: "Tools",
                message: "Please select at least one tool line.",
                variant: "error",
            });
            this.dispatchEvent(evt);
        }
    }

    transactionPrevious(event){
        this.productIds = event.detail.prodIds;
        this.tools = event.detail.toolseleted;
        this.selectedRecordType = event.detail.rectype;
        this.subType = event.detail.subtype;
        this.donatingCompany = event.detail.donatingcompany;
        this.showHide = false;
        this.note = event.detail.note;
    }
}