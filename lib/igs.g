################################################################################
##
## SubSemi
##
## Independent sets in groups and semigroups.
##
## Copyright (C) 2015-2016  Attila Egri-Nagy
##

#global checkpoint data structure is bound here
BindGlobal("SUBSEMI_IGSCheckPointData", rec());

#can we add newgen to gens that it still remains independent
#TODO this is actually very similar to IsSgpIGS, could be written as one function
CanWeAdd := function(gens, newgen, mt)
  local g,l,i;
  l := ShallowCopy(gens); #defensive copying
  for i  in [1..Size(gens)] do
    g := l[i]; #remembering the knocked out old generator
    l[i] := newgen; #putting in the new generator
    if IsInSgp(l,g,mt) then return false; fi;
    l[i] := g; #undo
  od;
  return true;
end;

IsCanonicalAddition := function(gens, newgen, mt)
  local set, p, rep;
  set := Set(Union(gens,[newgen]));
  p := SetConjugacyClassConjugator(set, PossibleMinConjugators(set,mt));
  rep := OnSets(set, p);
  return newgen = Maximum(rep)^(Inverse(p));
end;

ISxxx := function(mt, potgens,db,candidates,result, isNew, store, isCand)
  local H,set,counter,blistrep,diff,normalizer,n, l, ll;
  counter := 0;
  n := Size(Indices(mt));
  while not IsEmpty(candidates) do
    set := Retrieve(candidates);
    H := SgpInMulTab(set,mt);
    blistrep := BlistList(Indices(mt),set);
    if isNew(blistrep) then
      #StoreBlist(db,blistrep);
      #Add(result, blistrep);
      store(blistrep);
      if SizeBlist(H) < n then
        diff := Difference(potgens,ListBlist(Indices(mt),H));
        isCand(diff, blistrep, set);
        # orbit reps by the normalizer, making diff smaller, avoid dups
        #normalizer := Stabilizer(SymmetryGroup(mt), blistrep, OnFiniteSet);
        #diff := List(Orbits(normalizer, diff), x->x[1]);
        # checking whether adding elements from diff would yield igs' or not
        #diff := Filtered(diff, x -> CanWeAdd(set, x, mt));
        #it is enough the compile a List, rather than a Set
        ll := List(diff, x->Set(Concatenation(set,[x])));
        l := List(ll, x->SetConjugacyClassRep(x,PossibleMinConjugators(x,mt)));
        Perform(l, function(y) Store(candidates,y);end);
      fi;
    fi;
    counter := counter + 1;#####################################################
    if InfoLevel(SubSemiInfoClass)>0
       and (counter mod SubSemiOptions.LOGFREQ)=0 then
      Info(SubSemiInfoClass,1,FormattedBigNumberString(counter),
           " iss:", Size(result)," ~ ",
           FormattedBigNumberString(Size(result)),
           " stack:",String(Size(candidates)),
           " ", Peek(candidates));
    fi;#########################################################################
    if (counter mod SubSemiOptions.CHECKPOINTFREQ)=0 then
      SUBSEMI_IGSCheckPointData.candidates := candidates;
      SUBSEMI_IGSCheckPointData.mt := mt;
      SUBSEMI_IGSCheckPointData.potgens := potgens;
      SUBSEMI_IGSCheckPointData.db := db;
      SUBSEMI_IGSCheckPointData.result := result;
      SaveWorkspace(Concatenation("IGScheckpoint",
              String(IO_gettimeofday().tv_sec),".ws"));
      Info(SubSemiInfoClass,1,Concatenation("Checkpoint saved after ",
              FormattedBigNumberString(counter), " steps"));
    fi;
  od;
  Info(SubSemiInfoClass,1,"TOTAL: ",###########################################
       String(Size(result)),
       " in ",String(counter)," steps");########################################
  return result;
end;


# canonical construction path method
#potgens should be a subset of FullSet(mt)
ISCanCons := function(mt, potgens, iss, candidates)
  local H,set,counter,blistrep,diff,n, l, ll, minconjs, min;
  counter := 0;
  n := Size(Indices(mt));
  minconjs := MinimumConjugates(mt);
  while not IsEmpty(candidates) do
    set := Retrieve(candidates);
    if IsEmpty(set) then min := 0; else min := Minimum(set); fi;
    H := SgpInMulTab(set,mt);
    blistrep := BlistList(Indices(mt),set);
    Add(iss,blistrep);
    if SizeBlist(H) < n then
      diff := Difference(potgens,ListBlist(Indices(mt),H));
      #adding an element smaller than the minrep can't be canonical construction
      diff := Filtered(diff, x->minconjs[x] >= min);
      # checking whether adding elements from diff would yield igs' or not
      diff := Filtered(diff,
                      x -> not ForAny(set, y-> MonogenicSgps(mt)[x][y])
                           and IsCanonicalAddition(set,x,mt)
                           and CanWeAdd(set, x, mt));
      #it is enough the compile a List, rather than a Set
      ll := List(diff, x->Set(Concatenation(set,[x])));
      l := List(ll, x->SetConjugacyClassRep(x,PossibleMinConjugators(x,mt)));
      Perform(l, function(y) Store(candidates,y);end);
    fi;
    counter := counter + 1;#####################################################
    if InfoLevel(SubSemiInfoClass)>0
       and (counter mod SubSemiOptions.LOGFREQ)=0 then
      Info(SubSemiInfoClass,1,
           "iss:", Size(iss)," ~ ",
           FormattedBigNumberString(Size(iss)),
           " stack:",String(Size(candidates)),
           " ", Peek(candidates));
    fi;#########################################################################
    if (counter mod SubSemiOptions.CHECKPOINTFREQ)=0 then
      SUBSEMI_IGSCheckPointData.candidates := candidates;
      SUBSEMI_IGSCheckPointData.mt := mt;
      SUBSEMI_IGSCheckPointData.potgens := potgens;
      SUBSEMI_IGSCheckPointData.iss := iss;
      SaveWorkspace(Concatenation("IGScheckpoint",
              String(IO_gettimeofday().tv_sec),".ws"));
      Info(SubSemiInfoClass,1,Concatenation("Checkpoint saved after ",
              FormattedBigNumberString(counter), " steps"));
    fi;
  od;
  Info(SubSemiInfoClass,1,"TOTAL: ",###########################################
       String(Size(iss)),
       " in ",String(counter)," steps");########################################
  return  iss; #List(iss, x->SetByIndicatorFunction(x,mt));
end;

# keeping a database for checking against
#potgens should be a subset of FullSet(mt)
ISDatabase := function(mt, potgens,db,candidates,result)
  local H,set,counter,blistrep,diff,normalizer,n, l, ll;
  counter := 0;
  n := Size(Indices(mt));
  while not IsEmpty(candidates) do
    set := Retrieve(candidates);
    H := SgpInMulTab(set,mt);
    blistrep := BlistList(Indices(mt),set);
    if not IsInBlistStorage(db,blistrep) then
      StoreBlist(db,blistrep);
      Add(result, blistrep);
      if SizeBlist(H) < n then
        diff := Difference(potgens,ListBlist(Indices(mt),H));
        # orbit reps by the normalizer, making diff smaller, avoid dups
        normalizer := Stabilizer(SymmetryGroup(mt), set, OnSets);
        diff := List(Orbits(normalizer, diff), x->x[1]);
        # checking whether adding elements from diff would yield igs' or not
        diff := Filtered(diff, x -> CanWeAdd(set, x, mt));
        #it is enough the compile a List, rather than a Set
        ll := List(diff, x->Set(Concatenation(set,[x])));
        l := List(ll, x->SetConjugacyClassRep(x,PossibleMinConjugators(x,mt)));
        Perform(l, function(y) Store(candidates,y);end);
      fi;
    fi;
    counter := counter + 1;#####################################################
    if InfoLevel(SubSemiInfoClass)>0
       and (counter mod SubSemiOptions.LOGFREQ)=0 then
      Info(SubSemiInfoClass,1,FormattedBigNumberString(counter),
           " iss:", Size(result)," ~ ",
           FormattedBigNumberString(Size(result)),
           " stack:",String(Size(candidates)),
           " ", Peek(candidates));
    fi;#########################################################################
    if (counter mod SubSemiOptions.CHECKPOINTFREQ)=0 then
      SUBSEMI_IGSCheckPointData.candidates := candidates;
      SUBSEMI_IGSCheckPointData.mt := mt;
      SUBSEMI_IGSCheckPointData.potgens := potgens;
      SUBSEMI_IGSCheckPointData.db := db;
      SUBSEMI_IGSCheckPointData.result := result;
      SaveWorkspace(Concatenation("IGScheckpoint",
              String(IO_gettimeofday().tv_sec),".ws"));
      Info(SubSemiInfoClass,1,Concatenation("Checkpoint saved after ",
              FormattedBigNumberString(counter), " steps"));
    fi;
  od;
  Info(SubSemiInfoClass,1,"TOTAL: ",###########################################
       String(Size(result)),
       " in ",String(counter)," steps");########################################
  return result;
end;

# mt - multiplication table
# potgens - potential generators, e.g. Indices(mt) for all elements
ISWithGens := function(mt,seed, potgens,ISfunc)
  local stack,db;
  stack := DuplicateFreeStack();#since different cands may have the same rep
  Store(stack, seed);
  if ISfunc = ISDatabase then
    return ISDatabase(mt, potgens, BlistStorage(Size(mt)), stack, []);
  else
    return ISCanCons(mt, potgens, [] ,stack);
  fi;
end;

IS := function(mt,ISfunc) return ISWithGens(mt, [], Indices(mt),ISfunc); end;

# resuming an interrupted calculation by using global variables
# these variables get updated at each checkpoint
ResumeIGS := function(ISfunc)
  return ISfunc(SUBSEMI_IGSCheckPointData.mt,
                SUBSEMI_IGSCheckPointData.potgens,
                SUBSEMI_IGSCheckPointData.iss,
                SUBSEMI_IGSCheckPointData.candidates);
end;


### predicates, independent from the actual search algorithm ###################
# using group multiplication
# this takes the identity singleton as independent, unlike the group case
IsSgpIndependentSet := function(A)
  return IsDuplicateFreeList(A) and
         (Size(A)<2 or
          ForAll(A, x-> not (x in Group(Difference(A,[x])))));
end;

# Deciding whether gens is an independent generating set, by taking all
# of its subsets missing a single generator.
# gens - list, mt - MulTab, S - bitlist
# condition: S = SgpInMulTab(gens,mt); - not checked
IsSgpIGS := function(gens,mt,S)
  if Size(gens) < 2 then return true; fi;
  return not ForAny(gens,x->
                 SizeBlist(S)=SizeBlist(SgpInMulTab(Difference(gens,[x]),mt)));
end;

IsDeadEnd := function(gens,G)
  local diff;
  if IsEmpty(gens) then return false; fi;
  diff := Difference(AsList(G), AsList(Group(gens)));
  return (not IsEmpty(diff))
         and ForAll(diff, x-> not IsSgpIndependentSet(Union(gens,[x])));
end;
