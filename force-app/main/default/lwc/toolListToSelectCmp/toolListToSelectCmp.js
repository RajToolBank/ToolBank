import { api,wire, LightningElement } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ORDER_OBJECT from '@salesforce/schema/Product2';
import getTools from '@salesforce/apex/ConfirmOrderPageController.getTools';
import FAMILY from '@salesforce/schema/Product2.Family';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ToolListToSelectCmp extends LightningElement {

    categories =[];
    toolList;
    @api productRecords;
    @api recordId;
    @api orderDetail;
    @api timeZone;

    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    productMetadata;

    @wire(getTools, { toolIds: '$productRecords',  accid:'$orderDetail.Affiliate__c'}) 
        tools({data,error}){
            if(data){
                this.toolList = data;
                console.log(this.toolList)
            }
            else if(error){
                console(error);
                const evt = new ShowToastEvent({
                    title: "Tools",
                    message: error,
                    variant: "error",
                });
                this.dispatchEvent(evt);
            }
        };


    @wire(getPicklistValues, { recordTypeId: '$productMetadata.data.defaultRecordTypeId',  fieldApiName: FAMILY }) 
        wiredCategory({data, error}){
            if(data){
                this.categories = data.values;
                console.log(data.values);
            }
            if(error){

            }
        };

    handleSearch(event){
        let searchFilter = this.template.querySelector(`[data-id="searchTool"]`);

        let categoryFilter = this.template.querySelector(`[data-id="CategoryFilter"]`);
        console.log(searchFilter.value);
        console.log(JSON.parse(JSON.stringify(this.productRecords)));
        getTools({toolIds: this.productRecords, accid:this.orderDetail.Affiliate__c, searchString: searchFilter.value,category:categoryFilter.value}).then(res =>{
            console.log(res);
            this.toolList = res;
        }).catch(error =>{
            console.log(error);
        });
    }

    handleQuantity(event){
        event.target.value=event.target.value.replace(/[^0-9]/g,'');
        
    }

    selectTool(event){
        console.log(event.target);
        const id = event.target.value;
        console.log(id);
        let qty = this.template.querySelector(`[data-qty="`+id+`"]`);
        
        console.log(qty);
        if(event.target.checked){
            qty.classList.add("input-number");
        }else{
            qty.classList.remove("input-number");
        }
    }

    onAddselectedTool(event){

        let toolsItem = [];
        let state = this.template;
        let selectedToolsCmp = this.template.querySelectorAll(`.input-number`);
        let pickdate = this.orderDetail.EffectiveDate;
        console.log(pickdate);
        if(!pickdate) 
            pickdate = this.orderDetail.Desired_Pickup_Date__c;
        
        console.log(pickdate);
        let borrowing = this.orderDetail.Requested_Borrowing_Period__c;
        let borrow = "";
        if(borrowing){
            borrow = borrowing.replace("weeks", "");
            borrow = borrowing.replace("week", "");
        }
        
        pickdate = window.moment(pickdate);
        console.log(pickdate);
        let week = borrow?parseInt(borrow):1;
        const days = week*7;
        console.log(days);
        let retDate = pickdate.add(days,'days');
        console.log(retDate);
        let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(retDate);
        let mo = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(retDate);
        let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(retDate);
        retDate = `${ye}-${mo}-${da}`;
        console.log(retDate);
        
        let qtyError = false;
        let products = JSON.parse(JSON.stringify(this.productRecords));
        let count =products.length;
        if(selectedToolsCmp.length > 0){
            selectedToolsCmp.forEach(function(ele){
                if(!ele.value){
                    ele.style.borderColor="red";
                    qtyError = true;
                }
            });

            if(qtyError){
                const evt = new ShowToastEvent({
                    title: "Tools",
                    message: "Quantity is Missing for some tools please review.",
                    variant: "error",
                });
                this.dispatchEvent(evt);
                return;
            }

            selectedToolsCmp.forEach(function(ele){
                console.log(ele);
                let affiliateFee = parseInt(ele.dataset.handlingfee);
                let unitprice = parseFloat(ele.dataset.price);
                const handleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*week).toFixed(2);
                let qty =parseInt(ele.value);
                let totalFee = (handleFeePerTool*qty).toFixed(2);
                let tool ={
                    Id:count,
                    Product2:{
                                Name:ele.dataset.name,
                                Tool_Note__c:ele.dataset.note,
                                Id:ele.dataset.prod2id
                             },
                    Inventory_Tool__r:{
                                        On_Shelf_Quantity_F__c:ele.dataset.onshelfqty
                                    },
                    Product2Id:ele.dataset.prod2id,
                    Lowest_Available_Quantity_For_this_Item__c:"",
                    Quantity:ele.value,
                    Reserved_Quantity__c:ele.value,
                    Affiliate_Handling_Fee__c:affiliateFee,
                    UnitPrice:ele.dataset.price,
                    Inventory_Tool__c:ele.dataset.assetid,
                    PricebookEntryId:ele.dataset.qty,
                    Schedule_Return_Date__c:retDate,
                    Requested_Borrowing_Period__c:week+" "+(week===1?"week":"weeks"),
                    Status__c:"Unconfirmed",
                    Tool_Handling_Fee_Per_Item__c:handleFeePerTool,
                    Total_Handling_Fee__c:totalFee
                }

                if(!ele.value){
                    ele.style.borderColor="red";
                    qtyError = true;
                }
                else{
                    let checkbox = state.querySelector(`[data-id="`+ele.dataset.qty+`"]`);
                    let row = state.querySelector(`[data-rowid="`+ele.dataset.qty+`"]`);
                    checkbox.checked = false;
                    ele.classList.remove("input-number");
                    row.style.display = "none";
                    toolsItem.push(tool);
                    products.push(tool.Product2.Id);
                }
                count++;
            });

            
            if(!qtyError){
                this.productRecords = products;
                
                const selectEvent = new CustomEvent('selecttool', {
                    detail: { 
                        tools:toolsItem
                            }
                    });
                this.dispatchEvent(selectEvent);
            }

        }else{
            const evt = new ShowToastEvent({
                title: "Tools",
                message: "Please select at least one tool line.",
                variant: "error",
            });
            this.dispatchEvent(evt);
        }

        
    }
}