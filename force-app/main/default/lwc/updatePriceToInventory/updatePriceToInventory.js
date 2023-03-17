import { LightningElement } from 'lwc';
import runBatch from '@salesforce/apex/BatchUpdatePriceOnInventory.runBatch';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UpdatePriceToInventory extends LightningElement {

    progress = 0;
    isProgressing = false;

   

    connectedCallback() {
        
        // start
        this.isProgressing = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._interval = setInterval(() => {
            this.progress = this.progress === 100 ? 0 : this.progress + 1;
        }, 200);

        runBatch().then(res =>{
            if(res){
                this.progress = 100;
                const evt = new ShowToastEvent({
                    title: "Batch Process",
                    message: "Batch is successfully queued",
                    variant: "success",
                });
                this.dispatchEvent(evt);
                if (this.isProgressing) {
                    // stop
                    this.isProgressing = false;
                    clearInterval(this._interval);
                }
            }
        }).catch(err =>{
            console.log(err);
            if(err){
                const evt = new ShowToastEvent({
                    title: "Batch Process",
                    message: err.body.message,
                    variant: "error",
                });
                this.dispatchEvent(evt);
                if (this.isProgressing) {
                    // stop
                    this.isProgressing = false;
                    clearInterval(this._interval);
                }
            }
        })
    }

    disconnectedCallback() {
        clearInterval(this._interval);
    }
}