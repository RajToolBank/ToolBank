import { api, LightningElement } from 'lwc';
import createCommuinityUser from '@salesforce/apex/EnableContactAsCommunityUser.createCommuinityUser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EnableContactasCustomerUser extends LightningElement {

    @api
    recordId;
    progress = 0;
    isProgressing = false;


    connectedCallback() {
        
            // start
            this.isProgressing = true;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this._interval = setInterval(() => {
                this.progress = this.progress === 100 ? 0 : this.progress + 1;
            }, 200);
        
        createCommuinityUser({recordId:this.recordId}).then(res =>{
            if(res){
                this.progress = 100;
                const evt = new ShowToastEvent({
                    title: "Enable Contact as user",
                    message: "User Enabled Success",
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
                    title: "Enable Contact as user",
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