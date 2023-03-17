import { api, LightningElement, wire } from 'lwc';
import getOrderItems from '@salesforce/apex/ReturnOrderController.getOrderItems';
import getOrderItemsDirect from '@salesforce/apex/ReturnOrderController.getOrderItemsDirect';
import saveOrder from '@salesforce/apex/ReturnOrderController.saveOrder';
import TOOL_RETURN_FIELD from '@salesforce/schema/Order.Tools_Returned_By__c';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ReturnOrderCmp extends NavigationMixin(LightningElement)  {

    toolReturnedField = TOOL_RETURN_FIELD;

    @api
    recordId;
    loaded = false;
    readOnly = false;
    order;
    schPickTime;
    setReturnDate = false;
    orderItems;
    returnOrderItems;
    allOrderItems;
    filters = [
        {label:"All", value:"All"},
        {label:"Still out", value:"Still out"},
        {label:"Returned", value:"Returned"},
        {label:"Partially Returned", value:"Partially Returned"}
    ];

    extendDays;
    matchingDate;
    
    @wire(getOrderItems,({orderId:'$recordId'}))
        getAllItems({data,error}){
            if(data){
                console.log( data);
                this.order = data.order; 
                this.readOnly = data.readOnly;
                let totalTimeInSeconds = (data.order.Scheduled_Pickup_Time__c/1000);
                let result = new Date(null, null, null, null, null, totalTimeInSeconds);
                let tempTime = result.toTimeString().split(' ')[0].substring(0,5)
                tempTime = tempTime.split(':');
                if(data.order.Scheduled_Pickup_Time__c && tempTime){
                    const hour = parseInt(tempTime[0]) >12 && parseInt(tempTime[0]) !== 0 && parseInt(tempTime[0]) !== 12 ?(parseInt(tempTime)-12):(parseInt(tempTime[0]) === 0?12:tempTime[0]);
                    const hour12 =  parseInt(tempTime[0]) >=12?"PM":"AM";
                    this.schPickTime = hour+':'+tempTime[1]+' '+hour12;
                }

                let itemlist = JSON.parse(JSON.stringify(data.orderItems));
                for(let i in itemlist){
                    console.log( itemlist[i].UnitPrice);
                    itemlist[i].orderItem.UnitPrice = itemlist[i].orderItem.UnitPrice.toFixed(2);
                }

                let returnitemlist = JSON.parse(JSON.stringify(data.returnOrderItems));
                for(let i in returnitemlist){
                    returnitemlist[i].orderItem.UnitPrice = returnitemlist[i].orderItem.UnitPrice.toFixed(2);
                }

                this.orderItems = itemlist;
                this.allOrderItems = itemlist;
                this.returnOrderItems = returnitemlist;
            }
            if(error){
                console.log(error);
            }

            console.log( this.orderItems);
        }

    handleUndo(){
        this.loaded = true;
        let state = this;
        state.orderItems = [];
        state.allOrderItems = [];
        state.returnOrderItems = [];
        let recid = this.recordId
        getOrderItemsDirect({orderId: recid}).then(res =>{
            console.log( res);
                state.order = res.order; 
                let totalTimeInSeconds = (res.order.Scheduled_Pickup_Time__c/1000);
                let result = new Date(null, null, null, null, null, totalTimeInSeconds);
                let tempTime = result.toTimeString().split(' ')[0].substring(0,5)
                tempTime = tempTime.split(':');
                if(res.order.Scheduled_Pickup_Time__c && tempTime){
                    const hour = parseInt(tempTime[0]) >12 && parseInt(tempTime[0]) !== 0 && parseInt(tempTime[0]) !== 12 ?(parseInt(tempTime)-12):(parseInt(tempTime[0]) === 0?12:tempTime[0]);
                    const hour12 =  parseInt(tempTime[0]) >=12?"PM":"AM";
                    state.schPickTime = hour+':'+tempTime[1]+' '+hour12;
                }

                let itemlist = JSON.parse(JSON.stringify(res.orderItems));
                for(let i in itemlist){
                    console.log( itemlist[i].UnitPrice);
                    itemlist[i].orderItem.UnitPrice = itemlist[i].orderItem.UnitPrice.toFixed(2);
                }

                let returnitemlist = JSON.parse(JSON.stringify(res.returnOrderItems));
                for(let i in returnitemlist){
                    returnitemlist[i].orderItem.UnitPrice = returnitemlist[i].orderItem.UnitPrice.toFixed(2);
                }

                state.orderItems = itemlist;
                state.allOrderItems = itemlist;
                state.returnOrderItems = returnitemlist;
                state.loaded = false;
        }).catch(error =>{
            const evt = new ShowToastEvent({
                title: "Return Tools",
                message: error,
                variant: "error",
            });
            this.dispatchEvent(evt);
            state.loaded = false;
        })
    }

    openModal(event){
        let allselectrows = this.template.querySelectorAll(`[data-check="checkbox"]`);
        let isAnySelected = false;
        allselectrows.forEach(function(ele){

            if(ele.checked){
                isAnySelected = true;
            }
        });

        if(!isAnySelected){
            const evt = new ShowToastEvent({
                title: "Mass Date Change",
                message: "Please select atleast one tool",
                variant: "error",
            });
            this.dispatchEvent(evt);
            this.setReturnDate = false;
        }else{
            if(!this.setReturnDate){
                this.setReturnDate = true;
                this.template.querySelector(`[data-id="returnmodal"]`).style.display="block";
            }
            else {this.setReturnDate = false;
                this.template.querySelector(`[data-id="returnmodal"]`).style.display="none";
            }
       }

        return false;
    }

    closeOpenModal(event){
        this.setReturnDate = false;
        this.template.querySelector(`[data-id="returnmodal"]`).style.display="none";
    }

    handleModalRadio(event){
        
        if(event.target.dataset.id === "radio-62"){
            this.extendDays = null;
            this.matchingDate = null;
        }else if(event.target.dataset.id === "radio-63"){
            this.extendDays=  parseInt(this.template.querySelector(`[data-id="radio63"]`).value);
            this.matchingDate = null;
        }else if(event.target.dataset.id === "radio-64"){
            this.extendDays = parseInt(this.template.querySelector(`[data-id="radio64"]`).value);
            this.matchingDate = parseInt(this.template.querySelector(`[data-id="matchingDate"]`).value);
        }

    }

    handleModalOk(event){
        
        let template = this;
        let tempOrder = JSON.parse(JSON.stringify(this.order));
        let schpickDate = this.order.EffectiveDate;//this.template.querySelector(`[data-id="scheduleDate"]`);
        let schreturnDate = this.template.querySelector(`[data-id="scheduleReturnDate"]`);
        let myArray;
        let itemIds = [];
        let beyondWeek  = false;

       let allselectrows = template.template.querySelectorAll(`[data-check="checkbox"]`);
       let date_1 = new Date(schpickDate);
       let date_2 = schreturnDate.value?new Date(schreturnDate.value):date_1;
       let date_3 = new Date();
       let difference = date_2.getTime() - date_1.getTime();
       let TotalDays = Math.ceil(difference / (1000 * 3600 * 24));
       console.log(TotalDays);
       //let week = 1+Math.ceil((TotalDays-8)/7);
       let week = 1+((TotalDays-8) < 0?0:Math.ceil((TotalDays-8)/7));
       if(week > 16){
           beyondWeek = true;
       }
        if(!beyondWeek){
            this.loaded = true;
            this.setReturnDate = false;
            allselectrows.forEach(function(ele){

                if(ele.checked ){
                    const recid = ele.dataset.recid;
                    console.log(recid);
                    let retDate = template.template.querySelector(`[data-return="`+recid+`"]`);
                    let lostqty = template.template.querySelector(`[data-lostqty="`+recid+`"]`);
                    let stillOutqty = template.template.querySelector(`[data-stillout="`+recid+`"]`);
                    let totalFee = 0;
                    retDate.value =schreturnDate.value;
                    retDate.dataset.week = week+" "+(week===1?"week":"weeks")
                    let affiliateFee = parseInt(retDate.dataset.affiliatefee);
                    let unitprice = parseFloat(retDate.dataset.unitprice);
                    const handleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*week).toFixed(2);
                    retDate.dataset.week = week>1?(week+" weeks"):(week+" week");
                    let feeperTool = template.template.querySelector(`[data-toolfee="`+recid+`"]`);
                    feeperTool.innerHTML = "$ "+handleFeePerTool;
                    let basefee = template.template.querySelector(`[data-basefee="`+recid+`"]`);
                    basefee.innerHTML = "$ "+handleFeePerTool;
                    totalFee +=parseFloat(handleFeePerTool);
                    const lostToolFee = unitprice * parseInt(lostqty.value);
                    let lostfee = template.template.querySelector(`[data-lostfee="`+recid+`"]`);
                    lostfee.innerHTML = "$ "+(lostToolFee.toFixed(2));
                    totalFee +=parseFloat(lostToolFee);
                    let lateDiff = date_3.getTime() - (retDate.value?date_2.getTime():date_3.getTime());
                    if(lateDiff > 0){
                        console.log(lateDiff);
                        let latefee = template.template.querySelector(`[data-latefee="`+recid+`"]`);
                        latefee.innerHTML = "$ "+((handleFeePerTool * parseInt(stillOutqty.innerHTML) *2 ));
                        totalFee += parseFloat((handleFeePerTool * parseInt(stillOutqty.innerHTML) *2 ));
                    }else{
                        let latefee = template.template.querySelector(`[data-latefee="`+recid+`"]`);
                        latefee.innerHTML = "$ "+0;
                    }

                    let totalfees = template.template.querySelector(`[data-totalfee="`+recid+`"]`);
                    totalfees.innerHTML = "$ "+(totalFee);
                    
                }
            });
        }

        if(beyondWeek){
            const evt = new ShowToastEvent({
                title: "Return",
                message: "Please select a Return Date within 16 weeks of the Actual Pick Up Date.",
                variant: "error",
            });
            this.dispatchEvent(evt);
        }else{

            this.template.querySelector(`[data-id="returnmodal"]`).style.display="none";
            this.loaded = false;
        }
    }

    handleLineReturned(event){
        let recid = event.target.dataset.qtyid;
        let returnqty = this.template.querySelector(`[data-returnqty="`+recid+`"]`);
        let lostqty = this.template.querySelector(`[data-lostqty="`+recid+`"]`);
        let damagedqty = this.template.querySelector(`[data-damagedqty="`+recid+`"]`);
        let stillOut = this.template.querySelector(`[data-stillout="`+recid+`"]`);
        let borrowed = this.template.querySelector(`[data-borrowed="`+recid+`"]`);
        let retDate = this.template.querySelector(`[data-return="`+recid+`"]`);
        let schpickDate = this.order.EffectiveDate;
        const lost = lostqty && lostqty.value !== "NaN" && (lostqty.value)? parseInt(lostqty.value):0;
        const damaged = damagedqty && damagedqty.value !== "NaN" && (damagedqty.value) ? parseInt(damagedqty.value):0;
        const retQty = returnqty && returnqty.value !== "NaN" && (returnqty.value)? parseInt(returnqty.value):0;
        const borrowedQty = borrowed && borrowed.innerHTML !== "NaN" && (borrowed.innerHTML)? parseInt(borrowed.innerHTML):0;
        const stillOutqty = borrowedQty - ( lost + damaged + retQty);
        stillOut.innerHTML = stillOutqty;
        let totalFee = 0;
        let date_1 = new Date(schpickDate);
        let date_2 = retDate.value ?new Date(retDate.value):date_1;
        let date_3 = new Date();
        let difference = date_2.getTime() - date_1.getTime();
        let TotalDays = Math.ceil(difference / (1000 * 3600 * 24));
        //let week = 1+Math.ceil((TotalDays-8)/7);
        let week = 1+((TotalDays-8) < 0?0:Math.ceil((TotalDays-8)/7));
        let affiliateFee = parseInt(retDate.dataset.affiliatefee);
        let unitprice = parseFloat(retDate.dataset.unitprice);
        const handleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*week*parseInt(lost + damaged + retQty)).toFixed(2);
        retDate.dataset.week = week>1?(week+" weeks"):(week+" week");
        let basefee = this.template.querySelector(`[data-basefee="`+recid+`"]`);
        console.log(handleFeePerTool);
        basefee.innerHTML = "$ "+(handleFeePerTool);
        const lostToolFee = (unitprice * parseInt(lost)).toFixed(2);
        let lostfee = this.template.querySelector(`[data-lostfee="`+recid+`"]`);
        lostfee.innerHTML = "$ "+lostToolFee;

        let lateDiff = date_3.getTime() - (retDate.value?date_2.getTime():date_3.getTime());
        let lateDays = Math.ceil(lateDiff / (1000 * 3600 * 24));
        let lateweek = Math.ceil(lateDays/7);
        let lateCharge =0;
        if(lateweek > 0){
            console.log(lateDiff);
            const LatehandleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*lateweek).toFixed(2);
            let latefee = this.template.querySelector(`[data-latefee="`+recid+`"]`);
            lateCharge = (LatehandleFeePerTool * parseInt(( lost + damaged + retQty)) *2 ).toFixed(2);
            latefee.innerHTML = "$ "+(lateCharge);
            totalFee += lateCharge;
        }else{
            let latefee = this.template.querySelector(`[data-latefee="`+recid+`"]`);
            latefee.innerHTML = "$ "+0;
        }
        totalFee = (parseFloat(handleFeePerTool)+parseFloat(lostToolFee)+parseFloat(lateCharge)).toFixed(2);
        let totalfees = this.template.querySelector(`[data-totalfee="`+recid+`"]`);
        totalfees.innerHTML = "$ "+(totalFee);

    }


    handleReturnButton(event){
        let template = this;
        let allselectrows = template.template.querySelectorAll(`[data-check="checkbox"]`);
        let isSelected = false;
        allselectrows.forEach(function(ele){

            if(ele.checked){
                isSelected = true;
                const recid = ele.dataset.recid;
                let status = template.template.querySelector(`[data-sts="`+recid+`"]`);
                let stillOutqty = template.template.querySelector(`[data-stillout="`+recid+`"]`);
                let borrowed = template.template.querySelector(`[data-borrowed="`+recid+`"]`);

                let returnqty = template.template.querySelector(`[data-returnqty="`+recid+`"]`);
                let lostqty = template.template.querySelector(`[data-lostqty="`+recid+`"]`);
                let damagedqty = template.template.querySelector(`[data-damagedqty="`+recid+`"]`);

                if(parseInt(stillOutqty.innerHTML) === 0){
                    status.innerHTML = "Returned";
                    returnqty.disabled= true;
                    lostqty.disabled= true;
                    damagedqty.disabled= true;
                }
                else if(parseInt(stillOutqty.innerHTML) > 0 && parseInt(stillOutqty.innerHTML) < parseInt(borrowed.innerHTML))
                    status.innerHTML = "Partially Returned";
                else if(parseInt(stillOutqty.innerHTML) < 0){
                    //alert("Total return can not be greater than total borrowed");
                    const evt = new ShowToastEvent({
                        title: "Return",
                        message: "Total return can not be greater than total borrowed",
                        variant: "error",
                    });
                    template.dispatchEvent(evt);
                   
                    returnqty.style.borderColor = "red";
                    lostqty.style.borderColor = "red";
                    damagedqty.style.borderColor = "red";
                }
                
            }
        });

        if(!isSelected){
            //alert('Nothing is selected please select a row to return');
            const evt = new ShowToastEvent({
                title: "Return",
                message: "Nothing is selected please select a row to return",
                variant: "error",
            });
            this.dispatchEvent(evt);
        }
    }

    handleCancel(event){

        //this.dispatchEvent(new CloseActionScreenEvent());
        /*let template = this;
            const config = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: template.order.Id,
                    objectApiName:"Order",
                    actionName: 'view'
                }
            };
            this[NavigationMixin.Navigate](config);*/
            location.reload();
          
    }

    handlefilter(event){
        const filter = event.target.value;
        let state = this.template;
        let getAllTools = state.querySelectorAll(`[data-id="dataid"]`);

        getAllTools.forEach(function(ele){
            const recid = ele.dataset.rowid;

            let status = state.querySelector(`[data-sts="`+recid+`"]`);
            let stillOutqty = state.querySelector(`[data-stillout="`+recid+`"]`);
            const checkbox = state.querySelector(`[data-recid="`+ele.dataset.rowid+`"]`);
            if(filter === "Still out"){
                if(parseInt(stillOutqty.innerHTML)>0 || (parseInt(stillOutqty.innerHTML) <= 0 &&  status.innerHTML !== "Returned")){
                    ele.style.display = "table-row";
                    checkbox.classList.add("filtered");
                }else {
                    ele.style.display = "none";
                    checkbox.classList.remove("filtered");
                }
            }else if(filter === "Returned"){
                if(status.innerHTML === "Returned"){
                    ele.style.display = "table-row";
                }else {ele.style.display = "none";
                }
            } else if(filter === "All"){
                ele.style.display = "table-row";
                checkbox.classList.add("filtered");
            } else if(filter === "Partially Returned"){
                if(status.innerHTML === "Partially Returned"){
                    ele.style.display = "table-row";
                }else {ele.style.display = "none";
                }
            }



        });
    }

    handleSearchFilter(event){
        const searchString = event.target.value.toLowerCase();
        let filteredItems = [];
        if(searchString.length >=2){
            for(let i in this.allOrderItems){
                
                const name = this.allOrderItems[i].orderItem.Product2.Name.toLowerCase();
                let note;
                let alter;
                if(this.allOrderItems[i].orderItem.Product2.Tool_Note__c) 
                    note = this.allOrderItems[i].orderItem.Product2.Tool_Note__c.toLowerCase();
                
                if(this.allOrderItems[i].orderItem.Product2.ProductCode)
                    alter = this.allOrderItems[i].orderItem.Product2.ProductCode.toLowerCase();

                if((name && name.indexOf(searchString)>=0) || (note && note.indexOf(searchString)>=0) || (alter && alter.indexOf(searchString)>=0)){
                    filteredItems.push(this.allOrderItems[i]);
                }
            }
            this.orderItems = filteredItems;
        }else{
            this.orderItems = this.allOrderItems;
        }

        

    }

    handleSelectAll(event){
        let state = this;
        let getAllTools = state.template.querySelectorAll(`.filtered`);

        getAllTools.forEach(function(ele){
                ele.checked = event.target.checked;
                if(event.target.checked){
                    ele.classList.add("selected");
                    let recid = ele.dataset.recid;
                    console.log(recid);
                    let borrowed = state.template.querySelector(`[data-borrowed="`+recid+`"]`).innerHTML;
                    let retqty = state.template.querySelector(`[data-qtyid="`+recid+`"]`);
                    retqty.value = borrowed;
                    let tempev = {};
                    tempev["target"]={};
                    tempev.target["dataset"]={};
                    tempev.target.dataset["qtyid"] = recid;
                    state.handleLineReturned(tempev);
                }else
                ele.classList.remove("selected");
        });
    }


    handleSave(event){
        this.loaded = true;
        let state = this.template;
        let getAllTools = state.querySelectorAll(`[data-id="dataid"]`);
        let returnedBy = state.querySelector(`[data-id="returnedby"]`);
        let itemList = [];
        const EffectiveDate = this.order.EffectiveDate; 
        let allselectrows = state.querySelectorAll(`[data-check="checkbox"]`);
        let isSelected = false;
       allselectrows.forEach(function(ele){

            if(ele.checked){
                isSelected = true;
                const recid = ele.dataset.recid;
                let status = state.querySelector(`[data-sts="`+recid+`"]`);
                if(status.innerHTML !== "Partially Returned" && status.innerHTML !== "Returned"){
                    isSelected = false;
                }
            }
        });
        
        
        /*if(!isSelected){
            const evt = new ShowToastEvent({
                title: "Return Tools",
                message: "No items were returned.  Please select the row(s), update the quantites and click 'Return' before saving.",
                variant: "warning",
            });
            this.dispatchEvent(evt);
        }*/
        
        getAllTools.forEach(function(ele){
            const recid = ele.dataset.rowid;
            console.log(recid);
            const orderid = ele.dataset.orderid;
            let lost = state.querySelector(`[data-lostqty="`+recid+`"]`);
            let damaged = state.querySelector(`[data-damagedqty="`+recid+`"]`);
            let retur = state.querySelector(`[data-returnqty="`+recid+`"]`);
            let retDate = state.querySelector(`[data-return="`+recid+`"]`);
            let status = state.querySelector(`[data-sts="`+recid+`"]`);
            let base = state.querySelector(`[data-basefee="`+recid+`"]`);
            let borrowed = state.querySelector(`[data-borrowed="`+recid+`"]`);

            const lostqty = lost.value !== "NaN" && lost.value? parseInt(lost.value):0;
            const damagedqty = damaged.value !== "NaN" && damaged.value ? parseInt(damaged.value):0;
            const returnqty = retur.value !== "NaN" && retur.value? parseInt(retur.value):0;
            const returnDate = retDate.value;
            const newStatus =status.innerHTML;
            const basefee = !isNaN(base.innerHTML)? parseInt(base.innerHTML):0;
            const oldStatus = lost.dataset.already;
            const borrowedqty = borrowed.innerHTML !== "NaN" && borrowed.innerHTML?parseInt(borrowed.innerHTML):0;
            const assetid = retDate.dataset.assetid;
            const unitPrice = retDate.dataset.unitprice;
            const product2id = retDate.dataset.product2id;                    
            const pbeid= retDate.dataset.pbeid;                        
            const affiliatefee= retDate.dataset.affiliatefee;  
            const borrowedPeriod = retDate.dataset.week;       
                         
            console.log(borrowedPeriod);
            console.log(oldStatus);
            console.log(newStatus);

           


            if(oldStatus !== "Returned" && (newStatus === "Partially Returned" || newStatus === "Returned")){
                console.log(borrowedqty);
                console.log(lostqty);
                console.log(returnqty);
                console.log(damagedqty);
                const pendingQty = borrowedqty - (lostqty+damagedqty+returnqty);
                console.log(pendingQty);

                if(pendingQty === 0){
                    let item ={
                        Id:recid,
                        orderid:orderid,
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        lost:lostqty,
                        damaged:damagedqty,
                        returnqty:returnqty,
                        EffectiveDate:EffectiveDate,
                        returnedBy:returnedBy.value,
                        //basefee:basefee,
                        status:newStatus
                    }
                    itemList.push(item);
                }else if(pendingQty === borrowedqty){
                    let item ={
                        Id:recid,
                        orderid:orderid,
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        EffectiveDate:EffectiveDate,
                        lost:0,
                        damaged:0,
                        returnqty:0,
                        returnedBy:returnedBy.value,
                        //basefee:basefee,
                        status:oldStatus
                    }
                    itemList.push(item);
                }else{
                    let item1 ={
                        Id:recid,
                        orderid:orderid,
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        EffectiveDate:EffectiveDate,
                        lost:lostqty,
                        damaged:damagedqty,
                        returnqty:returnqty,
                        status:"Returned",
                        returnedBy:returnedBy.value,
                        //basefee:basefee,
                        borrowed:(lostqty+damagedqty+returnqty)
                    }
                    let item2 ={
                        Id:"2",
                        orderid:orderid,
                        returnDate:returnDate,
                        lost:0,
                        orderid:orderid,
                        borrowedPeriod:borrowedPeriod,
                        EffectiveDate:EffectiveDate,
                        damaged:0,
                        returnqty:0,
                        status:"Partially Returned",
                        //basefee:basefee,
                        borrowed:pendingQty,
                        assetid:assetid,
                        unitPrice:unitPrice,
                        product2id:product2id,
                        pbeid:pbeid,
                        returnedBy:returnedBy.value,
                        affiliatefee:affiliatefee
                    }
                    itemList.push(item1);
                    itemList.push(item2);
                }
            } else{
                let item ={
                    Id:recid,
                    orderid:orderid,
                    returnDate:returnDate,
                    borrowedPeriod:borrowedPeriod,
                    EffectiveDate:EffectiveDate,
                    lost:0,
                    damaged:0,
                    returnqty:0,
                    returnedBy:returnedBy.value,
                    //basefee:basefee,
                    status:oldStatus
                }
                itemList.push(item);
            }
            
        });

        console.log(itemList);

        saveOrder({itemsList:JSON.stringify(itemList) }).then(res=>{
            console.log(res);
            //alert("record saved successfully");
            if(isSelected){
                const evt = new ShowToastEvent({
                    title: "Return Tools",
                    message: "record saved successfully",
                    variant: "success",
                });
                this.dispatchEvent(evt);
            }
            
            //location.reload();
            if(res)
            return getOrderItemsDirect({orderId: this.recordId});
        }).then(res =>{
            console.log( res);
                this.order = res.order; 
                let totalTimeInSeconds = (res.order.Scheduled_Pickup_Time__c/1000);
                let result = new Date(null, null, null, null, null, totalTimeInSeconds);
                let tempTime = result.toTimeString().split(' ')[0].substring(0,5)
                tempTime = tempTime.split(':');
                if(res.order.Scheduled_Pickup_Time__c && tempTime){
                    const hour = parseInt(tempTime[0]) >12 && parseInt(tempTime[0]) !== 0 && parseInt(tempTime[0]) !== 12 ?(parseInt(tempTime)-12):(parseInt(tempTime[0]) === 0?12:tempTime[0]);
                    const hour12 =  parseInt(tempTime[0]) >=12?"PM":"AM";
                    this.schPickTime = hour+':'+tempTime[1]+' '+hour12;
                }

                let itemlist = JSON.parse(JSON.stringify(res.orderItems));
                for(let i in itemlist){
                    console.log( itemlist[i].UnitPrice);
                    itemlist[i].orderItem.UnitPrice = itemlist[i].orderItem.UnitPrice.toFixed(2);
                }

                let returnitemlist = JSON.parse(JSON.stringify(res.returnOrderItems));
                for(let i in returnitemlist){
                    returnitemlist[i].orderItem.UnitPrice = returnitemlist[i].orderItem.UnitPrice.toFixed(2);
                }

                this.orderItems = itemlist;
                this.allOrderItems = itemlist;
                this.returnOrderItems = returnitemlist;
                this.loaded = false;
        }).catch(error=>{
            console.log(error);
            const evt = new ShowToastEvent({
                title: "Return Tools",
                message: error,
                variant: "error",
            });
            this.dispatchEvent(evt);
            this.loaded = false;
        });
    }


    handleReturnAndSave(event){
        this.loaded = true;
        let template = this;
        let returnedBy = this.template.querySelector(`[data-id="returnedby"]`);
        let allselectrows = template.template.querySelectorAll(`[data-check="checkbox"]`);
        let isSelected = false;
       allselectrows.forEach(function(ele){

            if(ele.checked){
                isSelected = true;
                const recid = ele.dataset.recid;
                let status = template.template.querySelector(`[data-sts="`+recid+`"]`);
                if(status.innerHTML !== "Partially Returned" && status.innerHTML !== "Returned"){
                    isSelected = false;
                }
                /*let stillOutqty = template.template.querySelector(`[data-stillout="`+recid+`"]`);
                let borrowed = template.template.querySelector(`[data-borrowed="`+recid+`"]`);

                let returnqty = template.template.querySelector(`[data-returnqty="`+recid+`"]`);
                let lostqty = template.template.querySelector(`[data-lostqty="`+recid+`"]`);
                let damagedqty = template.template.querySelector(`[data-damagedqty="`+recid+`"]`);

                if(parseInt(stillOutqty.innerHTML) === 0){
                    status.innerHTML = "Returned";
                    returnqty.disabled= true;
                    lostqty.disabled= true;
                    damagedqty.disabled= true;
                }
                else if(parseInt(stillOutqty.innerHTML) > 0 && parseInt(stillOutqty.innerHTML) < parseInt(borrowed.innerHTML))
                    status.innerHTML = "Partially Returned";
                else if(parseInt(stillOutqty.innerHTML) < 0){
                    
                    const evt = new ShowToastEvent({
                        title: "Return Tools",
                        message: "Total return can not be greater than total borrowed",
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                   
                    returnqty.style.borderColor = "red";
                    lostqty.style.borderColor = "red";
                    damagedqty.style.borderColor = "red";
                }
                */
            }
        });
        
        
        /*if(!isSelected){
            const evt = new ShowToastEvent({
                title: "Return Tools",
                message: "No items were returned.  Please select the row(s), update the quantites and click 'Return' before saving.",
                variant: "error",
            });
            this.dispatchEvent(evt);
        }
        else{*/

        let state = this.template;
        let getAllTools = state.querySelectorAll(`[data-id="dataid"]`);
        let itemList = [];
        const EffectiveDate = this.order.EffectiveDate; 
        getAllTools.forEach(function(ele){
            const recid = ele.dataset.rowid;
            console.log(recid);
            const orderid = ele.dataset.orderid;
            let lost = state.querySelector(`[data-lostqty="`+recid+`"]`);
            let damaged = state.querySelector(`[data-damagedqty="`+recid+`"]`);
            let retur = state.querySelector(`[data-returnqty="`+recid+`"]`);
            let retDate = state.querySelector(`[data-return="`+recid+`"]`);
            let status = state.querySelector(`[data-sts="`+recid+`"]`);
            let base = state.querySelector(`[data-basefee="`+recid+`"]`);
            let borrowed = state.querySelector(`[data-borrowed="`+recid+`"]`);

            const lostqty = lost.value !== "NaN" && lost.value? parseInt(lost.value):0;
            const damagedqty = damaged.value !== "NaN" && damaged.value ? parseInt(damaged.value):0;
            const returnqty = retur.value !== "NaN" && retur.value? parseInt(retur.value):0;
            const returnDate = retDate.value;
            const newStatus =status.innerHTML;
            const basefee = !isNaN(base.innerHTML)? parseInt(base.innerHTML):0;
            const oldStatus = lost.dataset.already;
            const borrowedqty = borrowed.innerHTML !== "NaN" && borrowed.innerHTML?parseInt(borrowed.innerHTML):0;
            const assetid = retDate.dataset.assetid;
            const unitPrice = retDate.dataset.unitprice;
            const product2id = retDate.dataset.product2id;                    
            const pbeid= retDate.dataset.pbeid;                        
            const affiliatefee= retDate.dataset.affiliatefee;  
            const borrowedPeriod = retDate.dataset.week;       
                         
            console.log(oldStatus);
            console.log(newStatus);

           


            if(oldStatus !== "Returned" && (newStatus === "Partially Returned" || newStatus === "Returned")){
                console.log(borrowedqty);
                console.log(lostqty);
                console.log(returnqty);
                console.log(damagedqty);
                const pendingQty = borrowedqty - (lostqty+damagedqty+returnqty);
                console.log(pendingQty);

                if(pendingQty === 0){
                    let item ={
                        Id:recid,
                        orderid:orderid,
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        lost:lostqty,
                        damaged:damagedqty,
                        returnqty:returnqty,
                        EffectiveDate:EffectiveDate,
                        returnedBy:returnedBy.value,
                        //basefee:basefee,
                        status:newStatus
                    }
                    itemList.push(item);
                }else if(pendingQty === borrowedqty){
                    let item ={
                        Id:recid,
                        orderid:orderid,
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        EffectiveDate:EffectiveDate,
                        lost:0,
                        damaged:0,
                        returnqty:0,
                        returnedBy:returnedBy.value,
                        //basefee:basefee,
                        status:oldStatus
                    }
                    itemList.push(item);
                }else{
                    let item1 ={
                        Id:recid,
                        orderid:orderid,
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        EffectiveDate:EffectiveDate,
                        lost:lostqty,
                        damaged:damagedqty,
                        returnqty:returnqty,
                        status:"Returned",
                        returnedBy:returnedBy.value,
                        //basefee:basefee,
                        borrowed:(lostqty+damagedqty+returnqty)
                    }
                    let item2 ={
                        Id:"2",
                        orderid:orderid,
                        returnDate:returnDate,
                        lost:0,
                        orderid:orderid,
                        borrowedPeriod:borrowedPeriod,
                        EffectiveDate:EffectiveDate,
                        damaged:0,
                        returnqty:0,
                        status:"Partially Returned",
                        //basefee:basefee,
                        borrowed:pendingQty,
                        assetid:assetid,
                        unitPrice:unitPrice,
                        product2id:product2id,
                        pbeid:pbeid,
                        returnedBy:returnedBy.value,
                        affiliatefee:affiliatefee
                    }
                    itemList.push(item1);
                    itemList.push(item2);
                }
            } else{
                let item ={
                    Id:recid,
                    orderid:orderid,
                    returnDate:returnDate,
                    borrowedPeriod:borrowedPeriod,
                    EffectiveDate:EffectiveDate,
                    lost:0,
                    damaged:0,
                    returnqty:0,
                    returnedBy:returnedBy.value,
                    //basefee:basefee,
                    status:oldStatus
                }
                itemList.push(item);
            }
            
        });

        console.log(itemList);

        saveOrder({itemsList:JSON.stringify(itemList) }).then(res=>{
            console.log(res);
            //alert("record saved successfully");
            if(isSelected){
                const evt = new ShowToastEvent({
                    title: "Return Tools",
                    message: "record saved successfully",
                    variant: "success",
                });
                this.dispatchEvent(evt);
            }
            location.reload();
        }).catch(error=>{
            console.log(error);
            const evt = new ShowToastEvent({
                title: "Return Tools",
                message: error,
                variant: "error",
            });
            this.dispatchEvent(evt);
        });
    //}

    }
}