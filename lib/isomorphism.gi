################################################################################
##
## SubSemi
##
## Deciding isomorphism of multiplication tables,
## and based on that of semigroups.
##
## Copyright (C) 2013  Attila Egri-Nagy
##

InstallGlobalFunction(IsomorphismMulTabs,
function(mtA,mtB)
  local L, # the mapping i->L[i]
        N, # the number of elements of the semigroups
        Aprofs,Bprofs, #lookup tables i->ElementProfile(i)
        Bprofs2elts, #lookup table a profile in mtB -> elements of mtB
        BackTrack, # the embedded recursive backtrack function
        used, # keeping track of what elements we used when building up L
        found; # flag for exiting from backtrack gracefully (keeping  L)
  #-----------------------------------------------------------------------------
  BackTrack := function() # receiving L and used as parameters
    local k,i,candidates,X,Y;
    if Size(L)=N then found := true; return; fi;
    k := Size(L)+1; # the index of the next element
    # getting elements of B with matching profiles, not used yet
    candidates := Difference(AsSet(Bprofs2elts[Aprofs[k]]),used);
    if IsEmpty(candidates) then return; fi;
    for i in candidates do
      Add(L,i); AddSet(used, i); # EXTEND by i
      #subarray of mtA, taking the upper left corner
      X := SubArray(mtA, [1..Size(L)]);
      #using the mapping we already have, we map part of mtA to mtB
      X := List(X, x->List(x,
                   function(y)if(y=0) then return 0; else return L[y];fi;
                   end)); # 0 indicates missing elements
      Y := SubArray(mtB,L);
      if X = Y then
        BackTrack();
        if found then return;fi;
      fi;
      Remove(L); Remove(used, Position(used,i)); #UNDO extending
    od;
  end;
  #checking global invariants one by one
  if Size(Rows(mtA)) <> Size(Rows(mtB)) then return fail;fi;
  if MulTabFrequencies(mtA) <> MulTabFrequencies(mtB) then return fail;fi;
  if DiagonalFrequencies(mtA) <> DiagonalFrequencies(mtB) then return fail;fi;
  if IndexPeriodTypeFrequencies(mtA) <> IndexPeriodTypeFrequencies(mtB) then
    return fail;
  fi;
  #for lining-up the elements we need the profiles
  Aprofs := ElementProfileLookup(mtA);
  Bprofs := ElementProfileLookup(mtB);
  #just another quick invariant
  if AsSet(ValueSet(Aprofs)) <> AsSet(ValueSet(Bprofs)) then return fail;fi;
  Bprofs2elts := ReversedAssociativeList(Bprofs);
  #now the backtrack
  N := Size(Rows(mtA));
  used := [];
  found := false;
  L := [];
  BackTrack();
  if Size(L)=N then
    return PermList(L);
  else
    return fail;
  fi;
end);

#returns a mapping for the whole semigroup
InstallGlobalFunction(IsomorphismSemigroups,
function(S,T)
  local mtS, mtT, perm,source, image, mappingfunc;
  if Size(S) <> Size(T) then return fail; fi;
  #calculating multiplication tables
  mtS := MulTab(S);
  mtT := MulTab(T);
  perm := IsomorphismMulTabs(mtS, mtT);
  if perm = fail then return fail; fi; #not isomorphic
  #if they are isomorphic then we construct the mapping
  source := SortedElements(mtS);
  image := List(ListPerm(perm, Size(T)), x->SortedElements(mtT)[x]);
  mappingfunc := function(s) return image[Position(source,s)];end;
  return MappingByFunction(S,T,mappingfunc);
end);

# given a list of semigroups returns isomorphism class representatives
IsomorphismClassesSgpsReps := function(sgps)
  local fullcheck,al, k,tmp, result, sgp;
  #-----------------------------------------------------------------------------
  fullcheck := function(semis)
    local indices,i,mts,mt;
    indices:=[];
    mts := [];#List(semis,x->MulTab(x)); #precalc multabs
    for i in [1..Size(semis)] do
      #checking for the first x such that it is isomorphic to i
      mt := MulTab(semis[i]);
      if First(mts, x->IsomorphismMulTabs(mt,x)<>fail) = fail then
        Add(indices,i); #adding if it is not isomorphic to any already listed
        Add(mts,mt);
      fi;
    od;
    return List(indices, x->semis[x]);#just convert them back to semis
  end;
  #-----------------------------------------------------------------------------
  #we want to prefilter by table profiles
  al := AssociativeList();
  for sgp in sgps do
    Collect(al,MulTabProfile(MulTab(sgp)) ,sgp);
  od;
  result := [];
  for k in Keys(al) do
    tmp := al[k];
    if Size(tmp) = 1 then
      Append(result, tmp);
    else
      Append(result,fullcheck(tmp));
    fi;
  od;
  return result;
end;
