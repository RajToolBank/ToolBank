import { api,wire, LightningElement } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ORDER_OBJECT from '@salesforce/schema/Product2';
import getTools from '@salesforce/apex/ConfirmOrderPageController.getTools';
import FAMILY from '@salesforce/schema/Product2.Family';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BulkInventoryToolSelectCmp extends LightningElement {

    categories =[];
    toolList;
    @api productRecords;
    @api recordId;
    @api selectedTools;

    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    productMetadata;

    @wire(getTools, { toolIds: '$productRecords',  accid:'$recordId'}) 
        tools({data,error}){
            console.log(data);
            if(data){
                this.toolList = data;
            }
            else if(error){
                alert(error);
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
    
    handleCancel(event){
        location.reload();
    }

    handleSearch(event){
        let searchFilter = this.template.querySelector(`[data-id="searchTool"]`);

        let categoryFilter = this.template.querySelector(`[data-id="CategoryFilter"]`);
        console.log(searchFilter.value);
        console.log(JSON.parse(JSON.stringify(this.productRecords)));
        getTools({toolIds: this.productRecords, accid:this.recordId, searchString: searchFilter.value,category:categoryFilter.value}).then(res =>{
            console.log(res);
            this.toolList = res;
        }).catch(error =>{
            console.log(error);
        });
    }

    handleQuantity(event){
        event.target.value=event.target.value.replace(/[^0-9]/g,'');
        let qtyTT = event.target.value;
        console.log(event.target);
        let qtyid = event.target.dataset.qtyid;
        if(parseInt(qtyTT) > 0){
            let name = this.template.querySelector(`[data-assetid="`+qtyid+`"]`);
            name.classList.add("input-number");
        }else{
            let name = this.template.querySelector(`[data-assetid="`+qtyid+`"]`);
            name.classList.remove("input-number");
        }
        
    }

    selectTool(event){
        console.log(event.target);
        const id = event.target.value;
        console.log(id);
        let name = this.template.querySelector(`[data-assetid="`+id+`"]`);
        
        console.log(name);
        if(event.target.checked){
            name.classList.add("input-number");
        }else{
            name.classList.remove("input-number");
        }
    }

    onAddselectedTool(event){

        let toolsItem = [];
        let state = this.template;
        let selectedToolsCmp = this.template.querySelectorAll(`.input-number`);
        if(this.selectedTools){
            toolsItem =   JSON.parse(JSON.stringify(this.selectedTools));          
        }
        let qtyError = false;
        let products = JSON.parse(JSON.stringify(this.productRecords));
        let count =products.length;
        if(selectedToolsCmp || this.selectedTools.length > 0){

            if(selectedToolsCmp){
                selectedToolsCmp.forEach(function(ele){
                    let qtyid = state.querySelector(`[data-qtyid="`+ele.dataset.assetid+`"]`);
                    let tool ={
                        "Id":count,
                        "InventoryId":ele.dataset.assetid,
                        "Product2Id":ele.dataset.prod2id,
                        "Name":ele.dataset.name,
                        "OnshelfQty":ele.dataset.onshelf,
                        "Quantity":qtyid.value
                    }

                    
                        let checkbox = state.querySelector(`[data-id="`+ele.dataset.assetid+`"]`);
                        let row = state.querySelector(`[data-rowid="`+ele.dataset.assetid+`"]`);
                        checkbox.checked = false;
                        ele.classList.remove("input-number");
                        row.style.display = "none";
                        toolsItem.push(tool);
                        products.push(tool.Product2Id);
                    
                    count++;
                });
            }

            
            
                this.productRecords = products;
                
                const selectEvent = new CustomEvent('selecttool', {
                    detail: { 
                        tools:toolsItem
                            }
                    });
                this.dispatchEvent(selectEvent);
            

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