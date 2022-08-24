import { api, LightningElement, wire } from 'lwc';
import getOrderItems from '@salesforce/apex/ReturnOrderController.getOrderItems';
import saveOrder from '@salesforce/apex/ReturnOrderController.saveOrder';
import TOOL_PICKED_FIELD from '@salesforce/schema/Order.Tools_Picked_Up_By__c';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ReturnOrderCmp extends NavigationMixin(LightningElement)  {

    toolPickedField = TOOL_PICKED_FIELD;

    @api
    recordId;
    order;
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

    openModal(event){
        this.setReturnDate = true;
    }

    closeOpenModal(event){
        this.setReturnDate = false;
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
        
        console.log(this.extendDays);
        console.log(this.matchingDate);

    }

    handleModalOk(event){
        this.loaded = true;
        this.setReturnDate = false;
        let template = this;
        let tempOrder = JSON.parse(JSON.stringify(this.order));
        let schpickDate = this.order.EffectiveDate;//this.template.querySelector(`[data-id="scheduleDate"]`);
        let myArray;
        let itemIds = [];

       let allselectrows = template.template.querySelectorAll(`[data-check="checkbox"]`);
       allselectrows.forEach(function(ele){

            if(ele.checked){
                const recid = ele.dataset.recid;
                console.log(recid);
                let retDate = template.template.querySelector(`[data-return="`+recid+`"]`);
                let lostqty = template.template.querySelector(`[data-lostqty="`+recid+`"]`);
                let stillOutqty = template.template.querySelector(`[data-stillout="`+recid+`"]`);
                let totalFee = 0;
                let schDate = new Date(retDate.value);
                
                if(template.matchingDate){
                    
                    let mDate = new Date(template.matchingDate);
                    if(mDate === schDate)
                        schDate.setDate(schDate.getDate() + template.extendDays);

                }
                else if(template.extendDays){
                    schDate.setDate(schDate.getDate() + template.extendDays);
                    
                } else{
                   let borrowing = retDate.dataset.week;
                    if(borrowing){
                        borrowing = borrowing.replace("weeks", "");
                        borrowing = borrowing.replace("week", "");
                    }
                    
                    let week = parseInt(borrowing);
                    const days = week*7;
                    schDate = new Date(schpickDate);
                    schDate.setDate(schDate.getDate() + days);
                }
                let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(schDate);
                let mo = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(schDate);
                let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(schDate);
                retDate.value = `${ye}-${mo}-${da}`;
                let date_1 = new Date(schpickDate);
                let date_2 = new Date(retDate.value);
                let date_3 = new Date();
                let difference = date_2.getTime() - date_1.getTime();
                let TotalDays = Math.ceil(difference / (1000 * 3600 * 24));
                let week = Math.ceil(TotalDays/7);
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
                let lateDiff = date_3.getTime() - date_2.getTime();
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
        this.loaded = false;
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
        const lost = lostqty.value !== "NaN" && (lostqty.value)? parseInt(lostqty.value):0;
        const damaged = damagedqty.value !== "NaN" && (damagedqty.value) ? parseInt(damagedqty.value):0;
        const retQty = returnqty.value !== "NaN" && (returnqty.value)? parseInt(returnqty.value):0;
        const borrowedQty = borrowed.innerHTML !== "NaN" && (borrowed.innerHTML)? parseInt(borrowed.innerHTML):0;
        const stillOutqty = borrowedQty - ( lost + damaged + retQty);
        stillOut.innerHTML = stillOutqty;
        let totalFee = 0;
        let date_1 = new Date(schpickDate);
        let date_2 = new Date(retDate.value);
        let date_3 = new Date();
        let difference = date_2.getTime() - date_1.getTime();
        let TotalDays = Math.ceil(difference / (1000 * 3600 * 24));
        let week = Math.ceil(TotalDays/7);
        let affiliateFee = parseInt(retDate.dataset.affiliatefee);
        let unitprice = parseFloat(retDate.dataset.unitprice);
        const handleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*week).toFixed(2);
        retDate.dataset.week = week>1?(week+" weeks"):(week+" week");
        let feeperTool = this.template.querySelector(`[data-toolfee="`+recid+`"]`);
        feeperTool.innerHTML = "$ "+(handleFeePerTool);
        let basefee = this.template.querySelector(`[data-basefee="`+recid+`"]`);
        basefee.innerHTML = "$ "+(handleFeePerTool);
        const lostToolFee = (unitprice * parseInt(lost)).toFixed(2);
        let lostfee = this.template.querySelector(`[data-lostfee="`+recid+`"]`);
        lostfee.innerHTML = "$ "+lostToolFee;

        let lateDiff = date_3.getTime() - date_2.getTime();
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
                    alert("Total return can not be greater than total borrowed");
                   
                    returnqty.style.borderColor = "red";
                    lostqty.style.borderColor = "red";
                    damagedqty.style.borderColor = "red";
                }
                
            }
        });

        if(!isSelected){
            alert('Nothing is selected please select a row to return');
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
                if(parseInt(stillOutqty.innerHTML)>0){
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
                checkbox.classList.remove("filtered");
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
        let state = this.template;
        let getAllTools = state.querySelectorAll(`.filtered`);

        getAllTools.forEach(function(ele){
                ele.checked = event.target.checked;
                if(event.target.checked)
                    ele.classList.add("selected");
                else
                ele.classList.remove("selected");
        });
    }


    handleSave(event){
        
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
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        lost:lostqty,
                        damaged:damagedqty,
                        returnqty:returnqty,
                        EffectiveDate:EffectiveDate,
                        //basefee:basefee,
                        status:newStatus
                    }
                    itemList.push(item);
                }else if(pendingQty === borrowedqty){
                    let item ={
                        Id:recid,
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        EffectiveDate:EffectiveDate,
                        lost:0,
                        damaged:0,
                        returnqty:0,
                        //basefee:basefee,
                        status:oldStatus
                    }
                    itemList.push(item);
                }else{
                    let item1 ={
                        Id:recid,
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        EffectiveDate:EffectiveDate,
                        lost:lostqty,
                        damaged:damagedqty,
                        returnqty:returnqty,
                        status:"Returned",
                        //basefee:basefee,
                        borrowed:(lostqty+damagedqty+returnqty)
                    }
                    let item2 ={
                        Id:"2",
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
                        affiliatefee:affiliatefee
                    }
                    itemList.push(item1);
                    itemList.push(item2);
                }
            } else{
                let item ={
                    Id:recid,
                    returnDate:returnDate,
                    borrowedPeriod:borrowedPeriod,
                    EffectiveDate:EffectiveDate,
                    lost:0,
                    damaged:0,
                    returnqty:0,
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
            const evt = new ShowToastEvent({
                title: "Return Tools",
                message: "record saved successfully",
                variant: "success",
            });
            this.dispatchEvent(evt);
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
    }


    handleReturnAndSave(event){
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
                    alert("Total return can not be greater than total borrowed");
                   
                    returnqty.style.borderColor = "red";
                    lostqty.style.borderColor = "red";
                    damagedqty.style.borderColor = "red";
                }
                
            }
        });

        if(!isSelected){
            alert('Nothing is selected please select a row to return');
        }else{

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
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        lost:lostqty,
                        damaged:damagedqty,
                        returnqty:returnqty,
                        EffectiveDate:EffectiveDate,
                        //basefee:basefee,
                        status:newStatus
                    }
                    itemList.push(item);
                }else if(pendingQty === borrowedqty){
                    let item ={
                        Id:recid,
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        EffectiveDate:EffectiveDate,
                        lost:0,
                        damaged:0,
                        returnqty:0,
                        //basefee:basefee,
                        status:oldStatus
                    }
                    itemList.push(item);
                }else{
                    let item1 ={
                        Id:recid,
                        returnDate:returnDate,
                        borrowedPeriod:borrowedPeriod,
                        EffectiveDate:EffectiveDate,
                        lost:lostqty,
                        damaged:damagedqty,
                        returnqty:returnqty,
                        status:"Returned",
                        //basefee:basefee,
                        borrowed:(lostqty+damagedqty+returnqty)
                    }
                    let item2 ={
                        Id:"2",
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
                        affiliatefee:affiliatefee
                    }
                    itemList.push(item1);
                    itemList.push(item2);
                }
            } else{
                let item ={
                    Id:recid,
                    returnDate:returnDate,
                    borrowedPeriod:borrowedPeriod,
                    EffectiveDate:EffectiveDate,
                    lost:0,
                    damaged:0,
                    returnqty:0,
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
            const evt = new ShowToastEvent({
                title: "Return Tools",
                message: "record saved successfully",
                variant: "success",
            });
            this.dispatchEvent(evt);
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
    }

    }
}