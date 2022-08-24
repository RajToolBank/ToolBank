import { LightningElement, wire, api } from 'lwc';
import assetList from '@salesforce/apex/PlaceOrderController.returnAssets';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import TOOL_OBJECT from '@salesforce/schema/Product2';
import JOB_TYPE from '@salesforce/schema/Product2.Job_Type__c';
import HIGHLIGHT from '@salesforce/schema/Product2.Highlights__c';

export default class SelectTool extends LightningElement { 
    assets;
    jobtypes;
    highlights;
    jbtype={};
    highlightColor ={}

    @api orderDetails;
    @api affiliateId;

    @wire(assetList,{searchString: '',affiliateId:'$affiliateId'}) assetsList({data,error}){
        
        if(data){
            //console.log("data");
            //console.log(data);
            this.assets = data;
        }
        if(error){
            console.log("error");
            console.log(error);
        }
    };

    handleSearch(event){
        
        const searchString =event.target.value;
        
        assetList({searchString: searchString,affiliateId:this.affiliateId}).then(res =>{
            console.log(res);
            this.assets = res;
        }).catch(error =>{
            console.log(error);
        });
    }

    @wire(getObjectInfo, { objectApiName: TOOL_OBJECT })
    toolMetadata;

    @wire(getPicklistValues, { recordTypeId: '$toolMetadata.data.defaultRecordTypeId',  fieldApiName: JOB_TYPE }) 
    wiredjobType({data, error}){
        if(data){
            this.jobtypes  = data.values;
            let colorstype ={};
        
            this.jobtypes.forEach(function(value){
                
                var letters = 'BCDEF'.split('');
                var color = '#';
                for (var i = 0; i < 6; i++ ) {
                    color += letters[Math.floor(Math.random() * letters.length)];
                }
                colorstype[value.value]= color;

            });
            this.jbtype = colorstype;            
        }
        if(error){

        }
    };

    @wire(getPicklistValues, { recordTypeId: '$toolMetadata.data.defaultRecordTypeId',  fieldApiName: HIGHLIGHT }) 
    wiredhighlight({data, error}){
        if(data){
            this.highlights  = data.values;

            let colorstype ={};
        
            this.highlights.forEach(function(value){

                var letters = 'BCDEF'.split('');
                var color = '#';
                for (var i = 0; i < 6; i++ ) {
                    color += letters[Math.floor(Math.random() * letters.length)];
                }

                colorstype[value.value]= color;

            });
            this.highlightColor = colorstype;
        }
        if(error){

        }
    };

    handleHighlight(event){
        let state = event.target;
        let template = this.template;
       /* this.highlights.forEach(function(element){
            console.log(element);
            const label  = element.value;
            console.log(label);
            if(label === state.name){
                let commonTool = template.querySelector(`[data-label="`+label+`"]`);
                if(state.checked){
                        commonTool.style.background="green";     
                }else{
                    commonTool.style.background="";
                }
            }
        });*/

        let row = template.querySelectorAll(`tr[data-label]`);
       /* row.forEach(function(ele){
            console.log(ele.dataset.label);
            console.log(state.name);
            
            const label = ele.dataset.label;
            
            if(label && label.indexOf(state.name) >= 0){
                if(state.checked){
                    ele.style.background="green";     
                }else{
                    ele.style.background="";
                }
            }
        });   */

        let colorstype ={};
        
           
        colorstype = this.highlightColor;
        row.forEach(function(ele){
            
            const label = ele.dataset.label;
            if(label.indexOf(state.name) >= 0){
                const color = colorstype[state.name];
                if(state.checked){
                    ele.style.background=color;     
                }else{
                    ele.style.background="";
                }
                
            }
        });
    }

    handleJobType(event){
        let state = event.target;
        let template = this.template;
        let row = template.querySelectorAll(`tr[title]`);
        
        let colorstype ={};
        
           
        colorstype = this.jbtype;
        row.forEach(function(ele){
            
            const title = ele.title;
            if(title.indexOf(state.name) >= 0){
                const color = colorstype[state.name];
                if(state.checked){
                    ele.style.background=color;     
                }else{
                    ele.style.background="";
                }
                
            }
        });   
    }

    handleQuantity(event){
        event.target.value=event.target.value.replace(/[^0-9]/g,'');
        if(event.target.value>0){
            event.target.classList.add("input-number");
        }else{
            event.target.classList.remove("input-number");
        }
    }

    handleSelected(event){
        let state = event.target.checked;
        let template = this.template;
        let input = template.querySelectorAll(`.input-number`);
        let row = template.querySelectorAll(`tr[data-id]`);
        let rowids =[];

        

        input.forEach(function(el){
            let row = el.parentElement.parentElement.parentElement;
            console.log(row.dataset.id);
            rowids.push(row.dataset.id);
        });

        console.log(rowids);

        row.forEach(function(el){
            let rowid = el.dataset.id;
            console.log(rowid);
            console.log(rowids.indexOf(rowid));
            if(rowids.indexOf(rowid)<0){
                if(state)
                    el.style.display = 'none';
                else el.style.display = 'table-row';
            }
        });
       
    }

    handleSelectedCommon(event){
        let state = event.target.checked;
        let template = this.template;
        let row = template.querySelectorAll(`tr[data-id]`);
        console.log(row);
        row.forEach(function(el){
            let rowlabel = el.dataset.label;
            console.log(el);
            console.log(rowlabel);
            //console.log(rowlabel.indexOf("Common Tool"));
            if(rowlabel && rowlabel.indexOf("Common Tool")>=0){
                
            } else{
                if(state)
                    el.style.display = 'none';
                else el.style.display = 'table-row';
            }
        });
    }


    handleContinue = (event) =>{
        event.preventDefault();
        const name = event.target.value;
        let selectedToolsCmp = this.template.querySelectorAll(`.input-number`);
        let qtyerror = this.template.querySelector(`[data-id="qtyerror"]`);
        let tools = [];
        let borrowing = this.orderDetails.duration;
        if(borrowing){
            borrowing = borrowing.replace("weeks", "");
            borrowing = borrowing.replace("week", "");
        }
        let week = parseInt(borrowing)
        let totalToolHandlingFees =0;
        let totalRetailCostOrder =0;
        if(selectedToolsCmp.length > 0){
            qtyerror.innerHTML ="";
            selectedToolsCmp.forEach(function(element){
                let hadlingfee = week * element.dataset.hanlingfee *element.value;
                totalToolHandlingFees += hadlingfee;
                totalRetailCostOrder += element.dataset.price*element.value;
                tools.push({product2Id:element.dataset.id,
                    quantity:element.value,
                    retailPrice:element.dataset.price,
                    toolNote:element.dataset.toolnote,
                    toolName:element.dataset.toolname,
                    category:element.dataset.category,
                    subCategory:element.dataset.subcategory,
                    hanlingFee:hadlingfee,
                    affiliatefee:element.dataset.affilatefee,
                    picture:element.dataset.picture,
                    product2Id:element.dataset.id,
                    assetId:element.dataset.assetid,
                    pbeid:element.dataset.pbe
                });
            });
       
        
            const selectEvent = new CustomEvent('selecttool', {
            detail: { 
                totalToolHandlingFees:totalToolHandlingFees.toFixed(2),
                totalRetailCostOrder:totalRetailCostOrder.toFixed(2),
                tools:tools
                    }
            });
            this.dispatchEvent(selectEvent);
        }else{
            qtyerror.innerHTML ="Please Select at least One Tool."
        }
    }

    hundleSelectToolPrev(event){
        const selectEvent = new CustomEvent('selecttoolprev', {
            detail: "Select Tool Previous Event"
            });
            this.dispatchEvent(selectEvent);
    }

}