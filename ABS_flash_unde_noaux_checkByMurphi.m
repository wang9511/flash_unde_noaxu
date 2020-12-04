
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


ruleset j : NODE do
Invariant "rule_1"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.Local = false);
endruleset;
Invariant "rule_2"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.Local = false);
Invariant "rule_3"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Local = false);


ruleset i : NODE do
Invariant "rule_4"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_5"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.Local = false);
endruleset;
Invariant "rule_6"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.Local = false);


ruleset j : NODE do
Invariant "rule_7"
	(Sta.Dir.Local = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_9"
	(Sta.Dir.Local = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_10"
	(Sta.Dir.Local = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_11"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Local = false);


ruleset j : NODE do
Invariant "rule_12"
	(Sta.Dir.Local = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_13"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_14"
	(Sta.Dir.Local = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_15"
	(Sta.Dir.Local = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
Invariant "rule_16"
	(Sta.Dir.Local = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset i : NODE do
Invariant "rule_17"
	(Sta.Dir.Local = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_18"
	(Sta.Dir.Local = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;
Invariant "rule_19"
	(Sta.Dir.Local = true -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_22"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_23"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.Local = true);
endruleset;
Invariant "rule_24"
	(Sta.Dir.Local = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_26"
	(Sta.Dir.Local = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_27"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_28"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_29"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_30"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_31"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_34"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_36"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_37"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_38"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_39"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_40"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_42"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_45"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_48"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_51"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_52"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_53"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_54"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_55"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_56"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_58"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_60"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_61"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_64"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_65"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_66"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_67"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_68"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_70"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_71"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_73"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_75"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_77"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_78"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_80"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_82"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_84"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_87"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_88"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_89"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_90"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_91"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_92"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_94"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_96"
	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_97"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_100"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_101"
	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_104"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_105"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_106"
	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_108"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_111"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_113"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_115"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_116"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_124"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_126"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_129"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_139"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_140"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_141"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_145"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_148"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_158"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_159"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_160"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Proc != j);
endruleset;
Invariant "rule_163"
	(Sta.Dir.Dirty = false -> Sta.MemData = Sta.CurrData);
Invariant "rule_164"
	(Sta.Dir.ShrVld = true -> Sta.MemData = Sta.CurrData);


ruleset j : NODE do
Invariant "rule_165"
	(Sta.Dir.ShrSet[j] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_166"
	(Sta.Dir.ShrSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;
Invariant "rule_171"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.Dirty = true);
Invariant "rule_172"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_173"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_174"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_179"
	(Sta.Dir.Dirty = false -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_180"
	(Sta.Dir.Dirty = false -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;
Invariant "rule_181"
	(Sta.Dir.Dirty = false -> Sta.WbMsg.Cmd != WB_Wb);
Invariant "rule_182"
	(Sta.Dir.ShrVld = true -> Sta.Dir.Dirty = false);


ruleset j : NODE do
Invariant "rule_183"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_184"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.Dirty = false);
endruleset;
Invariant "rule_188"
	(Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_190"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_191"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_192"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.Dirty = true);
endruleset;
Invariant "rule_193"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.Dirty = true);
Invariant "rule_194"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_195"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_196"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrSet[i] = false);
endruleset;
Invariant "rule_200"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Dirty = true);


ruleset i : NODE do
Invariant "rule_202"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.Dirty = true);
endruleset;
Invariant "rule_203"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset i : NODE do
Invariant "rule_205"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.InvSet[i] = false);
endruleset;
Invariant "rule_206"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_207"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_208"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_209"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.InvSet[j] = false);
endruleset;
Invariant "rule_210"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.Pending = true);


ruleset j : NODE do
Invariant "rule_211"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_213"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_214"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_215"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_216"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;
Invariant "rule_217"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_219"
	(Sta.Dir.InvSet[i] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;
Invariant "rule_220"
	(Sta.Dir.ShrVld = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset j : NODE do
Invariant "rule_221"
	(Sta.Dir.ShrSet[j] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_222"
	(Sta.Dir.ShrSet[i] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_223"
	(Sta.Dir.InvSet[j] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;
Invariant "rule_224"
	(Sta.Dir.Pending = false -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_227"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_228"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;
Invariant "rule_229"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset j : NODE do
Invariant "rule_233"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_234"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_236"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_237"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_238"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;
Invariant "rule_239"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_240"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_241"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_242"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_243"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;
Invariant "rule_244"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Pending = true);


ruleset j : NODE do
Invariant "rule_245"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_247"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_248"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_249"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_250"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_254"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_255"
	(Sta.Dir.InvSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_257"
	(Sta.Proc[i].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_258"
	(Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_259"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;
Invariant "rule_260"
	(Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset j : NODE do
Invariant "rule_261"
	(Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;
Invariant "rule_262"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset i : NODE do
Invariant "rule_264"
	(Sta.Dir.ShrSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_266"
	(Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_267"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;
Invariant "rule_268"
	(Sta.Dir.Pending = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset i : NODE do
Invariant "rule_271"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_272"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_273"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_280"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_281"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_284"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_285"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_290"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_291"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_292"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_293"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_294"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_295"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_296"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_298"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_299"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_300"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_301"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_302"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_303"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_304"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_306"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_307"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_308"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_309"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_310"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_311"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_312"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_313"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_314"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_315"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_316"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_317"
	(Sta.Dir.InvSet[i] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_318"
	(Sta.Dir.HeadVld = false -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_319"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_320"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_321"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_323"
	(Sta.Dir.ShrVld = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_324"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_325"
	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_326"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_327"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_328"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_331"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_332"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_333"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_334"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_335"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_337"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_339"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_340"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_341"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_342"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_343"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_344"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_346"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_348"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_349"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_352"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_353"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_354"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_355"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_356"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_357"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_358"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_360"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_362"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_364"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_366"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_367"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_369"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_370"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_371"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_372"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_373"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_374"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_376"
	(Sta.Dir.HeadVld = false -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_378"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_379"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_382"
	(Sta.Dir.ShrVld = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_383"
	(Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_386"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_387"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_388"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_389"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_391"
	(Sta.Dir.InvSet[j] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_392"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_396"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_398"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_400"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_401"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_408"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_409"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_410"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_411"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_412"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_413"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_414"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_415"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_418"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_419"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_420"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_421"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_422"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_423"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_424"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_425"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_426"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_428"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_431"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_433"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_434"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_435"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_436"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_439"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_440"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_442"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_443"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_444"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_445"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_446"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_449"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_450"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_453"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_454"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_455"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_456"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_457"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_458"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_462"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_463"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_464"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_465"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_469"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_470"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_471"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_472"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_476"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_477"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_479"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_480"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_484"
	(Sta.Dir.InvSet[i] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_486"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_487"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_489"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_490"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_491"
	(Sta.Dir.InvSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_492"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_493"
	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_494"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_496"
	(Sta.Dir.InvSet[i] = false -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_499"
	(Sta.Dir.InvSet[i] = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_500"
	(Sta.Dir.InvSet[i] = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_501"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_503"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_504"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_506"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_507"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_508"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_511"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_512"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_514"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_516"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_517"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_518"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_519"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_521"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_522"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_523"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_526"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_527"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_529"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_530"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_531"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_532"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_536"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;
Invariant "rule_541"
	(Sta.Dir.HeadVld = false -> Sta.WbMsg.Cmd != WB_Wb);
Invariant "rule_543"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_544"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_545"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_549"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_550"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadVld = false);
endruleset;
Invariant "rule_551"
	(Sta.Dir.HeadVld = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_554"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;
Invariant "rule_555"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.HeadVld = true);
Invariant "rule_557"
	(Sta.Dir.ShrVld = true -> Sta.Dir.HeadVld = true);


ruleset j : NODE do
Invariant "rule_558"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_559"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_561"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_563"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_564"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_565"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.HeadVld = true);


ruleset j : NODE do
Invariant "rule_566"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_567"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_570"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_571"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_574"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_576"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_579"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_580"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_583"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_584"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_587"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_590"
	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_591"
	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_592"
	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_593"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_596"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_598"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_599"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_602"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.Proc[j].InvMarked = false);
endruleset;
Invariant "rule_606"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_607"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_608"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_609"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_610"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_612"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_614"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_615"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_616"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;
Invariant "rule_617"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.WbMsg.Data = Sta.CurrData);


ruleset i : NODE do
Invariant "rule_618"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;
Invariant "rule_621"
	(Sta.Dir.ShrVld = true -> Sta.WbMsg.Cmd != WB_Wb);


ruleset j : NODE do
Invariant "rule_622"
	(Sta.Dir.ShrSet[j] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_623"
	(Sta.Dir.ShrSet[i] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_624"
	(Sta.Dir.InvSet[j] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_627"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_629"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;
Invariant "rule_630"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.WbMsg.Cmd != WB_Wb);
Invariant "rule_636"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_637"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_638"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_639"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_642"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_645"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_646"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_649"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_656"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_658"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_659"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_661"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_669"
	(Sta.Dir.HeadPtr != i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_670"
	(Sta.Dir.HeadPtr != i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_674"
	(Sta.Dir.ShrVld = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_675"
	(Sta.Dir.ShrVld = false -> Sta.Dir.ShrSet[i] = false);
endruleset;
Invariant "rule_677"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_680"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_681"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_682"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_685"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_686"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_687"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.ShrVld = true);
endruleset;
Invariant "rule_689"
	(Sta.Dir.ShrVld = true -> Sta.Dir.Pending = false);


ruleset j : NODE do
Invariant "rule_690"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_692"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_693"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_694"
	(Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_695"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_696"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_698"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.InvSet[j] = true);
endruleset;


ruleset j : NODE do
Invariant "rule_699"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.Pending = false);
endruleset;


ruleset j : NODE do
Invariant "rule_700"
	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_702"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_703"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_704"
	(Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_705"
	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_706"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_708"
	(Sta.Dir.InvSet[j] = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_710"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_713"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_714"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_715"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_718"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrSet[j] = false);
endruleset;
Invariant "rule_721"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.ShWbMsg.Data = Sta.CurrData);
Invariant "rule_725"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_727"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_730"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_731"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_732"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_736"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_738"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_739"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_741"
	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_742"
	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_743"
	(Sta.Dir.ShrSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_744"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_745"
	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_749"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_750"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_752"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_753"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_754"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_757"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_758"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_760"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_761"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_762"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_763"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_766"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_768"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_770"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_773"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_777"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_778"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_780"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_781"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_784"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_785"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_787"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_788"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_789"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_792"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_794"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_796"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_799"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_801"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_815"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_816"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_817"
	(Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_819"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_821"
	(Sta.Dir.InvSet[j] = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_823"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_824"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_825"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_826"
	(Sta.Dir.InvSet[j] = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_828"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_829"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_832"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_834"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_835"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_838"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_840"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_841"
	(Sta.Dir.Pending = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_843"
	(Sta.Dir.Pending = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_844"
	(Sta.Dir.Pending = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_845"
	(Sta.Dir.Pending = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_846"
	(Sta.Dir.Pending = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_849"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_850"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.Pending = true);
endruleset;
Invariant "rule_851"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Pending = true);


ruleset j : NODE do
Invariant "rule_855"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_857"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_860"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_861"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_862"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_864"
	(Sta.Dir.HeadPtr != j -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_871"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_875"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_877"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_885"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_891"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_903"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_907"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_916"
	(Sta.Dir.HeadPtr != j -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_937"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_939"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_941"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_943"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_944"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_945"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_946"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_948"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_949"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_951"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_952"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_953"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_954"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_956"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_958"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_959"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_960"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_961"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_962"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_963"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_964"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_965"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_968"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_970"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_971"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_977"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_984"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_990"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_996"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_997"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_998"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_999"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1002"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1006"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1009"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1010"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1011"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1020"
	(Sta.Dir.Local = false & Sta.Dir.InvSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1024"
	(Sta.Dir.Local = false & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1027"
	(Sta.Dir.Local = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1031"
	(Sta.Dir.Dirty = true & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1034"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1035"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1036"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1037"
	(Sta.Dir.Local = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1039"
	(Sta.Dir.Local = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1040"
	(Sta.Dir.Local = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1041"
	(Sta.Dir.Local = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1043"
	(Sta.Dir.HeadVld = false & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1045"
	(Sta.Dir.Local = false & Sta.Dir.ShrVld = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1046"
	(Sta.Dir.Local = false & Sta.Dir.ShrSet[i] = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1047"
	(Sta.Dir.Local = false & Sta.Dir.Pending = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1051"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1052"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1053"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1054"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1055"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.Local = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1056"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1062"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1067"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1068"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1069"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1071"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Dir.Local = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1072"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.Local = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1073"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1074"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_1075"
	(Sta.MemData != Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1079"
	(Sta.Dir.Dirty = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1083"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.Local = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1084"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.Local = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1085"
	(Sta.Dir.HeadVld = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1087"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = false -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1088"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1089"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1093"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.Local = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1094"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.Local = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1095"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1096"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.Local = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1101"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1102"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1103"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1104"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1106"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1108"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1109"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1110"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1111"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_1112"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1118"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd = UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1119"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1120"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1121"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1122"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1123"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1125"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_1126"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1127"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1129"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1130"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1131"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1132"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1133"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1134"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1135"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1136"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1137"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1138"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1139"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1140"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.Pending = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1141"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1142"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1143"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1144"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1145"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1146"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1147"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1148"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1149"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1151"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1152"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1156"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1157"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1159"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1161"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1162"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1163"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1164"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1165"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1172"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1173"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1174"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1175"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1176"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1178"
	(Sta.Proc[j].InvMarked = true & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1179"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1180"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1181"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1182"
		(j != i) ->	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1183"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1184"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1185"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1186"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1187"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1188"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1189"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1190"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1192"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1194"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1195"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1196"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1198"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1199"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1200"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1202"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1203"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1204"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1208"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1209"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1217"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Dirty = false -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1219"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Dirty = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1222"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1224"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1226"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1227"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1228"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1230"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1231"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1234"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1235"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1238"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1240"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1241"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1246"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1247"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1255"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1273"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1275"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1276"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1277"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1279"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1281"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1282"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1283"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1284"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1286"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1288"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1290"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1295"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1296"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1297"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1298"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1299"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1300"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1301"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1306"
		(i != j) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1316"
		(i != j) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1323"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1330"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1334"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1335"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1336"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1337"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1338"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1342"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1343"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1345"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1346"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1347"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1351"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1352"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1354"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1355"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1356"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1359"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1360"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1364"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1365"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1366"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1367"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1368"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1369"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1370"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1372"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1373"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1374"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1375"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1377"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1378"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1380"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1381"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1382"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1383"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Proc = i -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1384"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1386"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1387"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1388"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1390"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1391"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1404"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1414"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1415"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1416"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1417"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1419"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1420"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1421"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1422"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1424"
		(i != j) ->	(Sta.Dir.Pending = false & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1425"
		(i != j) ->	(Sta.Dir.Pending = false & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1427"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1428"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1430"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1433"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1435"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1436"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1441"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1445"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1462"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Dir.Dirty = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1463"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.Dirty = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1468"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1469"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1472"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1474"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1475"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1480"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1481"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1491"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1511"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1513"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1514"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1515"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1517"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1519"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1525"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1526"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1527"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1528"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1530"
		(i != j) ->	(Sta.Dir.HeadVld = false & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1531"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1547"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1548"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1549"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1553"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1554"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1556"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1557"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1558"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1562"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1564"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1566"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1567"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1569"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1570"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1571"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1572"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1573"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1574"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1575"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1576"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1582"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1584"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1600"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1610"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1611"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1612"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1613"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1615"
		(i != j) ->	(Sta.Dir.Pending = false & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1616"
		(i != j) ->	(Sta.Dir.Pending = false & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1618"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1620"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1628"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_1640"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1641"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1642"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1645"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1646"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1654"
	(Sta.MemData != Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1655"
	(Sta.MemData != Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1656"
	(Sta.Dir.HeadVld = true & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1657"
	(Sta.Dir.Pending = false & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1658"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1663"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.MemData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1664"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.MemData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1669"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Dir.Dirty = false -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1670"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Dir.Dirty = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1671"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1673"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1674"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1675"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1676"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1677"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1678"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1679"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1680"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1683"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1691"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1693"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1694"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1695"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1696"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1697"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1698"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1699"
	(Sta.Dir.Dirty = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1700"
	(Sta.Dir.Dirty = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1701"
	(Sta.Dir.Dirty = true & Sta.Dir.HeadVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1702"
	(Sta.Dir.Dirty = true & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1703"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1704"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1709"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1718"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1719"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1720"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_1721"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1722"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1723"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1724"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_1727"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_1729"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_1730"
	(Sta.Proc[i].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1738"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1739"
	(Sta.Dir.HeadPtr = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1742"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1745"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1748"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1749"
	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1750"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1753"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1754"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1755"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1756"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1757"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1759"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1760"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1763"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1764"
	(Sta.Dir.HeadPtr = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1767"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1770"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_1773"
	(Sta.Dir.HeadPtr = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_1774"
	(Sta.Proc[i].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1777"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1778"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1782"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1783"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1795"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1796"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1813"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1814"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1815"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_1818"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_1821"
	(Sta.Proc[i].CacheState = CACHE_S & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1826"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_1827"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.HeadPtr = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1830"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1833"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1836"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1837"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_1839"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadPtr = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1842"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1845"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_1848"
	(Sta.Proc[i].CacheState = CACHE_S & Sta.Dir.HeadPtr = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1851"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1857"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1866"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_1875"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1876"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1877"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1878"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_1879"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1880"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1881"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1882"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1883"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1892"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1899"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1900"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1901"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1903"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1905"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1906"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1907"
	(Sta.Dir.HeadVld = false & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1908"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1909"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1910"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1911"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1912"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1913"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1914"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_1915"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1916"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1917"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1918"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1919"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1920"
		(i != j) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Dir.HeadPtr != i -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1921"
		(i != j) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Dir.HeadPtr != i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1922"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1923"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1925"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1926"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1928"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_1929"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1930"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1931"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1932"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1934"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.ShWbMsg.Proc != j -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1935"
		(i != j) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.ShWbMsg.Proc = i -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1936"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1937"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1938"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1939"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1940"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1941"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.ShWbMsg.Proc != j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1942"
		(i != j) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1943"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1944"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1945"
	(Sta.Dir.HeadVld = false & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1946"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1947"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1948"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1949"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1950"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1951"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1959"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1966"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1967"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1968"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1970"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1972"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1973"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1974"
	(Sta.Dir.HeadVld = false & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1975"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1976"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1977"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1978"
		(j != i) ->	(Sta.WbMsg.Cmd = WB_Wb & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1979"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1980"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1981"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1982"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1984"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1986"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1987"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1988"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1989"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1991"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1992"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1993"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1994"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1995"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1996"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1999"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2000"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2002"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2004"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2006"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2007"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2008"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2009"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2010"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2012"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2013"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2014"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2020"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2021"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2022"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2023"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2024"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2025"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2026"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2027"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2028"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2029"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2030"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2037"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2038"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2039"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2040"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2041"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2042"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2044"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2045"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2046"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2047"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2048"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2049"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2051"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2052"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2061"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].CacheState = CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2062"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2063"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState != CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2065"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2067"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_None -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2068"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2069"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2070"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2071"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2074"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2075"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2077"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2079"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2081"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2083"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2111"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2118"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2142"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2160"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2162"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2182"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2183"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[i].CacheState = CACHE_E -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2184"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2185"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2188"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_2193"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2194"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2201"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2202"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2203"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2204"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2208"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2210"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2212"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_2215"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2217"
	(Sta.Dir.ShrSet[j] = true & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2218"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2219"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2222"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2226"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2228"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2229"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2231"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_S -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2232"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2233"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2235"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2237"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2239"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2240"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2242"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2244"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2248"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2251"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2252"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2253"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2258"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2259"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2261"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2262"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2263"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2264"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_2265"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2267"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2268"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2270"
	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2272"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2273"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2274"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2278"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2281"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2284"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2285"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2287"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2290"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2291"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2293"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2294"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2295"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2298"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2299"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2300"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2303"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2304"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2305"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2306"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2307"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2308"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2310"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2311"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2312"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2313"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2314"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2315"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2316"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2317"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2319"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2320"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2321"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2322"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2323"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2325"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2326"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2327"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2328"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2329"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2330"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2332"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2334"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_2337"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2338"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2339"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2340"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2341"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2342"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2343"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2346"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2348"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2349"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2352"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2353"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2354"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2355"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2356"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2357"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2358"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2359"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2361"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2363"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2366"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2367"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2368"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2371"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2372"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2373"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2374"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2377"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2379"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2380"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2387"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2388"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2389"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2390"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2391"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2392"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2393"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2395"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = false -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2396"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2397"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2398"
	(Sta.Dir.HeadVld = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2402"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2403"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2404"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2405"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2415"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2417"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2418"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = false -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2421"
	(Sta.Dir.ShrVld = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2422"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2424"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2426"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2429"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2430"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2431"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.InvSet[j] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2432"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2433"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2435"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2437"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2438"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2439"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2449"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2452"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2453"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2456"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2457"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2458"
	(Sta.Dir.HeadVld = false & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2460"
	(Sta.Dir.HeadVld = true & Sta.Dir.ShrVld = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2461"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.HeadVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2462"
	(Sta.Dir.HeadVld = true & Sta.Dir.Pending = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2469"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2471"
	(Sta.Dir.Pending = false & Sta.Dir.ShrVld = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2472"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.ShrVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2475"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2480"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[j] = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2481"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2482"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2484"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2486"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2487"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2494"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2497"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2498"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2501"
	(Sta.Dir.ShrSet[i] = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2502"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Proc[i].CacheState = CACHE_I -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2512"
	(Sta.Proc[i].CacheState != CACHE_I & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2513"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2515"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState != CACHE_I -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2517"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2520"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2524"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2528"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2529"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2533"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2535"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2536"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2537"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2538"
	(Sta.Proc[i].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2545"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2549"
	(Sta.UniMsg[i].Cmd != UNI_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2550"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2551"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2552"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2556"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd = UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2557"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2558"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2561"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2563"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2564"
	(Sta.Proc[i].CacheState = CACHE_S & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2565"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2566"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2568"
	(Sta.Dir.ShrSet[i] = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2570"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2572"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2573"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd = UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2574"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2575"
	(Sta.UniMsg[i].Cmd != UNI_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2576"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2578"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2579"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2581"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2583"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2585"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2587"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2588"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_2589"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2590"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2594"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_2595"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2601"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd != UNI_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2602"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].InvMarked = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2603"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2604"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2607"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2609"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2613"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2614"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2615"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2617"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2618"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_None -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2620"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Cmd != UNI_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2621"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2623"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2624"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2626"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2628"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2630"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2632"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2633"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2634"
	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2635"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2636"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2641"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2650"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2673"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2683"
	(Sta.Proc[i].InvMarked = false & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2687"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2688"
	(Sta.Proc[i].InvMarked = false & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2689"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2694"
		(j != i) ->	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2696"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2698"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2703"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2706"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2708"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2709"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2710"
	(Sta.Proc[i].InvMarked = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2715"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2716"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].InvMarked = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2717"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2722"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2726"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2731"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2733"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2736"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2738"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2740"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2744"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2745"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2749"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2752"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2754"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2755"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2756"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2757"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2758"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].InvMarked = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2760"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2761"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2762"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2763"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2764"
	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2765"
	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2766"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2768"
	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2769"
	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2771"
	(Sta.Proc[j].InvMarked = true & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2772"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2774"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2775"
	(Sta.Proc[j].InvMarked = true & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2776"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2782"
	(Sta.Proc[j].InvMarked = true & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2783"
	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2784"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE do
Invariant "rule_2785"
	(Sta.Proc[j].InvMarked = true & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2786"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2787"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2788"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2789"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2790"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2791"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2792"
	(Sta.Dir.ShrSet[j] = true & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2794"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2795"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2796"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2797"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2801"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2802"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2803"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2804"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2805"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.WbMsg.Cmd = WB_Wb -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2806"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_2815"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2816"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2818"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2820"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2821"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2827"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2829"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2843"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2846"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2848"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2853"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2855"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2862"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2865"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2873"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2874"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2893"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2894"
		(j != i) ->	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2895"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2909"
	(Sta.Dir.ShrSet[j] = true & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2910"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2916"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2917"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2918"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2919"
	(Sta.Dir.ShrSet[j] = true & Sta.ShWbMsg.Proc = j -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2921"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2922"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2925"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2926"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2927"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2928"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2929"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2930"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2931"
	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2932"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2933"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2934"
	(Sta.Dir.ShrSet[j] = true & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2935"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2936"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2937"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2938"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.ShWbMsg.Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2939"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2950"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2951"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2952"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2953"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2954"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2956"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2963"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Proc = j -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2965"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2966"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2969"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2970"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2971"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2972"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2973"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2974"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2975"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2976"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2986"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2987"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2990"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2996"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3001"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3003"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3005"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3010"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3011"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3019"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3025"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3037"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3042"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3043"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3047"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3050"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3051"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3052"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3054"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3057"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3059"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3060"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3062"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3063"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3064"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3067"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3068"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3070"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3075"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3077"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_3080"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3090"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3092"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3096"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3103"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3107"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3108"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3109"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3113"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3114"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3118"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3120"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3129"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3131"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3138"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3139"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3140"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.Pending = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3141"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3142"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3143"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3144"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3145"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3146"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3147"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3148"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3149"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3151"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3152"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3153"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3154"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3155"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3156"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3159"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3160"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3161"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_3162"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3163"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3164"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3165"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3166"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_3167"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3168"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_3171"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_3172"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3173"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3174"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3178"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3179"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3182"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3183"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3184"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3185"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_3186"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3187"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_3188"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3197"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3198"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3203"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3204"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3207"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3208"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3209"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3210"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3221"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3222"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3223"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3224"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3225"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3227"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3228"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3238"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3239"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3240"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3241"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3242"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3243"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3244"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3245"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3246"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3247"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3248"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3252"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3253"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3255"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3256"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3257"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3258"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3261"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3262"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3263"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3264"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3265"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3266"
		(i != j) ->	(Sta.ShWbMsg.Proc != i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3267"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3268"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3269"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3270"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3271"
		(i != j) ->	(Sta.ShWbMsg.Proc != i & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3272"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3285"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3287"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_3290"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3292"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3297"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3298"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3301"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3302"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3305"
	(Sta.Proc[i].CacheState = CACHE_S & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3309"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3310"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3311"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3312"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3313"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_3314"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3315"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3320"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3321"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;
