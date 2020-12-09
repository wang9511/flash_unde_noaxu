
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


ruleset i : NODE do
Invariant "rule_1"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_5"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_6"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_8"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_9"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_10"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_12"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_13"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_14"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_16"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_17"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_19"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_20"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_21"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_23"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_24"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_25"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_28"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_29"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_30"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_31"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_33"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_34"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_35"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_36"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_39"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_40"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_41"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_42"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_44"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_45"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_46"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_47"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_49"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_50"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_51"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_52"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_53"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_54"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_55"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_56"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_58"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_59"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_60"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_61"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_62"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_63"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_64"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_66"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_67"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_68"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_69"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_70"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_71"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_72"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_73"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_75"
	(Sta.Dir.Local = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_76"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_77"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_78"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_79"
	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_81"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_82"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_84"
	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_85"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_86"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_87"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_88"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_89"
	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_90"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_92"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_93"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_94"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_95"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_98"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_99"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_100"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_101"
	(Sta.Dir.InvSet[j] = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_103"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_105"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_106"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_108"
	(Sta.Dir.ShrVld = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_109"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_110"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_111"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_113"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_114"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_115"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_116"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_120"
	(Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_121"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.Pending = false);
endruleset;


ruleset j : NODE do
Invariant "rule_122"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_124"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.InvSet[j] = true);
endruleset;


ruleset j : NODE do
Invariant "rule_125"
	(Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_126"
	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_127"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_128"
	(Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_130"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_131"
	(Sta.Dir.ShrSet[j] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_132"
	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_133"
	(Sta.Dir.ShrSet[j] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_135"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_136"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_137"
	(Sta.Dir.ShrSet[j] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_138"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_140"
	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_141"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_142"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_144"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_145"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_147"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_148"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_149"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_150"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_153"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_154"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_156"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_157"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_159"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_160"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_161"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_162"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_166"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_168"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_170"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_174"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_175"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_177"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;
Invariant "rule_199"
	(Sta.Dir.Pending = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
Invariant "rule_200"
	(Sta.Dir.Local = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset j : NODE do
Invariant "rule_201"
	(Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_203"
	(Sta.Dir.InvSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_205"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_208"
	(Sta.Proc[i].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_209"
	(Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;
Invariant "rule_212"
	(Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
Invariant "rule_215"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset i : NODE do
Invariant "rule_216"
	(Sta.Dir.ShrSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_217"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_218"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_219"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_220"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_224"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;
Invariant "rule_225"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
Invariant "rule_227"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Pending = true);
Invariant "rule_228"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Local = false);


ruleset j : NODE do
Invariant "rule_229"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_231"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_232"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_233"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_236"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_237"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].InvMarked = false);
endruleset;
Invariant "rule_238"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrVld = false);
Invariant "rule_241"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_242"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_243"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_244"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_245"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_246"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_248"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_249"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_252"
	(Sta.Dir.Pending = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;
Invariant "rule_253"
	(Sta.Dir.Pending = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
Invariant "rule_255"
	(Sta.Dir.ShrVld = true -> Sta.Dir.Pending = false);
Invariant "rule_257"
	(Sta.Dir.Pending = false -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_258"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE do
Invariant "rule_259"
	(Sta.Dir.Pending = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_260"
	(Sta.Dir.Pending = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_261"
	(Sta.Dir.Pending = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;
Invariant "rule_265"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Pending = true);
Invariant "rule_267"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrVld = false);
Invariant "rule_269"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.Pending = true);


ruleset i : NODE do
Invariant "rule_270"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_271"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_272"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE do
Invariant "rule_274"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_275"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_276"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_279"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_280"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_283"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_284"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_285"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_286"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_289"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_291"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_292"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_293"
	(Sta.Dir.Local = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_294"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.Local = false);
endruleset;
Invariant "rule_295"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Local = false);


ruleset j : NODE do
Invariant "rule_297"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.Local = false);
endruleset;
Invariant "rule_298"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.Local = false);


ruleset i : NODE do
Invariant "rule_299"
	(Sta.Dir.Local = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_300"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.Local = false);


ruleset i : NODE do
Invariant "rule_301"
	(Sta.Dir.Local = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_302"
	(Sta.Dir.Local = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_303"
	(Sta.Dir.Local = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_305"
	(Sta.Dir.Local = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;
Invariant "rule_306"
	(Sta.Dir.Local = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_308"
	(Sta.Dir.Local = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_309"
	(Sta.Dir.Local = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_310"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.Local = true);
endruleset;
Invariant "rule_311"
	(Sta.Dir.Local = true -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_312"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.Local = true);
endruleset;


ruleset j : NODE do
Invariant "rule_314"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_315"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_318"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_319"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_320"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_321"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_322"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_324"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_325"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_326"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_329"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_330"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_331"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_332"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_333"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_335"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_337"
	(Sta.Dir.HeadVld = false -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_339"
	(Sta.Dir.HeadVld = false -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;
Invariant "rule_340"
	(Sta.Dir.HeadVld = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
Invariant "rule_342"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_343"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_344"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_346"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadVld = false);
endruleset;
Invariant "rule_347"
	(Sta.Dir.HeadVld = false -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_348"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_351"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_352"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_353"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.HeadVld = true);
endruleset;
Invariant "rule_354"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.HeadVld = true);
Invariant "rule_356"
	(Sta.Dir.ShrVld = true -> Sta.Dir.HeadVld = true);


ruleset j : NODE do
Invariant "rule_357"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_358"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_360"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_361"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.HeadVld = true);


ruleset i : NODE do
Invariant "rule_362"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_363"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_364"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_365"
	(Sta.Dir.InvSet[j] = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_366"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_367"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_371"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_372"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_375"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_376"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_377"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_380"
	(Sta.Dir.InvSet[j] = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_381"
	(Sta.Dir.InvSet[j] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_383"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_384"
	(Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_388"
	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_389"
	(Sta.Dir.InvSet[j] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_392"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_393"
	(Sta.Dir.InvSet[j] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_394"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_414"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_416"
	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_417"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_418"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_419"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_422"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_424"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_425"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_426"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_427"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_429"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_430"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_431"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_434"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_435"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_436"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_437"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_442"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_443"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_446"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_447"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_450"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_453"
	(Sta.Dir.ShrVld = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_454"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_455"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_457"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_459"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_462"
	(Sta.Dir.Dirty = false -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_463"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_465"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_466"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_467"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_468"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_469"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_471"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_476"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_477"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_479"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_480"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_483"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_484"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_485"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_486"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_488"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_490"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_493"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_494"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_496"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_497"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_498"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_499"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_500"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_502"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_505"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_506"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_507"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_508"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_509"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_510"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_511"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_516"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_517"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_518"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_519"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_520"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_521"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_522"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_525"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_530"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_533"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_534"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_536"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_537"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_538"
	(Sta.Dir.InvSet[i] = false -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_540"
	(Sta.Dir.InvSet[i] = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_541"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_542"
	(Sta.Dir.InvSet[i] = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_545"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_546"
	(Sta.Dir.InvSet[i] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_547"
	(Sta.Dir.InvSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_549"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_550"
	(Sta.Dir.InvSet[i] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_551"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_553"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_554"
	(Sta.Dir.InvSet[i] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_555"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_557"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_559"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_561"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_562"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_563"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_566"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_568"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_569"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_570"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_575"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_577"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_578"
	(Sta.Dir.HeadPtr != j -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_587"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_591"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_601"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_603"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_606"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_611"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_615"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_627"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_638"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_642"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_643"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_644"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_646"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_648"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_652"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_653"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_654"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_656"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_658"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_660"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_661"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_662"
	(Sta.Dir.ShrVld = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_663"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_664"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_665"
	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_667"
	(Sta.Dir.Dirty = false -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_668"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_669"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_670"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_671"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_672"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_674"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_676"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_677"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_678"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_679"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_680"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_681"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_683"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_684"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_685"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_686"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_687"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_688"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_689"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;
Invariant "rule_693"
	(Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_694"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_695"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_696"
	(Sta.Dir.ShrSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_698"
	(Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_699"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_701"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_702"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_706"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
Invariant "rule_709"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_710"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_711"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_712"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrSet[i] = false);
endruleset;
Invariant "rule_714"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Dirty = true);


ruleset i : NODE do
Invariant "rule_715"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_717"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_718"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_720"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;
Invariant "rule_721"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.ShWbMsg.Data = Sta.CurrData);


ruleset i : NODE ; j : NODE do
Invariant "rule_751"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_767"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_774"
	(Sta.Dir.HeadPtr != j -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_780"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_783"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_784"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_786"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_790"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_791"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_793"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_796"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_797"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_798"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_799"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_802"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_803"
	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_804"
	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_805"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_807"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_809"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_817"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_818"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_819"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_820"
	(Sta.Dir.ShrVld = false -> Sta.Dir.ShrSet[i] = false);
endruleset;
Invariant "rule_822"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_823"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_824"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_825"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_828"
	(Sta.Dir.ShrVld = true -> Sta.MemData = Sta.CurrData);


ruleset j : NODE do
Invariant "rule_829"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_830"
	(Sta.Dir.ShrVld = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_831"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.ShrVld = true);
endruleset;
Invariant "rule_833"
	(Sta.Dir.ShrVld = true -> Sta.Dir.Dirty = false);


ruleset i : NODE do
Invariant "rule_834"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_835"
	(Sta.Dir.ShrVld = true -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_836"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_838"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_839"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;
Invariant "rule_840"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.Dirty = true);


ruleset i : NODE do
Invariant "rule_842"
	(Sta.Dir.ShrSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;
Invariant "rule_843"
	(Sta.Dir.Dirty = false -> Sta.MemData = Sta.CurrData);


ruleset i : NODE ; j : NODE do
Invariant "rule_847"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_850"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_851"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_853"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_854"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_855"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_857"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_859"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_864"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_867"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_868"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_870"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_871"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_872"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_874"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_875"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_876"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_877"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_880"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_882"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_883"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_884"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_886"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_887"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_889"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_890"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_892"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_893"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_895"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_897"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_899"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_900"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_903"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_904"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_906"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_907"
	(Sta.Dir.ShrSet[i] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_908"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_909"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_911"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_912"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_913"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_914"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_916"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_917"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_918"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_920"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_924"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_925"
	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_926"
	(Sta.Dir.ShrSet[i] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_928"
	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_930"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_931"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_933"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_934"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_936"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_938"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_939"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_941"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_943"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_944"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_945"
	(Sta.Dir.HeadPtr != i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_947"
	(Sta.Dir.HeadPtr != i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;
Invariant "rule_949"
	(Sta.Dir.Dirty = false -> Sta.WbMsg.Cmd != WB_Wb);
Invariant "rule_951"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.Dirty = true);


ruleset i : NODE do
Invariant "rule_953"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_954"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_956"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_957"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_958"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_961"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;
Invariant "rule_963"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_965"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;
Invariant "rule_967"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.WbMsg.Data = Sta.CurrData);


ruleset j : NODE do
Invariant "rule_968"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_969"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_972"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_973"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_975"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_976"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_983"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_985"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_986"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_988"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_989"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_993"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_999"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1005"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1006"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1008"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1009"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1010"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1011"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1024"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd != UNI_Get -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1027"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1034"
	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1037"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1038"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1039"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1043"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1044"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_1046"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1047"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1048"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1049"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1065"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Cmd != UNI_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1066"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd = UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1069"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1073"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1074"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1075"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1076"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1077"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1078"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1079"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1081"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1082"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1083"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1085"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1087"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1088"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1089"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd = UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1090"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1092"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1093"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1094"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1095"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1096"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1097"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1099"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1100"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1102"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1106"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1112"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1114"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1115"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1116"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1117"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1119"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1121"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd != UNI_Get -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1122"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1124"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1125"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1126"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1127"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1128"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1129"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1130"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1132"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1134"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_1135"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1141"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1146"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1147"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1150"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1151"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1153"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1154"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1155"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_1156"
	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1158"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1161"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1162"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1164"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1165"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1166"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1168"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1169"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1171"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_1172"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1173"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1178"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1179"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1181"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1182"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1184"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1190"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1191"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1193"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1194"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1196"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1197"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1199"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1200"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1207"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1208"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1209"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1210"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1211"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1213"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1215"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1216"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = j -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1217"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Proc = j -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1220"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1221"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1223"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1224"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1225"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1226"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1227"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1228"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1230"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1231"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1232"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1233"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1234"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1236"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1237"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1240"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1247"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1250"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1251"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1262"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1263"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1265"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1267"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1268"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1270"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1272"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1275"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1277"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1286"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1287"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1288"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1289"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1290"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1292"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1293"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1294"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1295"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_1297"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1298"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_1299"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1300"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.ShWbMsg.Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1301"
	(Sta.Dir.ShrSet[j] = true & Sta.ShWbMsg.Proc = j -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1304"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1305"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1306"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1307"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1308"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1309"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1310"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1311"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1312"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1313"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1315"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1316"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1317"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1318"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1319"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1320"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1322"
	(Sta.Dir.ShrSet[j] = true & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1323"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1324"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1325"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1326"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1327"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1329"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1330"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1331"
	(Sta.Dir.ShrSet[j] = true & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1332"
	(Sta.Dir.ShrSet[j] = true & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1335"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1338"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1347"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1350"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1353"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1354"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1355"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1356"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_1357"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1369"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1370"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1372"
	(Sta.Dir.ShrSet[j] = true & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1374"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1375"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1377"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1379"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1380"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1383"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_1384"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_1385"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1389"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1390"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1392"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1393"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1395"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1396"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1397"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1410"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1420"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1421"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1423"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1424"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1426"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1427"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1429"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1443"
	(Sta.Proc[i].ProcCmd != NODE_None & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1446"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1447"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1448"
	(Sta.Dir.Local = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1449"
	(Sta.Dir.Local = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1450"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.HeadVld = false -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1451"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.HeadVld = false -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1455"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1456"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1459"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1460"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1465"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1466"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1469"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1470"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1471"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1472"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1473"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_1474"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1475"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1476"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1477"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1479"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1480"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1481"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1482"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_1485"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_1486"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1487"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_1488"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_1489"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].InvMarked = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1490"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1492"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].InvMarked = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1493"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1495"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1498"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1499"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1500"
	(Sta.Dir.ShrVld = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1501"
	(Sta.Dir.ShrVld = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1502"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.MemData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1503"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.MemData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1504"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1505"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1506"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1508"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1509"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1510"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1511"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1512"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1514"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1515"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1516"
	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1517"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1518"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1519"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1521"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1523"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1524"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1525"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1526"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1530"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1531"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1594"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1595"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1601"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1602"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1605"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1607"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1608"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1609"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Dir.HeadVld = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1610"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.HeadVld = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1612"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.HeadVld = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1613"
		(j != i) ->	(Sta.ShWbMsg.Proc != j & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1614"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1615"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1617"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1618"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1619"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1620"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1621"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1622"
		(j != i) ->	(Sta.Dir.Dirty = false & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1623"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1624"
		(j != i) ->	(Sta.WbMsg.Cmd = WB_Wb & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1625"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1627"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1628"
	(Sta.Proc[j].CacheState != CACHE_E & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1629"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1630"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1631"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1632"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1633"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1637"
	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1638"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1641"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1644"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1646"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1647"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1649"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1650"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1652"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1653"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1655"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1657"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1660"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1661"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1664"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1665"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1666"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_1668"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1669"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1670"
	(Sta.Dir.HeadVld = false & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1671"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1672"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1673"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1675"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1676"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.ShWbMsg.Proc != j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1677"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.ShWbMsg.Proc != j -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1678"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_1679"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_1680"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_1682"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1683"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1684"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1685"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1686"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1687"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1688"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1689"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1690"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1692"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1693"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1694"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1695"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1696"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1697"
		(i != j) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Dir.HeadPtr != i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1698"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Dir.Dirty = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1699"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1700"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1701"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1702"
		(i != j) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Dir.HeadPtr != i -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1703"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Dir.Dirty = false -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1704"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1705"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1706"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1707"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_1708"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1709"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1710"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_1711"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1716"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1717"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1720"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1723"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1725"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_1726"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1728"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1729"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1731"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1732"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_1734"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_1737"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1739"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1740"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.Pending = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1741"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1742"
	(Sta.Dir.HeadVld = false & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1743"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = false -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1744"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = true -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1747"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Pending = false -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1748"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Dir.Pending = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1749"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1750"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1762"
	(Sta.Dir.Pending = false & Sta.Dir.ShrVld = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1763"
	(Sta.Dir.Pending = false & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1764"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1765"
	(Sta.Dir.Dirty = true & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1768"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = false -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1769"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = false -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1770"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = false -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1771"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = false -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1773"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Pending = false -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1774"
		(i != j) ->	(Sta.Dir.Pending = false & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1787"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1788"
	(Sta.Dir.Local = false & Sta.Dir.Pending = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1789"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1790"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = false -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1791"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1794"
	(Sta.Dir.Pending = true & Sta.Dir.HeadVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1797"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1798"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1808"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = false -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1809"
	(Sta.Dir.InvSet[i] = true & Sta.MemData != Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1810"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1811"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Dirty = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1813"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1823"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1824"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1826"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1828"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1829"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1830"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1831"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1832"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1833"
		(j != i) ->	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1834"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1835"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1836"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1837"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1838"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1839"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1840"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd != UNI_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1841"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1843"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1844"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1849"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1852"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1853"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1854"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1856"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1858"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1860"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1861"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1862"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1863"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1864"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1865"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1866"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1867"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1868"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1869"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1870"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1871"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1872"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1873"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1874"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1875"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1876"
		(j != i) ->	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1877"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1878"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1879"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1880"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1881"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1882"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1884"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1885"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_1886"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_1888"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1892"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1895"
	(Sta.Dir.Local = false & Sta.Dir.HeadVld = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1896"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1898"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1899"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1900"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1903"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1904"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1907"
	(Sta.Dir.Local = false & Sta.Dir.ShrVld = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1908"
	(Sta.Dir.Local = false & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1909"
	(Sta.Dir.Local = false & Sta.Dir.ShrSet[i] = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1910"
	(Sta.Dir.Local = false & Sta.Dir.Dirty = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1913"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1914"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1915"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1916"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1918"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1929"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1930"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1931"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1940"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = false -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1943"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1944"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Dir.Local = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1945"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1946"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1947"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1948"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1950"
	(Sta.Dir.Local = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1953"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = false -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1954"
	(Sta.Dir.InvSet[i] = true & Sta.MemData != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1955"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1956"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Dirty = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1958"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1959"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1965"
		(i != j) ->	(Sta.Dir.Local = true & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1966"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1967"
	(Sta.Dir.Local = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1974"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1976"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1977"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1978"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1979"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.ShWbMsg.Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1980"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1981"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1982"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1983"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1984"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1985"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1986"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.ShWbMsg.Proc != i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1987"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1988"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1989"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_1992"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_1994"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2002"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2004"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2006"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2007"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = j -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2008"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2009"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2010"
		(i != j) ->	(Sta.ShWbMsg.Proc != i & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2011"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2012"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_None -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2014"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2016"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2020"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2025"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2030"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2031"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2033"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.HeadVld = false -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2036"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = false -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2037"
	(Sta.Dir.InvSet[i] = true & Sta.MemData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2038"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2039"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Dirty = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2066"
		(i != j) ->	(Sta.Dir.HeadVld = false & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2067"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = false -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2070"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.HeadVld = false -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2084"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2087"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2088"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2091"
	(Sta.Dir.HeadVld = true & Sta.Dir.ShrVld = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2092"
	(Sta.Dir.HeadVld = true & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2093"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.HeadVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2094"
	(Sta.Dir.Dirty = true & Sta.Dir.HeadVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2097"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2098"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2099"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2100"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2139"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2144"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2149"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2162"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = j -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2166"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2167"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2169"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2170"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2171"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2172"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2173"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2174"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2178"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2182"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2186"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2209"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2213"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2214"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2216"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2218"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2223"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2226"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2228"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.ShWbMsg.Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2232"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2233"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2234"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2235"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2236"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2237"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2238"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2239"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2240"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2241"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2243"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2244"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2245"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2246"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2247"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2248"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2257"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2263"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[j] = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2266"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.InvSet[j] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2298"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2303"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2305"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2307"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2312"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2344"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2346"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2347"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2349"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2351"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2352"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2354"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2364"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2367"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2371"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2376"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2381"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2383"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2384"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2385"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2387"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2389"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2390"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2391"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2400"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2402"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2405"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2406"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2411"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2412"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2417"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2418"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2419"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2420"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2421"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2422"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2424"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2425"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2426"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2428"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2429"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2432"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2433"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2434"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2435"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2436"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2437"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2438"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2439"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2440"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2441"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2442"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2443"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2444"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2445"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2447"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2448"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2449"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2450"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2451"
		(j != i) ->	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2452"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2453"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2454"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2455"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2456"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2457"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2458"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2459"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2460"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2461"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2464"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2465"
		(j != i) ->	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2468"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2469"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2470"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2471"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2472"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2473"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2474"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2475"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2476"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2477"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2478"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2479"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2482"
		(j != i) ->	(Sta.Dir.Dirty = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2483"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2484"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2485"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2486"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2487"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2493"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2494"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2498"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2501"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2502"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2503"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2504"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2506"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2508"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2509"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2510"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2511"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2513"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2514"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2515"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc != i -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2516"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2517"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2518"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2519"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2520"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc != i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2521"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2522"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2523"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2524"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2525"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2526"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2529"
		(j != i) ->	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2531"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2532"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2533"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2534"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2535"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2536"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2538"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Dirty = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2539"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2540"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2547"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2551"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2555"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].CacheState = CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2562"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2563"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2566"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2571"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2579"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2580"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2586"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2587"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState != CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2589"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2590"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2596"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_2597"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2598"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2599"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2604"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2611"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2613"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2615"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2616"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2617"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2619"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_2622"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2625"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2629"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2632"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2633"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2636"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2639"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2641"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2646"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2648"
	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2649"
	(Sta.UniMsg[j].Cmd = UNI_PutX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2651"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2652"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2655"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2660"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2663"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2667"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2668"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2670"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2671"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2673"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.WbMsg.Cmd = WB_Wb -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2674"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2675"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2677"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2678"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2682"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2683"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2689"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2693"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_2694"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2697"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2699"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2702"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2704"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2705"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2709"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2712"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_2714"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_2715"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2716"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2718"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2720"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2725"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_2726"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2729"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2734"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2735"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2737"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2738"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2739"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2741"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_2742"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2744"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2745"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2748"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2749"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2750"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2752"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2755"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2756"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2761"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.ShrVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2763"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2764"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2767"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2771"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2772"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2777"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2779"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2781"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2782"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2783"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd != UNI_Get -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2785"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd != UNI_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2786"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2787"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2789"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2791"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2792"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2794"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2802"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2805"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2809"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2810"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2815"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2816"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2818"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2820"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd = UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2821"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2822"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2823"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2825"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2827"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2828"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2829"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2837"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2839"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2842"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2843"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2848"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2849"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2850"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2851"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2856"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2857"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2859"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.Proc[i].InvMarked = false -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2860"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2862"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.Proc[i].InvMarked = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2863"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2871"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2875"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2880"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2881"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2888"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[i].InvMarked = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2890"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].InvMarked = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2891"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2892"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2893"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2898"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadPtr = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2902"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2907"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2908"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2910"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2911"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2912"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2913"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2919"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2922"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2923"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2924"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2926"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2928"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2929"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2931"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2932"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2934"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2936"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2939"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2940"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2941"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2942"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2943"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2944"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2945"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2946"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2948"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2950"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2951"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2952"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2954"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2956"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2958"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2959"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2962"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2963"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2964"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2965"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2971"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Dir.HeadPtr = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2975"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2980"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2981"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2983"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2984"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2985"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2986"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2989"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].InvMarked = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2990"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_3000"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.HeadPtr = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3004"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3009"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.Proc[i].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_3010"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].InvMarked = true -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3012"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3013"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].InvMarked = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3014"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3015"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3017"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3018"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3019"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3020"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3021"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].InvMarked = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3022"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_3023"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3024"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3026"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3027"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3028"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3030"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3034"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3035"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3036"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3037"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3038"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3039"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3041"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3051"
	(Sta.Proc[i].CacheState = CACHE_I & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3052"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3054"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3055"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_3058"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3059"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3060"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3061"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3062"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3063"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3067"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3069"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3070"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3071"
	(Sta.Dir.HeadPtr = i & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3072"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3076"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3077"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3078"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3079"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_3080"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3081"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3082"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3084"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3139"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3140"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3142"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3151"
	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3154"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3155"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_3157"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3160"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_3161"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3164"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_3167"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3168"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3169"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState != CACHE_I -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3171"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3172"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3176"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3177"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3178"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3180"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3181"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3182"
	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3183"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3184"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3185"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_3188"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3192"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3195"
	(Sta.Proc[i].CacheState = CACHE_S & Sta.Dir.HeadPtr = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_3199"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3200"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3205"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3210"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3213"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_3214"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Dir.HeadPtr = i -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_3218"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3219"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3224"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_3225"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3227"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3228"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3229"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3234"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3235"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3238"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3239"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_3240"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3241"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3244"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_3245"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3246"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3250"
		(i != j) ->	(Sta.Dir.Dirty = false & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3251"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3252"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3253"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3255"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3257"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3258"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3259"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3260"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3261"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3263"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3264"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3266"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3267"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Dirty = false -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3268"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3270"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3272"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3273"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3274"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3276"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3277"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3279"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3280"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3281"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3284"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3291"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_3292"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3298"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3304"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;
