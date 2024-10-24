import { api, LightningElement } from 'lwc';
import disableContact from '@salesforce/apex/EnableContactAsCommunityUser.disableContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DisableContact extends LightningElement {
    @api recordId;
    progress = 0;
    isProgressing = false;


    connectedCallback() {
        
            // start
            this.isProgressing = true;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this._interval = setInterval(() => {
                this.progress = this.progress === 100 ? 0 : this.progress + 1;
            }, 200);
            
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const contactId = urlParams.get('recordId');
        console.log(contactId);    
        console.log(this.recordId);  

        disableContact({recordId:this.recordId}).then(res =>{
            if(res){
                this.progress = 100;
                const evt = new ShowToastEvent({
                    title: "Disable Portal User",
                    message: "User has been disabled.",
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
                    title: "Disable Portal User",
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