import { api, LightningElement, track, wire } from 'lwc';
import getValues from '@salesforce/apex/CreateTransaction.getValues'

export default class DependentPicklistCmp extends LightningElement {
    @api objectApiName;
    @api objectRecordTypeId;
    @api controllerFieldApiName;
    @api controllerFieldLabel;
    @api dependentFieldApiName;
    @api dependentFieldLabel;

    @track dependentPicklist =[];
     selectedValue;

  

    connectedCallback() {
        getValues({objectType:this.objectApiName, recordTypeId:this.objectRecordTypeId, fieldName:this.dependentFieldApiName})
        .then(res=>{
            console.log(res);
            this.dependentPicklist = res;
            if(this.objectRecordTypeId === "0124R000001u3lGQAQ" ){
                this.selectedValue = "Lost from Inventory";
                const selectType = new CustomEvent('selecttype', {
                    detail: { 
                        value:this.selectedValue
                    }
                });
                this.dispatchEvent(selectType);
            }
        }).catch(err => {
            console.log(err);
        })
    }

    selectValue(event){
        event.preventDefault();
        this.selectedValue = event.target.value;
        console.log(this.selectedValue);

        const selectType = new CustomEvent('selecttype', {
            detail: { 
                value:this.selectedValue
            }
        });
        this.dispatchEvent(selectType);
    }
}