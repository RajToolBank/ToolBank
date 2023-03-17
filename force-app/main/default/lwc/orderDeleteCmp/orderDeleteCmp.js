import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import deleteOrder from '@salesforce/apex/OrderCancelledCmpController.deleteOrder'

export default class OrderDeleteCmp extends LightningElement {
    @api
    recordId;
    progress = 0;
    isProgressing = false;


        connectedCallback() {
        
            // start
            this.isProgressing = true;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this._interval = setInterval(() => {
                this.progress = this.progress === 100 ? 0 : this.progress + 10;
            }, 200);

            deleteOrder({recordId:this.recordId})
            .then(res =>{
                if(res){
                    this.progress = 100;
                    const evt = new ShowToastEvent({
                        title: "Order cancellation",
                        message: res,
                        variant: res.indexOf("successfully")>0?"success":"error",
                    });
                    this.dispatchEvent(evt);
                    if (this.isProgressing) {
                        // stop
                        this.isProgressing = false;
                        clearInterval(this._interval);
                    }
                }
            }).catch(err=>{
                if(err){
                    const evt = new ShowToastEvent({
                        title: "Order cancellation",
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