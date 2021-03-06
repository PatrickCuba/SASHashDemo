Data Customer_Detail;
     If _N_=0 Then Set Address Account_Balance;

     If _N_=1 Then Do;
           Declare Hash ReadB(Dataset: "Address");
           ReadB.DefineKey('ClientID');
           ReadB.DefineData('ClientID', 'Suburb', 'State');
           ReadB.DefineDone();

           Declare Hash RBalances(Dataset: "Account_Balance", Ordered: "a");
           RBalances.DefineKey('ClientID', 'Acct'); 
           RBalances.DefineData('ClientID', 'Acct', 'Bal');
           RBalances.DefineDone();
           Declare HIter RBalancesIter('RBalances');

           Declare Hash ByStateBal(Ordered: "a");
           ByStateBal.DefineKey('State');
           ByStateBal.DefineData('State', 'StateBal');
           ByStateBal.DefineDone();
           Declare HIter ByStateIter('ByStateBal');

           Call Missing(of _All_);
     End;

     Set Customer End=End;

     Length StateBal 8.;

     /* Fetch Address Details */
	Suburb='';
	State='';
	rc=ReadB.Find();
     * if rc=0; * To return matches only * ;
     
     _HoldmyClient=ClientID;

     /* Aggregate the Balances to a Client */
     Cust_Bal=0;
     Rc=RBalancesIter.First();
     Do Until(Rc ne 0);
           If ClientID=_HoldmyClient Then Do;
                Cust_Bal=Cust_Bal+Bal;
           End;
           Rc=RBalancesIter.Next();
     End;
     ClientID=_HoldmyClient;

     /* We want a Summary of the Balances Per State */
     Rc=ByStateBal.Find();
     StateBal=Sum(StateBal, Cust_Bal);
 	 If State ne ' ' Then rc=ByStateBal.Replace();

     If End Then Do;
           Rc=ByStateBal.Output(Dataset: "Work.State_Summ");
           
/*           Length StateID 8.;*/
           Call Missing(StateID);

           /* Data set for each state ?*/
           Declare Hash HOH();
           HOH.DefineKey('State');
           HOH.DefineData('State', 'StateH');
           HOH.DefineDone();
           Declare Hash StateH(); 
           
           /* Read State Table list and add a new instance for each state */
            Rc=ByStateIter.First(); 
            Do Until(Rc ne 0); 
                StateH= _new_ Hash(); 
                StateH.DefineKey('State'); 
                StateH.DefineData('State', 'StateBal'); 
                StateH.DefineDone(); 
            
                Rc=StateH.Add(); 
                Rc=StateH.Output(Dataset: Compress("Work.State_"||State)); 
                Rc=ByStateIter.Next(); 
            End; 
     End;

     Drop Rc _HoldmyClient Acct Bal StateBal StateID;
Run;
