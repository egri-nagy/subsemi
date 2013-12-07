SameSgpEquivs := function(mt)
local al,i;  
  al := AssociativeList();
  for i in Indices(mt) do Assign(al,i,SgpInMulTab([i],mt));od;
  al := ReversedAssociativeList(al);
  return Filtered(ValueSet(al), x->Length(x)>1);
end;

# mt - MulTab, multiplication table
InstallGlobalFunction(SubSgpsBy1Extensions,
function(mt)
  local s, L, extend, result, syms,
        counter, log, dump, p_subs, p_counter, dumpcounter, secs, p_secs, tab,
        extend_conjreponly,equivs, indexblist;#,boosters;
  p_subs := 0; p_counter := 0; dumpcounter := 1;
  #-----------------------------------------------------------------------------
  log := function() #put some information on the screen
    secs := TimeInSeconds();
    Print("#", FormattedBigNumberString(counter)," #",Size(result)," ",
          FormattedMemoryString(MemoryUsage(result))," ",
          FormattedPercentageString(Size(result)-p_subs,counter-p_counter)," ");
    if (secs-p_secs) > 0 then
      Print(FormattedFloat(Float((Size(result)-p_subs)/(secs-p_secs))),
            "/s\c\n");
    else
      Print("\c\n");
    fi;
    p_subs := Size(result); p_counter := counter;
    p_secs := TimeInSeconds();
  end;
  #-----------------------------------------------------------------------------
  dump := function() #write all the subsemigroups into a file
    local r,filename,l,i, S,ll,output;
    p_secs := TimeInSeconds();
    if not HasOriginalName(mt) then
      Info(SubSemiInfoClass,1,"# No name, no dump!");
      return;
    fi;
    filename := Concatenation(OriginalName(mt),"_", String(dumpcounter),"subs");
    output := OutputTextFile(filename, false);
    for r in AsList(result) do
      AppendTo(output, EncodeBitString(AsBitString(r)),"\n");
    od;
    CloseStream(output);
    dumpcounter := dumpcounter + 1;
    Info(SubSemiInfoClass,1,Concatenation("#Dumping in ",
          FormattedTimeString(TimeInSeconds()-p_secs)));
    #resetting the timer no to mess up the speed gauge 
    p_secs := TimeInSeconds();
  end;
  #-----------------------------------------------------------------------------
  #ORIGINAL
  extend := function(base,s)
    local t, bl;
    #HOUSEKEEPING: logging, dumping
    counter := counter + 1;
    if InfoLevel(SubSemiInfoClass)>0 and (counter mod SubSemiOptions.LOGFREQ)=0 then
      log();
    fi;
    if (counter mod SubSemiOptions.DUMPFREQ)=0 then dump(); fi;
    #calculating the new subsgp
    bl := ClosureByQueue(base, [s], mt);
    if  bl in result then
      return; #just bail out if we already have it
    fi;
    #STORE
    AddSet(result, bl);
    Perform(List(syms, g -> OnFiniteSet(bl,g)),function(b)AddSet(result,b);end);
    #RECURSION
    for t in Difference(Indices(mt), ListBlist(Indices(mt),bl)) do
      extend(bl,t);
    od;
  end;
  #-----------------------------------------------------------------------------
  extend_conjreponly := function(base,s)
    local C,  bl, diff,f,i;
    #HOUSEKEEPING: logging, dumping
    counter := counter + 1;
    if InfoLevel(SubSemiInfoClass)>0 and (counter mod SubSemiOptions.LOGFREQ)=0 then
      log();
    fi;
    if (counter mod SubSemiOptions.DUMPFREQ)=0 then dump(); fi;
    #calculating the new subsgp
    bl := ClosureByQueue(base, [s], mt);#boosters[s]);#[s]);
    #its conjugacy class
    #C := [bl];
    #Perform(syms, function(g) AddSet(C,OnFiniteSet(bl,g));end);
    bl := ConjugacyClassRep(bl,mt);#C[1]; #the canonical rep
    if  bl in result then
      return; #just bail out if we already have it
    fi;
    #STORE
    AddSet(result, bl);
    #RECURSION
    diff := DifferenceBlist(indexblist, bl);
    for C in equivs do #keep maximum one from each equiv class
      f := false;
      for i in C do
        if diff[i] then
          if f then
            diff[i] := false;
          else
            f := true;
          fi;
        fi;
      od;
    od;
    Perform(ListBlist(Indices(mt),diff), function(t) extend_conjreponly(bl,t);end);
  end;
  #-----------------------------------------------------------------------------
  #MAIN
  L := SortedElements(mt);
  if HasSymmetries(mt) then
    syms := Symmetries(mt);
  else
    syms := [];
  fi;
  indexblist := BlistList(Indices(mt),Indices(mt));
  tab := Rows(mt);
  equivs := SameSgpEquivs(mt);
  #boosters := List([1..mt.n], i->ListBlist(Indices(mt),(GenerateSg(Rows(mt),Indices(mt),[i]))));
  result := DynamicIndexedHashSet([SizeBlist,FirstEntryPosOr1,LastEntryPosOr1]);
    #IndexedSet(13,BinaryBlistIndexer(13), ListWithIdenticalEntries(13,2));
  counter := 0;
  p_secs := TimeInSeconds();
  for s in Indices(mt) do
    Info(SubSemiInfoClass,1,
         Concatenation("# ", String(s),"/",String(Size(Indices(mt)))));
    #if IsEmpty(syms)
    extend_conjreponly(BlistList(Indices(mt), []),s);
  od;
  if InfoLevel(SubSemiInfoClass)>0 then log();fi;
  dump();
  Info(SubSemiInfoClass,1,Concatenation("#",String(counter)));
  return result;
end);
