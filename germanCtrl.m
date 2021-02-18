const
    NODE_NUM : 5;
    DATA_NUM : 2;

type
     NODE : 1..NODE_NUM;
     DATA : 1..DATA_NUM;
     
     CACHE_STATE : enum{I, S, E};
     CACHE : record State : CACHE_STATE;  end;
     
     MSG_CMD : enum{Empty, ReqS, ReqE, Inv, InvAck, GntS, GntE};
     MSG : record Cmd : MSG_CMD;   end;

var
    Cache: array [NODE] of CACHE;
    Chan1: array [NODE] of MSG;
    Chan2: array [NODE] of MSG;
    Chan3: array [NODE] of MSG;
    ShrSet: array [NODE] of boolean;
    InvSet: array [NODE] of boolean;
    ExGntd: boolean;
    CurCmd: MSG_CMD;
    CurPtr: NODE;
     
    

ruleset d: DATA do startstate "Init"
 for i: NODE do
   Chan1[i].Cmd := Empty;
   Chan2[i].Cmd := Empty; 
   Chan3[i].Cmd := Empty;   
      
   Cache[i].State := I;
    
   ShrSet[i] := false;
   InvSet[i] := false;
  end;
  CurCmd := Empty;
  ExGntd := false;
   
endstartstate; endruleset;

ruleset j: NODE do
 rule "SendReqS"
      Cache[j].State = I & Chan1[j].Cmd = Empty ==> 
        begin Chan1[j].Cmd := ReqS;
endrule; endruleset;

ruleset i: NODE do
 rule "SendReqEI"
      (Cache[i].State = I) & Chan1[i].Cmd = Empty ==> 
        begin Chan1[i].Cmd := ReqE;
endrule; endruleset;

ruleset i: NODE do
 rule "SendReqES"
      (Cache[i].State = S) & Chan1[i].Cmd = Empty ==> 
        begin Chan1[i].Cmd := ReqE;
endrule; endruleset;

ruleset i: NODE do
 rule "RecvReq"
       CurCmd = Empty & Chan1[i].Cmd != Empty ==>
        begin CurCmd := Chan1[i].Cmd; 
              Chan1[i].Cmd := Empty;
              CurPtr := i;
              for j: NODE do
               InvSet[j] := ShrSet[j];
              endfor;
endrule; endruleset;
  
ruleset i: NODE do
 rule "SendInvE"
      (CurCmd = ReqE)
      & InvSet[i] & Chan2[i].Cmd = Empty ==>
       begin
        Chan2[i].Cmd := Inv;
        InvSet[i] := false;
endrule; endruleset;
  
ruleset i: NODE do
 rule "SendInvS"
      (CurCmd = ReqS & ExGntd)
      & InvSet[i] & Chan2[i].Cmd = Empty ==>
       begin
        Chan2[i].Cmd := Inv;
        InvSet[i] := false;
endrule; endruleset;
 
ruleset i: NODE do
 rule "SendInvAck"
      Chan2[i].Cmd = Inv & Chan3[i].Cmd = Empty ==>
      begin
       Chan2[i].Cmd := Empty;
       Chan3[i].Cmd := InvAck;
        
       Cache[i].State := I;
endrule; endruleset;

ruleset i: NODE do
 rule "RecvInvAck1"
      CurCmd != Empty & Chan3[i].Cmd = InvAck &(ExGntd = true)==>
      begin 
       ShrSet[i] := false;
       
       ExGntd := false; 
      
       Chan3[i].Cmd := Empty;
endrule; endruleset;

ruleset i: NODE do
 rule "RecvInvAck2"
      CurCmd != Empty & Chan3[i].Cmd = InvAck&(ExGntd = false) ==>
      begin 
       ShrSet[i] := false;
        
       Chan3[i].Cmd := Empty;
endrule; endruleset;

ruleset i: NODE do
 rule "SendGntS"
      CurCmd = ReqS & CurPtr = i
      & !ExGntd & Chan2[i].Cmd = Empty ==>
      begin
       ShrSet[i] := true;
       CurCmd := Empty;
       Chan2[i].Cmd := GntS;
       
endrule; endruleset;

ruleset i: NODE do
 rule "SendGntE"
      CurCmd = ReqE & CurPtr = i & !ExGntd 
      & forall j: NODE do ShrSet[j] = false endforall
      & Chan2[i].Cmd = Empty ==>
      begin
       ShrSet[i] := true;
       CurCmd := Empty;
       ExGntd := true;
       Chan2[i].Cmd := GntE;
        
endrule; endruleset;

ruleset i: NODE do
 rule "RecvGntS"
      Chan2[i].Cmd = GntS ==>
      begin
       Cache[i].State := S;
       Chan2[i].Cmd := Empty;
        
endrule; endruleset;

ruleset i: NODE do
 rule "RecvGntE"
      Chan2[i].Cmd = GntE ==>
      begin
       Cache[i].State := E;
       Chan2[i].Cmd := Empty;
       
endrule; endruleset;

 
ruleset i: NODE; j: NODE do
invariant "CntrlProp"
      (Cache[i].State = E -> Cache[j].State != E);
endruleset;

 
