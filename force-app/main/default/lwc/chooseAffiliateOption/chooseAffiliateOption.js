import { LightningElement,wire } from 'lwc';
import getAffiliate from '@salesforce/apex/PlaceOrderController.getAffiliate';

export default class ChooseAffiliateOption extends LightningElement {

    affiliates=[];

    @wire(getAffiliate) getAffAcc({data,error}){
        if(data){
            let affiliateList =[];
            for(var i in data){
                let item = { label: data[i].Name, value: data[i].Id };

                affiliateList.push(item);
            }
            this.affiliates=affiliateList;
            /*this.affiliates = [
                { label: 'New', value: 'new' },
                { label: 'In Progress', value: 'inProgress' },
                { label: 'Finished', value: 'finished' },
            ];*/
        }else if(error){
            console.log(error);
        }
        console.log(this.affiliates);
    }

    handleAffiliateSelect(event){
        let data = event.detail.value;

        const selectEvent = new CustomEvent('selectaffilate', {
            detail: {
                affiliateId:data
            }
        });

        this.dispatchEvent(selectEvent);
    }
}