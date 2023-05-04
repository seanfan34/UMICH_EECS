
-- MSI 3-hop VI protocol

----------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------
const
  ProcCount: 3;          -- number processors
  ValueCount:   3;       -- number of data values.
  VC0: 0;                -- low priority
  VC1: 1;
  VC2: 2;
  QMax: 2;
  NumVCs: VC2 - VC0 + 1;
  NetMax: ProcCount+1;
  

----------------------------------------------------------------------
-- Types
----------------------------------------------------------------------
type
  Proc: scalarset(ProcCount);   -- unordered range of processors
  Value: scalarset(ValueCount); -- arbitrary values for tracking coherence
  Home: enum { HomeType };      -- need enumeration for IsMember calls
  Node: union { Home , Proc };

  Count : -3..3;
  VCType: VC0..NumVCs-1;

  MessageType: enum {  GetS, 
                       GetM, 

                       PutS,
                       PutM, 

                       PutAck, 

                       FwdGetS, 
                       FwdGetM, 

                       Inv, 
                       InvAck,
                       Data
                    };

  Message:
    Record
      mtype: MessageType;
      src: Node;
      -- do not need a destination for verification; the destination is indicated by which array entry in the Net the message is placed
      vc: VCType;
      val: Value;
      ack: Count;
    End;

  HomeState:
    Record
      state: enum { H_I, 
                    H_S, 
                    H_M, 	
      			        H_S_D }; 								--transient states during recall
      owner: Node;	
      sharers: multiset [ProcCount] of Node;    --No need for sharers in this protocol, but this is a good way to represent them
      val: Value; 
    End;

  ProcState:
    Record
       state: enum { P_S, 
                     P_I, 
                     P_M, 
                     P_SI_A, 
                     P_SM_A, 
                     P_SM_AD,
                     P_MI_A,  
                     P_IS_D,  
                     P_IM_AD, 
                     P_IM_A,
                     P_II_A 
                   };
      val: Value;
      ack: Count;
    End;

----------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------
var
  HomeNode:  HomeState;
  Procs: array [Proc] of ProcState;
  Net:   array [Node] of multiset [NetMax] of Message;  -- One multiset for each destination - messages are arbitrarily reordered by the multiset
  InBox: array [Node] of array [VCType] of Message; -- If a message is not processed, it is placed in InBox, blocking that virtual channel
  msg_processed: boolean;
  LastWrite: Value; -- Used to confirm that writes are not lost; this variable would not exist in real hardware

----------------------------------------------------------------------
-- Procedures
----------------------------------------------------------------------
Procedure Send(mtype:MessageType;
	       dst:Node;
	       src:Node;
         vc:VCType;
         val:Value;
         cnt:Count;
         );

var msg:Message;

Begin
  Assert (MultiSetCount(i:Net[dst], true) < NetMax) "Too many messages";
  msg.mtype := mtype;
  msg.src   := src;
  msg.vc    := vc;
  msg.val   := val;
  msg.ack   := cnt;
  MultiSetAdd(msg, Net[dst]);
End;

Procedure ErrorUnhandledMsg(msg:Message; n:Node);
Begin
  error "Unhandled message type!";
End;

Procedure ErrorUnhandledState();
Begin
  error "Unhandled state!";
End;



Procedure AddToSharersList(n:Node);
Begin
  if MultiSetCount(i:HomeNode.sharers, HomeNode.sharers[i] = n) = 0
  then
    MultiSetAdd(n, HomeNode.sharers);
  endif;
End;

Function IsSharer(n:Node) : Boolean;
Begin
  return MultiSetCount(i:HomeNode.sharers, HomeNode.sharers[i] = n) > 0
End;

Procedure RemoveFromSharersList(n:Node);
Begin
  MultiSetRemovePred(i:HomeNode.sharers, HomeNode.sharers[i] = n);
End;

-- Sends a message to all sharers except rqst
Procedure SendInvReqToSharers(rqst:Node);
Begin
  for n:Node do
    if (IsMember(n, Proc) &
        MultiSetCount(i:HomeNode.sharers, HomeNode.sharers[i] = n) != 0)
    then
      if n != rqst
      then 
        -- Send invalidation message here 
        Send(Inv,n,rqst,VC2,UNDEFINED,MultiSetCount(i:HomeNode.sharers, true));
      endif;
    endif;
  endfor;
End;

Procedure FinishInvReqToSharers(rqst:Node);
Begin
  for n:Node do
    if (IsMember(n, Proc) &
        MultiSetCount(i:HomeNode.sharers, HomeNode.sharers[i] = n) != 0)
    then
      RemoveFromSharersList(n);
      if n != rqst 
      then 
        -- Send invalidation message here 
        Send(Inv,n,rqst,VC2,UNDEFINED,MultiSetCount(i:HomeNode.sharers, true));
      endif;
    endif;
  endfor;
End;



Procedure HomeReceive(msg:Message);
var cnt:0..ProcCount;  -- for counting sharers
Begin
-- Debug output may be helpful:
put "Receiving "; put msg.mtype; put " on VC"; put msg.vc; 
put " at home -- "; put HomeNode.state;

  -- The line below is not needed in Valid/Invalid protocol.  However, the 
  -- compiler barfs if we put this inside a switch, so it is useful to
  -- pre-calculate the sharer count here
cnt := MultiSetCount(i:HomeNode.sharers, true);


  -- default to 'processing' message.  set to false otherwise
  msg_processed := true;

  switch HomeNode.state
  case H_I:
    switch msg.mtype

    case GetS:
      HomeNode.state := H_S;
      HomeNode.owner := UNDEFINED;
      AddToSharersList(msg.src);
      Send(Data, msg.src, HomeType, VC2, HomeNode.val, 0);

    case GetM: 
      HomeNode.state := H_M;
      HomeNode.owner := msg.src;
      Send(Data, msg.src, HomeType, VC2, HomeNode.val, 0);

    case PutM:
      Send(PutAck, msg.src, HomeType, VC1, UNDEFINED, 0);

    case PutS:
      Send(PutAck, msg.src, HomeType, VC1, UNDEFINED, 0);

    else
      ErrorUnhandledMsg(msg, HomeType);

    endswitch;

  
  case H_S:
    switch msg.mtype
    case GetS:
      AddToSharersList(msg.src);
      Send(Data, msg.src, HomeType, VC2, HomeNode.val, 0);
            
    case GetM:
        HomeNode.owner := msg.src;
        if(cnt=1 & IsSharer(msg.src)) then
            HomeNode.state := H_M;
            RemoveFromSharersList(msg.src); 
            Send(Data, msg.src, HomeType, VC2, HomeNode.val, 0); 
        elsif(cnt != 0 & !IsSharer(msg.src)) then 
            HomeNode.state := H_M;
            Send(Data, msg.src, HomeType, VC2, HomeNode.val, cnt);
            FinishInvReqToSharers(msg.src); 
        else 
            HomeNode.state := H_M;
            Send(Data, msg.src, HomeType, VC2, UNDEFINED, (cnt-1));
            FinishInvReqToSharers(msg.src); 
        endif;

    case PutS:
        if (cnt = 1 & IsSharer(msg.src)) then
            HomeNode.state := H_I;
        endif;
        RemoveFromSharersList(msg.src);
        Send(PutAck, msg.src, HomeType, VC1, UNDEFINED,0); 

    case PutM:
        if (cnt = 1 & IsSharer(msg.src)) then
            HomeNode.state := H_I;
        endif;
        Send(PutAck, msg.src, HomeType, VC1, UNDEFINED, 0);
        RemoveFromSharersList(msg.src);
    else
      ErrorUnhandledMsg(msg, HomeType);

    endswitch;


case H_M:
    switch msg.mtype
   
    case GetS:
        AddToSharersList(msg.src); -- add the src to sharer
        AddToSharersList(HomeNode.owner); --add when receive data
        Send(FwdGetS,HomeNode.owner,msg.src,VC2, UNDEFINED, cnt);
        HomeNode.owner := UNDEFINED; --The no owner, the old owner should evict
        
        HomeNode.state := H_S_D;
        
    case PutS:
        RemoveFromSharersList(msg.src);
        Send(PutAck, msg.src, HomeType, VC1, UNDEFINED, 0);
    case PutM:
        if(msg.src = HomeNode.owner) then
            HomeNode.owner := UNDEFINED;
            HomeNode.state := H_I;
            HomeNode.val := msg.val;
            Send(PutAck, msg.src, HomeType, VC1, UNDEFINED, 0);
        else
            Send(PutAck, msg.src, HomeType, VC1, UNDEFINED, 0);
        endif;
        
    case GetM:
        Send(FwdGetM, HomeNode.owner,msg.src, VC2, UNDEFINED, 0);
        HomeNode.owner := msg.src;

    else
      ErrorUnhandledMsg(msg, HomeType);
    endswitch;

case H_S_D:
    switch msg.mtype
    case GetS:
        msg_processed := false;
    case GetM:
        msg_processed := false;

    case PutS:
        Send(PutAck, msg.src, HomeType, VC1, UNDEFINED, 0);
        RemoveFromSharersList(msg.src);

    case PutM:
        if(msg.src != HomeNode.owner) then
            Send(PutAck,msg.src, HomeType, VC1, UNDEFINED, 0);
            RemoveFromSharersList(msg.src);
        endif;
    
    case Data:
        HomeNode.val := msg.val;
        HomeNode.state := H_S;

    else 
        msg_processed := false;   
    endswitch;

    else
        ErrorUnhandledState();
    endswitch;
End;
   

Procedure ProcReceive(msg:Message; p:Proc);
Begin
  put "Receiving "; put msg.mtype; put " on VC"; put msg.vc; 
  put " at proc "; put p; put "\n";

  -- default to 'processing' message.  set to false otherwise
  msg_processed := true;

  alias ps:Procs[p].state do
  alias pv:Procs[p].val do
  alias pc:Procs[p].ack do

  switch ps

  case P_I:
    switch msg.mtype
    case Inv:
      Send(InvAck, msg.src, p, VC2, UNDEFINED,0);
    else
      ErrorUnhandledMsg(msg, p);
    endswitch;

  case P_S:
    switch msg.mtype
    case Inv:
      ps := P_I;
      Send(InvAck, msg.src, p, VC2, UNDEFINED, 0); 
      pv := undefined;
      
    else
      ErrorUnhandledMsg(msg, p);
    endswitch;

  case P_M:    
    switch msg.mtype
    case FwdGetS:
      Send(Data, HomeType, p, VC2, pv, 0);
      Send(Data, msg.src, p, VC2, pv, 0);
      ps := P_S;

    case FwdGetM:
      ps := P_I;
      Send(Data, msg.src, p, VC2, pv, 0);
      undefine pv;
    else
      ErrorUnhandledMsg(msg, p);
	endswitch;

  case P_IM_AD:
    switch msg.mtype
  	case FwdGetS:
  		msg_processed := false;
  	case FwdGetM:
  		msg_processed := false;

    case Data:
        pv := msg.val;
        if (msg.src = HomeType) then
            if(msg.ack = 0 | pc + msg.ack = 0) then 
                ps := P_M;
                LastWrite := pv;
                pc := 0;
            else
                ps := P_IM_A;
                pc := pc + msg.ack;
            endif;
        else 
            ps := P_M;
            LastWrite := pv;
            pc := msg.ack;
        endif;

    case InvAck:
        if (pc = 1) then 
            ps := P_M;
            LastWrite := pv;
            pc := 0;
        else
            pc := pc - 1;
        endif;
    case PutS:
        msg_processed := false;
    else
        ErrorUnhandledMsg(msg, p);
   endswitch;

 case P_IM_A:
    switch msg.mtype
    case FwdGetM:
        msg_processed := false;
    case FwdGetS:
        msg_processed := false;
    case InvAck:
        if (pc = 1) then 
            pc := 0;
            ps := P_M;
            LastWrite := pv;
        else
            pc := pc -1;
        endif;
    else
        ErrorUnhandledMsg(msg, p);
    endswitch;

  case P_IS_D:
    switch msg.mtype
    case Data:
        ps := P_S;
        pv := msg.val;
    case Inv:
        msg_processed := false;

    else
        ErrorUnhandledMsg(msg, p);
    endswitch;

  case P_SI_A:
    switch msg.mtype
    case Inv:
        Send(InvAck, msg.src, p, VC2, UNDEFINED, 0);
        ps := P_II_A;
        undefine pv;

    case PutAck:
        ps := P_I;
        undefine pv;
    else
        ErrorUnhandledMsg(msg, p);
    endswitch;

  case P_SM_AD:
    switch msg.mtype
    case Data:
        pv := msg.val;
        if(msg.src = HomeType) then
            if (msg.ack = 0) then
                ps:= P_M;
                pc := 0;
            else
                pc := pc + msg.ack;
                ps := P_SM_A;
            endif;
        else
            ps := P_M;
            LastWrite := pv;
            pc := 0;
        endif;     
      
    case FwdGetS:
        msg_processed := false;
    case FwdGetM:
        msg_processed := false;
    case PutS:
        msg_processed := false;

    case InvAck:
        msg_processed:= false;

    case Inv:
        Send(InvAck, msg.src, p, VC2, UNDEFINED, 0); 
        ps := P_IM_AD;
        pv := undefined;
        pc := 0;
    else
        ErrorUnhandledMsg(msg, p);
    endswitch;

  case P_SM_A:
    switch msg.mtype           
    case FwdGetS:
        msg_processed := false;
    case FwdGetM:
        msg_processed := false;
    case PutS:
        msg_processed := false;

    case InvAck:
        pc := pc -1;
        if (pc = 0) then 
            ps := P_M;
            LastWrite := pv;    
        endif;

    else
        ErrorUnhandledMsg(msg, p);
    endswitch;

  case P_MI_A:
    switch msg.mtype
    case FwdGetS:
        Send(Data, msg.src, p, VC2, pv, 0); 
        Send(Data, HomeType, p, VC2, pv, 0);
        ps := P_SI_A;
        
    case FwdGetM:
        Send(Data, msg.src, p, VC2, pv, 0);
        ps := P_II_A; 

    case PutAck:
        ps := P_I;
        undefine pv;
        pc := 0;
    case PutM:
        msg_processed := false;
    else
        ErrorUnhandledMsg(msg, p);
    endswitch;

  case P_II_A:
    switch msg.mtype
    case PutAck:
        ps := P_I;
        pc := 0;
        undefine pv;
    case GetM:
        msg_processed:= false;
    case GetS:
        msg_processed := false;
    else
        ErrorUnhandledMsg(msg,p);
    endswitch;

  ----------------------------
  -- Error catch
  ----------------------------
  else
    ErrorUnhandledState();

  endswitch;
  
  endalias;
  endalias;
  endalias;
End;

----------------------------------------------------------------------
-- Rules
----------------------------------------------------------------------

-- Processor actions (affecting coherency)

ruleset n:Proc Do
  alias p:Procs[n] Do

	ruleset v:Value Do
  	rule "Store hit"
   	  (p.state = P_M)
    	==>
 		   p.val := v;      
 		   LastWrite := v;  --We use LastWrite to sanity check that reads receive the value of the last write
  	endrule;
	  endruleset;

    rule "Store value at I state"
      (p.state = P_I) 
      ==>
        Send(GetM, HomeType, n, VC1, UNDEFINED, 0);
        p.state := P_IM_AD
    endrule;

    rule "Load value at I state"
      (p.state = P_I)
      ==>
        Send(GetS, HomeType, n, VC1, UNDEFINED,0);
        p.state := P_IS_D;
    endrule;

    rule "Send GetM at S state"
      (p.state = P_S)
      ==>
          Send(GetM, HomeType, n, VC1, UNDEFINED, 0);
          p.state := P_SM_AD;
    endrule;

    rule "Writeback PutS at S state"
      (p.state = P_S)
      ==>
          Send(PutS, HomeType, n, VC0, UNDEFINED,0); 
          p.state := P_SI_A;
    endrule;

    rule "Writeback PutM at M state"
      (p.state = P_M)
      ==>
          Send(PutM, HomeType, n, VC0, p.val,0); 
          p.state := P_MI_A;
    endrule;

  endalias;
endruleset;


-- Message delivery rules
ruleset n:Node do
  choose midx:Net[n] do
    alias chan:Net[n] do
    alias msg:chan[midx] do
    /*alias box:InBox[n] do*/

		-- Pick a random message in the network and delivier it
    rule "receive-net"

    (msg.vc = VC2) | (msg.vc = VC1 & MultiSetCount(m:chan, chan[m].vc = VC2) = 0) |
    (msg.vc = VC0 & MultiSetCount(m:chan, chan[m].vc = VC1) = 0 & MultiSetCount(m:chan, chan[m].vc = VC2) = 0)
    ==>

      if IsMember(n, Home)
      then
          HomeReceive(msg);
          if  msg_processed
			    then
				    MultiSetRemove(midx, chan);
	  	    endif;
	  
          else
          ProcReceive(msg, n);
			    if msg_processed
			    then
	  			  MultiSetRemove(midx, chan);
			    endif;
      endif;  
    endrule;
  
    endalias;
    endalias;
   
  endchoose;  
/*
	-- Try to deliver a message from a blocked VC; perhaps the node can handle it now
	ruleset vc:VCType do
    rule "receive-blocked-vc"
			(! isundefined(InBox[n][vc].mtype))
    ==>
      if IsMember(n, Home)
      then
        HomeReceive(InBox[n][vc]);
      else
        ProcReceive(InBox[n][vc], n);
			endif;

			if msg_processed
			then
				-- Message has been handled, forget it
	  		undefine InBox[n][vc];
			endif;
	  
    endrule;
  endruleset;
*/
endruleset;

----------------------------------------------------------------------
-- Startstate
----------------------------------------------------------------------
startstate

	For v:Value do
  -- home node initialization
  HomeNode.state := H_I;
  undefine HomeNode.owner;
  HomeNode.val := v;
	endfor;
	LastWrite := HomeNode.val;
  
  -- processor initialization
  for i:Proc do
    Procs[i].state := P_I;
    Procs[i].ack   := 0;
    undefine Procs[i].val;
  endfor;

  -- network initialization
  undefine Net;
endstartstate;

----------------------------------------------------------------------
-- Invariants
----------------------------------------------------------------------

invariant "Invalid implies empty owner"
  HomeNode.state = H_I
    ->
      IsUndefined(HomeNode.owner);
invariant "Process initial at M state"
 Forall n : Proc Do	
     Procs[n].state = P_M
    ->
			Procs[n].ack = 0
	end;
invariant "value is undefined while invalid"
  Forall n : Proc Do	
     Procs[n].state = P_I
    ->
			IsUndefined(Procs[n].val)
	end;

invariant "values in memory matches value of last write, when shared or invalid"
  HomeNode.state = H_I | HomeNode.state = H_S
   ->
    HomeNode.val = LastWrite;

invariant "values in memory matches value of last write, when shared or modified"
  Forall n : Proc Do	
    Procs[n].state = P_S | Procs[n].state = P_M
    ->
		Procs[n].val = LastWrite --LastWrite is updated whenever a new value is created 
	end;

invariant "values in shared state match memory"
  Forall n : Proc Do	
     HomeNode.state = H_S & Procs[n].state = P_S
    ->
			HomeNode.val = Procs[n].val
	end;

invariant "modified implies empty sharers list"
  HomeNode.state = H_M
    ->
      MultiSetCount(i:HomeNode.sharers, true) = 0;

invariant "Invalid implies empty sharer list"
  HomeNode.state = H_I
    ->
      MultiSetCount(i:HomeNode.sharers, true) = 0;
