
const

  NODE_NUM : 2;
  DATA_NUM : 2;
                                                        
type

  NODE : scalarset(NODE_NUM);
  DATA : scalarset(DATA_NUM);
  ABS_NODE : union {NODE, enum{Other}};
  
  CACHE_STATE : enum{CACHE_I,CACHE_S,CACHE_E};
  
  NODE_CMD : enum{NODE_None,NODE_Get,NODE_GetX};
  
  NODE_STATE : record
    ProcCmd : NODE_CMD;
    InvMarked : boolean;
    CacheState : CACHE_STATE;
    CacheData : DATA;
  end;
  new_type_0 : array [ NODE ] of boolean;
  new_type_1 : array [ NODE ] of boolean;
  
  DIR_STATE : record
    Pending : boolean;
    Local : boolean;
    Dirty : boolean;
    HeadVld : boolean;
    HeadPtr : ABS_NODE;
    ShrVld : boolean;
    InvSet : new_type_0;
    ShrSet : new_type_1;
    HomeHeadPtr : boolean;
    HomeShrSet : boolean;
    HomeInvSet : boolean;
  end;
  
  UNI_CMD : enum{UNI_None,UNI_Get,UNI_GetX,UNI_Put,UNI_PutX,UNI_Nak};
  
  UNI_MSG : record
    Cmd : UNI_CMD;
    Proc : ABS_NODE;
    HomeProc : boolean;
    Data : DATA;
  end;
  
  INV_CMD : enum{INV_None,INV_Inv,INV_InvAck};
  
  INV_MSG : record
    Cmd : INV_CMD;
  end;
  
  RP_CMD : enum{RP_None,RP_Replace};
  
  RP_MSG : record
    Cmd : RP_CMD;
  end;
  
  WB_CMD : enum{WB_None,WB_Wb};
  
  WB_MSG : record
    Cmd : WB_CMD;
    Proc : ABS_NODE;
    HomeProc : boolean;
    Data : DATA;
  end;
  
  SHWB_CMD : enum{SHWB_None,SHWB_ShWb,SHWB_FAck};
  
  SHWB_MSG : record
    Cmd : SHWB_CMD;
    Proc : ABS_NODE;
    HomeProc : boolean;
    Data : DATA;
  end;
  
  NAKC_CMD : enum{NAKC_None,NAKC_Nakc};
  
  NAKC_MSG : record
    Cmd : NAKC_CMD;
  end;
  new_type_2 : array [ NODE ] of NODE_STATE;
  new_type_3 : array [ NODE ] of UNI_MSG;
  new_type_4 : array [ NODE ] of INV_MSG;
  new_type_5 : array [ NODE ] of RP_MSG;
  
  STATE : record
    Proc : new_type_2;
    Dir : DIR_STATE;
    MemData : DATA;
    UniMsg : new_type_3;
    InvMsg : new_type_4;
    RpMsg : new_type_5;
    WbMsg : WB_MSG;
    ShWbMsg : SHWB_MSG;
    NakcMsg : NAKC_MSG;
    HomeProc : NODE_STATE;
    HomeUniMsg : UNI_MSG;
    HomeInvMsg : INV_MSG;
    HomeRpMsg : RP_MSG;
    CurrData : DATA;
  end;


var

  Sta : STATE;

rule "NI_Replace_Home1"
  Sta.HomeRpMsg.Cmd = RP_Replace &
  Sta.Dir.ShrVld
==>
begin
  Sta.HomeRpMsg.Cmd := RP_None;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
endrule;

rule "NI_Replace_Home2"
  Sta.HomeRpMsg.Cmd = RP_Replace &
  !Sta.Dir.ShrVld
==>
begin
  Sta.HomeRpMsg.Cmd := RP_None;
endrule;

ruleset  src : NODE do
rule "NI_Replace3"
  Sta.RpMsg[src].Cmd = RP_Replace &
  Sta.Dir.ShrVld
==>
begin
  Sta.RpMsg[src].Cmd := RP_None;
  Sta.Dir.ShrSet[src] := false;
  Sta.Dir.InvSet[src] := false;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Replace4"
  Sta.RpMsg[src].Cmd = RP_Replace &
  !Sta.Dir.ShrVld
==>
begin
  Sta.RpMsg[src].Cmd := RP_None;
endrule;
endruleset;

rule "NI_ShWb5"
  Sta.ShWbMsg.Cmd = SHWB_ShWb &
  Sta.ShWbMsg.HomeProc
==>
begin
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.ShWbMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.ShrVld := true;
  for p : NODE do
    if (p = Sta.ShWbMsg.Proc & Sta.ShWbMsg.HomeProc = false) | Sta.Dir.ShrSet[p]  then
      Sta.Dir.ShrSet[p] := true;
      Sta.Dir.InvSet[p] := true;
    else
      Sta.Dir.ShrSet[p] := false;
      Sta.Dir.InvSet[p] := false;
    end;
  end;
  if (Sta.ShWbMsg.HomeProc | Sta.Dir.HomeShrSet) then 
    Sta.Dir.HomeShrSet := true; 
    Sta.Dir.HomeInvSet := true; 
  else 
    Sta.Dir.HomeShrSet := false; 
    Sta.Dir.HomeInvSet := false; 
  end; 
  Sta.MemData := Sta.ShWbMsg.Data;
  undefine Sta.ShWbMsg.Proc;
  undefine Sta.ShWbMsg.Data;
endrule;

rule "NI_ShWb6"
  Sta.ShWbMsg.Cmd = SHWB_ShWb &
  Sta.Dir.HomeShrSet
==>
begin
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.ShWbMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.ShrVld := true;
  for p : NODE do
    if (p = Sta.ShWbMsg.Proc & Sta.ShWbMsg.HomeProc = false) | Sta.Dir.ShrSet[p]  then
      Sta.Dir.ShrSet[p] := true;
      Sta.Dir.InvSet[p] := true;
    else
      Sta.Dir.ShrSet[p] := false;
      Sta.Dir.InvSet[p] := false;
    end;
  end;
  if (Sta.ShWbMsg.HomeProc | Sta.Dir.HomeShrSet) then 
    Sta.Dir.HomeShrSet := true; 
    Sta.Dir.HomeInvSet := true; 
  else 
    Sta.Dir.HomeShrSet := false; 
    Sta.Dir.HomeInvSet := false; 
  end; 
  Sta.MemData := Sta.ShWbMsg.Data;
  undefine Sta.ShWbMsg.Proc;
  undefine Sta.ShWbMsg.Data;
endrule;

rule "NI_ShWb7"
  Sta.ShWbMsg.Cmd = SHWB_ShWb &
  !Sta.ShWbMsg.HomeProc &
  !Sta.Dir.HomeShrSet
==>
begin
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.ShWbMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.ShrVld := true;
  for p : NODE do
    if (p = Sta.ShWbMsg.Proc & Sta.ShWbMsg.HomeProc = false) | Sta.Dir.ShrSet[p]  then
      Sta.Dir.ShrSet[p] := true;
      Sta.Dir.InvSet[p] := true;
    else
      Sta.Dir.ShrSet[p] := false;
      Sta.Dir.InvSet[p] := false;
    end;
  end;
  if (Sta.ShWbMsg.HomeProc | Sta.Dir.HomeShrSet) then 
    Sta.Dir.HomeShrSet := true; 
    Sta.Dir.HomeInvSet := true; 
  else 
    Sta.Dir.HomeShrSet := false; 
    Sta.Dir.HomeInvSet := false; 
  end; 
  Sta.MemData := Sta.ShWbMsg.Data;
  undefine Sta.ShWbMsg.Proc;
  undefine Sta.ShWbMsg.Data;
endrule;

rule "NI_FAck8"
  Sta.ShWbMsg.Cmd = SHWB_FAck &
  Sta.Dir.Dirty = true
==>
begin
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.Dir.Pending := false;
  Sta.ShWbMsg.HomeProc := false;
  Sta.Dir.HeadPtr := Sta.ShWbMsg.Proc;
  Sta.Dir.HomeHeadPtr := Sta.ShWbMsg.HomeProc;
  undefine Sta.ShWbMsg.Proc;
  undefine Sta.ShWbMsg.Data;
endrule;

rule "NI_FAck9"
  Sta.ShWbMsg.Cmd = SHWB_FAck &
  Sta.Dir.Dirty != true
==>
begin
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.Dir.Pending := false;
  Sta.ShWbMsg.HomeProc := false;
  undefine Sta.ShWbMsg.Proc;
  undefine Sta.ShWbMsg.Data;
endrule;

rule "NI_Wb10"
  Sta.WbMsg.Cmd = WB_Wb
==>
begin
  Sta.WbMsg.Cmd := WB_None;
  Sta.WbMsg.HomeProc := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.HeadVld := false;
  Sta.MemData := Sta.WbMsg.Data;
  undefine Sta.Dir.HeadPtr;
  undefine Sta.WbMsg.Proc;
  undefine Sta.WbMsg.Data;
endrule;

ruleset  src : NODE do
rule "NI_InvAck_311"
  Sta.InvMsg[src].Cmd = INV_InvAck &
  Sta.Dir.Pending = true &
  Sta.Dir.InvSet[src] = true &
  Sta.Dir.Dirty = true &
  Sta.Dir.HomeInvSet = false &
  forall p : NODE do
    p = src | Sta.Dir.InvSet[p] = false
  end
==>
begin
  Sta.InvMsg[src].Cmd := INV_None;
  Sta.Dir.InvSet[src] := false;
  Sta.Dir.Pending := false;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_InvAck_212"
  Sta.InvMsg[src].Cmd = INV_InvAck &
  Sta.Dir.Pending = true &
  Sta.Dir.InvSet[src] = true &
  Sta.Dir.Local = false &
  Sta.Dir.HomeInvSet = false &
  forall p : NODE do
    p = src |
    Sta.Dir.InvSet[p] = false
  end
==>
begin
  Sta.InvMsg[src].Cmd := INV_None;
  Sta.Dir.InvSet[src] := false;
  Sta.Dir.Pending := false;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_InvAck_113"
  Sta.InvMsg[src].Cmd = INV_InvAck &
  Sta.Dir.Pending = true &
  Sta.Dir.InvSet[src] = true &
  Sta.Dir.Local = true &
  Sta.Dir.Dirty = false &
  Sta.Dir.HomeInvSet = false &
  forall p : NODE do
    p = src |
    Sta.Dir.InvSet[p] = false
  end
==>
begin
  Sta.InvMsg[src].Cmd := INV_None;
  Sta.Dir.InvSet[src] := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Local := false;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_InvAck_exists14"
  Sta.InvMsg[src].Cmd = INV_InvAck &
  Sta.Dir.Pending = true &
  Sta.Dir.InvSet[src] = true &
  dst != src &
  Sta.Dir.InvSet[dst]
==>
begin
  Sta.InvMsg[src].Cmd := INV_None;
  Sta.Dir.InvSet[src] := false;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_InvAck_exists_Home15"
  Sta.InvMsg[src].Cmd = INV_InvAck &
  Sta.Dir.Pending = true &
  Sta.Dir.InvSet[src] = true &
  Sta.Dir.HomeInvSet
==>
begin
  Sta.InvMsg[src].Cmd := INV_None;
  Sta.Dir.InvSet[src] := false;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Inv16"
  Sta.InvMsg[dst].Cmd = INV_Inv &
  Sta.Proc[dst].ProcCmd = NODE_Get
==>
begin
  Sta.InvMsg[dst].Cmd := INV_InvAck;
  Sta.Proc[dst].CacheState := CACHE_I;
  undefine Sta.Proc[dst].CacheData;
  Sta.Proc[dst].InvMarked := true;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Inv17"
  Sta.InvMsg[dst].Cmd = INV_Inv &
  Sta.Proc[dst].ProcCmd != NODE_Get
==>
begin
  Sta.InvMsg[dst].Cmd := INV_InvAck;
  Sta.Proc[dst].CacheState := CACHE_I;
  undefine Sta.Proc[dst].CacheData;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Remote_PutX18"
  Sta.UniMsg[dst].Cmd = UNI_PutX &
  Sta.Proc[dst].ProcCmd = NODE_GetX
==>
begin
  Sta.UniMsg[dst].Cmd := UNI_None;
  Sta.UniMsg[dst].HomeProc := false;
  Sta.Proc[dst].ProcCmd := NODE_None;
  Sta.Proc[dst].InvMarked := false;
  Sta.Proc[dst].CacheState := CACHE_E;
  Sta.Proc[dst].CacheData := Sta.UniMsg[dst].Data;
  undefine Sta.UniMsg[dst].Proc;
  undefine Sta.UniMsg[dst].Data;
endrule;
endruleset;

rule "NI_Local_PutXAcksDone19"
  Sta.HomeUniMsg.Cmd = UNI_PutX
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_None;
  Sta.HomeUniMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Local := true;
  Sta.Dir.HeadVld := false;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.HomeUniMsg.Data;
  undefine Sta.Dir.HeadPtr;
  undefine Sta.HomeUniMsg.Proc;
  undefine Sta.HomeUniMsg.Data;
endrule;

ruleset  dst : NODE do
rule "NI_Remote_Put20"
  Sta.UniMsg[dst].Cmd = UNI_Put &
  Sta.Proc[dst].InvMarked
==>
begin
  Sta.UniMsg[dst].Cmd := UNI_None;
  Sta.UniMsg[dst].HomeProc := false;
  Sta.Proc[dst].ProcCmd := NODE_None;
  Sta.Proc[dst].InvMarked := false;
  Sta.Proc[dst].CacheState := CACHE_I;
  undefine Sta.Proc[dst].CacheData;
  undefine Sta.UniMsg[dst].Proc;
  undefine Sta.UniMsg[dst].Data;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Remote_Put21"
  Sta.UniMsg[dst].Cmd = UNI_Put &
  !Sta.Proc[dst].InvMarked
==>
begin
  Sta.UniMsg[dst].Cmd := UNI_None;
  Sta.UniMsg[dst].HomeProc := false;
  Sta.Proc[dst].ProcCmd := NODE_None;
  Sta.Proc[dst].CacheState := CACHE_S;
  Sta.Proc[dst].CacheData := Sta.UniMsg[dst].Data;
  undefine Sta.UniMsg[dst].Proc;
  undefine Sta.UniMsg[dst].Data;
endrule;
endruleset;

rule "NI_Local_Put22"
  Sta.HomeUniMsg.Cmd = UNI_Put &
  Sta.HomeProc.InvMarked
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_None;
  Sta.HomeUniMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.Local := true;
  Sta.MemData := Sta.HomeUniMsg.Data;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
  undefine Sta.HomeUniMsg.Proc;
  undefine Sta.HomeUniMsg.Data;
endrule;

rule "NI_Local_Put23"
  Sta.HomeUniMsg.Cmd = UNI_Put &
  !Sta.HomeProc.InvMarked
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_None;
  Sta.HomeUniMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.Local := true;
  Sta.MemData := Sta.HomeUniMsg.Data;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.CacheState := CACHE_S;
  Sta.HomeProc.CacheData := Sta.HomeUniMsg.Data;
  undefine Sta.HomeUniMsg.Proc;
  undefine Sta.HomeUniMsg.Data;
endrule;

ruleset  dst : NODE do
rule "NI_Remote_GetX_PutX_Home24"
  Sta.HomeUniMsg.Cmd = UNI_GetX &
  Sta.HomeUniMsg.Proc = dst &
  Sta.HomeUniMsg.HomeProc = false &
  Sta.Proc[dst].CacheState = CACHE_E
==>
begin
  Sta.Proc[dst].CacheState := CACHE_I;
  Sta.HomeUniMsg.Cmd := UNI_PutX;
  Sta.HomeUniMsg.Data := Sta.Proc[dst].CacheData;
  undefine Sta.Proc[dst].CacheData;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Remote_GetX_PutX25"
  src != dst &
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].Proc = dst &
  Sta.UniMsg[src].HomeProc = false &
  Sta.Proc[dst].CacheState = CACHE_E
==>
begin
  Sta.Proc[dst].CacheState := CACHE_I;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.Proc[dst].CacheData;
  Sta.ShWbMsg.Cmd := SHWB_FAck;
  Sta.ShWbMsg.Proc := src;
  Sta.ShWbMsg.HomeProc := false;
  undefine Sta.ShWbMsg.Data;
  undefine Sta.Proc[dst].CacheData;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Remote_GetX_Nak_Home26"
  Sta.HomeUniMsg.Cmd = UNI_GetX &
  Sta.HomeUniMsg.Proc = dst &
  Sta.HomeUniMsg.HomeProc = false &
  Sta.Proc[dst].CacheState != CACHE_E
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_Nak;
  Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Remote_GetX_Nak27"
  src != dst &
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].Proc = dst &
  Sta.UniMsg[src].HomeProc = false &
  Sta.Proc[dst].CacheState != CACHE_E
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].Proc := dst;
  Sta.UniMsg[src].HomeProc := false;
  undefine Sta.UniMsg[src].Data;
  Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_1128"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = true &
  Sta.HomeProc.CacheState = CACHE_E
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.HomeProc.CacheData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Local_GetX_PutX_1029"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.ShrSet[dst] &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src & ((Sta.Dir.ShrVld & Sta.Dir.ShrSet[p]) | ((Sta.Dir.HeadVld & Sta.Dir.HeadPtr = p) & Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_10_Home30"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_931"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr != src &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_932"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HomeHeadPtr = true &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Local_GetX_PutX_8_NODE_Get33"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.ShrSet[dst] &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
  Sta.HomeProc.InvMarked := true;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Local_GetX_PutX_834"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.ShrSet[dst] &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_8_Home_NODE_Get35"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
  Sta.HomeProc.InvMarked := true;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_8_Home36"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_7_NODE_Get37"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr != src &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  Sta.HomeProc.InvMarked := true;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_7_NODE_Get38"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HomeHeadPtr = true &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  Sta.HomeProc.InvMarked := true;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_739"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr != src &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_740"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_641"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet = false &
  forall p : NODE do
    p != src ->
    Sta.Dir.ShrSet[p] = false
  end &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_542"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet = false &
  forall p : NODE do
    p != src ->
    Sta.Dir.ShrSet[p] = false
  end &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_443"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet = false &
  forall p : NODE do
    p != src ->
    Sta.Dir.ShrSet[p] = false
  end &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
  Sta.HomeProc.InvMarked := true;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_344"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_245"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_146"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  Sta.HomeProc.InvMarked := true;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_GetX47"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HeadPtr != src
==>
begin
  Sta.Dir.Pending := true;
  Sta.UniMsg[src].Cmd := UNI_GetX;
  Sta.UniMsg[src].Proc := Sta.Dir.HeadPtr;
  undefine Sta.UniMsg[src].Data;
  Sta.UniMsg[src].HomeProc := Sta.Dir.HomeHeadPtr;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_GetX48"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HomeHeadPtr = true
==>
begin
  Sta.Dir.Pending := true;
  Sta.UniMsg[src].Cmd := UNI_GetX;
  Sta.UniMsg[src].Proc := Sta.Dir.HeadPtr;
  undefine Sta.UniMsg[src].Data;
  Sta.UniMsg[src].HomeProc := Sta.Dir.HomeHeadPtr;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_Nak49"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = true
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_Nak50"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = true &
  Sta.HomeProc.CacheState != CACHE_E
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_Nak51"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Remote_Get_Put_Home52"
  Sta.HomeUniMsg.Cmd = UNI_Get &
  Sta.HomeUniMsg.Proc = dst &
  Sta.HomeUniMsg.HomeProc = false &
  Sta.Proc[dst].CacheState = CACHE_E
==>
begin
  Sta.Proc[dst].CacheState := CACHE_S;
  Sta.HomeUniMsg.Cmd := UNI_Put;
  Sta.HomeUniMsg.Data := Sta.Proc[dst].CacheData;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Remote_Get_Put53"
  src != dst &
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].Proc = dst &
  Sta.UniMsg[src].HomeProc = false &
  Sta.Proc[dst].CacheState = CACHE_E
==>
begin
  Sta.Proc[dst].CacheState := CACHE_S;
  Sta.UniMsg[src].Cmd := UNI_Put;
  Sta.UniMsg[src].Data := Sta.Proc[dst].CacheData;
  Sta.ShWbMsg.Cmd := SHWB_ShWb;
  Sta.ShWbMsg.Proc := src;
  Sta.ShWbMsg.HomeProc := false;
  Sta.ShWbMsg.Data := Sta.Proc[dst].CacheData;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Remote_Get_Nak_Home54"
  Sta.HomeUniMsg.Cmd = UNI_Get &
  Sta.HomeUniMsg.Proc = dst &
  Sta.HomeUniMsg.HomeProc = false &
  Sta.Proc[dst].CacheState != CACHE_E
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_Nak;
  Sta.NakcMsg.Cmd := NAKC_Nakc;
  undefine Sta.HomeUniMsg.Data;
  undefine Sta.HomeUniMsg.Proc;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Remote_Get_Nak55"
  src != dst &
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].Proc = dst &
  Sta.UniMsg[src].HomeProc = false &
  Sta.Proc[dst].CacheState != CACHE_E
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].Proc := dst;
  Sta.UniMsg[src].HomeProc := false;
  undefine Sta.UniMsg[src].Data;
  Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Put_Dirty56"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = true &
  Sta.HomeProc.CacheState = CACHE_E
==>
begin
  Sta.Dir.Dirty := false;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.MemData := Sta.HomeProc.CacheData;
  Sta.HomeProc.CacheState := CACHE_S;
  Sta.UniMsg[src].Cmd := UNI_Put;
  Sta.UniMsg[src].Data := Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Put57"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false
==>
begin
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.UniMsg[src].Cmd := UNI_Put;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Put_Head58"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld
==>
begin
  Sta.Dir.ShrVld := true;
  Sta.Dir.ShrSet[src] := true;
  for p : NODE do
    if (p = src) then
      Sta.Dir.InvSet[p] := true;
    else
      Sta.Dir.InvSet[p] := Sta.Dir.ShrSet[p];
    end;
  end;
  Sta.Dir.HomeInvSet := Sta.Dir.HomeShrSet;
  Sta.UniMsg[src].Cmd := UNI_Put;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Get59"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HeadPtr != src
==>
begin
  Sta.Dir.Pending := true;
  Sta.UniMsg[src].Cmd := UNI_Get;
  Sta.UniMsg[src].Proc := Sta.Dir.HeadPtr;
  undefine Sta.UniMsg[src].Data;
  Sta.UniMsg[src].HomeProc := Sta.Dir.HomeHeadPtr;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Get60"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HomeHeadPtr = true
==>
begin
  Sta.Dir.Pending := true;
  Sta.UniMsg[src].Cmd := UNI_Get;
  Sta.UniMsg[src].Proc := Sta.Dir.HeadPtr;
  undefine Sta.UniMsg[src].Data;
  Sta.UniMsg[src].HomeProc := Sta.Dir.HomeHeadPtr;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Nak61"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = true
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Nak62"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = true &
  Sta.HomeProc.CacheState != CACHE_E
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Nak63"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

rule "NI_Nak_Clear64"
  Sta.NakcMsg.Cmd = NAKC_Nakc
==>
begin
  Sta.NakcMsg.Cmd := NAKC_None;
  Sta.Dir.Pending := false;
endrule;

rule "NI_Nak_Home65"
  Sta.HomeUniMsg.Cmd = UNI_Nak
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_None;
  Sta.HomeUniMsg.HomeProc := false;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  undefine Sta.HomeUniMsg.Proc;
  undefine Sta.HomeUniMsg.Data;
endrule;

ruleset  dst : NODE do
rule "NI_Nak66"
  Sta.UniMsg[dst].Cmd = UNI_Nak
==>
begin
  Sta.UniMsg[dst].Cmd := UNI_None;
  Sta.UniMsg[dst].HomeProc := false;
  Sta.Proc[dst].ProcCmd := NODE_None;
  Sta.Proc[dst].InvMarked := false;
  undefine Sta.UniMsg[dst].Proc;
  undefine Sta.UniMsg[dst].Data;
endrule;
endruleset;

rule "PI_Local_Replace67"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_S
==>
begin
  Sta.Dir.Local := false;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;

ruleset  src : NODE do
rule "PI_Remote_Replace68"
  Sta.Proc[src].ProcCmd = NODE_None &
  Sta.Proc[src].CacheState = CACHE_S
==>
begin
  Sta.Proc[src].CacheState := CACHE_I;
  Sta.RpMsg[src].Cmd := RP_Replace;
  undefine Sta.Proc[src].CacheData;
endrule;
endruleset;

rule "PI_Local_PutX69"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_E &
  Sta.Dir.Pending = true
==>
begin
  Sta.HomeProc.CacheState := CACHE_I;
  Sta.Dir.Dirty := false;
  Sta.MemData := Sta.HomeProc.CacheData;
  undefine Sta.HomeProc.CacheData;
endrule;

rule "PI_Local_PutX70"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_E &
  Sta.Dir.Pending != true
==>
begin
  Sta.HomeProc.CacheState := CACHE_I;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := false;
  Sta.MemData := Sta.HomeProc.CacheData;
  undefine Sta.HomeProc.CacheData;
endrule;

ruleset  dst : NODE do
rule "PI_Remote_PutX71"
  Sta.Proc[dst].ProcCmd = NODE_None &
  Sta.Proc[dst].CacheState = CACHE_E
==>
begin
  Sta.Proc[dst].CacheState := CACHE_I;
  Sta.WbMsg.Cmd := WB_Wb;
  Sta.WbMsg.Proc := dst;
  Sta.WbMsg.HomeProc := false;
  Sta.WbMsg.Data := Sta.Proc[dst].CacheData;
  undefine Sta.Proc[dst].CacheData;
endrule;
endruleset;

rule "PI_Local_GetX_PutX_HeadVld7572"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_S &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = true
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.Dir.Pending := true;
  Sta.Dir.HeadVld := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if (((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    (Sta.Dir.HeadPtr = p &
    Sta.Dir.HomeHeadPtr = false))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_PutX_HeadVld7473"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = true
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.Dir.Pending := true;
  Sta.Dir.HeadVld := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if (((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    (Sta.Dir.HeadPtr = p &
    Sta.Dir.HomeHeadPtr = false))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_PutX7374"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_S &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_PutX7275"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_PutX_HeadVld76"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = true
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.Dir.Pending := true;
  Sta.Dir.HeadVld := false;
  undefine Sta.Dir.HeadPtr;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if (((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    (Sta.Dir.HeadPtr = p &
    Sta.Dir.HomeHeadPtr = false))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_PutX_HeadVld77"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_S &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = true
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.Dir.Pending := true;
  Sta.Dir.HeadVld := false;
  undefine Sta.Dir.HeadPtr;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if (((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    (Sta.Dir.HeadPtr = p &
    Sta.Dir.HomeHeadPtr = false))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_GetX78"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true
==>
begin
  Sta.HomeProc.ProcCmd := NODE_GetX;
  Sta.Dir.Pending := true;
  Sta.HomeUniMsg.Cmd := UNI_GetX;
  Sta.HomeUniMsg.Proc := Sta.Dir.HeadPtr;
  Sta.HomeUniMsg.HomeProc := Sta.Dir.HomeHeadPtr;
endrule;

rule "PI_Local_GetX_GetX79"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_S &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true
==>
begin
  Sta.HomeProc.ProcCmd := NODE_GetX;
  Sta.Dir.Pending := true;
  Sta.HomeUniMsg.Cmd := UNI_GetX;
  Sta.HomeUniMsg.Proc := Sta.Dir.HeadPtr;
  Sta.HomeUniMsg.HomeProc := Sta.Dir.HomeHeadPtr;
endrule;

ruleset  src : NODE do
rule "PI_Remote_GetX80"
  Sta.Proc[src].ProcCmd = NODE_None &
  Sta.Proc[src].CacheState = CACHE_I
==>
begin
  Sta.Proc[src].ProcCmd := NODE_GetX;
  Sta.UniMsg[src].Cmd := UNI_GetX;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

rule "PI_Local_Get_Put81"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.HomeProc.InvMarked
==>
begin
  Sta.Dir.Local := true;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;

rule "PI_Local_Get_Put82"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  !Sta.HomeProc.InvMarked
==>
begin
  Sta.Dir.Local := true;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.CacheState := CACHE_S;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_Get_Get83"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true
==>
begin
  Sta.HomeProc.ProcCmd := NODE_Get;
  Sta.Dir.Pending := true;
  Sta.HomeUniMsg.Cmd := UNI_Get;
  Sta.HomeUniMsg.Proc := Sta.Dir.HeadPtr;
  Sta.HomeUniMsg.HomeProc := Sta.Dir.HomeHeadPtr;
  undefine Sta.HomeUniMsg.Data;
endrule;

ruleset  src : NODE do
rule "PI_Remote_Get84"
  Sta.Proc[src].ProcCmd = NODE_None &
  Sta.Proc[src].CacheState = CACHE_I
==>
begin
  Sta.Proc[src].ProcCmd := NODE_Get;
  Sta.UniMsg[src].Cmd := UNI_Get;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  data : DATA do
rule "Store_Home85"
  Sta.HomeProc.CacheState = CACHE_E
==>
begin
  Sta.HomeProc.CacheData := data;
  Sta.CurrData := data;
endrule;
endruleset;

ruleset  data : DATA; src : NODE do
rule "Store86"
  Sta.Proc[src].CacheState = CACHE_E
==>
begin
  Sta.Proc[src].CacheData := data;
  Sta.CurrData := data;
endrule;
endruleset;

ruleset  h : NODE; d : DATA do
startstate
  undefine Sta;
  Sta.MemData := d;
  Sta.Dir.Pending := false;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.HeadVld := false;
  Sta.Dir.HeadPtr := h;
  Sta.Dir.HomeHeadPtr := true;
  Sta.Dir.ShrVld := false;
  Sta.WbMsg.Cmd := WB_None;
  Sta.WbMsg.Proc := h;
  Sta.WbMsg.HomeProc := true;
  Sta.WbMsg.Data := d;
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.ShWbMsg.Proc := h;
  Sta.ShWbMsg.HomeProc := true;
  Sta.ShWbMsg.Data := d;
  Sta.NakcMsg.Cmd := NAKC_None;
  for p : NODE do
    Sta.Proc[p].ProcCmd := NODE_None;
    Sta.Proc[p].InvMarked := false;
    Sta.Proc[p].CacheState := CACHE_I;
    Sta.Proc[p].CacheData := d;
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
    Sta.UniMsg[p].Cmd := UNI_None;
    Sta.UniMsg[p].Proc := h;
    Sta.UniMsg[p].HomeProc := true;
    Sta.UniMsg[p].Data := d;
    Sta.InvMsg[p].Cmd := INV_None;
    Sta.RpMsg[p].Cmd := RP_None;
  end;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
  Sta.HomeProc.CacheData := d;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeUniMsg.Cmd := UNI_None;
  Sta.HomeUniMsg.Proc := h;
  Sta.HomeUniMsg.HomeProc := true;
  Sta.HomeUniMsg.Data := d;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.HomeRpMsg.Cmd := RP_None;
  Sta.CurrData := d;
endstartstate;
endruleset;
invariant "CacheStateProp"
  forall p : NODE do
    forall q : NODE do
      (p != q ->
      !(Sta.Proc[p].CacheState = CACHE_E &
      Sta.Proc[q].CacheState = CACHE_E))
    end
  end;

invariant "CacheStatePropHome"
  forall p : NODE do
    !(Sta.Proc[p].CacheState = CACHE_E &
    Sta.HomeProc.CacheState = CACHE_E)
  end;

invariant "DataProp"
  forall p : NODE do
    (Sta.Proc[p].CacheState = CACHE_E ->
    Sta.Proc[p].CacheData = Sta.CurrData)
  end;

invariant "MemDataProp"
  (Sta.Dir.Dirty = false ->
  Sta.MemData = Sta.CurrData);


-- No abstract rule for rule NI_Replace3



-- No abstract rule for rule NI_Replace4


rule "n_ABS_NI_InvAck_311_NODE_1"

	Sta.Dir.Pending = true &
	Sta.Dir.Dirty = true &
	Sta.Dir.HomeInvSet = false
	& forall NODE_2 : NODE do
			false | Sta.Dir.InvSet[NODE_2] = false
	end
 	& Sta.Dir.Local = true &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Dir.HeadVld = false &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.Dir.HeadVld = true &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.WbMsg.Cmd != WB_Wb&
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.UniMsg[NODE_2].Proc != Other &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr = NODE_1
	end
==>
begin
	Sta.Dir.Pending := false;
endrule;
rule "n_ABS_NI_InvAck_212_NODE_1"

	Sta.Dir.Pending = true &
	Sta.Dir.Local = false &
	Sta.Dir.HomeInvSet = false
	& forall NODE_2 : NODE do
			false |
    Sta.Dir.InvSet[NODE_2] = false
	end
 	& Sta.WbMsg.Cmd != WB_Wb &
		Sta.Dir.Dirty = false &
		Sta.Dir.Local = true &
		Sta.Dir.ShrVld = true &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.MemData = Sta.CurrData &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.Dir.HeadVld = false &
		Sta.Dir.HeadVld = true &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.Dir.Pending = false&
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.UniMsg[NODE_2].Proc != Other &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr = NODE_1
	end
==>
begin
	Sta.Dir.Pending := false;
endrule;
rule "n_ABS_NI_InvAck_113_NODE_1"

	Sta.Dir.Pending = true &
	Sta.Dir.Local = true &
	Sta.Dir.Dirty = false &
	Sta.Dir.HomeInvSet = false
	& forall NODE_2 : NODE do
			false |
    Sta.Dir.InvSet[NODE_2] = false
	end
 	& Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.Dir.HeadVld = false &
		Sta.Dir.HeadVld = true &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.WbMsg.Cmd != WB_Wb&
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.UniMsg[NODE_2].Proc != Other &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr = NODE_1
	end
==>
begin
	Sta.Dir.Pending := false ;
	Sta.Dir.Local := false;
endrule;

ruleset NODE_2 : NODE do
rule "n_ABS_NI_InvAck_exists14_NODE_1"

	Sta.InvMsg[NODE_2].Cmd = INV_InvAck &
	Sta.Dir.Pending = true &
	Sta.Dir.InvSet[NODE_2] = true &
	false
 	& Sta.WbMsg.Cmd != WB_Wb &
		Sta.Dir.Dirty = false &
		Sta.Dir.ShrVld = true &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Dir.Local = true &
		Sta.Dir.ShrVld = false &
		Sta.MemData = Sta.CurrData &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.Dir.HeadVld = false &
		Sta.Dir.HeadPtr = NODE_2 &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.Dir.Pending = false&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.InvMsg[NODE_2].Cmd := INV_None ;
	Sta.Dir.InvSet[NODE_2] := false;
endrule;
endruleset;



-- No abstract rule for rule NI_InvAck_exists14



-- No abstract rule for rule NI_InvAck_exists14



-- No abstract rule for rule NI_InvAck_exists_Home15



-- No abstract rule for rule NI_Inv16



-- No abstract rule for rule NI_Inv17



-- No abstract rule for rule NI_Remote_PutX18



-- No abstract rule for rule NI_Remote_Put20



-- No abstract rule for rule NI_Remote_Put21


rule "n_ABS_NI_Remote_GetX_PutX_Home24_NODE_1"

	Sta.HomeUniMsg.Cmd = UNI_GetX &
	Sta.HomeUniMsg.Proc = Other &
	Sta.HomeUniMsg.HomeProc = false
 	& Sta.Dir.HeadVld = true &
		Sta.Dir.Pending = true &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.ShWbMsg.Cmd = SHWB_FAck &
		Sta.Dir.Dirty = true &
		Sta.Dir.Local = false &
		Sta.Dir.ShrVld = false&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_2].Cmd != UNI_Put &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.ShWbMsg.Proc != NODE_2 &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.Dir.ShrSet[NODE_2] = false &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.Proc[NODE_2].CacheState = CACHE_I &
		Sta.Proc[NODE_2].CacheState != CACHE_S &
		Sta.Proc[NODE_2].InvMarked = false &
		Sta.UniMsg[NODE_2].Proc != Other &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.Dir.HeadPtr = NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.ShWbMsg.Proc = NODE_1 &
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.HomeUniMsg.Cmd := UNI_PutX;
endrule;

ruleset NODE_2 : NODE do
rule "n_ABS_NI_Remote_GetX_PutX25_NODE_1"

	Sta.UniMsg[NODE_2].Cmd = UNI_GetX &
	Sta.UniMsg[NODE_2].Proc = Other &
	Sta.UniMsg[NODE_2].HomeProc = false
 	& Sta.Dir.Dirty = false &
		Sta.UniMsg[NODE_2].Cmd != UNI_Put &
		Sta.Dir.HeadVld = false &
		Sta.Dir.HeadVld = true &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.Dir.Pending = true &
		Sta.MemData = Sta.CurrData &
		Sta.ShWbMsg.Proc != NODE_2 &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.Dir.ShrSet[NODE_2] = false &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Proc[NODE_2].CacheState = CACHE_I &
		Sta.Proc[NODE_2].CacheState != CACHE_S &
		Sta.Proc[NODE_2].InvMarked = false &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.ShWbMsg.Cmd = SHWB_FAck &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.Dir.Dirty = true &
		Sta.Dir.Local = false &
		Sta.Dir.ShrVld = false &
		Sta.Dir.HeadPtr = NODE_2&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.ShWbMsg.Proc = NODE_1 &
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.UniMsg[NODE_2].Proc != NODE_1 &
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.UniMsg[NODE_2].Cmd := UNI_PutX ;
	Sta.ShWbMsg.Cmd := SHWB_FAck ;
	Sta.ShWbMsg.Proc := NODE_2 ;
	Sta.ShWbMsg.HomeProc := false;
endrule;
endruleset;



ruleset NODE_1 : NODE do
rule "n_ABS_NI_Remote_GetX_PutX25_NODE_2"

	Sta.Proc[NODE_1].CacheState = CACHE_E
 	& Sta.Dir.Dirty = false &
		Sta.Proc[NODE_1].InvMarked = false &
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.Dir.HeadVld = false &
		Sta.Dir.HeadVld = true &
		Sta.Dir.InvSet[NODE_1] = false &
		Sta.ShWbMsg.Proc = NODE_1 &
		Sta.Dir.Pending = true &
		Sta.MemData = Sta.CurrData &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.InvMsg[NODE_1].Cmd != INV_InvAck &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.UniMsg[NODE_1].Cmd != UNI_Put &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Dir.ShrSet[NODE_1] = false &
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.InvMsg[NODE_1].Cmd != INV_Inv &
		Sta.Proc[NODE_1].CacheState != CACHE_S &
		Sta.Proc[NODE_1].CacheState = CACHE_I &
		Sta.ShWbMsg.Cmd = SHWB_FAck &
		Sta.Dir.Dirty = true &
		Sta.Dir.HeadPtr != NODE_1 &
		Sta.Dir.Local = false &
		Sta.UniMsg[NODE_1].Cmd != UNI_PutX &
		Sta.Dir.ShrVld = false &
		Sta.Proc[NODE_1].CacheState != CACHE_E&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_1].Proc != NODE_2 &
		Sta.ShWbMsg.Proc != NODE_2 &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.Dir.HeadPtr = NODE_2
	end
==>
begin
	Sta.Proc[NODE_1].CacheState := CACHE_I ;
	Sta.ShWbMsg.Cmd := SHWB_FAck ;
	Sta.ShWbMsg.Proc := Other ;
	Sta.ShWbMsg.HomeProc := false;
endrule;
endruleset;


rule "n_ABS_NI_Remote_GetX_PutX25_NODE_1_NODE_2"

	Other != Other
 	& Sta.Dir.Dirty = false &
		Sta.Dir.HeadVld = false &
		Sta.Dir.HeadVld = true &
		Sta.Dir.Pending = true &
		Sta.MemData = Sta.CurrData &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.ShWbMsg.Cmd = SHWB_FAck &
		Sta.Dir.Dirty = true &
		Sta.Dir.Local = false &
		Sta.Dir.ShrVld = false&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_2].Cmd != UNI_Put &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.ShWbMsg.Proc != NODE_2 &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.Dir.ShrSet[NODE_2] = false &
		Sta.Proc[NODE_2].CacheState = CACHE_I &
		Sta.Proc[NODE_2].CacheState != CACHE_S &
		Sta.Proc[NODE_2].InvMarked = false &
		Sta.UniMsg[NODE_2].Proc != Other &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.Dir.HeadPtr = NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Proc[NODE_1].InvMarked = false &
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.Dir.InvSet[NODE_1] = false &
		Sta.ShWbMsg.Proc = NODE_1 &
		Sta.UniMsg[NODE_1].Proc != Other &
		Sta.InvMsg[NODE_1].Cmd != INV_InvAck &
		Sta.UniMsg[NODE_1].Cmd != UNI_Put &
		Sta.Dir.ShrSet[NODE_1] = false &
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.InvMsg[NODE_1].Cmd != INV_Inv &
		Sta.Proc[NODE_1].CacheState != CACHE_S &
		Sta.Proc[NODE_1].CacheState = CACHE_I &
		Sta.Dir.HeadPtr != NODE_1 &
		Sta.UniMsg[NODE_1].Cmd != UNI_PutX &
		Sta.Proc[NODE_1].CacheState != CACHE_E
	end
==>
begin
	Sta.ShWbMsg.Cmd := SHWB_FAck ;
	Sta.ShWbMsg.Proc := Other ;
	Sta.ShWbMsg.HomeProc := false;
endrule;
rule "n_ABS_NI_Remote_GetX_Nak_Home26_NODE_1"

	Sta.HomeUniMsg.Cmd = UNI_GetX &
	Sta.HomeUniMsg.Proc = Other &
	Sta.HomeUniMsg.HomeProc = false
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.HomeUniMsg.Cmd := UNI_Nak ;
	Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;

ruleset NODE_2 : NODE do
rule "n_ABS_NI_Remote_GetX_Nak27_NODE_1"

	Sta.UniMsg[NODE_2].Cmd = UNI_GetX &
	Sta.UniMsg[NODE_2].Proc = Other &
	Sta.UniMsg[NODE_2].HomeProc = false
 	& Sta.Dir.Local = false &
		Sta.Dir.Dirty = false &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.Dir.Pending = true &
		Sta.Dir.ShrVld = false &
		Sta.MemData = Sta.CurrData &
		Sta.Dir.HeadVld = false &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.Dir.HeadPtr != NODE_2&
	forall NODE_1 : NODE do
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.UniMsg[NODE_2].Cmd := UNI_Nak ;
	Sta.UniMsg[NODE_2].Proc := Other ;
	Sta.UniMsg[NODE_2].HomeProc := false ;
	Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
endruleset;



ruleset NODE_1 : NODE do
rule "n_ABS_NI_Remote_GetX_Nak27_NODE_2"

	Sta.Proc[NODE_1].CacheState != CACHE_E
 	& Sta.Dir.Dirty = false &
		Sta.Proc[NODE_1].InvMarked = false &
		Sta.Dir.HeadVld = false &
		Sta.Dir.InvSet[NODE_1] = false &
		Sta.Dir.Pending = true &
		Sta.MemData = Sta.CurrData &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.InvMsg[NODE_1].Cmd != INV_InvAck &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.UniMsg[NODE_1].Cmd != UNI_Put &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Dir.ShrSet[NODE_1] = false &
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.InvMsg[NODE_1].Cmd != INV_Inv &
		Sta.Proc[NODE_1].CacheState != CACHE_S &
		Sta.Proc[NODE_1].CacheState = CACHE_I &
		Sta.Dir.HeadPtr != NODE_1 &
		Sta.Dir.Local = false &
		Sta.UniMsg[NODE_1].Cmd != UNI_PutX &
		Sta.Dir.ShrVld = false&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_1].Proc != NODE_2 &
		Sta.Dir.HeadPtr != NODE_2
	end
==>
begin
	Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
endruleset;


rule "n_ABS_NI_Remote_GetX_Nak27_NODE_1_NODE_2"

	Other != Other
 	& Sta.Dir.Dirty = false &
		Sta.Dir.HeadVld = false &
		Sta.Dir.Pending = true &
		Sta.MemData = Sta.CurrData &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Dir.Local = false &
		Sta.Dir.ShrVld = false&
	forall NODE_1 : NODE do
		Sta.Proc[NODE_1].InvMarked = false &
		Sta.Dir.InvSet[NODE_1] = false &
		Sta.UniMsg[NODE_1].Proc != Other &
		Sta.InvMsg[NODE_1].Cmd != INV_InvAck &
		Sta.UniMsg[NODE_1].Cmd != UNI_Put &
		Sta.Dir.ShrSet[NODE_1] = false &
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.InvMsg[NODE_1].Cmd != INV_Inv &
		Sta.Proc[NODE_1].CacheState != CACHE_S &
		Sta.Proc[NODE_1].CacheState = CACHE_I &
		Sta.Dir.HeadPtr != NODE_1 &
		Sta.UniMsg[NODE_1].Cmd != UNI_PutX
	end&
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end
==>
begin
	Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_1128_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = true &
	Sta.Dir.Local = true &
	Sta.HomeProc.CacheState = CACHE_E
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	Sta.Dir.InvSet[p] := false ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;

ruleset NODE_2 : NODE do
rule "n_ABS_NI_Local_GetX_PutX_1029_NODE_1"

	Sta.UniMsg[NODE_2].Cmd = UNI_GetX &
	Sta.UniMsg[NODE_2].HomeProc &
	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = NODE_2 &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.Local = false
 	& 
	forall NODE_1 : NODE do
		Sta.UniMsg[NODE_2].Proc != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := NODE_2 ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((p != NODE_2 & ((Sta.Dir.ShrVld & Sta.Dir.ShrSet[p]) | ((Sta.Dir.HeadVld & Sta.Dir.HeadPtr = p) & Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.UniMsg[NODE_2].Cmd := UNI_PutX ;
	Sta.UniMsg[NODE_2].Data := Sta.MemData;
endrule;
endruleset;



ruleset NODE_1 : NODE do
rule "n_ABS_NI_Local_GetX_PutX_1029_NODE_2"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.ShrSet[NODE_1] &
	Sta.Dir.Local = false
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false & ((Sta.Dir.ShrVld & Sta.Dir.ShrSet[p]) | ((Sta.Dir.HeadVld & Sta.Dir.HeadPtr = p) & Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None;
endrule;
endruleset;


rule "n_ABS_NI_Local_GetX_PutX_1029_NODE_1_NODE_2"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.Local = false
 	& 
	forall NODE_1 : NODE do
		Sta.InvMsg[NODE_1].Cmd != INV_Inv
	end&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_2].Proc != Other
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false & ((Sta.Dir.ShrVld & Sta.Dir.ShrSet[p]) | ((Sta.Dir.HeadVld & Sta.Dir.HeadPtr = p) & Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_10_Home30_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.HomeShrSet &
	Sta.Dir.Local = false
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_931_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr != Other &
	Sta.Dir.Local = false
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_932_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HomeHeadPtr = true &
	Sta.Dir.Local = false
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None;
endrule;

ruleset NODE_2 : NODE do
rule "n_ABS_NI_Local_GetX_PutX_8_NODE_Get33_NODE_1"

	Sta.UniMsg[NODE_2].Cmd = UNI_GetX &
	Sta.UniMsg[NODE_2].HomeProc &
	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = NODE_2 &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd = NODE_Get
 	& 
	forall NODE_1 : NODE do
		Sta.UniMsg[NODE_2].Proc != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := NODE_2 ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((p != NODE_2 &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.UniMsg[NODE_2].Cmd := UNI_PutX ;
	Sta.UniMsg[NODE_2].Data := Sta.MemData ;
	Sta.HomeProc.CacheState := CACHE_I ;
	Sta.HomeProc.InvMarked := true;
endrule;
endruleset;



ruleset NODE_1 : NODE do
rule "n_ABS_NI_Local_GetX_PutX_8_NODE_Get33_NODE_2"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.ShrSet[NODE_1] &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.HomeProc.CacheState := CACHE_I ;
	Sta.HomeProc.InvMarked := true;
endrule;
endruleset;


rule "n_ABS_NI_Local_GetX_PutX_8_NODE_Get33_NODE_1_NODE_2"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd = NODE_Get
 	& 
	forall NODE_1 : NODE do
		Sta.InvMsg[NODE_1].Cmd != INV_Inv
	end&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_2].Proc != Other
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.HomeProc.CacheState := CACHE_I ;
	Sta.HomeProc.InvMarked := true;
endrule;

ruleset NODE_2 : NODE do
rule "n_ABS_NI_Local_GetX_PutX_834_NODE_1"

	Sta.UniMsg[NODE_2].Cmd = UNI_GetX &
	Sta.UniMsg[NODE_2].HomeProc &
	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = NODE_2 &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd != NODE_Get
 	& 
	forall NODE_1 : NODE do
		Sta.UniMsg[NODE_2].Proc != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := NODE_2 ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((p != NODE_2 &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.UniMsg[NODE_2].Cmd := UNI_PutX ;
	Sta.UniMsg[NODE_2].Data := Sta.MemData ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;
endruleset;



ruleset NODE_1 : NODE do
rule "n_ABS_NI_Local_GetX_PutX_834_NODE_2"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.ShrSet[NODE_1] &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;
endruleset;


rule "n_ABS_NI_Local_GetX_PutX_834_NODE_1_NODE_2"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd != NODE_Get
 	& 
	forall NODE_1 : NODE do
		Sta.InvMsg[NODE_1].Cmd != INV_Inv
	end&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_2].Proc != Other
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_8_Home_NODE_Get35_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.HomeShrSet &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd = NODE_Get
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.HomeProc.CacheState := CACHE_I ;
	Sta.HomeProc.InvMarked := true;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_8_Home36_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.HomeShrSet &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd != NODE_Get
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_7_NODE_Get37_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr != Other &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd = NODE_Get
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.HomeProc.CacheState := CACHE_I ;
	Sta.HomeProc.InvMarked := true;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_7_NODE_Get38_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HomeHeadPtr = true &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd = NODE_Get
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.HomeProc.CacheState := CACHE_I ;
	Sta.HomeProc.InvMarked := true;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_739_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HeadPtr != Other &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd != NODE_Get
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_740_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd != NODE_Get
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true ;
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	if ((false &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true ;
	Sta.InvMsg[p].Cmd := INV_Inv ;
	else
      Sta.Dir.InvSet[p] := false ;
	Sta.InvMsg[p].Cmd := INV_None ;
	end ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeInvMsg.Cmd := INV_None ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_641_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.HomeShrSet = false &
	Sta.Dir.Local = false
	& forall NODE_2 : NODE do
			false ->
    Sta.Dir.ShrSet[NODE_2] = false
	end
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	Sta.Dir.InvSet[p] := false ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_542_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.HomeShrSet = false &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd != NODE_Get
	& forall NODE_2 : NODE do
			false ->
    Sta.Dir.ShrSet[NODE_2] = false
	end
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	Sta.Dir.InvSet[p] := false ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_443_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadPtr = Other &
	Sta.Dir.HomeHeadPtr = false &
	Sta.Dir.HomeShrSet = false &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd = NODE_Get
	& forall NODE_2 : NODE do
			false ->
    Sta.Dir.ShrSet[NODE_2] = false
	end
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	Sta.Dir.InvSet[p] := false ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeProc.CacheState := CACHE_I ;
	Sta.HomeProc.InvMarked := true;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_344_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld = false &
	Sta.Dir.Local = false
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	Sta.Dir.InvSet[p] := false ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_245_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld = false &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd != NODE_Get
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	Sta.Dir.InvSet[p] := false ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeProc.CacheState := CACHE_I;
endrule;
rule "n_ABS_NI_Local_GetX_PutX_146_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld = false &
	Sta.Dir.Local = true &
	Sta.HomeProc.ProcCmd = NODE_Get
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Local := false ;
	Sta.Dir.Dirty := true ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.Dir.ShrVld := false ;
	for p : NODE do
    Sta.Dir.ShrSet[p] := false ;
	Sta.Dir.InvSet[p] := false ;
	end ;
	Sta.Dir.HomeShrSet := false ;
	Sta.Dir.HomeInvSet := false ;
	Sta.HomeProc.CacheState := CACHE_I ;
	Sta.HomeProc.InvMarked := true;
endrule;
rule "n_ABS_NI_Local_GetX_GetX47_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = true &
	Sta.Dir.Local = false &
	Sta.Dir.HeadPtr != Other
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end
==>
begin
	Sta.Dir.Pending := true;
endrule;
rule "n_ABS_NI_Local_GetX_GetX48_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = true &
	Sta.Dir.Local = false &
	Sta.Dir.HomeHeadPtr = true
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true;
endrule;

-- No abstract rule for rule NI_Local_GetX_Nak49



-- No abstract rule for rule NI_Local_GetX_Nak50



-- No abstract rule for rule NI_Local_GetX_Nak51


rule "n_ABS_NI_Remote_Get_Put_Home52_NODE_1"

	Sta.HomeUniMsg.Cmd = UNI_Get &
	Sta.HomeUniMsg.Proc = Other &
	Sta.HomeUniMsg.HomeProc = false
 	& Sta.Dir.HeadVld = true &
		Sta.Dir.Pending = true &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.ShWbMsg.Cmd = SHWB_FAck &
		Sta.Dir.Dirty = true &
		Sta.Dir.Local = false &
		Sta.Dir.ShrVld = false&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_2].Cmd != UNI_Put &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.ShWbMsg.Proc != NODE_2 &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.Dir.ShrSet[NODE_2] = false &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.Proc[NODE_2].CacheState = CACHE_I &
		Sta.Proc[NODE_2].CacheState != CACHE_S &
		Sta.Proc[NODE_2].InvMarked = false &
		Sta.UniMsg[NODE_2].Proc != Other &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.Dir.HeadPtr = NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.ShWbMsg.Proc = NODE_1 &
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.HomeUniMsg.Cmd := UNI_Put;
endrule;

ruleset NODE_2 : NODE do
rule "n_ABS_NI_Remote_Get_Put53_NODE_1"

	Sta.UniMsg[NODE_2].Cmd = UNI_Get &
	Sta.UniMsg[NODE_2].Proc = Other &
	Sta.UniMsg[NODE_2].HomeProc = false
 	& Sta.Dir.Dirty = false &
		Sta.UniMsg[NODE_2].Cmd != UNI_Put &
		Sta.Dir.HeadVld = false &
		Sta.Dir.HeadVld = true &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.Dir.Pending = true &
		Sta.MemData = Sta.CurrData &
		Sta.ShWbMsg.Proc != NODE_2 &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.Dir.ShrSet[NODE_2] = false &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Proc[NODE_2].CacheState = CACHE_I &
		Sta.Proc[NODE_2].CacheState != CACHE_S &
		Sta.Proc[NODE_2].InvMarked = false &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.ShWbMsg.Cmd = SHWB_FAck &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.Dir.Dirty = true &
		Sta.Dir.Local = false &
		Sta.Dir.ShrVld = false &
		Sta.Dir.HeadPtr = NODE_2&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.ShWbMsg.Proc = NODE_1 &
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.UniMsg[NODE_2].Proc != NODE_1 &
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.UniMsg[NODE_2].Cmd := UNI_Put ;
	Sta.ShWbMsg.Cmd := SHWB_ShWb ;
	Sta.ShWbMsg.Proc := NODE_2 ;
	Sta.ShWbMsg.HomeProc := false;
endrule;
endruleset;



ruleset NODE_1 : NODE do
rule "n_ABS_NI_Remote_Get_Put53_NODE_2"

	Sta.Proc[NODE_1].CacheState = CACHE_E
 	& Sta.Dir.Dirty = false &
		Sta.Proc[NODE_1].InvMarked = false &
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.Dir.HeadVld = false &
		Sta.Dir.HeadVld = true &
		Sta.Dir.InvSet[NODE_1] = false &
		Sta.ShWbMsg.Proc = NODE_1 &
		Sta.Dir.Pending = true &
		Sta.MemData = Sta.CurrData &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.InvMsg[NODE_1].Cmd != INV_InvAck &
		Sta.UniMsg[NODE_1].Cmd != UNI_Put &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Dir.ShrSet[NODE_1] = false &
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.InvMsg[NODE_1].Cmd != INV_Inv &
		Sta.Proc[NODE_1].CacheState != CACHE_S &
		Sta.ShWbMsg.Cmd = SHWB_FAck &
		Sta.Proc[NODE_1].CacheState = CACHE_I &
		Sta.Dir.Dirty = true &
		Sta.Dir.HeadPtr != NODE_1 &
		Sta.Dir.Local = false &
		Sta.UniMsg[NODE_1].Cmd != UNI_PutX &
		Sta.Dir.ShrVld = false &
		Sta.Proc[NODE_1].CacheState != CACHE_E&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_1].Proc != NODE_2 &
		Sta.ShWbMsg.Proc != NODE_2 &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.Dir.HeadPtr = NODE_2
	end
==>
begin
	Sta.Proc[NODE_1].CacheState := CACHE_S ;
	Sta.ShWbMsg.Cmd := SHWB_ShWb ;
	Sta.ShWbMsg.Proc := Other ;
	Sta.ShWbMsg.HomeProc := false ;
	Sta.ShWbMsg.Data := Sta.Proc[NODE_1].CacheData;
endrule;
endruleset;


rule "n_ABS_NI_Remote_Get_Put53_NODE_1_NODE_2"

	Other != Other
 	& Sta.Dir.Dirty = false &
		Sta.Dir.HeadVld = false &
		Sta.Dir.HeadVld = true &
		Sta.Dir.Pending = true &
		Sta.MemData = Sta.CurrData &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.ShWbMsg.Cmd = SHWB_FAck &
		Sta.Dir.Dirty = true &
		Sta.Dir.Local = false &
		Sta.Dir.ShrVld = false&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_2].Cmd != UNI_Put &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.ShWbMsg.Proc != NODE_2 &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.Dir.ShrSet[NODE_2] = false &
		Sta.Proc[NODE_2].CacheState = CACHE_I &
		Sta.Proc[NODE_2].CacheState != CACHE_S &
		Sta.Proc[NODE_2].InvMarked = false &
		Sta.UniMsg[NODE_2].Proc != Other &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.Dir.HeadPtr = NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Proc[NODE_1].InvMarked = false &
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.Dir.InvSet[NODE_1] = false &
		Sta.ShWbMsg.Proc = NODE_1 &
		Sta.UniMsg[NODE_1].Proc != Other &
		Sta.InvMsg[NODE_1].Cmd != INV_InvAck &
		Sta.UniMsg[NODE_1].Cmd != UNI_Put &
		Sta.Dir.ShrSet[NODE_1] = false &
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.InvMsg[NODE_1].Cmd != INV_Inv &
		Sta.Proc[NODE_1].CacheState != CACHE_S &
		Sta.Proc[NODE_1].CacheState = CACHE_I &
		Sta.Dir.HeadPtr != NODE_1 &
		Sta.UniMsg[NODE_1].Cmd != UNI_PutX &
		Sta.Proc[NODE_1].CacheState != CACHE_E
	end
==>
begin
	Sta.ShWbMsg.Cmd := SHWB_ShWb ;
	Sta.ShWbMsg.Proc := Other ;
	Sta.ShWbMsg.HomeProc := false;
endrule;
rule "n_ABS_NI_Remote_Get_Nak_Home54_NODE_1"

	Sta.HomeUniMsg.Cmd = UNI_Get &
	Sta.HomeUniMsg.Proc = Other &
	Sta.HomeUniMsg.HomeProc = false
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.HomeUniMsg.Cmd := UNI_Nak ;
	Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;

ruleset NODE_2 : NODE do
rule "n_ABS_NI_Remote_Get_Nak55_NODE_1"

	Sta.UniMsg[NODE_2].Cmd = UNI_Get &
	Sta.UniMsg[NODE_2].Proc = Other &
	Sta.UniMsg[NODE_2].HomeProc = false
 	& Sta.Dir.Local = false &
		Sta.Dir.Dirty = false &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Dir.Pending = true &
		Sta.Dir.ShrVld = false &
		Sta.MemData = Sta.CurrData &
		Sta.Dir.HeadVld = false &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.WbMsg.Cmd != WB_Wb&
	forall NODE_1 : NODE do
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.UniMsg[NODE_2].Cmd := UNI_Nak ;
	Sta.UniMsg[NODE_2].Proc := Other ;
	Sta.UniMsg[NODE_2].HomeProc := false ;
	Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
endruleset;



ruleset NODE_1 : NODE do
rule "n_ABS_NI_Remote_Get_Nak55_NODE_2"

	Sta.Proc[NODE_1].CacheState != CACHE_E
 	& Sta.Dir.Dirty = false &
		Sta.Proc[NODE_1].InvMarked = false &
		Sta.Dir.HeadVld = false &
		Sta.Dir.InvSet[NODE_1] = false &
		Sta.Dir.Pending = true &
		Sta.MemData = Sta.CurrData &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.InvMsg[NODE_1].Cmd != INV_InvAck &
		Sta.UniMsg[NODE_1].Cmd != UNI_Put &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Dir.ShrSet[NODE_1] = false &
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.InvMsg[NODE_1].Cmd != INV_Inv &
		Sta.Proc[NODE_1].CacheState != CACHE_S &
		Sta.Proc[NODE_1].CacheState = CACHE_I &
		Sta.Dir.HeadPtr != NODE_1 &
		Sta.Dir.Local = false &
		Sta.UniMsg[NODE_1].Cmd != UNI_PutX &
		Sta.Dir.ShrVld = false&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_1].Proc != NODE_2 &
		Sta.Dir.HeadPtr != NODE_2
	end
==>
begin
	Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
endruleset;


rule "n_ABS_NI_Remote_Get_Nak55_NODE_1_NODE_2"

	Other != Other
 	& Sta.Dir.Dirty = false &
		Sta.Dir.HeadVld = false &
		Sta.Dir.Pending = true &
		Sta.MemData = Sta.CurrData &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.Dir.Local = false &
		Sta.Dir.ShrVld = false&
	forall NODE_1 : NODE do
		Sta.Proc[NODE_1].InvMarked = false &
		Sta.Dir.InvSet[NODE_1] = false &
		Sta.UniMsg[NODE_1].Proc != Other &
		Sta.InvMsg[NODE_1].Cmd != INV_InvAck &
		Sta.UniMsg[NODE_1].Cmd != UNI_Put &
		Sta.Dir.ShrSet[NODE_1] = false &
		Sta.ShWbMsg.Proc != NODE_1 &
		Sta.InvMsg[NODE_1].Cmd != INV_Inv &
		Sta.Proc[NODE_1].CacheState != CACHE_S &
		Sta.Proc[NODE_1].CacheState = CACHE_I &
		Sta.Dir.HeadPtr != NODE_1 &
		Sta.UniMsg[NODE_1].Cmd != UNI_PutX
	end&
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end
==>
begin
	Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
rule "n_ABS_NI_Local_Get_Put_Dirty56_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = true &
	Sta.Dir.Local = true &
	Sta.HomeProc.CacheState = CACHE_E
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Dirty := false ;
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false ;
	Sta.MemData := Sta.HomeProc.CacheData ;
	Sta.HomeProc.CacheState := CACHE_S;
endrule;
rule "n_ABS_NI_Local_Get_Put57_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld = false
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.HeadVld := true ;
	Sta.Dir.HeadPtr := Other ;
	Sta.Dir.HomeHeadPtr := false;
endrule;
rule "n_ABS_NI_Local_Get_Put_Head58_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = false &
	Sta.Dir.HeadVld
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.ShrVld := true ;
	for p : NODE do
    if (false) then
      Sta.Dir.InvSet[p] := true ;
	else
      Sta.Dir.InvSet[p] := Sta.Dir.ShrSet[p] ;
	end ;
	end ;
	Sta.Dir.HomeInvSet := Sta.Dir.HomeShrSet;
endrule;
rule "n_ABS_NI_Local_Get_Get59_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = true &
	Sta.Dir.Local = false &
	Sta.Dir.HeadPtr != Other
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end
==>
begin
	Sta.Dir.Pending := true;
endrule;
rule "n_ABS_NI_Local_Get_Get60_NODE_1"

	Sta.Dir.Pending = false &
	Sta.Dir.Dirty = true &
	Sta.Dir.Local = false &
	Sta.Dir.HomeHeadPtr = true
 	& 
	forall NODE_2 : NODE do
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.Dir.Pending := true;
endrule;

-- No abstract rule for rule NI_Local_Get_Nak61



-- No abstract rule for rule NI_Local_Get_Nak62



-- No abstract rule for rule NI_Local_Get_Nak63



-- No abstract rule for rule NI_Nak66



-- No abstract rule for rule PI_Remote_Replace68


rule "n_ABS_PI_Remote_PutX71_NODE_1"
Sta.Dir.HeadVld = true &
		Sta.Dir.Pending = true &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.ShWbMsg.Cmd = SHWB_FAck &
		Sta.Dir.Dirty = true &
		Sta.Dir.Local = false &
		Sta.Dir.ShrVld = false&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_2].Cmd != UNI_Put &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.ShWbMsg.Proc != NODE_2 &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.Dir.ShrSet[NODE_2] = false &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.Proc[NODE_2].CacheState = CACHE_I &
		Sta.Proc[NODE_2].CacheState != CACHE_S &
		Sta.Proc[NODE_2].InvMarked = false &
		Sta.UniMsg[NODE_2].Proc != Other &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.Dir.HeadPtr = NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.ShWbMsg.Proc = NODE_1 &
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.WbMsg.Cmd := WB_Wb ;
	Sta.WbMsg.Proc := Other ;
	Sta.WbMsg.HomeProc := false;
endrule;

-- No abstract rule for rule PI_Remote_GetX80



-- No abstract rule for rule PI_Remote_Get84



ruleset DATA_1 : DATA do
rule "n_ABS_Store86_NODE_1"
Sta.Dir.HeadVld = true &
		Sta.Dir.Pending = true &
		Sta.ShWbMsg.Cmd != SHWB_ShWb &
		Sta.NakcMsg.Cmd != NAKC_Nakc &
		Sta.WbMsg.Cmd != WB_Wb &
		Sta.ShWbMsg.Cmd != SHWB_FAck &
		Sta.ShWbMsg.Cmd = SHWB_FAck &
		Sta.Dir.Dirty = true &
		Sta.Dir.Local = false &
		Sta.Dir.ShrVld = false&
	forall NODE_2 : NODE do
		Sta.UniMsg[NODE_2].Cmd != UNI_Put &
		Sta.InvMsg[NODE_2].Cmd != INV_Inv &
		Sta.ShWbMsg.Proc != NODE_2 &
		Sta.Proc[NODE_2].CacheState != CACHE_E &
		Sta.Dir.ShrSet[NODE_2] = false &
		Sta.InvMsg[NODE_2].Cmd != INV_InvAck &
		Sta.Dir.HeadPtr != NODE_2 &
		Sta.Proc[NODE_2].CacheState = CACHE_I &
		Sta.Proc[NODE_2].CacheState != CACHE_S &
		Sta.Proc[NODE_2].InvMarked = false &
		Sta.UniMsg[NODE_2].Proc != Other &
		Sta.Dir.InvSet[NODE_2] = false &
		Sta.UniMsg[NODE_2].Cmd != UNI_PutX &
		Sta.Dir.HeadPtr = NODE_2
	end&
	forall NODE_1 : NODE do
		Sta.Dir.HeadPtr = NODE_1 &
		Sta.ShWbMsg.Proc = NODE_1 &
		Sta.Dir.HeadPtr != NODE_1
	end
==>
begin
	Sta.CurrData := DATA_1;
endrule;
endruleset;



ruleset i : NODE do
Invariant "rule_1"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.HeadPtr = i);
endruleset;
