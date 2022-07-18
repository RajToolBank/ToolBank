import { api, LightningElement,wire } from 'lwc';
import getProducts from '@salesforce/apex/AdditionalChargesController.getProducts';
import addProducts from '@salesforce/apex/AdditionalChargesController.addProducts';

export default class AdditionalChargesCmp extends LightningElement {

    @api
    recordId;
    products;
    @wire(getProducts,({}))
    getAllProducts({data,error}){
        if(data){
            console.log( data);
            this.products = data;  
        }
        if(error){
            console.log(error);
        }
    }

    handleSelectAll(event){
        let state = this.template;
        let getAllTools = state.querySelectorAll(`.filtered`);

        getAllTools.forEach(function(ele){
                ele.checked = event.target.checked;
        });
    }

    handleAddProducts(event){

        let state = this;
        let getAllTools = state.template.querySelectorAll(`[data-id="dataid"]`);
        let itemList = [];

        getAllTools.forEach(function(ele){
            const recid = ele.dataset.pbeid;
            console.log(recid);
            const check = state.template.querySelectorAll(`[data-recid="`+recid+`"]`);
            console.log(check);
            console.log(check[0].checked);
            if(check[0].checked){
                let item = {
                    pbeid:recid,
                    unitprice:ele.dataset.unitprice,
                    qty:1,
                    orderId:state.recordId,
                    type:ele.dataset.type,
                    category:ele.dataset.category
                }

                itemList.push(item);
            }
        });

        console.log(itemList);

        addProducts({orderItems:JSON.stringify(itemList) }).then(res=>{
            console.log(res);
            alert("Charges Added successfully");
        }).catch(error=>{
            console.log(error);
        });
    }
}