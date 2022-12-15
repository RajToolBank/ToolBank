import { api, LightningElement,wire } from 'lwc';
import getProducts from '@salesforce/apex/AdditionalChargesController.getProducts';
import addProducts from '@salesforce/apex/AdditionalChargesController.addProducts';
import getAdditionProducts from '@salesforce/apex/AdditionalChargesController.getAdditionProducts';
import deleteItems from '@salesforce/apex/AdditionalChargesController.deleteItems';
import getOrder from '@salesforce/apex/AdditionalChargesController.getOrder';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import MembershipFeePBEId from '@salesforce/label/c.MembershipFeePBEId';

export default class AdditinalChargesRelatedListCmp extends LightningElement {

    @api
    recordId;
    showComp = false;
    products;
    options;
    orderlink;
    membershipFee;
    num;

    label = {
        MembershipFeePBEId
    };

    @wire(getProducts)
    getAllProducts({data,error}){
        if(data){
            if(this.recordId.startsWith("801"))
                this.showComp = true; 
            let optlist =[];
            for(let i in data){
                let item = { label: data[i].Product2.Name, 
                    value: data[i].Id,
                    category: data[i].Product2.Family };
                optlist.push(item);
            }
            this.options = optlist;
            
            console.log( this.options); 
            this.orderlink = "/lightning/r/Order/"+this.recordId+"/related/OrderItems/view";
        }
        if(error){
            if(this.recordId.startsWith("Hello"))
                this.showComp = true; 
            console.log(error);
        }
    }

    @wire(getOrder,{orderId: '$recordId'})
    getOrder({data,error}){
        if(data){
            console.log(data);
            this.membershipFee = data.Affiliate__r.Membership_Fees_Amount__c;
        }else if(error){

        }
    }

    @wire(getAdditionProducts,{orderid: '$recordId'})
    additionProducts({data,error}){
        if(data){
            let itemlist = JSON.parse(JSON.stringify(data));
            for(let i in itemlist){
                itemlist[i].index = i;
                itemlist[i].edit = false;
                itemlist[i].UnitPrice = itemlist[i].UnitPrice.toFixed(2);
            }
            this.products = itemlist;  
            this.num = data.length;
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

       
        let itemList = JSON.parse(JSON.stringify(this.products));
        
        itemList.push({index:itemList.length,edit:true,UnitPrice:0.00,Description:""});
        
        console.log(itemList);

        this.products =itemList;

    }

    handleChange(event) {
        console.log(event.detail.value);
        console.log(MembershipFeePBEId);
        console.log(this.membershipFee);
        const index = event.target.dataset.index;
        const recId = event.target.dataset.dropid;
        const pbeId = event.detail.value;
        const category = event.target.options.find(opt => opt.value === pbeId).category;
        let unitpriceEle = this.template.querySelector(`[data-inputindex="`+index+`"]`);
        let descripEle = this.template.querySelector(`[data-descripindex="`+index+`"]`);
        const unitprice = unitpriceEle.value != "NaN"?parseFloat(unitpriceEle.value):0;
        let itemList = JSON.parse(JSON.stringify(this.products));
        let item = {};
        item.Id = recId?recId:null;
        item.PricebookEntryId = pbeId;
        item.edit = true;
        item.UnitPrice = pbeId === MembershipFeePBEId?this.membershipFee: unitprice.toFixed(2);
        item.OrderId = this.recordId;
        item.qty=1;
        item.Description = descripEle.value;
        item.type='Additional Charges';
        item.category = category;
        item.index = index;
        itemList[index] = item;
        this.products =itemList;

    }

    handlePriceChange(event) {
        
        const index = event.target.dataset.inputindex;
        const recId = event.target.dataset.priceid;
        console.log(index);
        let item = JSON.parse(JSON.stringify(this.products[index]));
        let pbeId;
        let category;
        let pbeIdEle = this.template.querySelector(`[data-index="`+index+`"]`);
        let descripEle = this.template.querySelector(`[data-descripindex="`+index+`"]`);
        console.log(pbeIdEle);
        if(pbeIdEle){ 
            pbeId = pbeIdEle.value;
            if(pbeIdEle.options)
            category = pbeIdEle.options.find(opt => opt.value === pbeId).category;
            item.PricebookEntryId = pbeId;
            item.category = category;
        }
        console.log(event.target.value);
        let unitprice = event.target.value;// != "NaN"?parseFloat(event.target.value):0;

        console.log(unitprice);
        console.log(pbeId);
        let itemList = JSON.parse(JSON.stringify(this.products));
        
        item.Id = recId?recId:null;
        
        item.edit = true;
        item.UnitPrice = unitprice;
        item.OrderId = this.recordId;
        item.qty=1;
        item.Description = descripEle.value;
        item.type='Additional Charges';
        
        item.index = index;
        itemList[index] = item;
        this.products =itemList;

    }

    handleDescripChange(event){
        const index = event.target.dataset.descripindex;
        const recId = event.target.dataset.descripid;
        console.log(index);
        let item = JSON.parse(JSON.stringify(this.products[index]));
        let pbeId;
        let category;
        let pbeIdEle = this.template.querySelector(`[data-index="`+index+`"]`);
        console.log(pbeIdEle);
        if(pbeIdEle){ 
            pbeId = pbeIdEle.value;
            category = pbeIdEle.options.find(opt => opt.value === pbeId).category;
            item.PricebookEntryId = pbeId;
            item.category = category;
        }
        const descrip = event.target.value;
        let unitpriceEle = this.template.querySelector(`[data-inputindex="`+index+`"]`);
        const unitprice = unitpriceEle.value != "NaN"?parseFloat(unitpriceEle.value):0;
        
        console.log(unitprice);
        console.log(pbeId);
        let itemList = JSON.parse(JSON.stringify(this.products));

        item.Id = recId?recId:null;

        item.edit = true;
        item.UnitPrice = unitprice.toFixed(2);
        item.OrderId = this.recordId;
        item.qty=1;
        item.type='Additional Charges';
        item.Description = descrip;
        item.index = index;
        itemList[index] = item;
        this.products =itemList;
    }

    handleEdit(event){
        const index = event.target.dataset.editindex;
        let itemlist = JSON.parse(JSON.stringify(this.products));
            for(let i in itemlist){
                if(index === itemlist[i].index)
                    itemlist[i].edit = true;
            }
            this.products = itemlist; 
    }

    handleDelete(event){
        const index = event.target.dataset.deleteindex;
        console.log(index );
        let itemlistToDelete = [];
        let itemlist = JSON.parse(JSON.stringify(this.products));
            for(let i in itemlist){
                if(index === itemlist[i].index ){
                    if(itemlist[i].Id){
                        itemlistToDelete.push(itemlist[i]);
                        itemlist.splice(i,1); 
                    }else{
                        
                        itemlist.splice(i,1); 
                    }
                }
            }
            this.products = itemlist;
            console.log(this.products);
            deleteItems({orderItems:JSON.stringify(itemlistToDelete) }).then(res=>{
                console.log(res);
                let getitemlist = JSON.parse(JSON.stringify(res));
                for(let i in getitemlist){
                    getitemlist[i].index = i;
                    getitemlist[i].edit = false;
                    getitemlist[i].UnitPrice = getitemlist[i].UnitPrice.toFixed(2);
                }
                this.products = getitemlist;  
                this.num = res.length;
            // alert("Charges Added successfully");
                const evt = new ShowToastEvent({
                    title: "Delete Additional Charges",
                    message: "Deleted Successfully",
                    variant: "success",
                });
                this.dispatchEvent(evt);
            }).catch(error =>{
                console.log(error);
                const evt = new ShowToastEvent({
                    title: "Delete Additional Charges",
                    message: "Charges not deleted, please try again or reach out to admin",
                    variant: "error",
                });
                this.dispatchEvent(evt);
            })
           
    }

    handleSaveProducts(event){
        console.log(this.products );
         addProducts({orderItems:JSON.stringify(this.products) }).then(res=>{
            console.log(res);
            let itemlist = JSON.parse(JSON.stringify(res));
            for(let i in itemlist){
                itemlist[i].index = i;
                itemlist[i].edit = false;
                itemlist[i].UnitPrice = itemlist[i].UnitPrice.toFixed(2);
            }
            this.products = itemlist;  
            this.num = res.length;
           // alert("Charges Added successfully");
           getRecordNotifyChange([{ recordId: this.recordId }]);
            const evt = new ShowToastEvent({
                title: "Add Additional Charges",
                message: "Charges Added Successfully",
                variant: "success",
            });
            this.dispatchEvent(evt);
        }).catch(error=>{
            console.log(error);
            const evt = new ShowToastEvent({
                title: "Add Additional Charges",
                message: "Charges not Added, please try again or reach out to admin",
                variant: "error",
            });
            this.dispatchEvent(evt);
        });
    }
}